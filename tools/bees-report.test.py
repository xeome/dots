#!/usr/bin/env python3
"""python3 -I tools/bees-report.test.py — checks home/dot_local/bin/executable_bees-report.
The lines are trimmed copies of real bees journal lines."""
import importlib.machinery
import importlib.util
import pathlib
import sys

sys.dont_write_bytecode = True
path = str(pathlib.Path(__file__).resolve().parents[1] / "home/dot_local/bin/executable_bees-report")
spec = importlib.util.spec_from_loader("bees_report", importlib.machinery.SourceFileLoader("bees_report", path))
bees_report = importlib.util.module_from_spec(spec)
spec.loader.exec_module(bees_report)

P = "xeome-desktop beesd[952]:"
lines = [
    # One 12K extent referenced from two snapshots: deduped twice, freed once.
    f"2026-10-10T02:21:41+03:00 {P} ref_469229d000_12K_10[697631]: dedup: src 34.688K [0x0..0x8ac0] {{0x42ae122000z0}} /a",
    f"2026-10-10T02:21:41+03:00 {P} ref_469229d000_12K_10[697631]:        dst 34.688K [0x0..0x8ac0] {{0x469229d000z0}} /a",
    f"2026-10-10T02:21:41+03:00 {P} ref_469229d000_12K_10[697631]: dedup: src 34.688K [0x0..0x8ac0] {{0x42ae122000z0}} /b",
    # A fractional size with no _<n> suffix.
    f"2026-10-10T03:00:00+03:00 {P} ref_8ddcfe9000_2.5M[11050]: dedup: src 2.5M [0x0..0x280000] {{0x41281ac000}} /c",
    # Not a dedup: the scan line of the same extent.
    f"2026-10-10T03:00:00+03:00 {P} ref_8ddcfe9000_2.5M[11050]: scan: 2.5M 1d0c0pz 0.001s /c",
    # The first address again a day later: new data that btrfs put at a freed address.
    f"2026-10-11T09:00:00+03:00 {P} ref_469229d000_4K[11050]: dedup: src 4K [0x0..0x1000] {{0x42ae122000z0}} /d",
    # A dedup line whose thread name is not ref_<bytenr>_<size>: reported, not counted.
    f"2026-10-11T09:00:00+03:00 {P} extent_7[11050]: dedup: src 4K [0x0..0x1000] {{0x42ae122000z0}} /e",
]

got, unread = bees_report.freed_per_day(lines)
want = {"2026-10-10": 12 * 2**10 + 2.5 * 2**20, "2026-10-11": 4 * 2**10}
assert dict(got) == want, f"{dict(got)} != {want}"
assert unread == 1, unread
print("ok")
