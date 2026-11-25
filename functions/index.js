const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp();
}
const db = admin.firestore();
const { signatureMatches, paymentMatches, orderPricing, deductOrderStock } = require("./payment-validation");
const { HttpsError } = require("firebase-functions/v2/https");
const Razorpay = require("razorpay");
const {executeOrderFulfillment} = require("./order-fulfillment");

function paymentGateway() {
  const keyId = process.env.RAZORPAY_KEY?.trim();
  const secret = process.env.RAZORPAY_SECRET?.trim();
  if (!keyId || !secret) throw new HttpsError("unavailable", "Payment service is unavailable.");
  const projectId = process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT || admin.app().options.projectId;
  if (projectId !== "kissanfresh-a72c1" && !keyId.startsWith("rzp_test_")) {
    throw new HttpsError("failed-precondition", "Development checkout requires Razorpay test credentials.");
  }
  return new Razorpay({key_id: keyId, key_secret: secret});
}

async function priceOrder(reader, order, uid) {
  if (!Array.isArray(order?.items) || order.items.length < 1 || order.items.length > 100 ||
      order.items.some((item) => typeof item?.productId !== "string" ||
        !item.productId || item.productId.includes("/"))) {
    throw new HttpsError("invalid-argument", "Invalid order items.");
  }
  const refs = [...new Set(order.items.map((item) => item.productId))]
    .map((id) => db.collection("products").doc(id));
  const products = new Map((await reader.getAll(...refs))
    .filter((snap) => snap.exists).map((snap) => [snap.id, snap.data()]));
  let coupon;
  if (order.couponCode) {
    const query = db.collection("coupons")
      .where("code", "==", String(order.couponCode).trim().toUpperCase()).limit(1);
    const snapshot = await reader.get(query);
    coupon = snapshot.docs[0]?.data();
    if (coupon?.maxUsesPerUser != null) {
      const prior = await reader.get(db.collection("orders").where("userId", "==", uid)
        .where("couponCode", "==", coupon.code).limit(coupon.maxUsesPerUser || 1));
      if (prior.size >= coupon.maxUsesPerUser) {
        throw new HttpsError("failed-precondition", "Coupon usage limit reached.");
      }
    }
  }
  const wallet = order.walletAppliedPaise > 0
    ? await reader.get(db.collection("debug_wallet_accounts").doc(uid)) : null;
  return orderPricing(order, products, coupon, Number(wallet?.data()?.balancePaise || 0));
}

function orderInput(data) {
  const order = data?.order;
  if (!order || !Number.isFinite(order.latitude) || !Number.isFinite(order.longitude) ||
      getDistance(order.latitude, order.longitude, 19.8762, 75.3433) > 30 ||
      typeof order.slotId !== "string" || !order.slotId || order.slotId.includes("/")) {
    throw new HttpsError("failed-precondition", "Select a valid delivery address and slot.");
  }
  return {
    items: order.items,
    totalAmount: order.totalAmount,
    walletAppliedPaise: order.walletAppliedPaise ?? 0,
    couponCode: order.couponCode ? String(order.couponCode).trim().toUpperCase() : null,
    slotId: order.slotId,
    latitude: order.latitude,
    longitude: order.longitude,
    deliveryAddress: String(order.deliveryAddress || "").slice(0, 1000),
    deliveryInstruction: String(order.deliveryInstruction || "").slice(0, 500),
    orderNumber: String(order.orderNumber || "").slice(0, 80),
    orderDate: new Date().toISOString(),
    orderType: order.orderType,
  };
}

function checkoutRequestId(id) {
  if (typeof id !== "string" || !/^[a-f0-9-]{36}$/i.test(id)) {
    throw new HttpsError("invalid-argument", "Missing checkout reference.");
  }
  return id;
}

const { setGlobalOptions } = require("firebase-functions/v2");
setGlobalOptions({ region: "us-central1" });

const debugWalletFunctions = require("./debug-wallet")({ admin, db });
exports.getDebugWallet = debugWalletFunctions.getDebugWallet;
exports.previewDebugOrderAdjustment = debugWalletFunctions.previewDebugOrderAdjustment;
exports.createDebugOrderAdjustment = debugWalletFunctions.createDebugOrderAdjustment;
exports.refundWalletToBank = debugWalletFunctions.refundWalletToBank;

/**
 * Haversine formula to calculate distance between two points in km.
 * @param {number} lat1 Latitude of point 1.
 * @param {number} lon1 Longitude of point 1.
 * @param {number} lat2 Latitude of point 2.
 * @param {number} lon2 Longitude of point 2.
 * @return {number} Distance in km.
 */
function getDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // Earth's radius in km
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}


async function generateSlotsCore(db, admin) {
  try {
    const configSnap = await db.collection("config").doc("slots").get();
    let activeHours = [];
    if (configSnap.exists && configSnap.data().activeHours && configSnap.data().activeHours.length > 0) {
      activeHours = configSnap.data().activeHours;
    } else {
      activeHours = Array.from({length: 16}, (_, i) => i + 6); // 6 to 21
    }
    // Firestore configuration is user-editable, so normalise it before using it
    // in document IDs and date construction. Invalid values used to make the
    // callable fail with a generic "internal" error in the dashboard.
    activeHours = [...new Set(activeHours
      .map((hour) => Number(hour))
      .filter((hour) => Number.isInteger(hour) && hour >= 0 && hour <= 23))]
      .sort((a, b) => a - b);
    if (activeHours.length === 0) {
      throw new Error("Choose at least one valid delivery hour (00:00–23:00) before generating slots.");
    }

    const ridersQuery = db.collection("riders")
      .where("status", "==", "ACTIVE");
    const ridersSnap = await ridersQuery.get();
    const activeRiders = ridersSnap.docs.map((doc) => {
      return { id: doc.id, ...doc.data() };
    });

    const capacityPerSlot = activeRiders.length * 6;
    let batch = db.batch();
    let writeCount = 0;

    const formatter = new Intl.DateTimeFormat("en-CA", {
      timeZone: "Asia/Kolkata",
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
    });

    // `Intl.DateTimeFormat(...).format()` is locale/ICU dependent. Construct
    // the ID explicitly so slots always use the expected YYYY-MM-DD_HH form.
    const formatDateInIndia = (date) => {
      const parts = Object.fromEntries(formatter.formatToParts(date)
        .filter(({ type }) => type !== "literal")
        .map(({ type, value }) => [type, value]));
      return `${parts.year}-${parts.month}-${parts.day}`;
    };

    let slotsCreated = 0;
    let existingSlots = 0;

    for (let dayOffset = 0; dayOffset <= 1; dayOffset++) {
      const targetDate = new Date();
      const dayMs = dayOffset * 24 * 60 * 60 * 1000;
      targetDate.setTime(targetDate.getTime() + dayMs);
      const dateString = formatDateInIndia(targetDate);

      console.log(`Generating slots for date: ${dateString}`);

      for (const hour of activeHours) {
        const hourString = hour.toString().padStart(2, "0");
        const slotId = `${dateString}_${hourString}`;

        const slotRef = db.collection("slots").doc(slotId);
        const slotSnap = await slotRef.get();
        if (slotSnap.exists) {
          existingSlots++;
          continue; // Skip if already created
        }

        const slotStartStr = `${dateString}T${hourString}:00:00+05:30`;
        const nextHourStr = (hour + 1).toString().padStart(2, "0");
        const slotEndStr = `${dateString}T${nextHourStr}:00:00+05:30`;

        const slotStart = new Date(slotStartStr);
        const slotEnd = new Date(slotEndStr);

        batch.set(slotRef, {
          startTime: admin.firestore.Timestamp.fromDate(slotStart),
          endTime: admin.firestore.Timestamp.fromDate(slotEnd),
          isActive: true,
          isLocked: false,
          capacity: capacityPerSlot,
          assignedOrders: 0,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        writeCount++;

        for (const rider of activeRiders) {
          const riderSlotRef = slotRef.collection("riders").doc(rider.id);
          batch.set(riderSlotRef, {
            riderId: rider.riderId || rider.id,
            maxOrders: 6,
            assignedOrders: 0,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          }, { merge: true });
          writeCount++;
        }

        slotsCreated++;

        if (writeCount > 400) {
          await batch.commit();
          batch = db.batch();
          writeCount = 0;
        }
      }
    }

    if (writeCount > 0) {
      await batch.commit();
    }

    console.log(`Successfully generated ${slotsCreated} slots.`);
    return {
      success: true,
      count: slotsCreated,
      existingCount: existingSlots,
      activeRiderCount: activeRiders.length,
    };
  } catch (error) {
    console.error("Error generating daily slots:", error);
    throw error;
  }
}

exports.generateDailySlots = require("firebase-functions/v2/scheduler")
  .onSchedule({
    schedule: "0 0 * * *",
    timeZone: "Asia/Kolkata",
    retryCount: 3,
  }, async (event) => {
    await generateSlotsCore(db, admin);
  });

exports.manualGenerateSlots = require("firebase-functions/v2/https")
  .onCall(async (request) => {
    const { HttpsError } = require("firebase-functions/v2/https");
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "You must be signed in to generate slots.");
    }

    try {
      const requesterDoc = await db.collection("users").doc(request.auth.uid).get();
      const requester = requesterDoc.data();
      const role = requester?.role?.toUpperCase();
      const canManageSlots = role === "ADMIN" ||
        (role === "MANAGEMENT" && requester?.permissions?.["Slot Management"] === true);

      if (!requesterDoc.exists || !canManageSlots) {
        throw new HttpsError("permission-denied", "You do not have permission to generate slots.");
      }

      const result = await generateSlotsCore(db, admin);
      return result;
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      throw new HttpsError("internal", error.message);
    }
  });

