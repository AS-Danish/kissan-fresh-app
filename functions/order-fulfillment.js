const {HttpsError} = require("firebase-functions/v2/https");
const {deductOrderStock} = require("./payment-validation");

/**
 * Idempotent Order Fulfillment Helper.
 * Transits a pre-order from 'pending_orders/{orderId}' to 'orders/{orderId}'.
 * Can be safely called multiple times by both the client callback and the webhook.
 */
async function executeOrderFulfillment(
  {db, admin, notify}, orderId, paymentDetails,
) {
  const confirmedOrderRef = db.collection("orders").doc(orderId);
  const pendingOrderRef = db.collection("pending_orders").doc(orderId);

  // 1. Idempotency Check: If already confirmed in orders, exit cleanly
  const existingOrderSnap = await confirmedOrderRef.get();
  if (existingOrderSnap.exists) {
    if (existingOrderSnap.data().razorpayOrderId !== paymentDetails.razorpayOrderId) {
      throw new Error("Confirmed order does not belong to this Razorpay checkout.");
    }
    console.log(`Order ${orderId} is already fulfilled. Skipping duplicate fulfillment.`);
    return {
      success: true,
      alreadyFulfilled: true,
      orderId: orderId,
    };
  }

  // 2. Fetch pre-order draft from pending_orders
  const pendingSnap = await pendingOrderRef.get();
  if (!pendingSnap.exists) {
    console.error(`Pending order ${orderId} not found in pending_orders collection.`);
    return {
      success: false,
      error: "pending_order_not_found",
      message: "Order pre-record not found.",
    };
  }

  const draftData = pendingSnap.data();
  if (draftData.status === "FULFILLED") {
    console.log(`Pending order ${orderId} was already fulfilled.`);
    return {
      success: true,
      alreadyFulfilled: true,
      orderId: orderId,
    };
  }

  let enrichedOrderData;
  let alreadyFulfilled = false;
  let failure;
  try {
    await db.runTransaction(async (transaction) => {
      enrichedOrderData = undefined;
      alreadyFulfilled = false;
      failure = undefined;
      const checkSnap = await transaction.get(confirmedOrderRef);
      if (checkSnap.exists) {
        if (checkSnap.data().razorpayOrderId !== paymentDetails.razorpayOrderId) {
          throw new Error("Confirmed order does not belong to this Razorpay checkout.");
        }
        alreadyFulfilled = true;
        return;
      }
      const currentDraft = (await transaction.get(pendingOrderRef)).data();
      if (!currentDraft) throw new Error("Pending checkout disappeared during fulfillment.");
      if (currentDraft.status === "FAILED") {
        failure = {reason: currentDraft.failureReason, message: currentDraft.failureMessage};
        return;
      }
      const fail = (reason, message) => {
        failure = {reason, message};
        transaction.update(pendingOrderRef, {
          status: "FAILED", failureReason: reason, failureMessage: message,
          paymentId: paymentDetails.paymentId,
          refundRequired: true,
          capturedAt: admin.firestore.FieldValue.delete(),
          failedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        transaction.create(db.collection("failed_orders").doc(orderId), {
          orderId, error: message, status: "paid_but_stock_failed", refundStatus: "pending",
          paymentId: paymentDetails.paymentId, totalAmount: draftData.payablePaise / 100,
          currency: "INR", userId: draftData.userId,
          retryAfter: admin.firestore.Timestamp.now(),
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
      };
      if (currentDraft.customerDetached) {
        return fail("checkout_detached", "A late payment arrived after checkout was closed.");
      }
      const userRef = db.collection("users").doc(draftData.userId);
      const userSnap = await transaction.get(userRef);
      const customerName = userSnap.exists
        ? userSnap.data()?.name || userSnap.data()?.displayName || "Guest"
        : "Guest";

      // A. Verify Coupon if present
      let couponDoc = null;
      if (draftData.couponCode) {
        const couponQuery = db.collection("coupons")
          .where("code", "==", draftData.couponCode.toString().trim().toUpperCase())
          .limit(1);
        const couponSnapshot = await transaction.get(couponQuery);
        if (couponSnapshot.empty) return fail("coupon_unavailable", "The coupon is no longer available.");
        if (!couponSnapshot.empty) {
          couponDoc = couponSnapshot.docs[0];
          const coupon = couponDoc.data();
          const usageLimit = Number(coupon.totalUsageLimit || 0);
          const usageCount = Number(coupon.currentUsageCount || 0);
          if (!coupon.isActive || (usageLimit > 0 && usageCount >= usageLimit)) {
            return fail("coupon_unavailable", "The coupon is no longer available.");
          }
        }
      }

      // B. Verify and deduct Stock
      const uniqueProductIds = [...new Set(draftData.items.map((item) => item.productId))];
      const productRefs = uniqueProductIds.map((id) => db.collection("products").doc(id));
      const productSnaps = await transaction.getAll(...productRefs);

      const productDataMap = {};
      const productRefMap = {};

      for (const snap of productSnaps) {
        if (!snap.exists) {
          return fail("product_unavailable", "A product in your order is no longer available.");
        }
        productDataMap[snap.id] = snap.data();
        productRefMap[snap.id] = snap.ref;
      }

      try {
        deductOrderStock(draftData.items, new Map(Object.entries(productDataMap)));
      } catch (error) {
        if (!(error instanceof HttpsError) || !error.details?.reason) throw error;
        return fail(error.details.reason, error.message);
      }

      // C. Verify Slot & Rider Assignment
      const slotRef = db.collection("slots").doc(draftData.slotId);
      const slotSnap = await transaction.get(slotRef);
      if (!slotSnap.exists) {
        return fail("slot_invalid", "Selected delivery slot no longer exists.");
      }

      const slotCtx = slotSnap.data();
      if (!slotCtx.isActive || slotCtx.isLocked) {
        return fail("slot_inactive", "The selected delivery slot is no longer active.");
      }

      const cap = slotCtx.capacity || 0;
      const ass = slotCtx.assignedOrders || 0;
      if (ass >= cap) {
        return fail("slot_full", "The selected slot is now fully booked.");
      }

      const avRidersQuery = slotRef.collection("riders")
        .where("assignedOrders", "<", 6)
        .orderBy("assignedOrders", "asc")
        .limit(1);
      const ridersSnap = await transaction.get(avRidersQuery);
      if (ridersSnap.empty) {
        return fail("slot_full_riders", "No riders are currently available for this delivery slot.");
      }

      const selectedSlotDoc = slotSnap;
      const selectedRiderDoc = ridersSnap.docs[0];

      const requestedWalletPaise = draftData.walletAppliedPaise || 0;
      const walletRef = db.collection("debug_wallet_accounts").doc(draftData.userId);
      const walletData = requestedWalletPaise > 0
        ? (await transaction.get(walletRef)).data() : null;
      if (requestedWalletPaise > 0 && Number(walletData?.balancePaise || 0) < requestedWalletPaise) {
        return fail("wallet_balance_changed", "Wallet balance changed during checkout.");
      }

      // D. Apply Stock Updates
      for (const id of uniqueProductIds) {
        transaction.update(productRefMap[id], productDataMap[id]);
      }

      if (couponDoc) {
        transaction.update(couponDoc.ref, {
          currentUsageCount: admin.firestore.FieldValue.increment(1),
        });
      }

      const newSlotAssignedOrders = (selectedSlotDoc.data().assignedOrders || 0) + 1;
      transaction.update(selectedSlotDoc.ref, { assignedOrders: newSlotAssignedOrders });

      const newRiderAssignedOrders = (selectedRiderDoc.data().assignedOrders || 0) + 1;
      transaction.update(selectedRiderDoc.ref, { assignedOrders: newRiderAssignedOrders });

      if (walletData) {
        transaction.update(walletRef, {
          balancePaise: Number(walletData.balancePaise) - requestedWalletPaise,
          lifetimeDebitPaise: (Number(walletData.lifetimeDebitPaise) || 0) + requestedWalletPaise,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        transaction.create(db.collection("debug_wallet_entries").doc(`order_${orderId}`), {
          userId: draftData.userId, orderId, type: "ORDER_DEBIT",
          amountPaise: -requestedWalletPaise, currency: "INR",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      // F. Write Confirmed Order Document
      const cleanDraft = { ...draftData };
      delete cleanDraft.razorpayOrderId;
      delete cleanDraft.payablePaise;
      delete cleanDraft.capturedAt;
      delete cleanDraft.capturedPaymentId;
      enrichedOrderData = {
        ...cleanDraft,
        id: orderId,
        slotId: selectedSlotDoc.id,
        riderId: selectedRiderDoc.id,
        status: "ASSIGNED",
        paymentStatus: "paid",
        customerName: customerName,
        paymentId: paymentDetails.paymentId || draftData.paymentId || null,
        razorpayOrderId: paymentDetails.razorpayOrderId || draftData.razorpayOrderId || null,
        fulfilledVia: paymentDetails.source || "system",
        createdAt: draftData.createdAt || admin.firestore.FieldValue.serverTimestamp(),
        assignedAt: admin.firestore.FieldValue.serverTimestamp(),
        paidAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      transaction.set(confirmedOrderRef, enrichedOrderData);
      transaction.update(pendingOrderRef, {
        status: "FULFILLED",
        capturedAt: admin.firestore.FieldValue.delete(),
        fulfilledAt: admin.firestore.FieldValue.serverTimestamp(),
        fulfilledVia: paymentDetails.source || "system",
      });
    });

    if (alreadyFulfilled) return {success: true, orderId};
    if (failure) return {
      success: false, orderId, error: failure.reason, message: failure.message,
      refundInitiated: true, status: "refund_pending",
    };

    console.log(`✅ Order ${orderId} successfully fulfilled via ${paymentDetails.source}.`);

    await notify(enrichedOrderData, draftData.userId)
      .catch((error) => console.error("Order notification failed", orderId, error.message));

    return {
      success: true,
      orderId: orderId,
      slotId: enrichedOrderData.slotId,
      riderId: enrichedOrderData.riderId,
    };
  } catch (err) {
    console.error(`Error executing order fulfillment for ${orderId}:`, err);
    throw err;
  }
}

module.exports = {executeOrderFulfillment};
