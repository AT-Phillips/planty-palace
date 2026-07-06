import { onCall, HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions";
import { getFirestore } from "firebase-admin/firestore";
import { cachedFetch, normalizeKey } from "./cache";
import { openWeatherApiKey } from "./secrets";

const TWENTY_MINUTES_MS = 20 * 60 * 1000;
const NINETY_DAYS_MS = 90 * 24 * 60 * 60 * 1000;

export interface WeatherResult {
  tempCelsius: number;
  condition: string;
  iconCode: string;
}

/** Rounds to a ~5km grid cell so nearby users share one cached result. */
export function gridKey(lat: number, lon: number): string {
  const roundedLat = Math.round(lat * 20) / 20;
  const roundedLon = Math.round(lon * 20) / 20;
  return `${roundedLat}_${roundedLon}`;
}

export function parseWeather(data: Record<string, unknown>): WeatherResult {
  const main = (data.main as Record<string, unknown> | undefined) ?? {};
  const weather = ((data.weather as Record<string, unknown>[] | undefined) ?? [])[0] ?? {};
  return {
    tempCelsius: typeof main.temp === "number" ? main.temp : 0,
    condition: (weather.main as string | undefined)?.toString() ?? "",
    iconCode: (weather.icon as string | undefined)?.toString() ?? "",
  };
}

async function fetchWeatherLive(lat: number, lon: number, apiKey: string): Promise<WeatherResult> {
  const uri = `https://api.openweathermap.org/data/2.5/weather?lat=${lat}&lon=${lon}&appid=${apiKey}&units=metric`;
  const response = await fetch(uri);
  if (!response.ok) {
    throw new Error(`OpenWeatherMap returned ${response.status}`);
  }
  return parseWeather((await response.json()) as Record<string, unknown>);
}

export const fetchWeather = onCall({ secrets: [openWeatherApiKey] }, async (request) => {
  const lat = request.data?.lat as number | undefined;
  const lon = request.data?.lon as number | undefined;
  if (typeof lat !== "number" || typeof lon !== "number") {
    throw new HttpsError("invalid-argument", "lat and lon are required.");
  }

  try {
    const result = await cachedFetch(
      getFirestore(),
      "weather_cache",
      gridKey(lat, lon),
      TWENTY_MINUTES_MS,
      () => fetchWeatherLive(lat, lon, openWeatherApiKey.value())
    );
    logger.info("fetchWeather ok", { lat, lon });
    return result;
  } catch (err) {
    logger.error("fetchWeather failed", { lat, lon, error: (err as Error).message });
    throw new HttpsError("unavailable", `Weather fetch failed: ${(err as Error).message}`);
  }
});

export interface GeocodingResult {
  name: string;
  state: string | null;
  country: string;
  lat: number;
  lon: number;
}

export function parseGeocodingResults(raw: unknown): GeocodingResult[] {
  const results = (raw as Record<string, unknown>[] | undefined) ?? [];
  return results.map((entry) => ({
    name: (entry.name as string | undefined) ?? "",
    state: (entry.state as string | undefined) ?? null,
    country: (entry.country as string | undefined) ?? "",
    lat: entry.lat as number,
    lon: entry.lon as number,
  }));
}

/** Thrown when a (possibly retried) geocoding query genuinely has no
 * matches, so callers can distinguish "no results" from a real failure and
 * skip caching it - see cachedFetch, which would otherwise persist an empty
 * array for the full TTL. */
export class NoGeocodingResultsError extends Error {
  constructor(query: string) {
    super(`No geocoding results for "${query}"`);
    this.name = "NoGeocodingResultsError";
  }
}

// Matches a plain "City, ST" query: comma-separated, with a 2-letter
// alphabetic second part (a US state code, not a country code).
const US_STATE_QUERY = /^[^,]+,\s*[A-Za-z]{2}$/;

async function fetchGeocodingOnce(query: string, apiKey: string): Promise<GeocodingResult[]> {
  const uri = `https://api.openweathermap.org/geo/1.0/direct?q=${encodeURIComponent(query)}&limit=5&appid=${apiKey}`;
  const response = await fetch(uri);
  if (!response.ok) {
    throw new Error(`OpenWeatherMap geocoding returned ${response.status}`);
  }
  return parseGeocodingResults(await response.json());
}

/**
 * OWM's Direct Geocoding endpoint only recognizes a 2-letter US state code
 * as the middle segment of a 3-part "city,state,country" query - a 2-part
 * "City, ST" query makes OWM read "ST" as an invalid country code and
 * legitimately return zero results. Retry with an explicit ",US" appended
 * in that case before giving up.
 */
export async function fetchGeocodingLive(query: string, apiKey: string): Promise<GeocodingResult[]> {
  let results = await fetchGeocodingOnce(query, apiKey);
  if (results.length === 0 && US_STATE_QUERY.test(query)) {
    results = await fetchGeocodingOnce(`${query},US`, apiKey);
  }
  if (results.length === 0) {
    throw new NoGeocodingResultsError(query);
  }
  return results;
}

// City coordinates are effectively static - a much longer freshness window
// than live weather is appropriate here.
export const geocodeCity = onCall({ secrets: [openWeatherApiKey] }, async (request) => {
  const query = (request.data?.query as string | undefined)?.trim();
  if (!query) return [];

  try {
    const results = await cachedFetch(
      getFirestore(),
      "geocoding_cache",
      normalizeKey(query),
      NINETY_DAYS_MS,
      () => fetchGeocodingLive(query, openWeatherApiKey.value())
    );
    logger.info("geocodeCity ok", { query, count: results.length });
    return results;
  } catch (err) {
    if (err instanceof NoGeocodingResultsError) {
      logger.info("geocodeCity no results", { query });
      return [];
    }
    logger.error("geocodeCity failed", { query, error: (err as Error).message });
    throw new HttpsError("unavailable", `City search failed: ${(err as Error).message}`);
  }
});
