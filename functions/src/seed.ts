import { onRequest } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { logger } from "firebase-functions";
import { getFirestore } from "firebase-admin/firestore";
import { cachedFetch, normalizeKey } from "./cache";
import { perenualApiKey } from "./secrets";
import { parseSearchResults, parseDetail, SpeciesSummary } from "./perenual";
import { COMMON_SPECIES_QUERIES } from "./common_species";

const THIRTY_DAYS_MS = 30 * 24 * 60 * 60 * 1000;
const PERENUAL_BASE = "https://perenual.com/api/v2";

// Perenual's free tier is 100 requests/day total, shared with real app
// traffic - stop well before exhausting it so seeding never itself causes
// the outage it's meant to prevent. Safe to re-run: cachedFetch skips
// anything already freshly cached, so each run picks up where it left off.
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

interface SeedRunResult {
  total: number;
  stoppedEarly: boolean;
  results: Record<string, string>;
}

/**
 * Pre-populates the shared species cache for common houseplants/trees/
 * flowers, so these don't wait for organic traffic to become fast and
 * Perenual-quota-free. Safe to call repeatedly/on a schedule - already-
 * fresh cache entries are skipped, and it respects Perenual's daily quota
 * via the X-RateLimit-Remaining header rather than risking causing the
 * exact outage it exists to prevent.
 */
async function runSeed(): Promise<SeedRunResult> {
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

  return { total: COMMON_SPECIES_QUERIES.length, stoppedEarly, results };
}

/**
 * Manual trigger for `runSeed` - not part of the public app surface, gated
 * by a random token (set via functions/.env, SEED_ADMIN_TOKEN) rather than
 * public auth, since it's an occasional admin operation. Mainly useful for
 * an on-demand run outside the weekly schedule below.
 */
export const seedCommonSpecies = onRequest(
  { secrets: [perenualApiKey] },
  async (req, res) => {
    const token = req.get("x-admin-token");
    if (!token || token !== process.env.SEED_ADMIN_TOKEN) {
      res.status(403).json({ error: "Forbidden" });
      return;
    }
    res.status(200).json(await runSeed());
  }
);

/** Automatically resumes seeding weekly, so the cache stays warm without
 * needing a manual trigger - also naturally refreshes entries as the
 * 30-day cache freshness window elapses. */
export const seedCommonSpeciesWeekly = onSchedule(
  { schedule: "every monday 06:00", secrets: [perenualApiKey], timeZone: "America/Chicago" },
  async () => {
    const result = await runSeed();
    logger.info("Weekly species cache seed complete", result);
  }
);
