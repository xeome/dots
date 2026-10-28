// The arithmetic Shot depends on, kept out of QML so node can check it:
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
