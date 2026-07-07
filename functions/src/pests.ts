import { onCall } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";
import { cachedFetch, normalizeKey } from "./cache";
import { perenualApiKey } from "./secrets";

const PERENUAL_BASE = "https://perenual.com/api";
const NINETY_DAYS_MS = 90 * 24 * 60 * 60 * 1000;

export interface PestDiseaseInfo {
  id: number;
  commonName: string;
  scientificName: string | null;
  family: string | null;
  description: string | null;
  solution: string | null;
  hostPlants: string[];
  imageUrl: string | null;
}

/** Perenual's pest/disease fields are sometimes an array of paragraphs
 * rather than a single string - join them the same way `careParts` does
 * for species care instructions. */
function joinTextField(value: unknown): string | null {
  if (Array.isArray(value)) {
    const joined = value.filter((v): v is string => typeof v === "string").join("\n\n");
    return joined || null;
  }
  return typeof value === "string" && value.trim() !== "" ? value : null;
}

function firstImageUrl(value: unknown): string | null {
  if (!Array.isArray(value) || value.length === 0) return null;
  const first = value[0] as Record<string, unknown> | undefined;
  return (
    (first?.regular_url as string | undefined) ||
    (first?.medium_url as string | undefined) ||
    (first?.thumbnail as string | undefined) ||
    null
  );
}

export function parsePestDiseaseList(raw: unknown): PestDiseaseInfo[] {
  const results = ((raw as { data?: unknown[] })?.data ?? []) as Record<string, unknown>[];
  return results.map((entry) => {
    const scientificNames = entry.scientific_name as string[] | undefined;
    const host = (entry.host as string[] | undefined) ?? (entry.host_plants as string[] | undefined) ?? [];
    return {
      id: entry.id as number,
      commonName: (entry.common_name as string | undefined) ?? "Unknown problem",
      scientificName: scientificNames?.[0]?.toString() ?? null,
      family: (entry.family as string | undefined) ?? null,
      description: joinTextField(entry.description),
      solution: joinTextField(entry.solution),
      hostPlants: Array.isArray(host) ? host.filter((h): h is string => typeof h === "string") : [],
      imageUrl: firstImageUrl(entry.images),
    };
  });
}

async function fetchPestDiseaseListLive(query: string, apiKey: string): Promise<PestDiseaseInfo[]> {
  const uri = `${PERENUAL_BASE}/pest-disease-list?key=${apiKey}&q=${encodeURIComponent(query)}`;
  const response = await fetch(uri);
  if (!response.ok) {
    throw new Error(`Perenual pest/disease list returned ${response.status}`);
  }
  return parsePestDiseaseList(await response.json());
}

// Pest/disease reference info is effectively static - same long freshness
// window as geocoding, and it shares the same daily Perenual quota as
// species search/detail, so caching aggressively matters just as much here.
export const searchPestsDiseases = onCall({ secrets: [perenualApiKey] }, async (request) => {
  const query = (request.data?.query as string | undefined)?.trim();
  if (!query) return [];

  return cachedFetch(
    getFirestore(),
    "pest_disease_cache",
    normalizeKey(query),
    NINETY_DAYS_MS,
    () => fetchPestDiseaseListLive(query, perenualApiKey.value())
  );
});