/**
 * Triggered when a new document is added to the 'failed_orders' collection.
 * This function automatically issues a refund using the Razorpay API.
 */
const refundLeaseMs = 5 * 60 * 1000;

async function refundFailedCheckout(ref) {
  const orderId = ref.id;
  const pending = await db.collection("pending_orders").doc(orderId).get();
  const draft = pending.data();
  if (draft?.status !== "FAILED" || !draft.refundRequired || !draft.paymentId) return;
  const claim = await db.runTransaction(async (transaction) => {
    const data = (await transaction.get(ref)).data();
    if (!data || data.paymentId !== draft.paymentId || data.userId !== draft.userId ||
        !["pending", "processing"].includes(data.refundStatus) ||
        data.retryAfter?.toMillis() > Date.now()) return null;
    const attempts = (data.attempts || 0) + 1;
    const lease = require("node:crypto").randomUUID();
    transaction.update(ref, {
      refundStatus: "processing", attempts, lease,
      retryAfter: admin.firestore.Timestamp.fromMillis(Date.now() + refundLeaseMs),
    });
    return {attempts, lease, refundId: data.refundId};
  });
  if (!claim) return;

  const finish = (changes) => db.runTransaction(async (transaction) => {
    if ((await transaction.get(ref)).data()?.lease !== claim.lease) return;
    if (["processed", "failed"].includes(changes.refundStatus)) {
      changes.retryAfter = admin.firestore.FieldValue.delete();
    }
    transaction.update(ref, changes);
  });
  try {
    const gateway = paymentGateway();
    const payment = await gateway.payments.fetch(draft.paymentId);
    if (payment.order_id !== draft.razorpayOrderId ||
        payment.amount !== draft.payablePaise || payment.currency !== "INR") {
      return await finish({refundStatus: "failed", refundError: "Payment does not match the order."});
    }
    // A previous invocation may have created the refund and crashed before
    // saving its ID. Look it up before attempting another refund.
    const refunds = await gateway.payments.fetchMultipleRefund(draft.paymentId);
    const existing = claim.refundId
      ? refunds.items.find((refund) => refund.id === claim.refundId)
      : refunds.items.find((refund) => refund.status !== "failed");
    if (existing && existing.amount !== payment.amount) {
      return await finish({refundStatus: "failed", refundError: "Partial refund requires review."});
    }
    if (!existing && claim.refundId) {
      throw new Error("Previously created refund is not available yet.");
    }
    if (!existing && !paymentMatches(payment, draft)) {
      return await finish({refundStatus: "failed", refundError: "Payment requires review."});
    }
    const refund = existing || await gateway.payments.refund(draft.paymentId, {
      amount: payment.amount, receipt: orderId, notes: {orderId},
    });
    await finish({
      refundStatus: refund.status === "failed" ? "failed" :
        refund.status === "processed" ? "processed" : "processing",
      refundId: refund.id, refundTimestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (error) {
    console.error("Checkout refund attempt failed", orderId, error.message);
    await finish({
      refundStatus: claim.attempts >= 8 ? "failed" : "pending",
      refundError: "Razorpay refund could not be confirmed.",
      retryAfter: admin.firestore.Timestamp.fromMillis(Date.now() +
        Math.min(60, 2 ** claim.attempts) * 60000),
    });
  }
}

exports.processimmediaterefund = require("firebase-functions/v2/firestore").onDocumentCreated({
  document: "failed_orders/{docId}", secrets: ["RAZORPAY_KEY", "RAZORPAY_SECRET"],
  retry: true,
}, async (event) => {
  if (event.data) await refundFailedCheckout(event.data.ref);
});

/**
 * Callable function to process order creation and specific slot/rider
 * assignment natively inside a transaction.
 */
exports.createOrder = require("firebase-functions/v2/https")
  .onCall({ enforceAppCheck: true }, async (request) => {
      const auth = request.auth;
      if (!auth) throw new HttpsError("unauthenticated", "Sign in to place an order.");
      const input = orderInput(request.data);
      const requestId = request.data?.requestId
        ? checkoutRequestId(request.data.requestId)
        : require("node:crypto").createHash("sha256").update(input.orderNumber).digest("hex");
      if (!input.orderNumber) throw new HttpsError("invalid-argument", "Missing order reference.");
      const requestRef = db.collection("direct_order_requests").doc(`${auth.uid}_${requestId}`);
      const selectedSlotId = input.slotId;
      const requestedWalletPaise = input.walletAppliedPaise;
      if (!["COD", "Wallet"].includes(input.orderType)) {
        throw new HttpsError("failed-precondition", "Use the verified online checkout.");
      }

      try {
        const result = await db.runTransaction(async (transaction) => {
          const prior = (await transaction.get(requestRef)).data();
          if (prior) return {...prior, replayed: true};
          const priced = await priceOrder(transaction, input, auth.uid);
          if (input.orderType === "Wallet" && priced.payablePaise !== 0) {
            throw new HttpsError("failed-precondition", "Wallet balance does not cover this order.");
          }
          const { payablePaise, ...orderData } = priced;
          orderData.paymentStatus = payablePaise === 0 ? "paid" : "pending";
          const userRef = db.collection("users").doc(auth.uid);
          const userSnap = await transaction.get(userRef);
          const customerName = userSnap.exists ? (userSnap.data()?.name || userSnap.data()?.displayName || "Guest") : "Guest";

          let walletRef = null;
          let walletData = null;
          if (requestedWalletPaise > 0) {
            if (requestedWalletPaise > Math.round(Number(orderData.totalAmount || 0) * 100)) {
              throw new HttpsError("invalid-argument", "Wallet amount exceeds the order total.");
            }
            walletRef = db.collection("debug_wallet_accounts").doc(auth.uid);
            const walletSnap = await transaction.get(walletRef);
            walletData = walletSnap.data() || {};
            if ((Number(walletData.balancePaise) || 0) < requestedWalletPaise) {
              throw new HttpsError("failed-precondition", "Wallet balance changed. Refresh checkout and try again.");
            }
          }

          let couponDoc = null;
          if (orderData.couponCode) {
            const couponQuery = db.collection("coupons")
              .where("code", "==", orderData.couponCode.toString().trim().toUpperCase())
              .limit(1);
            const couponSnapshot = await transaction.get(couponQuery);
            if (couponSnapshot.empty) {
              throw new HttpsError("failed-precondition", "The selected coupon is no longer available.");
            }
            couponDoc = couponSnapshot.docs[0];
            const coupon = couponDoc.data();
            const usageLimit = Number(coupon.totalUsageLimit || 0);
            const usageCount = Number(coupon.currentUsageCount || 0);
            if (!coupon.isActive || (usageLimit > 0 && usageCount >= usageLimit)) {
              throw new HttpsError("failed-precondition", "The selected coupon has expired or reached its usage limit.");
            }
          }

          const uniqueProductIds = [...new Set(orderData.items.map((item) => item.productId))];
          const productRefs = uniqueProductIds.map((id) => db.collection("products").doc(id));
          const productSnaps = await transaction.getAll(...productRefs);

          const productDataMap = {};
          const productRefMap = {};

          for (const snap of productSnaps) {
            if (!snap.exists) {
              throw new HttpsError("failed-precondition", "A product in your order is no longer available.", {reason: "product_unavailable"});
            }
            productDataMap[snap.id] = snap.data();
            productRefMap[snap.id] = snap.ref;
          }

          deductOrderStock(orderData.items, new Map(Object.entries(productDataMap)));

          const slotRef = db.collection("slots").doc(selectedSlotId);
          const slotSnap = await transaction.get(slotRef);
          if (!slotSnap.exists) {
            throw new HttpsError("failed-precondition",
              `Selected slot no longer exists.`,
              { reason: "slot_invalid" });
          }

          const slotCtx = slotSnap.data();
          if (!slotCtx.isActive || slotCtx.isLocked) {
            throw new HttpsError("failed-precondition",
              "The selected delivery slot is no longer active.",
              { reason: "slot_inactive" });
          }

          const cap = slotCtx.capacity || 0;
          const ass = slotCtx.assignedOrders || 0;

          if (ass >= cap) {
            throw new HttpsError("failed-precondition",
              "The selected slot is now fully booked. " +
              "Please select another slot.",
              { reason: "slot_full" });
          }

          const avRidersQuery = slotRef.collection("riders")
            .where("assignedOrders", "<", 6)
            .orderBy("assignedOrders", "asc")
            .limit(1);

          const ridersSnap = await transaction.get(avRidersQuery);

          if (ridersSnap.empty) {
            throw new HttpsError("failed-precondition",
              "Currently no slots are available. Please try again later.",
              { reason: "slot_full_riders" });
          }

          const selectedSlotDoc = slotSnap;
          const selectedRiderDoc = ridersSnap.docs[0];

          // A create precondition prevents overwriting an existing order.
          const shortId = `KF-${require("node:crypto").randomBytes(8).toString("hex").toUpperCase()}`;
          const orderRef = db.collection("orders").doc(shortId);

          for (const id of uniqueProductIds) {
            transaction.update(productRefMap[id], productDataMap[id]);
          }

          if (couponDoc) {
            transaction.update(couponDoc.ref, {
              currentUsageCount: admin.firestore.FieldValue.increment(1),
            });
          }

          const newSlotAssignedOrders =
            (selectedSlotDoc.data().assignedOrders || 0) + 1;
          transaction.update(selectedSlotDoc.ref,
            { assignedOrders: newSlotAssignedOrders });

          const newRiderAssignedOrders =
            (selectedRiderDoc.data().assignedOrders || 0) + 1;
          transaction.update(selectedRiderDoc.ref,
            { assignedOrders: newRiderAssignedOrders });

          const cleanOrderData = { ...orderData };
          delete cleanOrderData.walletAppliedPaise;
          const enrichedOrderData = {
            ...cleanOrderData,
            id: shortId, // use new short ID
            userId: auth.uid,
            slotId: selectedSlotDoc.id,
            riderId: selectedRiderDoc.id,
            status: "ASSIGNED",
            customerName: customerName,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            assignedAt: admin.firestore.FieldValue.serverTimestamp(),
            ...(requestedWalletPaise > 0 ? { walletAppliedPaise: requestedWalletPaise } : {}),
          };

          transaction.create(orderRef, enrichedOrderData);
          transaction.create(requestRef, {
            id: enrichedOrderData.id, slotId: enrichedOrderData.slotId,
            riderId: enrichedOrderData.riderId,
          });
          if (walletRef) {
            transaction.update(walletRef, {
              balancePaise: (Number(walletData.balancePaise) || 0) - requestedWalletPaise,
              lifetimeDebitPaise: (Number(walletData.lifetimeDebitPaise) || 0) + requestedWalletPaise,
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            transaction.create(db.collection("debug_wallet_entries").doc(`order_${shortId}`), {
              userId: auth.uid,
              orderId: shortId,
              type: "ORDER_DEBIT",
              amountPaise: -requestedWalletPaise,
              currency: "INR",
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
          }

          return enrichedOrderData;
        });

        if (result.replayed) {
          return {success: true, orderId: result.id, slotId: result.slotId, riderId: result.riderId};
        }

        console.log(`✅ Order ${result.id} successfully created and ` +
          `assigned to requested Slot: ${result.slotId}, ` +
          `Rider: ${result.riderId}`);

        // 6. Send FCM Notification to User (Non-blocking)
        try {
          const userRef = db.collection("users").doc(auth.uid);
          const userSnap = await userRef.get();
          const fcmToken = userSnap.data()?.fcmToken;

          if (fcmToken) {
            const message = {
              notification: {
                title: "Order Successfully Placed!",
                body: `Your order #${result.id} has been confirmed. ` +
                  `Thank you for shopping with Kissan Fresh!`,
              },
              android: {
                notification: {
                  channelId: "high_importance_channel",
                  sound: "loud_alert",
                },
              },
              apns: {
                payload: {
                  aps: {
                    sound: "loud_alert.caf",
                  },
                },
              },
              data: {
                orderId: result.id,
                type: "ORDER_PLACED",
              },
              token: fcmToken,
            };
            await admin.messaging().send(message);
            console.log(`FCM notification sent for Order: ${result.id}`);
          } else {
            console.log(`No FCM token found for User: ${auth.uid}. ` +
              `Skipping notification.`);
          }
        } catch (err) {
          console.error(`Error sending FCM notification for order ${result.id}:`, err);
        }

        // 6b. Send FCM Notification to Admin Devices (Non-blocking)
        try {
          const adminTokensSnap = await db.collection("admin_tokens").get();
          if (!adminTokensSnap.empty) {
            const tokens = [];
            adminTokensSnap.forEach((doc) => {
              const t = doc.data().token;
              if (t) {
                tokens.push(t);
              }
            });

            if (tokens.length > 0) {
              const customerName = result.customerName || "Customer";
              const multicastMessage = {
                notification: {
                  title: "New Order Arrived!",
                  body: `New Order Arrived from "${customerName}"`,
                },
                android: {
                  notification: {
                    channelId: "high_importance_channel",
                    sound: "loud_alert",
                  },
                },
                apns: {
                  payload: {
                    aps: {
                      sound: "loud_alert.caf",
                    },
                  },
                },
                data: {
                  orderId: result.id,
                  type: "NEW_ORDER_ADMIN",
                },
                tokens: tokens,
              };

              const response = await admin.messaging().sendEachForMulticast(multicastMessage);
              console.log(`Admin FCM notifications sent: success ${response.successCount}, failure ${response.failureCount}`);

              // Clean up invalid or unregistered tokens from database
              if (response.failureCount > 0) {
                const batch = db.batch();
                response.responses.forEach((resp, idx) => {
                  if (!resp.success) {
                    const error = resp.error;
                    if (error && (error.code === "messaging/registration-token-not-registered" ||
                                  error.code === "messaging/invalid-registration-token")) {
                      const failedToken = tokens[idx];
                      const tokenDocRef = db.collection("admin_tokens").doc(failedToken);
                      batch.delete(tokenDocRef);
                      console.log(`Cleaning up invalid admin token: ${failedToken}`);
                    }
                  }
                });
                await batch.commit();
              }
            }
          } else {
            console.log("No admin FCM tokens found in admin_tokens collection.");
          }
        } catch (adminErr) {
          console.error("Error sending admin FCM notification:", adminErr);
        }

        // 6c. Send FCM Notification to Dashboard Devices (Non-blocking)
        try {
          const dashboardTokensSnap = await db.collection("dashboard_tokens").get();
          if (!dashboardTokensSnap.empty) {
            const tokens = [];
            dashboardTokensSnap.forEach((doc) => {
              const t = doc.data().token;
              if (t) {
                tokens.push(t);
              }
            });

            if (tokens.length > 0) {
              const customerName = result.customerName || "Customer";
              const multicastMessage = {
                notification: {
                  title: "New Order Arrived!",
                  body: `New Order Arrived from "${customerName}"`,
                },
                data: {
                  orderId: result.id,
                  type: "NEW_ORDER_DASHBOARD",
                },
                tokens: tokens,
              };

              const response = await admin.messaging().sendEachForMulticast(multicastMessage);
              console.log(`Dashboard FCM notifications sent: success ${response.successCount}, failure ${response.failureCount}`);

              // Clean up invalid or unregistered tokens from database
              if (response.failureCount > 0) {
                const batch = db.batch();
                response.responses.forEach((resp, idx) => {
                  if (!resp.success) {
                    const error = resp.error;
                    if (error && (error.code === "messaging/registration-token-not-registered" ||
                                  error.code === "messaging/invalid-registration-token")) {
                      const failedToken = tokens[idx];
                      const tokenDocRef = db.collection("dashboard_tokens").doc(failedToken);
                      batch.delete(tokenDocRef);
                      console.log(`Cleaning up invalid dashboard token: ${failedToken}`);
                    }
                  }
                });
                await batch.commit();
              }
            }
          } else {
            console.log("No dashboard FCM tokens found in dashboard_tokens collection.");
          }
        } catch (dashboardErr) {
          console.error("Error sending dashboard FCM notification:", dashboardErr);
        }


          return {
            success: true,
            message: "Order processed successfully",
            orderId: result.id,
            slotId: result.slotId,
            riderId: result.riderId,
          };
        } catch (error) {
          if (error instanceof HttpsError) {
            throw error;
          }
          console.error(`🚨 Error creating order ${input.orderNumber}:`, error);
          throw new HttpsError("internal",
            "An unexpected error occurred while placing your order.",
            error.message);
        }
      });

/**
 * Reusable helper to dispatch push notifications and external alerts when an order is confirmed.
 */
async function dispatchOrderPlacedNotifications(orderResult, userId) {
  // 1. Send FCM Notification to User
  try {
    const userRef = db.collection("users").doc(userId);
    const userSnap = await userRef.get();
    const fcmToken = userSnap.data()?.fcmToken;

    if (fcmToken) {
      const message = {
        notification: {
          title: "Order Successfully Placed!",
          body: `Your order #${orderResult.id} has been confirmed. Thank you for shopping with Kissan Fresh!`,
        },
        android: {
          notification: {
            channelId: "high_importance_channel",
            sound: "loud_alert",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "loud_alert.caf",
            },
          },
        },
        data: {
          orderId: orderResult.id,
          type: "ORDER_PLACED",
        },
        token: fcmToken,
      };
      await admin.messaging().send(message);
      console.log(`FCM notification sent for Order: ${orderResult.id}`);
    } else {
      console.log(`No FCM token found for User: ${userId}. Skipping notification.`);
    }
  } catch (err) {
    console.error(`Error sending FCM notification for order ${orderResult.id}:`, err);
  }

  // 2. Send FCM Notification to Admin Devices
  try {
    const adminTokensSnap = await db.collection("admin_tokens").get();
    if (!adminTokensSnap.empty) {
      const tokens = [];
      adminTokensSnap.forEach((doc) => {
        const t = doc.data().token;
        if (t) tokens.push(t);
      });

      if (tokens.length > 0) {
        const customerName = orderResult.customerName || "Customer";
        const multicastMessage = {
          notification: {
            title: "New Order Arrived!",
            body: `New Order Arrived from "${customerName}"`,
          },
          android: {
            notification: {
              channelId: "high_importance_channel",
              sound: "loud_alert",
            },
          },
          apns: {
            payload: {
              aps: {
                sound: "loud_alert.caf",
              },
            },
          },
          data: {
            orderId: orderResult.id,
            type: "NEW_ORDER_ADMIN",
          },
          tokens: tokens,
        };

        const response = await admin.messaging().sendEachForMulticast(multicastMessage);
        console.log(`Admin FCM notifications sent: success ${response.successCount}, failure ${response.failureCount}`);

        if (response.failureCount > 0) {
          const batch = db.batch();
          response.responses.forEach((resp, idx) => {
            if (!resp.success) {
              const error = resp.error;
              if (error && (error.code === "messaging/registration-token-not-registered" ||
                            error.code === "messaging/invalid-registration-token")) {
                const failedToken = tokens[idx];
                batch.delete(db.collection("admin_tokens").doc(failedToken));
                console.log(`Cleaning up invalid admin token: ${failedToken}`);
              }
            }
          });
          await batch.commit();
        }
      }
    }
  } catch (adminErr) {
    console.error("Error sending admin FCM notification:", adminErr);
  }

  // 3. Send FCM Notification to Dashboard Devices
  try {
    const dashboardTokensSnap = await db.collection("dashboard_tokens").get();
    if (!dashboardTokensSnap.empty) {
      const tokens = [];
      dashboardTokensSnap.forEach((doc) => {
        const t = doc.data().token;
        if (t) tokens.push(t);
      });

      if (tokens.length > 0) {
        const customerName = orderResult.customerName || "Customer";
        const multicastMessage = {
          notification: {
            title: "New Order Arrived!",
            body: `New Order Arrived from "${customerName}"`,
          },
          data: {
            orderId: orderResult.id,
            type: "NEW_ORDER_DASHBOARD",
          },
          tokens: tokens,
        };

        const response = await admin.messaging().sendEachForMulticast(multicastMessage);
        console.log(`Dashboard FCM notifications sent: success ${response.successCount}, failure ${response.failureCount}`);

        if (response.failureCount > 0) {
          const batch = db.batch();
          response.responses.forEach((resp, idx) => {
            if (!resp.success) {
              const error = resp.error;
              if (error && (error.code === "messaging/registration-token-not-registered" ||
                            error.code === "messaging/invalid-registration-token")) {
                const failedToken = tokens[idx];
                batch.delete(db.collection("dashboard_tokens").doc(failedToken));
                console.log(`Cleaning up invalid dashboard token: ${failedToken}`);
              }
            }
          });
          await batch.commit();
        }
      }
    }
  } catch (dashboardErr) {
    console.error("Error sending dashboard FCM notification:", dashboardErr);
  }

  // 4. Send Telegram Alert if configured
  try {
    const botToken = process.env.TELEGRAM_BOT_TOKEN;
    const chatId = process.env.TELEGRAM_CHAT_ID;
    if (botToken && chatId) {
      const text = `🛒 *New Order Received!*\n\n*Order ID:* ${orderResult.id}\n*Slot:* ${orderResult.slotId}\n*Rider ID:* ${orderResult.riderId}\n*Status:* Confirmed`;
      await fetch(`https://api.telegram.org/bot${botToken}/sendMessage`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          chat_id: chatId,
          text: text,
          parse_mode: "Markdown",
        }),
      });
      console.log(`Telegram notification sent for Order: ${orderResult.id}`);
    }
  } catch (tgErr) {
    console.error("Error sending Telegram alert:", tgErr);
  }
}

const paymentSecrets = ["RAZORPAY_KEY", "RAZORPAY_SECRET"];
const paymentCallable = {enforceAppCheck: true, secrets: paymentSecrets};
const {onCall, onRequest} = require("firebase-functions/v2/https");

async function readPendingOrder(orderId, uid) {
  if (typeof orderId !== "string" || !/^KF-[A-Z0-9]{6,24}$/.test(orderId)) {
    throw new HttpsError("invalid-argument", "Invalid order reference.");
  }
  const draft = (await db.collection("pending_orders").doc(orderId).get()).data();
  if (!draft || (uid && draft.userId !== uid)) {
    throw new HttpsError("not-found", "Order reference not found.");
  }
  return draft;
}

function checkoutResponse(draft) {
  return {success: true, orderId: draft.id, razorpayOrderId: draft.razorpayOrderId,
    amountPaise: draft.payablePaise, keyId: process.env.RAZORPAY_KEY.trim()};
}

exports.createRazorpayOrder = onCall(paymentCallable, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in to check out.");
  const uid = request.auth.uid;
  const input = orderInput(request.data);
  if (!input.orderNumber) throw new HttpsError("invalid-argument", "Missing order reference.");
  const requestId = request.data?.requestId ? checkoutRequestId(request.data.requestId)
    : require("node:crypto").createHash("sha256").update(input.orderNumber).digest("hex");
  const ref = db.collection("payment_requests").doc(`${uid}_${requestId}`);
  const prior = (await ref.get()).data();
  const fingerprint = require("node:crypto").createHash("sha256")
    .update(JSON.stringify([input.items.map(({productId, variationId, quantity}) =>
      [productId, variationId ?? null, quantity]), input.slotId, input.deliveryAddress,
      input.deliveryInstruction, input.couponCode, input.totalAmount, input.walletAppliedPaise]))
    .digest("hex");
  const existingSession = async (existing) => {
    if (existing.fingerprint && existing.fingerprint !== fingerprint) {
      throw new HttpsError("failed-precondition",
        "This payment attempt belongs to a different cart. Check its status first.");
    }
    const draft = await readPendingOrder(existing.orderId, uid);
    if (draft.status !== "PENDING_PAYMENT" || draft.customerDetached) {
      throw new HttpsError("failed-precondition", "This checkout has already ended.");
    }
    return checkoutResponse(draft);
  };
  if (prior?.orderId) return existingSession(prior);
  const priced = await priceOrder({
    getAll: (...refs) => db.getAll(...refs), get: (ref) => ref.get(),
  }, input, uid);
  if (priced.payablePaise <= 0) {
    throw new HttpsError("failed-precondition", "Use wallet checkout for this order.");
  }
  const slotRef = db.collection("slots").doc(input.slotId);
  const [slotSnapshot, riders] = await Promise.all([
    slotRef.get(),
    slotRef.collection("riders").where("assignedOrders", "<", 6).limit(1).get(),
  ]);
  const slot = slotSnapshot.data();
  if (!slot?.isActive || slot.isLocked || (slot.assignedOrders || 0) >= (slot.capacity || 0) ||
      riders.empty) {
    throw new HttpsError("failed-precondition", "Select an available delivery slot.");
  }
  const id = `KF-${require("node:crypto").randomBytes(8).toString("hex").toUpperCase()}`;
  const gatewayOrder = await paymentGateway().orders.create({
    amount: priced.payablePaise, currency: "INR", receipt: id, notes: {orderId: id},
  });
  const draft = {...priced, id, userId: uid, orderType: "Online",
    razorpayOrderId: gatewayOrder.id, status: "PENDING_PAYMENT",
    createdAt: admin.firestore.FieldValue.serverTimestamp()};
  const selected = await db.runTransaction(async (transaction) => {
    const existing = (await transaction.get(ref)).data();
    if (existing?.orderId) return existing;
    transaction.create(db.collection("pending_orders").doc(id), draft);
    transaction.create(ref, {orderId: id, fingerprint, createdAt: draft.createdAt});
    return null;
  });
  return selected ? existingSession(selected) : checkoutResponse(draft);
});

async function reconcileOrder(orderId, draft, payment, source) {
  if (draft.status === "FULFILLED") return {success: true, orderId, status: "confirmed"};
  if (draft.status === "FAILED") {
    const refund = (await db.collection("failed_orders").doc(orderId).get()).data();
    const status = refund?.refundStatus === "processed" ? "refunded" :
      refund?.refundStatus === "failed" ? "refund_review" : "refund_pending";
    return {success: false, orderId, status};
  }
  if (!paymentMatches(payment, draft)) return {success: false, orderId, status: "pending"};
  const ref = db.collection("pending_orders").doc(orderId);
  await db.runTransaction(async (transaction) => {
    const current = (await transaction.get(ref)).data();
    if (current?.status === "PENDING_PAYMENT" && !current.capturedPaymentId) {
      transaction.update(ref, {capturedPaymentId: payment.id,
        capturedAt: admin.firestore.FieldValue.serverTimestamp()});
    }
  });
  const result = await executeOrderFulfillment({
    db, admin, notify: dispatchOrderPlacedNotifications,
  }, orderId, {
    paymentId: payment.id, razorpayOrderId: draft.razorpayOrderId, source,
  });
  return {...result, status: result.success ? "confirmed" : "refund_pending"};
}

exports.verifyAndConfirmOrder = onCall(paymentCallable, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in to check your order.");
  const {orderId, razorpayPaymentId, razorpayOrderId, razorpaySignature} = request.data || {};
  const draft = await readPendingOrder(orderId, request.auth.uid);
  if (razorpayOrderId !== draft.razorpayOrderId || !razorpayPaymentId ||
      !signatureMatches(process.env.RAZORPAY_SECRET?.trim(),
        `${draft.razorpayOrderId}|${razorpayPaymentId}`, razorpaySignature)) {
    throw new HttpsError("permission-denied", "Payment signature is invalid.");
  }
  const payment = await paymentGateway().payments.fetch(razorpayPaymentId);
  return reconcileOrder(orderId, draft, payment, "client_confirmation");
});

async function reconcileCapturedOrder(id, draft, source) {
  if (draft.status !== "PENDING_PAYMENT") return reconcileOrder(id, draft, null, source);
  if (draft.capturedPaymentId) {
    const payment = await paymentGateway().payments.fetch(draft.capturedPaymentId);
    return reconcileOrder(id, draft, payment, source);
  }
  const payments = await paymentGateway().orders.fetchPayments(draft.razorpayOrderId);
  const captured = payments.items.find((payment) => paymentMatches(payment, draft));
  return reconcileOrder(id, draft, captured, source);
}

exports.getCheckoutStatus = onCall(paymentCallable, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in to check your order.");
  const orderId = request.data?.orderId;
  return reconcileCapturedOrder(orderId, await readPendingOrder(orderId, request.auth.uid), "status_check");
});

