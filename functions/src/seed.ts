import { onRequest } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";
import { cachedFetch, normalizeKey } from "./cache";
import { perenualApiKey } from "./secrets";
import { parseSearchResults, parseDetail, SpeciesSummary } from "./perenual";
import { COMMON_SPECIES_QUERIES } from "./common_species";

const THIRTY_DAYS_MS = 30 * 24 * 60 * 60 * 1000;
const PERENUAL_BASE = "https://perenual.com/api/v2";

// Perenual's free tier is 100 requests/day total, shared with real app
// traffic - stop well before exhausting it so seeding never itself causes
// the outage it's meant to prevent. Safe to re-run daily: cachedFetch skips
// anything already freshly cached, so this picks up where it left off.
const MIN_REMAINING_QUOTA_TO_CONTINUE = 20;

class QuotaExhaustedError extends Error {}

function remainingQuota(response: Response): number | null {
  const header = response.headers.get("x-ratelimit-remaining");
  return header ? Number(header) : null;
}

async function fetchSearchLive(query: string, apiKey: string): Promise<SpeciesSummary[]> {
  const uri = `${PERENUAL_BASE}/species-list?key=${apiKey}&q=${encodeURIComponent(query)}`;
  const response = await fetch(uri);
  const remaining = remainingQuota(response);
  if (!response.ok) throw new Error(`Perenual returned ${response.status}`);
  const parsed = parseSearchResults(await response.json());
  if (remaining !== null && remaining < MIN_REMAINING_QUOTA_TO_CONTINUE) {
    throw new QuotaExhaustedError(`Stopping early - only ${remaining} requests left today`);
  }
  return parsed;
}

async function fetchDetailLive(id: number, apiKey: string) {
  const uri = `${PERENUAL_BASE}/species/details/${id}?key=${apiKey}`;
  const response = await fetch(uri);
  const remaining = remainingQuota(response);
  if (!response.ok) throw new Error(`Perenual returned ${response.status}`);
  const parsed = parseDetail((await response.json()) as Record<string, unknown>);
  if (remaining !== null && remaining < MIN_REMAINING_QUOTA_TO_CONTINUE) {
    throw new QuotaExhaustedError(`Stopping early - only ${remaining} requests left today`);
  }
  return parsed;
}

/**
 * One-time (or periodically re-run) admin operation: pre-populates the
 * shared species cache for common houseplants/trees/flowers, so these
 * don't wait for organic traffic to become fast and Perenual-quota-free.
 * Not part of the public app surface - gated by a random token known only
 * to the deployer, set via functions/.env (SEED_ADMIN_TOKEN), not exposed
 * to the Flutter client at all.
 */
export const seedCommonSpecies = onRequest(
  { secrets: [perenualApiKey] },
  async (req, res) => {
    const token = req.get("x-admin-token");
    if (!token || token !== process.env.SEED_ADMIN_TOKEN) {
      res.status(403).json({ error: "Forbidden" });
      return;
    }

    const db = getFirestore();
    const results: Record<string, string> = {};
    let stoppedEarly = false;

    for (const query of COMMON_SPECIES_QUERIES) {
      if (stoppedEarly) {
        results[query] = "skipped (quota budget reached this run)";
        continue;
      }

      try {
        const summaries = await cachedFetch(
          db,
          "species_search_cache",
          normalizeKey(query),
          THIRTY_DAYS_MS,
          () => fetchSearchLive(query, perenualApiKey.value())
        );

        if (summaries.length > 0) {
          const topId = summaries[0].id;
          await cachedFetch(
            db,
            "species_detail_cache",
            String(topId),
            THIRTY_DAYS_MS,
            () => fetchDetailLive(topId, perenualApiKey.value())
          );
        }

        results[query] = `ok (${summaries.length} results)`;
      } catch (err) {
        if (err instanceof QuotaExhaustedError) {
          results[query] = "ok, then stopped (quota budget reached)";
          stoppedEarly = true;
        } else {
          results[query] = `error: ${(err as Error).message}`;
        }
      }
    }

    res.status(200).json({
      total: COMMON_SPECIES_QUERIES.length,
      stoppedEarly,
      results,
    });
  }
);
