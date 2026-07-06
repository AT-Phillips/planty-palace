import * as assert from "assert";
import { gridKey, parseWeather } from "./weather";

describe("gridKey", () => {
  it("rounds coordinates to a shared grid cell", () => {
    assert.strictEqual(gridKey(40.7128, -74.006), gridKey(40.71, -74.0));
  });

  it("produces different keys for meaningfully different locations", () => {
    assert.notStrictEqual(gridKey(40.7128, -74.006), gridKey(34.0522, -118.2437));
  });
});

describe("parseWeather", () => {
  it("extracts temperature, condition, and icon", () => {
    const result = parseWeather({
      main: { temp: 21.5 },
      weather: [{ main: "Clouds", icon: "04d" }],
    });
    assert.strictEqual(result.tempCelsius, 21.5);
    assert.strictEqual(result.condition, "Clouds");
    assert.strictEqual(result.iconCode, "04d");
  });

  it("defaults gracefully when fields are missing", () => {
    const result = parseWeather({});
    assert.strictEqual(result.tempCelsius, 0);
    assert.strictEqual(result.condition, "");
    assert.strictEqual(result.iconCode, "");
  });
});