exports.detachCheckout = onCall(paymentCallable, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in to check your order.");
  const id = request.data?.orderId;
  const draft = await readPendingOrder(id, request.auth.uid);
  if (draft.status !== "PENDING_PAYMENT") return reconcileOrder(id, draft, null, "status_check");
  const payments = await paymentGateway().orders.fetchPayments(draft.razorpayOrderId);
  const captured = payments.items.find((payment) => paymentMatches(payment, draft));
  if (captured) return reconcileOrder(id, draft, captured, "status_check");
  if (payments.items.some((payment) => !["failed", "refunded"].includes(payment.status))) {
    return {status: "pending"};
  }
  // Keep the draft available to the webhook and scheduler if a late capture arrives.
  const ref = db.collection("pending_orders").doc(id);
  const detached = await db.runTransaction(async (transaction) => {
    const current = (await transaction.get(ref)).data();
    if (current.status !== "PENDING_PAYMENT") return false;
    transaction.update(ref, {customerDetached: true});
    return true;
  });
  return detached ? {status: "detached"} :
    reconcileOrder(id, await readPendingOrder(id, request.auth.uid), null, "status_check");
});

exports.reconcilePendingPayments = require("firebase-functions/v2/scheduler").onSchedule({
  schedule: "every 15 minutes", secrets: paymentSecrets,
}, async () => {
  const due = await db.collection("failed_orders")
    .where("retryAfter", "<=", admin.firestore.Timestamp.now()).orderBy("retryAfter").limit(100).get();
  for (let offset = 0; offset < due.docs.length; offset += 5) {
    const results = await Promise.allSettled(
      due.docs.slice(offset, offset + 5).map((doc) => refundFailedCheckout(doc.ref)),
    );
    for (const result of results) {
      if (result.status === "rejected") console.error("Refund reconciliation error", result.reason);
    }
  }
  // Captures already verified by the backend remain recoverable after the
  // normal checkout search window, even after a prolonged outage.
  let capturedQuery = db.collection("pending_orders").orderBy("capturedAt").limit(100);
  for (;;) {
    const page = await capturedQuery.get();
    for (const doc of page.docs) {
      try {
        await reconcileCapturedOrder(doc.id, doc.data(), "scheduled_reconciliation");
      } catch (error) {
        console.error("Captured payment still awaiting fulfillment", doc.id, error.message);
      }
    }
    if (page.size < 100) break;
    capturedQuery = capturedQuery.startAfter(page.docs.at(-1));
  }
  const recent = admin.firestore.Timestamp.fromMillis(Date.now() - 7 * 86400000);
  let query = db.collection("pending_orders").where("createdAt", ">=", recent)
    .orderBy("createdAt").limit(100);
  for (;;) {
    const page = await query.get();
    for (const doc of page.docs) {
      const draft = doc.data();
      if (draft.status !== "PENDING_PAYMENT" || draft.capturedPaymentId) continue;
      try {
        await reconcileCapturedOrder(doc.id, draft, "scheduled_reconciliation");
      } catch (error) {
        console.error("Payment reconciliation failed", doc.id, error.message);
      }
    }
    if (page.size < 100) break;
    query = query.startAfter(page.docs.at(-1));
  }
});

