const {createHmac, timingSafeEqual} = require("node:crypto");
const {HttpsError} = require("firebase-functions/v2/https");

function signatureMatches(secret, message, signature) {
  if (!secret || !message || typeof signature !== "string" ||
      !/^[a-f0-9]{64}$/i.test(signature)) return false;
  const expected = createHmac("sha256", secret).update(message).digest();
  return timingSafeEqual(expected, Buffer.from(signature, "hex"));
}

function paymentMatches(payment, draft) {
  return payment?.status === "captured" &&
    payment.order_id === draft.razorpayOrderId &&
    payment.amount === draft.payablePaise &&
    payment.currency === "INR" &&
    !payment.amount_refunded;
}

function inventoryFor(product, item) {
  if (!product) {
    throw new HttpsError("failed-precondition", "A product is unavailable.", {reason: "product_unavailable"});
  }
  const variants = product.hasVariations ? product.variations ?? [] : [];
  if (!variants.length) return product;
  const variant = item.variationId
    ? variants.find((entry) => String(entry.id ?? "null") === item.variationId ||
      `${entry.unitValue || ""}${entry.unit || ""}` === item.variationId)
    : variants[0];
  if (!variant) {
    throw new HttpsError("failed-precondition", "A product variation is unavailable.",
      {reason: "variation_unavailable"});
  }
  return variant;
}

function deductOrderStock(items, products) {
  for (const item of items) {
    const inventory = inventoryFor(products.get(item.productId), item);
    const stock = Number(inventory.stockCount || 0);
    if (!Number.isSafeInteger(item.quantity) || item.quantity < 1 || item.quantity > 999) {
      throw new HttpsError("invalid-argument", "Invalid order quantity.", {reason: "invalid_quantity"});
    }
    if (!Number.isSafeInteger(stock) || stock < item.quantity) {
      throw new HttpsError("failed-precondition",
        `Insufficient stock for ${item.title} (${item.unit}).`, {reason: "insufficient_stock"});
    }
    inventory.stockCount = stock - item.quantity;
    if (inventory.stockCount === 0) inventory.inStock = false;
  }
}

function orderPricing(order, products, coupon, walletBalance) {
  const quantities = new Map();
  let subtotal = 0;
  let eligibleSubtotal = 0;
  const items = order.items.map((item) => {
    const product = products.get(item.productId);
    const inventory = inventoryFor(product, item);
    const price = Number(inventory.price);
    const quantity = item.quantity;
    if (!Number.isFinite(price) || price < 0 ||
        !Number.isSafeInteger(quantity) || quantity < 1 || quantity > 999) {
      throw new HttpsError("invalid-argument", "Invalid product price or quantity.");
    }
    const key = inventory;
    const requested = (quantities.get(key) || 0) + quantity;
    quantities.set(key, requested);
    if (!Number.isSafeInteger(Number(inventory.stockCount || 0)) ||
        requested > Number(inventory.stockCount || 0)) {
      throw new HttpsError("failed-precondition", "A product has insufficient stock.");
    }
    const lineTotal = Math.round(price * 100) * quantity;
    subtotal += lineTotal;
    if (coupon && product.productOrigin === coupon.productType &&
        (coupon.applyTo === "all" ||
          (!coupon.applicableProduct && !coupon.applicableCategory) ||
          coupon.applicableProduct === item.productId ||
          coupon.applicableCategory === product.category)) eligibleSubtotal += lineTotal;
    return {
      productId: item.productId,
      variationId: item.variationId ?? null,
      title: String(product.title || product.name || item.title || "").slice(0, 200),
      unit: String(item.unit || "").slice(0, 50),
      image: String(product.image || item.image || "").slice(0, 1000),
      quantity, price, mrp: Number(inventory.mrp ?? price),
    };
  });
  let discount = 0;
  if (order.couponCode) {
    if (!coupon?.isActive || !eligibleSubtotal ||
        subtotal < Math.round(Number(coupon.minOrderValue || 0) * 100) ||
        (coupon.totalUsageLimit != null &&
         Number(coupon.currentUsageCount || 0) >= Number(coupon.totalUsageLimit))) {
      throw new HttpsError("failed-precondition", "The selected coupon is unavailable.");
    }
    const value = Number(coupon.discountValue);
    if (!Number.isFinite(value) || value < 0) {
      throw new HttpsError("failed-precondition", "The selected coupon is invalid.");
    }
    discount = Math.min(eligibleSubtotal, Math.round(
      coupon.discountType === "percentage" ? eligibleSubtotal * value / 100 : value * 100,
    ));
  }
  const delivery = subtotal > 30000 ? 0 : 3000;
  const total = subtotal + delivery - discount;
  const wallet = order.walletAppliedPaise ?? 0;
  if (!Number.isSafeInteger(wallet) || wallet < 0 || wallet > walletBalance || wallet > total) {
    throw new HttpsError("failed-precondition", "Wallet balance changed. Refresh checkout.");
  }
  if (Math.round(Number(order.totalAmount) * 100) !== total) {
    throw new HttpsError("failed-precondition", "The order total changed. Refresh checkout.");
  }
  return {...order, items, subtotal: subtotal / 100, deliveryFee: delivery / 100,
    couponDiscount: discount / 100, discount: 0, totalAmount: total / 100,
    walletAppliedPaise: wallet, payablePaise: total - wallet};
}

module.exports = {signatureMatches, paymentMatches, orderPricing, deductOrderStock};
