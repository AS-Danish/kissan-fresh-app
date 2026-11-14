const test = require("node:test");
const assert = require("node:assert/strict");
const {executeOrderFulfillment} = require("./order-fulfillment");

function fixture({stock = 2, failCommit = false} = {}) {
  const id = "KF-TEST01";
  const draft = {
    id, userId: "buyer", slotId: "evening", razorpayOrderId: "order_test",
    status: "PENDING_PAYMENT", payablePaise: 5000,
    items: [{productId: "fruit", quantity: 1, title: "Fruit"}],
  };
  const records = new Map([
    [`pending_orders/${id}`, draft], ["users/buyer", {name: "Buyer"}],
    ["products/fruit", {stockCount: stock}],
    ["slots/evening", {isActive: true, capacity: 10, assignedOrders: 0}],
    ["slots/evening/riders/rider", {assignedOrders: 0}],
  ]);
  function snapshot(ref) {
    return {id: ref.id, ref, exists: records.has(ref.path),
      data: () => structuredClone(records.get(ref.path))};
  }
  function collection(path) {
    return {
      doc: (id) => reference(`${path}/${id}`),
      where: () => ({orderBy: () => ({limit: () => ({path, query: true})})}),
    };
  }
  function reference(path) {
    return {path, id: path.split("/").at(-1), get: async () => snapshot(reference(path)),
      collection: (name) => collection(`${path}/${name}`)};
  }
  const db = {
    collection,
    async runTransaction(body) {
      const writes = [];
      await body({
        get: async (ref) => ref.query
          ? {empty: false, docs: [snapshot(reference(`${ref.path}/rider`))]}
          : snapshot(ref),
        getAll: async (...refs) => refs.map(snapshot),
        set: (ref, data) => writes.push(() => records.set(ref.path, data)),
        create: (ref, data) => writes.push(() => {
          assert.equal(records.has(ref.path), false);
          records.set(ref.path, data);
        }),
        update: (ref, data) => writes.push(() =>
          records.set(ref.path, {...records.get(ref.path), ...data})),
      });
      if (failCommit) throw Error("temporary Firestore failure");
      for (const write of writes) write();
    },
  };
  const stamp = () => 0;
  const admin = {firestore: {FieldValue: {serverTimestamp: stamp, delete: stamp}, Timestamp: {now: stamp}}};
  let notifications = 0;
  const fulfill = () => executeOrderFulfillment({
    db, admin, notify: async () => notifications++,
  }, id, {paymentId: "pay_test", razorpayOrderId: "order_test"});
  return {id, records, fulfill, notifications: () => notifications,
    restoreFirestore: () => { failCommit = false; }};
}

test("captured payment creates one order even when confirmation is repeated", async () => {
  const f = fixture();
  assert.equal((await f.fulfill()).success, true);
  assert.equal((await f.fulfill()).success, true);
  assert.equal(f.records.get(`orders/${f.id}`).customerName, "Buyer");
  assert.equal(f.records.get("products/fruit").stockCount, 1);
  assert.equal(f.notifications(), 1);
});

test("stock loss queues one refund without creating an order or consuming capacity", async () => {
  const f = fixture({stock: 0});
  assert.equal((await f.fulfill()).status, "refund_pending");
  assert.equal((await f.fulfill()).status, "refund_pending");
  assert.equal(f.records.has(`orders/${f.id}`), false);
  assert.equal(f.records.get(`failed_orders/${f.id}`).paymentId, "pay_test");
  assert.equal(f.records.get("slots/evening").assignedOrders, 0);
});

test("an interrupted commit leaves the checkout retryable", async () => {
  const f = fixture({failCommit: true});
  await assert.rejects(f.fulfill(), /temporary Firestore failure/);
  assert.equal(f.records.get(`pending_orders/${f.id}`).status, "PENDING_PAYMENT");
  assert.equal(f.records.get("products/fruit").stockCount, 2);
  f.restoreFirestore();
  assert.equal((await f.fulfill()).success, true);
  assert.equal(f.records.get("products/fruit").stockCount, 1);
});
