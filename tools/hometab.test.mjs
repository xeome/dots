// node tools/hometab.test.mjs — checks home/dot_config/zen/hometab.
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import vm from "node:vm";
import { isoWeek, greeting } from "../home/dot_config/exact_quickshell/exact_xeome/Calc.mjs";

const DIR = new URL("../home/dot_config/zen/hometab/", import.meta.url);
const JS = readFileSync(new URL("hometab.js", DIR), "utf8");
const CSS = readFileSync(new URL("hometab.css", DIR), "utf8");

// Loads given the same `store` share localStorage, as hometabs do.
function load(store, start, reply) {
    const clock = { now: start };
    const timers = [];
    const fetches = [];
    class FakeDate extends Date {
        constructor(...a) { super(...(a.length ? a : [clock.now])); }
        static now() { return clock.now; }
    }
    const els = {};
    const ctx = {
        Date: FakeDate,
        setTimeout: (fn, ms) => timers.push({ fn, ms }),
        fetch: url => { fetches.push(url); return reply(); },
        localStorage: {
            getItem: k => (k in store ? store[k] : null),
            setItem: (k, v) => { store[k] = String(v); },
        },
        document: { getElementById: id => (els[id] ??= { textContent: "" }) },
    };
    vm.runInNewContext(JS, ctx);
    // Late, as a busy or throttled tab fires.
    const fire = (late = 7) => {
        assert.equal(timers.length, 1, `${timers.length} timers pending`);
        const t = timers.pop();
        clock.now += t.ms + late;
        t.fn();
        return t.ms;
    };
    return { timers, fetches, fire, els };
}

const ok = () => Promise.resolve({ ok: true, json: () => Promise.resolve({ current_condition: [{ temp_C: "13", weatherDesc: [{ value: "Clear" }] }] }) });
const never = () => new Promise(() => {});
const offline = () => Promise.reject(new TypeError("offline"));
// 12:34:56.789: not on a second, so a delay counted in whole seconds is caught.
const START = new Date(2026, 10, 1, 12, 34, 56, 789).getTime();

// One timer, re-armed to the next minute boundary after every tick. A fixed
// 60000 or a whole-second count would give 60000 or 4000 here.
{
    const page = load({}, START, ok);
    assert.equal(page.timers.length, 1);
    assert.equal(page.fire(), 3211);
    for (let i = 0; i < 5; i++) assert.equal(page.fire(), 59993);
}

// Tick 60 lands at 13:34:00.007, 59:03 after the load; tick 61 is the first past an hour.
{
    const page = load({}, START, ok);
    assert.equal(page.fetches.length, 1);
    for (let tick = 1; tick <= 61; tick++) {
        page.fire();
        assert.equal(page.fetches.length, tick < 61 ? 1 : 2, `fetches after tick ${tick}`);
    }
}

// A second hometab opened while the first one's fetch is still out.
{
    const store = {};
    load(store, START, never);
    const second = load(store, START + 2000, ok);
    assert.equal(second.fetches.length, 0);
}

// Offline: a failed fetch still counts as this hour's attempt.
{
    const page = load({}, START, offline);
    await new Promise(r => setImmediate(r));
    for (let tick = 1; tick <= 60; tick++) page.fire();
    assert.equal(page.fetches.length, 1);
}

assert.ok(JS.includes(isoWeek.toString()), "hometab.js's isoWeek differs from Calc.mjs");
assert.ok(JS.includes(greeting.toString()), "hometab.js's greeting differs from Calc.mjs");

assert.doesNotMatch(CSS.replace(/\/\*[\s\S]*?\*\//g, ""), /animation|@keyframes/, "hometab.css animates");
assert.doesNotMatch(JS, /requestAnimationFrame|setInterval/, "hometab.js has a timer besides the minute tick");

console.log("hometab OK");
