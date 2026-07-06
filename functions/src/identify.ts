import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, Firestore } from "firebase-admin/firestore";
import { getStorage } from "firebase-admin/storage";
import { plantNetApiKey } from "./secrets";

const DAILY_LIMIT = 50;

export interface PlantSuggestion {
  scientificName: string;
  commonName: string | null;
  score: number;
}

/** Atomically checks and increments a per-user daily counter, throwing once
 * the safety-net cap is hit. Protects against a bug or bad actor burning
 * the whole PlantNet quota - PlantNet calls are inherently per-user and
 * can't be cached like the Perenual/weather lookups. */
export async function checkAndIncrementRateLimit(db: Firestore, uid: string): Promise<void> {
  const today = new Date().toISOString().slice(0, 10);
  const ref = db.collection("usage_limits").doc(`${uid}_${today}`);

  await db.runTransaction(async (tx) => {
    const doc = await tx.get(ref);
    const count = doc.exists ? ((doc.data()?.count as number | undefined) ?? 0) : 0;
    if (count >= DAILY_LIMIT) {
      throw new HttpsError(
        "resource-exhausted",
        "Daily identification limit reached. Try again tomorrow."
      );
    }
    tx.set(ref, { count: count + 1 }, { merge: true });
  });
}

export function parseIdentifyResults(data: Record<string, unknown>): PlantSuggestion[] {
  const results = (data.results as Record<string, unknown>[] | undefined) ?? [];
  return results
    .map((r) => {
      const species = (r.species as Record<string, unknown> | undefined) ?? {};
      const commonNames = species.commonNames as string[] | undefined;
      return {
        scientificName: species.scientificNameWithoutAuthor?.toString() ?? "Unknown",
        commonName: commonNames && commonNames.length > 0 ? commonNames[0] : null,
        score: typeof r.score === "number" ? r.score : 0,
      };
    })
    .sort((a, b) => b.score - a.score)
    .slice(0, 5);
}

export const identifyPlant = onCall(
  { secrets: [plantNetApiKey], timeoutSeconds: 60 },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Sign-in required.");

    const imagePath = request.data?.imagePath as string | undefined;
    const organ = (request.data?.organ as string | undefined) ?? "leaf";
    if (!imagePath) throw new HttpsError("invalid-argument", "imagePath is required.");

    const file = getStorage().bucket().file(imagePath);
    try {
      await checkAndIncrementRateLimit(getFirestore(), uid);

      const [buffer] = await file.download();

      const form = new FormData();
      form.append("organs", organ);
      form.append("images", new Blob([buffer]), "photo.jpg");

      const uri = `https://my-api.plantnet.org/v2/identify/all?api-key=${plantNetApiKey.value()}`;
      const response = await fetch(uri, { method: "POST", body: form });
      if (!response.ok) {
        throw new HttpsError("unavailable", `PlantNet returned ${response.status}`);
      }

      return parseIdentifyResults((await response.json()) as Record<string, unknown>);
    } finally {
      // Always clean up the temp upload, even if the rate limit rejected
      // this request before ever calling PlantNet.
      await file.delete({ ignoreNotFound: true });
    }
  }
);
