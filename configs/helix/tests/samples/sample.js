// Parity sample for JavaScript.
import { readFile } from "node:fs/promises";
import path from "node:path";

/**
 * Parse a config file.
 * @param {string} file - path to the file
 * @returns {Promise<object>}
 */
export async function loadConfig(file = "config.json") {
  const text = await readFile(path.resolve(file), "utf8");
  return JSON.parse(text);
}

const PATTERN = /^v(\d+)\.(\d+)$/i;
let counter = 0;
var legacy = null;

class Counter extends EventTarget {
  #count = 0;
  static instances = 0;

  constructor(start = 0) {
    super();
    this.#count = start;
    Counter.instances += 1;
  }

  get value() {
    return this.#count;
  }

  increment(step = 1) {
    this.#count += step;
    return this;
  }
}

const greet = (name) => `Hello, ${name.toUpperCase()}!\n`;

function classify(value) {
  if (typeof value === "number" && !Number.isNaN(value)) {
    return value > 0 ? "positive" : "non-positive";
  } else if (value instanceof Counter) {
    return "counter";
  }
  switch (value) {
    case undefined:
      return "missing";
    default:
      return String(value);
  }
}

try {
  const items = [1, 2, 3].map((n) => n * 2).filter(Boolean);
  for (const item of items) {
    counter += item;
  }
  const { a, ...rest } = { a: 1, b: true, c: 3.14 };
  console.log(greet("world"), PATTERN.test("v1.2"), a, rest, legacy);
} catch (err) {
  throw new Error(`failed: ${err.message}`);
} finally {
  delete globalThis.temp;
}
