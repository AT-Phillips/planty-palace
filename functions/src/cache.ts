import { Firestore } from "firebase-admin/firestore";

interface CacheEntry<T> {
  data: T;
  cachedAt: number;
}

/**
 * Turns arbitrary user input into a safe Firestore document ID: lowercase,
 * trimmed, non-alphanumeric characters collapsed to underscores.
 */
export function normalizeKey(input: string): string {
  return input.trim().toLowerCase().replace(/[^a-z0-9]+/g, "_").slice(0, 200);
}

async function getCached<T>(
  db: Firestore,
  collection: string,
  key: string,
  ttlMs: number
): Promise<{ data: T; stale: boolean } | null> {
  const doc = await db.collection(collection).doc(key).get();
  if (!doc.exists) return null;
  const entry = doc.data() as CacheEntry<T>;
  const age = Date.now() - entry.cachedAt;
  return { data: entry.data, stale: age > ttlMs };
}

async function setCached<T>(
  db: Firestore,
  collection: string,
  key: string,
  data: T
): Promise<void> {
  await db.collection(collection).doc(key).set({ data, cachedAt: Date.now() });
}

/**
 * Fetch-through cache with stale-on-error fallback. A fresh cache hit
 * returns immediately with no live call. A miss or stale entry triggers a
 * live fetch; if that live fetch fails, a stale cache entry (if any) is
 * served instead of throwing - old data beats none. Only throws if there's
 * truly nothing to fall back to.
 */
export async function cachedFetch<T>(
  db: Firestore,
  collection: string,
  key: string,
  ttlMs: number,
  fetchLive: () => Promise<T>
): Promise<T> {
  const cached = await getCached<T>(db, collection, key, ttlMs);
  if (cached && !cached.stale) return cached.data;

  try {
    const fresh = await fetchLive();
    await setCached(db, collection, key, fresh);
    return fresh;
  } catch (err) {
    if (cached) return cached.data;
    throw err;
  }
}
