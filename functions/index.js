const {onDocumentCreated} = require("firebase-functions/v2/firestore");
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
