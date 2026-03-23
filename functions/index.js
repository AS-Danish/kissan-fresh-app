const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {setGlobalOptions} = require("firebase-functions/v2");
const admin = require("firebase-admin");
const Razorpay = require("razorpay");

admin.initializeApp();

// Set global options to use Node 20 and specific region if needed
setGlobalOptions({region: "us-central1"});

/**
 * Triggered when a new document is added to the 'failed_orders' collection.
 * This function automatically issues a refund using the Razorpay API.
 */
exports.processimmediaterefund = onDocumentCreated("failed_orders/{docId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) {
    console.log("No data associated with the event");
    return null;
  }

  const data = snapshot.data();
  const docId = event.params.docId;

  // Only attempt refund if status is 'paid_but_stock_failed' and not already refunded
  if (data.status !== "paid_but_stock_failed" || data.refundStatus === "processed") {
    console.log(`Document ${docId} skipped: Status is ${data.status}, RefundStatus is ${data.refundStatus}`);
    return null;
  }

  const {paymentId, totalAmount, currency} = data;

  if (!paymentId) {
    console.error(`Document ${docId} missing paymentId. Cannot process refund.`);
    return snapshot.ref.update({
      refundStatus: "failed",
      refundError: "Missing paymentId",
    });
  }

  // Initialize Razorpay with keys from secret manager
  // IMPORTANT: You must set these in your Firebase project using:
  // firebase functions:secrets:set RAZORPAY_KEY
  // firebase functions:secrets:set RAZORPAY_SECRET
  const razorpayKey = process.env.RAZORPAY_KEY;
  const razorpaySecret = process.env.RAZORPAY_SECRET;

  if (!razorpayKey || !razorpaySecret) {
    console.error("Razorpay keys are not configured in Firebase Secrets.");
    return snapshot.ref.update({
      refundStatus: "failed",
      refundError: "Razorpay keys not configured in Secrets",
    });
  }

  const razorpay = new Razorpay({
    key_id: razorpayKey,
    key_secret: razorpaySecret,
  });

  try {
    console.log(`Initiating v2 refund for Payment ID: ${paymentId}, Amount: ${totalAmount}`);

    const refund = await razorpay.payments.refund(paymentId, {
      amount: Math.round(totalAmount * 100),
      notes: {
        reason: "Auto-refund due to stock race condition (v2)",
        failed_order_doc_id: docId,
      },
    });

    console.log(`Refund successful for ${docId}:`, refund.id);

    return snapshot.ref.update({
      refundStatus: "processed",
      refundId: refund.id,
      refundTimestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (error) {
    console.error(`Refund failed for ${docId}:`, error);
    return snapshot.ref.update({
      refundStatus: "failed",
      refundError: error.message || "Unknown error during refund",
    });
  }
});

/**
 * Callable function to process order creation and slot/rider assignment natively inside a transaction.
 */
exports.createOrder = onCall(async (request) => {
  const data = request.data;
  const auth = request.auth;

  if (!auth) {
    throw new HttpsError("unauthenticated", "User must be logged in to place an order.");
  }

  const orderData = data.order;
  if (!orderData || !orderData.items || orderData.items.length === 0) {
    throw new HttpsError("invalid-argument", "Missing order items.");
  }

  const db = admin.firestore();
  const now = admin.firestore.Timestamp.now();

  try {
    // 1. Fetch candidate slots outside transaction
    const candidateSlotsSnap = await db.collection("slots")
      .where("isActive", "==", true)
      .where("isLocked", "==", false)
      .where("endTime", ">", now)
      .orderBy("endTime", "asc")
      .limit(5)
      .get();
    
    if (candidateSlotsSnap.empty) {
      throw new HttpsError("failed-precondition", "Currently no slots are available. Please try again later.", { reason: "no_slots_available" });
    }

    const candidateSlotIds = candidateSlotsSnap.docs.map(doc => doc.id);

    // 2. Perform Transaction
    const result = await db.runTransaction(async (transaction) => {
      // a. Check all products to verify stock availability
      const productRefs = orderData.items.map(item => db.collection("products").doc(item.productId));
      const productSnaps = await transaction.getAll(...productRefs);
      const stockUpdates = [];

      for (let i = 0; i < productSnaps.length; i++) {
        const snap = productSnaps[i];
        const item = orderData.items[i];

        if (!snap.exists) {
          throw new HttpsError("failed-precondition", `Product ${item.title} no longer available.`, { reason: "product_unavailable" });
        }

        const currentStock = snap.data().stockCount || 0;
        if (currentStock < item.quantity) {
          throw new HttpsError("failed-precondition", `Insufficient stock for ${item.title}. Available: ${currentStock}`, { reason: "insufficient_stock" });
        }

        stockUpdates.push({ ref: snap.ref, newStock: currentStock - item.quantity });
      }

      // b. Verify candidate slots and look for one with capacity and assignable rider
      let selectedSlotDoc = null;
      let selectedRiderDoc = null;

      for (const slotId of candidateSlotIds) {
        const slotRef = db.collection("slots").doc(slotId);
        const slotSnap = await transaction.get(slotRef);

        if (!slotSnap.exists) continue;

        const slotCtx = slotSnap.data();
        if (!slotCtx.isActive || slotCtx.isLocked) continue;

        const cap = slotCtx.capacity || 0;
        const ass = slotCtx.assignedOrders || 0;

        if (ass >= cap) continue;

        // Valid slot found. Look for an available rider in this slot's subcollection
        const avRidersQuery = slotRef.collection("riders")
            .where("assignedOrders", "<", 6)
            .orderBy("assignedOrders", "asc")
            .limit(1);

        const ridersSnap = await transaction.get(avRidersQuery);

        if (!ridersSnap.empty) {
          selectedSlotDoc = slotSnap;
          selectedRiderDoc = ridersSnap.docs[0];
          break; // Stop looking once we found both
        }
      }

      if (!selectedSlotDoc || !selectedRiderDoc) {
        throw new HttpsError("failed-precondition", "No active slots are currently available for delivery. They might be fully booked.", { reason: "no_slots_available" });
      }

      // c. Write operations
      // Deduct stock levels
      for (const update of stockUpdates) {
        transaction.update(update.ref, { stockCount: update.newStock });
      }

      // Update Slot
      const newSlotAssignedOrders = (selectedSlotDoc.data().assignedOrders || 0) + 1;
      transaction.update(selectedSlotDoc.ref, { assignedOrders: newSlotAssignedOrders });

      // Update Rider
      const newRiderAssignedOrders = (selectedRiderDoc.data().assignedOrders || 0) + 1;
      transaction.update(selectedRiderDoc.ref, { assignedOrders: newRiderAssignedOrders });

      // Create final order Document natively including assigned states
      const orderRef = db.collection("orders").doc(orderData.id);
      const enrichedOrderData = {
        ...orderData,
        slotId: selectedSlotDoc.id,
        riderId: selectedRiderDoc.id,
        status: "assigned",
        // Force timestamp for DB sorting reliability rather than trusting client DateTime entirely
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        assignedAt: admin.firestore.FieldValue.serverTimestamp()
      };
      
      transaction.set(orderRef, enrichedOrderData);
      
      return enrichedOrderData;
    });

    console.log(`✅ Order ${orderData.id} successfully created and assigned to Slot: ${result.slotId}, Rider: ${result.riderId}`);
    return { success: true, message: "Order processed successfully", orderId: orderData.id, slotId: result.slotId, riderId: result.riderId };

  } catch (error) {
    if (error instanceof HttpsError) {
      throw error;
    }
    console.error(`🚨 Error creating order ${orderData.id}:`, error);
    throw new HttpsError("internal", "An unexpected error occurred while placing your order.", error.message);
  }
});
