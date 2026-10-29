"""
Merges files/boot/cmdline into /etc/kernel/cmdline, which kernel-install
copies into every loader entry. That file holds the whole cmdline, root= and
resume= included, and has no drop-in directory, so deploy.py owns tokens by
key instead: a token in files/boot/cmdline replaces every token with the same
key (the text before "="), and every other token stays as it was.

Deleting a token from files/boot/cmdline leaves it in /etc/kernel/cmdline:
keep its key with the value you want instead.

    python3 -I infra/cmdline.py   # self-check
"""


def owned(text):
    """The tokens in files/boot/cmdline, comment lines dropped."""
    return [t for line in text.splitlines() if not line.lstrip().startswith("#") for t in line.split()]


def key(token):
    return token.split("=", 1)[0]


def merge(current, tokens):
    keys = {key(t) for t in tokens}
    return " ".join([t for t in current.split() if key(t) not in keys] + tokens) + "\n"


if __name__ == "__main__":
    import pathlib

    tokens = owned((pathlib.Path(__file__).parent / "files/boot/cmdline").read_text())
    keys = {key(t) for t in tokens}
    # Shaped like xeome-desktop's: a value holding "=" and "/", a trailing
    # space, and keys the file owns already present with other values.
    current = ("nvme_load=YES nowatchdog rw rootflags=subvol=/@ root=UUID=5a4c2dc5-0000 "
               "resume=UUID=30d1ef18-0000 quiet loglevel=7 zswap.enabled=1 "
               "vt.default_red=6,255 vt.default_grn=7,134 vt.default_blu=9,120 ")
    merged = merge(current, tokens)
    kept = [t for t in current.split() if key(t) not in keys]
    assert merged.split()[: len(kept)] == kept, f"foreign tokens changed: {merged!r}"
    for t in tokens:
        same = [m for m in merged.split() if key(m) == key(t)]
        assert same == [t], f"{key(t)}: {same}, want [{t!r}]"
    assert merge(merged, tokens) == merged, "a second merge changes the cmdline"
    print("cmdline OK")
