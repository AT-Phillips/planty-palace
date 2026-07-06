import * as assert from "assert";
import "./test-setup";
import { getFirestore } from "firebase-admin/firestore";
import { checkAndIncrementRateLimit, parseIdentifyResults } from "./identify";

const db = getFirestore();

describe("parseIdentifyResults", () => {
  it("maps PlantNet's result shape, sorts by score desc, and caps at 5", () => {
    const raw = {
      results: [
        { score: 0.2, species: { scientificNameWithoutAuthor: "Low Score" } },
        {
          score: 0.9,
          species: {
            scientificNameWithoutAuthor: "Monstera deliciosa",
            commonNames: ["Swiss cheese plant"],
          },
        },
        { score: 0.1, species: { scientificNameWithoutAuthor: "A" } },
        { score: 0.1, species: { scientificNameWithoutAuthor: "B" } },
        { score: 0.1, species: { scientificNameWithoutAuthor: "C" } },
        { score: 0.1, species: { scientificNameWithoutAuthor: "D" } },
      ],
    };
    const suggestions = parseIdentifyResults(raw);
    assert.strictEqual(suggestions.length, 5);
    assert.strictEqual(suggestions[0].scientificName, "Monstera deliciosa");
    assert.strictEqual(suggestions[0].commonName, "Swiss cheese plant");
    assert.strictEqual(suggestions[0].score, 0.9);
  });

  it("returns an empty array when there are no results", () => {
    assert.deepStrictEqual(parseIdentifyResults({}), []);
  });
});

describe("checkAndIncrementRateLimit", () => {
  const uid = "test-user-1";

  afterEach(async () => {
    const today = new Date().toISOString().slice(0, 10);
    await db.collection("usage_limits").doc(`${uid}_${today}`).delete();
  });

  it("allows calls under the daily cap and increments the counter", async () => {
    await checkAndIncrementRateLimit(db, uid);
    await checkAndIncrementRateLimit(db, uid);

    const today = new Date().toISOString().slice(0, 10);
    const doc = await db.collection("usage_limits").doc(`${uid}_${today}`).get();
    assert.strictEqual(doc.data()?.count, 2);
  });

  it("throws resource-exhausted once the cap is reached", async () => {
    const today = new Date().toISOString().slice(0, 10);
    await db.collection("usage_limits").doc(`${uid}_${today}`).set({ count: 50 });

    await assert.rejects(checkAndIncrementRateLimit(db, uid), (err: any) => {
      return err.code === "resource-exhausted";
    });
  });
});
