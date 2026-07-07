import * as assert from "assert";
import { parsePestDiseaseList } from "./pests";

describe("parsePestDiseaseList", () => {
  it("maps Perenual's pest-disease-list shape to info records", () => {
    const raw = {
      data: [
        {
          id: 42,
          common_name: "Spider mites",
          scientific_name: ["Tetranychidae"],
          family: "Tetranychidae",
          description: "Tiny pests that thrive in dry conditions.",
          solution: "Increase humidity and wipe leaves regularly.",
          host: ["Monstera", "Pothos"],
          images: [{ regular_url: "https://example.com/mite.jpg" }],
        },
      ],
    };
    const results = parsePestDiseaseList(raw);
    assert.strictEqual(results.length, 1);
    assert.strictEqual(results[0].id, 42);
    assert.strictEqual(results[0].commonName, "Spider mites");
    assert.strictEqual(results[0].scientificName, "Tetranychidae");
    assert.strictEqual(results[0].description, "Tiny pests that thrive in dry conditions.");
    assert.strictEqual(results[0].solution, "Increase humidity and wipe leaves regularly.");
    assert.deepStrictEqual(results[0].hostPlants, ["Monstera", "Pothos"]);
    assert.strictEqual(results[0].imageUrl, "https://example.com/mite.jpg");
  });

  it("joins array-shaped description/solution fields into paragraphs", () => {
    const results = parsePestDiseaseList({
      data: [{ id: 1, description: ["First paragraph.", "Second paragraph."] }],
    });
    assert.strictEqual(results[0].description, "First paragraph.\n\nSecond paragraph.");
  });

  it("defaults missing fields to null/empty rather than throwing", () => {
    const results = parsePestDiseaseList({ data: [{ id: 1 }] });
    assert.strictEqual(results[0].commonName, "Unknown problem");
    assert.strictEqual(results[0].scientificName, null);
    assert.strictEqual(results[0].description, null);
    assert.deepStrictEqual(results[0].hostPlants, []);
    assert.strictEqual(results[0].imageUrl, null);
  });

  it("returns an empty array when data is missing", () => {
    assert.deepStrictEqual(parsePestDiseaseList({}), []);
  });
});
