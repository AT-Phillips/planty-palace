import { onCall, HttpsError } from "firebase-functions/v2/https";
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
    return await cachedFetch(
      getFirestore(),
      "weather_cache",
      gridKey(lat, lon),
      TWENTY_MINUTES_MS,
      () => fetchWeatherLive(lat, lon, openWeatherApiKey.value())
    );
  } catch (err) {
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

async function fetchGeocodingLive(query: string, apiKey: string): Promise<GeocodingResult[]> {
  const uri = `https://api.openweathermap.org/geo/1.0/direct?q=${encodeURIComponent(query)}&limit=5&appid=${apiKey}`;
  const response = await fetch(uri);
  if (!response.ok) {
    throw new Error(`OpenWeatherMap geocoding returned ${response.status}`);
  }
  return parseGeocodingResults(await response.json());
}

// City coordinates are effectively static - a much longer freshness window
// than live weather is appropriate here.
export const geocodeCity = onCall({ secrets: [openWeatherApiKey] }, async (request) => {
  const query = (request.data?.query as string | undefined)?.trim();
  if (!query) return [];

  try {
    return await cachedFetch(
      getFirestore(),
      "geocoding_cache",
      normalizeKey(query),
      NINETY_DAYS_MS,
      () => fetchGeocodingLive(query, openWeatherApiKey.value())
    );
  } catch (err) {
    throw new HttpsError("unavailable", `City search failed: ${(err as Error).message}`);
  }
});
