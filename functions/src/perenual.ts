import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";
import { cachedFetch, normalizeKey } from "./cache";
import { perenualApiKey } from "./secrets";

const PERENUAL_BASE = "https://perenual.com/api/v2";
const THIRTY_DAYS_MS = 30 * 24 * 60 * 60 * 1000;

const WATERING_TO_DAYS: Record<string, number> = {
  frequent: 3,
  average: 7,
  minimum: 14,
  none: 30,
};

export interface SpeciesSummary {
  id: number;
  scientificName: string;
  commonName: string | null;
  thumbnailUrl: string | null;
}

export interface SpeciesDetail {
  scientificName: string;
  commonName: string | null;
  imageUrl: string | null;
  wateringIntervalDays: number | null;
  careInstructions: string;
  description: string | null;
  origin: string | null;
  family: string | null;
  poisonousToHumans: boolean | null;
  poisonousToPets: boolean | null;
}

function asBool(value: unknown): boolean | null {
  if (value === null || value === undefined) return null;
  if (typeof value === "boolean") return value;
  if (typeof value === "number") return value !== 0;
  return null;
}

export function parseSearchResults(raw: unknown): SpeciesSummary[] {
  const results = ((raw as { data?: unknown[] })?.data ?? []) as Record<string, unknown>[];
  return results.map((entry) => {
    const commonName = (entry.common_name as string | undefined) ?? null;
    const image = entry.default_image as Record<string, unknown> | undefined;
    const scientificNames = entry.scientific_name as string[] | undefined;
    return {
      id: entry.id as number,
      scientificName: scientificNames?.[0]?.toString() ?? commonName ?? "Unknown species",
      commonName,
      thumbnailUrl:
        (image?.thumbnail as string | undefined) ?? (image?.small_url as string | undefined) ?? null,
    };
  });
}

export function parseDetail(data: Record<string, unknown>): SpeciesDetail {
  const watering = (data.watering as string | undefined)?.toLowerCase();
  const wateringIntervalDays = watering ? WATERING_TO_DAYS[watering] ?? null : null;

  const sunlight = data.sunlight;
  const sunlightText = Array.isArray(sunlight) ? sunlight.join(", ") : (sunlight as string | undefined);
  const careLevel = data.care_level as string | undefined;

  const careParts = [
    data.watering ? `Watering: ${data.watering}` : null,
    sunlightText ? `Sunlight: ${sunlightText}` : null,
    careLevel ? `Care level: ${careLevel}` : null,
  ].filter((part): part is string => Boolean(part));

  const origin = data.origin;
  const originText = Array.isArray(origin) ? origin.join(", ") : (origin as string | undefined);
  const image = data.default_image as Record<string, unknown> | undefined;
  const scientificNames = data.scientific_name as string[] | undefined;
  const commonName = (data.common_name as string | undefined) ?? null;
  const description = (data.description as string | undefined)?.trim();

  return {
    scientificName: scientificNames?.[0]?.toString() ?? commonName ?? "Unknown species",
    commonName,
    imageUrl:
      (image?.regular_url as string | undefined) ?? (image?.medium_url as string | undefined) ?? null,
    wateringIntervalDays,
    careInstructions: careParts.join("\n"),
    description: description ? description : null,
    origin: originText ? originText : null,
    family: (data.family as string | undefined) ?? null,
    poisonousToHumans: asBool(data.poisonous_to_humans),
    poisonousToPets: asBool(data.poisonous_to_pets),
  };
}

async function fetchSearchLive(query: string, apiKey: string): Promise<SpeciesSummary[]> {
  const uri = `${PERENUAL_BASE}/species-list?key=${apiKey}&q=${encodeURIComponent(query)}`;
  const response = await fetch(uri);
  if (!response.ok) {
    throw new Error(`Perenual returned ${response.status}`);
  }
  return parseSearchResults(await response.json());
}

async function fetchDetailLive(id: number, apiKey: string): Promise<SpeciesDetail> {
  const uri = `${PERENUAL_BASE}/species/details/${id}?key=${apiKey}`;
  const response = await fetch(uri);
  if (!response.ok) {
    throw new Error(`Perenual returned ${response.status}`);
  }
  return parseDetail((await response.json()) as Record<string, unknown>);
}

export const searchSpecies = onCall({ secrets: [perenualApiKey] }, async (request) => {
  const query = (request.data?.query as string | undefined)?.trim();
  if (!query) return [];

  try {
    return await cachedFetch(
      getFirestore(),
      "species_search_cache",
      normalizeKey(query),
      THIRTY_DAYS_MS,
      () => fetchSearchLive(query, perenualApiKey.value())
    );
  } catch (err) {
    throw new HttpsError("unavailable", `Species search failed: ${(err as Error).message}`);
  }
});

export const fetchSpeciesDetail = onCall({ secrets: [perenualApiKey] }, async (request) => {
  const id = request.data?.id as number | undefined;
  if (typeof id !== "number") {
    throw new HttpsError("invalid-argument", "id is required.");
  }

  try {
    return await cachedFetch(
      getFirestore(),
      "species_detail_cache",
      String(id),
      THIRTY_DAYS_MS,
      () => fetchDetailLive(id, perenualApiKey.value())
    );
  } catch (err) {
    throw new HttpsError("unavailable", `Species detail fetch failed: ${(err as Error).message}`);
  }
});