exports.razorpayWebhook = onRequest({
  secrets: [...paymentSecrets, "RAZORPAY_WEBHOOK_SECRET"],
}, async (req, res) => {
  if (req.method !== "POST") return res.sendStatus(405);
  const secret = process.env.RAZORPAY_WEBHOOK_SECRET?.trim();
  if (!secret) return res.sendStatus(503);
  if (!signatureMatches(secret, req.rawBody, req.headers["x-razorpay-signature"])) {
    return res.sendStatus(401);
  }
  if (!["order.paid", "payment.captured"].includes(req.body?.event)) return res.sendStatus(204);
  const entity = req.body.payload?.payment?.entity;
  const order = req.body.payload?.order?.entity;
  const id = order?.receipt || order?.notes?.orderId || entity?.notes?.orderId;
  if (!id) return res.sendStatus(204);
  try {
    const draft = await readPendingOrder(id);
    if ((entity?.order_id || order?.id) !== draft.razorpayOrderId) return res.sendStatus(204);
    await reconcileCapturedOrder(id, draft, "razorpay_webhook");
    return res.sendStatus(204);
  } catch (error) {
    if (["invalid-argument", "not-found"].includes(error.code)) return res.sendStatus(204);
    console.error("Razorpay webhook reconciliation failed", id, error.message);
    return res.sendStatus(500);
  }
});

