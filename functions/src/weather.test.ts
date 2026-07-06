import * as assert from "assert";
import "./test-setup";
import * as sinon from "sinon";
import { getFirestore } from "firebase-admin/firestore";
import { gridKey, parseWeather, fetchGeocodingLive, NoGeocodingResultsError } from "./weather";
import { cachedFetch } from "./cache";

describe("gridKey", () => {
  it("rounds coordinates to a shared grid cell", () => {
    assert.strictEqual(gridKey(40.7128, -74.006), gridKey(40.71, -74.0));
  });

  it("produces different keys for meaningfully different locations", () => {
    assert.notStrictEqual(gridKey(40.7128, -74.006), gridKey(34.0522, -118.2437));
  });
});

describe("parseWeather", () => {
  it("extracts temperature, condition, and icon", () => {
    const result = parseWeather({
      main: { temp: 21.5 },
      weather: [{ main: "Clouds", icon: "04d" }],
    });
    assert.strictEqual(result.tempCelsius, 21.5);
    assert.strictEqual(result.condition, "Clouds");
    assert.strictEqual(result.iconCode, "04d");
  });

  it("defaults gracefully when fields are missing", () => {
    const result = parseWeather({});
    assert.strictEqual(result.tempCelsius, 0);
    assert.strictEqual(result.condition, "");
    assert.strictEqual(result.iconCode, "");
  });
});

function fakeResponse(body: unknown): Response {
  return new Response(JSON.stringify(body), { status: 200 });
}

describe("fetchGeocodingLive", () => {
  afterEach(() => {
    sinon.restore();
  });

  it("retries a 'City, ST' query with ',US' appended when the first attempt is empty", async () => {
    const stub = sinon.stub(globalThis, "fetch");
    stub.onCall(0).resolves(fakeResponse([]));
    stub.onCall(1).resolves(fakeResponse([{ name: "Wichita", state: "Kansas", country: "US", lat: 1, lon: 2 }]));

    const results = await fetchGeocodingLive("Wichita, KS", "key");

    assert.strictEqual(results.length, 1);
    assert.strictEqual(results[0].name, "Wichita");
    assert.strictEqual(stub.callCount, 2);
    const secondUrl = stub.getCall(1).args[0] as string;
    assert.ok(secondUrl.includes(encodeURIComponent("Wichita, KS,US")));
  });

  it("throws NoGeocodingResultsError when both attempts return empty", async () => {
    // A Response body can only be read once, so each call needs its own
    // instance rather than reusing one via `.resolves`.
    const stub = sinon.stub(globalThis, "fetch");
    stub.callsFake(async () => fakeResponse([]));

    await assert.rejects(
      fetchGeocodingLive("Wichita, KS", "key"),
      (err: unknown) => err instanceof NoGeocodingResultsError
    );
    assert.strictEqual(stub.callCount, 2);
  });

  it("does not retry a query that doesn't look like 'City, ST'", async () => {
    const stub = sinon.stub(globalThis, "fetch");
    stub.resolves(fakeResponse([]));

    await assert.rejects(
      fetchGeocodingLive("Atlantis", "key"),
      (err: unknown) => err instanceof NoGeocodingResultsError
    );
    assert.strictEqual(stub.callCount, 1);
  });

  it("returns results directly without retrying when the first attempt succeeds", async () => {
    const stub = sinon.stub(globalThis, "fetch");
    stub.resolves(fakeResponse([{ name: "Portland", state: "Oregon", country: "US", lat: 1, lon: 2 }]));

    const results = await fetchGeocodingLive("Portland", "key");
    assert.strictEqual(results.length, 1);
    assert.strictEqual(stub.callCount, 1);
  });
});

describe("geocoding cache interaction with NoGeocodingResultsError", () => {
  const db = getFirestore();
  const collection = "geocoding_cache_test";

  afterEach(async () => {
    const snapshot = await db.collection(collection).get();
    await Promise.all(snapshot.docs.map((d) => d.ref.delete()));
  });

  it("never persists a cache entry when fetchLive throws NoGeocodingResultsError", async () => {
    await assert.rejects(
      cachedFetch(db, collection, "no_match_key", 1000 * 60 * 60 * 24 * 90, async () => {
        throw new NoGeocodingResultsError("no such place");
      }),
      (err: unknown) => err instanceof NoGeocodingResultsError
    );

    const doc = await db.collection(collection).doc("no_match_key").get();
    assert.strictEqual(doc.exists, false);
  });
});
