#!/usr/bin/env python3
"""Thumbnails for the hive.

The comb must never wait on a full decode: every wallpaper is cut once
into a small centred crop and cached on disk, and the hive reads only
from the cache. Entries arrive as one JSON array in the first argument
— [{"p": "/path/to/wallpaper", "b": true}] — where `b` asks for the
blurred cut that motion wallpapers rest behind. A blurred entry also
cuts its sharp twin, keyed under "#:<path>", so a hover can resolve
the fog. The map of key to thumb leaves on stdout; entries magick can-
not read are forgiven once and never retried.
"""

import hashlib
import json
import sys
import subprocess
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

# A cell's box is underside √3·R × 2·R; two rows of 92 read at 336.
SIZE = 336
CACHE = Path.home() / ".cache" / "nocturnus-hive"


def cut(path: str, dest: Path, mist: bool) -> None:
    command = ["magick", path, "-thumbnail", f"{SIZE}x{SIZE}^",
               "-gravity", "center", "-extent", f"{SIZE}x{SIZE}"]
    if mist:
        command += ["-blur", "0x30"]
    command += ["-quality", "87", str(dest)]
    subprocess.run(command, check=False,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def make(entry: dict) -> list[tuple[str, str | None]]:
    """Cut one wax thumbnail, blurred when asked, plus the sharp twin
    the hover resolves. Returns the (key, thumb) pairs."""
    path = entry.get("p", "")
    mist = bool(entry.get("b", False))
    key = hashlib.sha1(path.encode()).hexdigest()
    made: list[tuple[str, str | None]] = []

    def claim(salt: str, mist: bool) -> str | None:
        thumb = CACHE / (salt + ".jpg")
        forgiven = CACHE / (salt + ".fail")
        if not thumb.exists() and not forgiven.exists():
            scratch = CACHE / (salt + ".part.jpg")
            cut(path, scratch, mist)
            if scratch.exists() and scratch.stat().st_size > 0:
                scratch.replace(thumb)
            else:
                # Magick could not read it; forgive it once and never
                # waste a worker on it again. The cell shows the origi-
                # nal instead.
                if scratch.exists():
                    scratch.unlink()
                forgiven.touch()
        return str(thumb) if thumb.exists() else None

    if mist:
        made.append((path, claim(key + ".blur", True)))
        made.append(("#:" + path, claim(key + ".sharp", False)))
    else:
        made.append((path, claim(key, False)))
    return made


def main() -> int:
    try:
        entries = json.loads(sys.argv[1]) if len(sys.argv) > 1 else []
    except json.JSONDecodeError:
        entries = []
    CACHE.mkdir(parents=True, exist_ok=True)
    mapping: dict[str, str] = {}
    with ThreadPoolExecutor(max_workers=8) as pool:
        for pairs in pool.map(make, entries):
            for key, thumb in pairs:
                if thumb:
                    mapping[key] = thumb
    print(json.dumps(mapping))
    return 0


if __name__ == "__main__":
    sys.exit(main())
