#!/usr/bin/env python3
"""Thumbnails for the hive.

The comb must never wait on a full decode: every wallpaper is cut once
into a small centred crop and cached on disk, and the hive reads only
from the cache. Paths arrive as one JSON array in the first argument;
the map of path to thumb leaves on stdout, paths missing a thumb leav-
ing nothing behind (the cell shows the original instead, and the next
open tries again).
"""

import hashlib
import json
import os
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

# A cell's box is underside √3·R × 2·R; two rows of 92 read at 336.
SIZE = 336
CACHE = Path.home() / ".cache" / "nocturnus-hive"


def make(path: str) -> str | None:
    key = hashlib.sha1(path.encode()).hexdigest()
    thumb = CACHE / (key + ".jpg")
    forgiven = CACHE / (key + ".fail")
    if not thumb.exists() and not forgiven.exists():
        scratch = thumb.with_suffix(".part.jpg")
        cut = subprocess.run(
            ["magick", path, "-thumbnail", f"{SIZE}x{SIZE}^",
             "-gravity", "center", "-extent", f"{SIZE}x{SIZE}",
             "-quality", "87", str(scratch)],
            check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if cut.returncode == 0 and scratch.exists():
            scratch.replace(thumb)
        else:
            # Magick could not read it; forgive it once and never waste a
            # worker on it again. The cell shows the original instead.
            if scratch.exists():
                scratch.unlink()
            forgiven.touch()
    return str(thumb) if thumb.exists() else None


def main() -> int:
    try:
        paths = json.loads(sys.argv[1]) if len(sys.argv) > 1 else []
    except json.JSONDecodeError:
        paths = []
    CACHE.mkdir(parents=True, exist_ok=True)
    with ThreadPoolExecutor(max_workers=8) as pool:
        made = list(pool.map(make, paths))
    print(json.dumps({p: t for p, t in zip(paths, made) if t}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
