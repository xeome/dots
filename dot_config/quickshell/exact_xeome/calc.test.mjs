// node dot_config/quickshell/exact_xeome/calc.test.mjs — checks Calc.mjs.
// Source-only (.chezmoiignore): Quickshell never loads it.
import assert from "node:assert/strict";
import { crop, cpuBusy, isoWeek, greeting } from "./Calc.mjs";

const rect = (x, y, width, height) => ({ x, y, width, height });

// Rounding x and width apart gives 10 wide here; the edges are at 10 and 21.
assert.deepEqual(crop(rect(10.4, 10.4, 10.4, 10.4), 100, 100, 100, 100), { x: 10, y: 10, w: 11, h: 11 });
// Scale 2, a half-pixel selection running to the bottom-right corner.
assert.deepEqual(crop(rect(1900.25, 1070.25, 19.75, 9.75), 1920, 1080, 3840, 2160), { x: 3801, y: 2141, w: 39, h: 19 });
// A floating window hanging off the top-left: vips refuses a negative origin.
assert.deepEqual(crop(rect(-5, -5, 20, 20), 100, 100, 100, 100), { x: 0, y: 0, w: 15, h: 15 });
assert.equal(crop(rect(150, 10, 20, 20), 100, 100, 100, 100), null);

// user nice system idle iowait irq softirq steal guest guest_nice. guest is
// already inside user, so counting it again would read 30 instead of 22.
assert.equal(cpuBusy("cpu  100 0 100 700 100 0 0 0 50 0", "cpu  200 0 200 1300 200 0 0 0 150 0"), 22);

// 2027-01-01 is a Friday, still in 2026's week 53; 2026-12-28 is that week's Monday.
assert.equal(isoWeek(new Date(2027, 0, 1)), 53);
assert.equal(isoWeek(new Date(2026, 11, 28)), 53);
assert.equal(isoWeek(new Date(2026, 9, 28)), 44);

// Each boundary hour and the one before it.
assert.deepEqual([0, 4, 5, 11, 12, 17, 18, 23].map(greeting),
    ["night", "night", "morning", "morning", "afternoon", "afternoon", "evening", "evening"]);

console.log("calc OK");
