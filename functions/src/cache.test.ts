import * as assert from "assert";
import "./test-setup";
import { getFirestore } from "firebase-admin/firestore";
import { cachedFetch, normalizeKey } from "./cache";

// Requires the Firestore emulator - run via:
//   firebase emulators:exec --only firestore "npm test"
// (which sets FIRESTORE_EMULATOR_HOST automatically).

const db = getFirestore();

async function clearCollection(name: string) {
  const snapshot = await db.collection(name).get();
  await Promise.all(snapshot.docs.map((d) => d.ref.delete()));
}

describe("normalizeKey", () => {
  it("lowercases, trims, and collapses non-alphanumeric runs", () => {
    assert.strictEqual(normalizeKey("  Monstera Deliciosa!! "), "monstera_deliciosa_");
  });
});

describe("cachedFetch", () => {
  const collection = "test_cache";

  afterEach(async () => {
    await clearCollection(collection);
  });

  it("calls fetchLive and caches the result on a miss", async () => {
    let calls = 0;
    const result = await cachedFetch(db, collection, "key1", 1000 * 60, async () => {
      calls++;
      return { value: "fresh" };
    });
    assert.strictEqual(result.value, "fresh");
    assert.strictEqual(calls, 1);

    const doc = await db.collection(collection).doc("key1").get();
    assert.ok(doc.exists);
  });

  it("returns the fresh cached value without calling fetchLive again", async () => {
    await db.collection(collection).doc("key2").set({
      data: { value: "cached" },
      cachedAt: Date.now(),
    });

    let calls = 0;
    const result = await cachedFetch(db, collection, "key2", 1000 * 60, async () => {
      calls++;
      return { value: "fresh" };
    });
    assert.strictEqual(result.value, "cached");
    assert.strictEqual(calls, 0);
  });

  it("refetches when the cached entry is older than the TTL", async () => {
    await db.collection(collection).doc("key3").set({
      data: { value: "stale" },
      cachedAt: Date.now() - 1000 * 60 * 60, // 1 hour old
    });

    let calls = 0;
    const result = await cachedFetch(db, collection, "key3", 1000 * 60, async () => {
      calls++;
      return { value: "refreshed" };
    });
    assert.strictEqual(result.value, "refreshed");
    assert.strictEqual(calls, 1);
  });

  it("serves the stale cached value if the live refetch fails", async () => {
    await db.collection(collection).doc("key4").set({
      data: { value: "stale-but-good" },
      cachedAt: Date.now() - 1000 * 60 * 60,
    });

    const result = await cachedFetch<{ value: string }>(db, collection, "key4", 1000 * 60, async () => {
      throw new Error("upstream is down");
    });
    assert.strictEqual(result.value, "stale-but-good");
  });

  it("throws if there is no cache to fall back to and the live fetch fails", async () => {
    await assert.rejects(
      cachedFetch(db, collection, "key5", 1000 * 60, async () => {
        throw new Error("upstream is down");
      }),
      /upstream is down/
    );
  });
});
