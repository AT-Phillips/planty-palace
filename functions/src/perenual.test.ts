import * as assert from "assert";
import { parseSearchResults, parseDetail } from "./perenual";

describe("parseSearchResults", () => {
  it("maps Perenual's species-list shape to summaries", () => {
    const raw = {
      data: [
        {
          id: 123,
          scientific_name: ["Monstera deliciosa"],
          common_name: "Swiss cheese plant",
          default_image: { thumbnail: "https://example.com/thumb.jpg" },
        },
      ],
    };
    const results = parseSearchResults(raw);
    assert.strictEqual(results.length, 1);
    assert.strictEqual(results[0].id, 123);
    assert.strictEqual(results[0].scientificName, "Monstera deliciosa");
    assert.strictEqual(results[0].commonName, "Swiss cheese plant");
    assert.strictEqual(results[0].thumbnailUrl, "https://example.com/thumb.jpg");
  });

  it("falls back to common name, then 'Unknown species', when scientific name is missing", () => {
    const withCommonOnly = parseSearchResults({
      data: [{ id: 1, common_name: "Some Plant" }],
    });
    assert.strictEqual(withCommonOnly[0].scientificName, "Some Plant");

    const withNeither = parseSearchResults({ data: [{ id: 2 }] });
    assert.strictEqual(withNeither[0].scientificName, "Unknown species");
  });

  it("returns an empty array when data is missing", () => {
    assert.deepStrictEqual(parseSearchResults({}), []);
  });
});

describe("parseDetail", () => {
  it("maps watering frequency to an interval and builds care instructions", () => {
    const detail = parseDetail({
      scientific_name: ["Monstera deliciosa"],
      common_name: "Swiss cheese plant",
      watering: "Average",
      sunlight: ["part shade", "full shade"],
      care_level: "Moderate",
      default_image: { regular_url: "https://example.com/full.jpg" },
      origin: ["Central America"],
      family: "Araceae",
      poisonous_to_humans: 1,
      poisonous_to_pets: 0,
    });

    assert.strictEqual(detail.wateringIntervalDays, 7);
    assert.strictEqual(
      detail.careInstructions,
      "Watering: Average\nSunlight: part shade, full shade\nCare level: Moderate"
    );
    assert.strictEqual(detail.imageUrl, "https://example.com/full.jpg");
    assert.strictEqual(detail.origin, "Central America");
    assert.strictEqual(detail.poisonousToHumans, true);
    assert.strictEqual(detail.poisonousToPets, false);
  });

  it("returns null wateringIntervalDays for an unrecognized watering value", () => {
    const detail = parseDetail({ watering: "sometimes" });
    assert.strictEqual(detail.wateringIntervalDays, null);
  });

  it("omits empty optional fields as null rather than empty strings", () => {
    const detail = parseDetail({});
    assert.strictEqual(detail.description, null);
    assert.strictEqual(detail.origin, null);
    assert.strictEqual(detail.careInstructions, "");
  });
});