/**
 * Triggered when an order status is updated.
 * Sends a push notification to the user.
 */
exports.onOrderStatusUpdate = require("firebase-functions/v2/firestore")
  .onDocumentUpdated("orders/{orderId}", async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    // Only proceed if status has changed
    if (before.status === after.status) return null;

    const orderId = event.params.orderId;
    const userId = after.userId;
    const newStatus = (after.status || "").toUpperCase();

    if (!userId) return null;

    try {
      // Fetch user token
      const userSnap = await db.collection("users").doc(userId).get();
      const userData = userSnap.data();
      const fcmToken = userData?.fcmToken;

      if (!fcmToken) {
        console.log(`No FCM token found for user ${userId}. Skipping.`);
        return null;
      }

      // Determine message body based on status
      let body = `Your order #${orderId} status has been updated to ${newStatus}.`;

      if (newStatus === "ASSIGNED") {
        body = `Order #${orderId} has been assigned to a rider and will be with you soon.`;
      } else if (newStatus === "OUT FOR DELIVERY") {
        body = `Order #${orderId} is out for delivery! 🚚 Get ready for freshness.`;
      } else if (newStatus === "DELIVERED") {
        body = `Order #${orderId} has been delivered. Enjoy your Kissan Fresh products! 🧺`;
      } else if (newStatus === "CANCELLED") {
        body = `Order #${orderId} has been cancelled. Please contact support if you have questions.`;
      } else if (newStatus === "PROCESSING") {
        body = `Order #${orderId} is now being processed and prepared for delivery.`;
      }

      const message = {
        notification: {
          title: "Order Update",
          body: body,
        },
        android: {
          notification: {
            channelId: "high_importance_channel",
            sound: "loud_alert",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "loud_alert.caf",
            },
          },
        },
        data: {
          orderId: orderId,
          type: "ORDER_STATUS_UPDATE",
          status: newStatus,
        },
        token: fcmToken,
      };

      await admin.messaging().send(message);
      console.log(`✅ FCM notification sent for Order: ${orderId}, Status: ${newStatus}`);
    } catch (error) {
      console.error(`🚨 Error sending FCM for order ${orderId}:`, error);
    }
    return null;
  });

