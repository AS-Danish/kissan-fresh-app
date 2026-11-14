const test = require("node:test");
const assert = require("node:assert/strict");
const {createHmac} = require("node:crypto");
const {signatureMatches, paymentMatches, orderPricing} = require("./payment-validation");

test("rejects missing, forged and malformed signatures", () => {
  const message = "order_test|pay_test";
  const signed = createHmac("sha256", "test").update(message).digest("hex");
  assert.equal(signatureMatches("test", message, signed), true);
  assert.equal(signatureMatches("test", message, undefined), false);
  assert.equal(signatureMatches("", message, signed), false);
  assert.equal(signatureMatches("test", "order_other|pay_test", signed), false);
  assert.equal(signatureMatches("test", message, "z".repeat(64)), false);
});

test("requires the exact captured amount, currency, and saved Razorpay order", () => {
  const draft = {razorpayOrderId: "order_test", payablePaise: 5200};
  const payment = {order_id: "order_test", amount: 5200, currency: "INR", status: "captured"};
  assert.equal(paymentMatches(payment, draft), true);
  for (const mismatch of [{amount: 1}, {order_id: "other"}, {currency: "USD"},
    {status: "authorized"}, {amount_refunded: 500}]) {
    assert.equal(paymentMatches({...payment, ...mismatch}, draft), false);
  }
});

test("prices items from the catalog and rejects edited totals and wallet credit", () => {
  const products = new Map([["fruit", {price: 55, stockCount: 4, title: "Fruit"}]]);
  const order = {items: [{productId: "fruit", quantity: 2, price: 1}],
    totalAmount: 140, walletAppliedPaise: 500};
  const result = orderPricing(order, products, null, 500);
  assert.equal(result.items[0].price, 55);
  assert.equal(result.payablePaise, 13500);
  assert.throws(() => orderPricing({...order, totalAmount: 1}, products, null, 500));
  assert.throws(() => orderPricing(order, products, null, 499));
  assert.throws(() => orderPricing({...order, items: [...order.items, ...order.items,
    ...order.items]}, products, null, 500));
});

test("uses variation price and limits coupon discount to eligible merchandise", () => {
  const products = new Map([
    ["fruit", {productOrigin: "kissan-fresh", category: "Fruit", hasVariations: true,
      variations: [{id: "small", price: 100, stockCount: 2}]}],
    ["salad", {productOrigin: "kissan-fresh", category: "Salad", price: 200, stockCount: 2}],
  ]);
  const coupon = {isActive: true, productType: "kissan-fresh", applicableCategory: "Fruit",
    discountType: "flat", discountValue: 150};
  const order = {items: [{productId: "fruit", variationId: "small", quantity: 1},
    {productId: "salad", quantity: 1}], totalAmount: 230, couponCode: "FRUIT"};
  assert.equal(orderPricing(order, products, coupon, 0).payablePaise, 23000);
  assert.throws(() => orderPricing(order, products, {...coupon, totalUsageLimit: 0}, 0));
});
