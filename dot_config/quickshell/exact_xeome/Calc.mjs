// The arithmetic Shot and Desk depend on, kept out of QML so node can check it:
// node dot_config/quickshell/exact_xeome/calc.test.mjs

// The crop box in frame pixels for a selection in the screen's logical pixels,
// or null when none of it is on screen. The selection is cut to the screen on
// all four sides first (a window can hang off any edge), then its edges are
// rounded rather than its width: rounding x and width apart can land a pixel
// past the frame, and vips refuses the whole crop for that.
export function crop(sel, w, h, frameW, frameH) {
    const kx = frameW / w, ky = frameH / h;
    const x1 = Math.round(Math.max(0, sel.x) * kx), x2 = Math.round(Math.min(w, sel.x + sel.width) * kx);
    const y1 = Math.round(Math.max(0, sel.y) * ky), y2 = Math.round(Math.min(h, sel.y + sel.height) * ky);
    return x2 > x1 && y2 > y1 ? { x: x1, y: y1, w: x2 - x1, h: y2 - y1 } : null;
}

// ISO 8601 week number of the week holding d (any day of it).
export function isoWeek(d) {
    const thu = new Date(d.getFullYear(), d.getMonth(), d.getDate() + 3 - (d.getDay() + 6) % 7);
    const jan1 = new Date(thu.getFullYear(), 0, 1);
    // Round before dividing: a DST boundary in between leaves the raw
    // millisecond gap an hour short of a whole number of days.
    return Math.floor(Math.round((thu - jan1) / 86400000) / 7) + 1;
}

// Desk's greeting for an hour of the day, 0-23.
export function greeting(h) {
    return h < 5 ? "night" : h < 12 ? "morning" : h < 18 ? "afternoon" : "evening";
}

// Busy percentage between two "cpu ..." lines of /proc/stat. Only the first
// eight counters: guest and guest_nice are already inside user and nice.
// idle and iowait both count as idle, as top does.
export function cpuBusy(prev, cur) {
    const a = prev.trim().split(/\s+/).slice(1, 9).map(Number);
    const b = cur.trim().split(/\s+/).slice(1, 9).map(Number);
    const total = b.reduce((s, v) => s + v, 0) - a.reduce((s, v) => s + v, 0);
    const idle = b[3] + b[4] - a[3] - a[4];
    return total > 0 ? Math.round(100 * (total - idle) / total) : 0;
}