/**
 * Sync Firestore Products to Algolia Index
 */
exports.syncProductToAlgolia = require("firebase-functions/v2/firestore")
  .onDocumentWritten({
    document: "products/{productId}",
    secrets: ["ALGOLIA_APP_ID", "ALGOLIA_ADMIN_API_KEY"],
  }, async (event) => {
    const algoliasearch = require("algoliasearch");

    // Check if secrets are available in the environment
    const appId = process.env.ALGOLIA_APP_ID;
    const adminKey = process.env.ALGOLIA_ADMIN_API_KEY;

    if (!appId || !adminKey) {
        console.error("Algolia credentials are not configured in Firebase Secrets.");
        return null;
    }

    const client = algoliasearch(appId, adminKey);
    const index = client.initIndex("products");
    const productId = event.params.productId;

    // Document was deleted
    if (!event.data.after.exists) {
        try {
            await index.deleteObject(productId);
            console.log(`Successfully deleted product ${productId} from Algolia`);
        } catch (error) {
            console.error(`Error deleting product ${productId} from Algolia`, error);
        }
        return null;
    }

    // Document was created or updated
    const data = event.data.after.data();

    const algoliaObject = {
        objectID: productId,
        name: data.name,
        description: data.description,
        category: data.category,
        price: data.price,
        mrp: data.mrp,
        discountPercentage: data.discountPercentage,
        image: data.images && data.images.length > 0 ? data.images[0] : null,
        productOrigin: data.productOrigin,
        inStock: data.inStock,
        tags: data.tags,
        hasVariations: data.hasVariations,
        unit: data.unit,
        unitValue: data.unitValue
    };

    try {
        await index.saveObject(algoliaObject);
        console.log(`Successfully synced product ${productId} to Algolia`);
    } catch (error) {
        console.error(`Error syncing product ${productId} to Algolia`, error);
    }

    return null;
  });

/**
 * Helper to normalize dates/timestamps to ISO string for Algolia.
 * @param {*} val Date, Timestamp, or date string/number.
 * @return {string|null} ISO date string or null.
 */
function normalizeDateToIso(val) {
  if (!val) return null;
  if (typeof val.toDate === "function") return val.toDate().toISOString();
  if (typeof val.toMillis === "function") return new Date(val.toMillis()).toISOString();
  if (val instanceof Date) return val.toISOString();
  if (typeof val === "number") return new Date(val).toISOString();
  if (typeof val === "string") {
    const parsed = Date.parse(val);
    return isNaN(parsed) ? val : new Date(parsed).toISOString();
  }
  return null;
}

/**
 * Helper to normalize timestamps to epoch milliseconds for Algolia.
 * @param {*} val Date, Timestamp, or date string/number.
 * @return {number|null} Milliseconds timestamp or null.
 */
function normalizeTimestampToMillis(val) {
  if (!val) return null;
  if (typeof val.toMillis === "function") return val.toMillis();
  if (typeof val.toDate === "function") return val.toDate().getTime();
  if (val instanceof Date) return val.getTime();
  if (typeof val === "number") return val;
  if (typeof val === "string") {
    const parsed = Date.parse(val);
    return isNaN(parsed) ? null : parsed;
  }
  return null;
}

/**
 * Sync Firestore Orders to Algolia Index
 */
exports.syncOrderToAlgolia = require("firebase-functions/v2/firestore")
  .onDocumentWritten({
    document: "orders/{orderId}",
    secrets: ["ALGOLIA_APP_ID", "ALGOLIA_ADMIN_API_KEY"],
  }, async (event) => {
    const algoliasearch = require("algoliasearch");

    const appId = process.env.ALGOLIA_APP_ID;
    const adminKey = process.env.ALGOLIA_ADMIN_API_KEY;

    if (!appId || !adminKey) {
      console.error("Algolia credentials are not configured in Firebase Secrets.");
      return null;
    }

    const client = algoliasearch(appId, adminKey);
    const index = client.initIndex("orders");
    const orderId = event.params.orderId;

    // Document was deleted
    if (!event.data.after.exists) {
      try {
        await index.deleteObject(orderId);
        console.log(`Successfully deleted order ${orderId} from Algolia`);
      } catch (error) {
        console.error(`Error deleting order ${orderId} from Algolia`, error);
      }
      return null;
    }

    // Document was created or updated
    const data = event.data.after.data();
    if (!data) return null;

    const orderDate = normalizeDateToIso(data.orderDate) ||
      normalizeDateToIso(data.createdAt) ||
      new Date().toISOString();

    const items = Array.isArray(data.items) ? data.items.map((item) => ({
      productId: item.productId || item.id || null,
      title: item.title || item.name || "",
      price: Number(item.price) || 0,
      mrp: Number(item.mrp) || 0,
      quantity: Number(item.quantity) || 1,
      unit: item.unit || "",
      image: item.image || (item.images && item.images[0]) || null,
    })) : [];

    const algoliaObject = {
      objectID: orderId,
      id: orderId,
      path: `orders/${orderId}`,
      orderNumber: data.orderNumber || orderId,
      orderDate: orderDate,
      userId: data.userId || null,
      customerName: data.customerName || null,
      status: (data.status || "PENDING").toUpperCase(),
      orderType: (data.orderType || data.paymentMethod || "ONLINE").toUpperCase(),
      paymentMethod: (data.paymentMethod || data.orderType || "ONLINE").toUpperCase(),
      paymentStatus: (data.paymentStatus || "pending").toLowerCase(),
      totalAmount: data.totalAmount != null ? Number(data.totalAmount) : 0,
      subtotal: data.subtotal != null ? Number(data.subtotal) : 0,
      deliveryFee: data.deliveryFee != null ? Number(data.deliveryFee) : 0,
      discount: data.discount != null ? Number(data.discount) : 0,
      couponDiscount: data.couponDiscount != null ? Number(data.couponDiscount) : 0,
      walletAppliedPaise: Number(data.walletAppliedPaise) || 0,
      debugAdjustedAmountPaise: Number(data.debugAdjustedAmountPaise) || 0,
      slotId: data.slotId || null,
      riderId: data.riderId || null,
      deliveryInstruction: data.deliveryInstruction || null,
      deliveryAddress: data.deliveryAddress || data.address || null,
      phoneNumber: data.phoneNumber || data.phone || data.userPhone || null,
      latitude: data.latitude != null ? Number(data.latitude) : null,
      longitude: data.longitude != null ? Number(data.longitude) : null,
      items: items,
      createdAt: normalizeTimestampToMillis(data.createdAt) || Date.now(),
      updatedAt: normalizeTimestampToMillis(data.updatedAt) || Date.now(),
      assignedAt: normalizeTimestampToMillis(data.assignedAt),
    };

    try {
      await index.saveObject(algoliaObject);
      console.log(`Successfully synced order ${orderId} to Algolia`);
    } catch (error) {
      console.error(`Error syncing order ${orderId} to Algolia`, error);
    }

    return null;
  });

/**
 * Triggered when a new offer notification is created.
 * If it's marked as instant, send it immediately.
 */
exports.onInstantOfferCreated = require("firebase-functions/v2/firestore")
  .onDocumentCreated("offer_notifications/{docId}", async (event) => {
    const data = event.data.data();
    if (!data) return null;

    if (data.isInstant && data.status === "PENDING") {
      const message = {
        topic: "all_users",
        notification: {
          title: data.title,
          body: data.body,
        },
        android: {
          notification: {
            channelId: "high_importance_channel",
            sound: "loud_alert",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "loud_alert.caf",
            },
          },
        },
        data: {
          type: "OFFER_NOTIFICATION",
          docId: event.params.docId,
        },
      };

      if (data.imageUrl) {
        message.notification.imageUrl = data.imageUrl;
      }

      try {
        await admin.messaging().send(message);
        console.log(`✅ Instant offer sent for doc ${event.params.docId}`);
        return event.data.ref.update({
          status: "SENT",
          sentAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      } catch (error) {
        console.error(`🚨 Error sending instant offer ${event.params.docId}:`, error);
        return event.data.ref.update({
          status: "FAILED",
          error: error.message,
        });
      }
    }
    return null;
  });

/**
 * Scheduled function to process scheduled offers.
 * Runs every minute.
 */
exports.processScheduledOffers = require("firebase-functions/v2/scheduler")
  .onSchedule({
    schedule: "* * * * *",
    timeZone: "Asia/Kolkata",
    retryCount: 3,
    maxInstances: 1,
    concurrency: 1,
  }, async (event) => {
    const now = admin.firestore.Timestamp.now();
    try {
      const pendingOffersSnap = await db.collection("offer_notifications")
        .where("status", "==", "PENDING")
        .where("isInstant", "==", false)
        .where("scheduledFor", "<=", now)
        .limit(100)
        .get();

      if (pendingOffersSnap.empty) {
        console.log("No pending scheduled offers found.");
        return null;
      }

      for (const doc of pendingOffersSnap.docs) {
        const data = doc.data();

        const message = {
          topic: "all_users",
          notification: {
            title: data.title,
            body: data.body,
          },
          android: {
            notification: {
              channelId: "high_importance_channel",
              sound: "loud_alert",
            },
          },
          apns: {
            payload: {
              aps: {
                sound: "loud_alert.caf",
              },
            },
          },
          data: {
            type: "OFFER_NOTIFICATION",
            docId: doc.id,
          },
        };

        if (data.imageUrl) {
          message.notification.imageUrl = data.imageUrl;
        }

        try {
          await admin.messaging().send(message);
        } catch (error) {
          console.error(`🚨 Error sending scheduled offer ${doc.id}:`, error);
          await doc.ref.update({
            status: "FAILED",
            error: error.message,
          });
          continue;
        }
        await doc.ref.update({
          status: "SENT",
          sentAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`✅ Scheduled offer sent for doc ${doc.id}`);
      }

      console.log(`Processed ${pendingOffersSnap.size} scheduled offers.`);
    } catch (error) {
      console.error("Error in processScheduledOffers:", error);
      throw error;
    }
    return null;
  });

/**
 * Callable function to create management users.
 * Only accessible by an existing ADMIN.
 */
exports.createUser = require("firebase-functions/v2/https")
  .onCall(async (request) => {
    const data = request.data;
    const auth = request.auth;
    const { HttpsError } = require("firebase-functions/v2/https");

    if (!auth) {
      throw new HttpsError("unauthenticated", "You must be logged in to create a user.");
    }

    try {
      // Verify requester is an ADMIN
      const requesterDoc = await db.collection("users").doc(auth.uid).get();
      if (!requesterDoc.exists || requesterDoc.data()?.role?.toUpperCase() !== "ADMIN") {
        throw new HttpsError("permission-denied", "Only administrators can create users.");
      }

      const { email, password, role } = data;

      if (!email || !password || !role) {
        throw new HttpsError("invalid-argument", "Missing required fields (email, password, role).");
      }

      const upperRole = role.toUpperCase();
      if (upperRole !== "ADMIN" && upperRole !== "MANAGEMENT") {
        throw new HttpsError("invalid-argument", "Role must be ADMIN or MANAGEMENT.");
      }

      // Create user in Firebase Auth
      const userRecord = await admin.auth().createUser({
        email: email,
        password: password,
      });

      // Create user document in Firestore
      await db.collection("users").doc(userRecord.uid).set({
        email: email,
        role: upperRole,
        permissions: {},
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        uid: userRecord.uid,
        message: "User successfully created.",
      };
    } catch (error) {
      console.error("Error creating user:", error);
      if (error instanceof HttpsError) {
        throw error;
      }
      throw new HttpsError("internal", error.message);
    }
  });

/**
 * Callable function to update a user's password.
 * Only accessible by an existing ADMIN.
 */
exports.updateUserPassword = require("firebase-functions/v2/https")
  .onCall(async (request) => {
    const data = request.data;
    const auth = request.auth;
    const { HttpsError } = require("firebase-functions/v2/https");

    if (!auth) {
      throw new HttpsError("unauthenticated", "You must be logged in to update a password.");
    }

    try {
      // Verify requester is an ADMIN
      const requesterDoc = await db.collection("users").doc(auth.uid).get();
      if (!requesterDoc.exists || requesterDoc.data()?.role?.toUpperCase() !== "ADMIN") {
        throw new HttpsError("permission-denied", "Only administrators can update passwords.");
      }

      const { uid, newPassword } = data;

      if (!uid || !newPassword) {
        throw new HttpsError("invalid-argument", "Missing required fields (uid, newPassword).");
      }

      if (newPassword.length < 6) {
        throw new HttpsError("invalid-argument", "Password must be at least 6 characters long.");
      }

      // Update user password in Firebase Auth
      await admin.auth().updateUser(uid, {
        password: newPassword,
      });

      return {
        success: true,
        message: "Password updated successfully.",
      };
    } catch (error) {
      console.error("Error updating user password:", error);
      if (error instanceof HttpsError) {
        throw error;
      }
      throw new HttpsError("internal", error.message);
    }
  });
