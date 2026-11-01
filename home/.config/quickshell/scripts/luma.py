#!/usr/bin/env python3
# ╭──────────────────────────────────────────────────────────────────────────╮
# │                                                                          │
# │   L U M A                                                                │
# │   how light the wallpaper is under a widget                              │
# │                                                                          │
# │   github.com/Phalynxi/Nocturnus                                      │
# │                                                                          │
# ╰──────────────────────────────────────────────────────────────────────────╯

# `luma.py PICTURE X Y W H` prints the mean luminance (0 black, 1 white) of
# the part of PICTURE a widget covers, the box given as fractions of the
# screen. The picture is taken as filling the screen the way the wallpaper
# daemon fills it, cropped to cover, so the box lands on what is behind it.
# Prints nothing on any failure; the widget keeps its last answer.

import subprocess
import sys


def main(path, x, y, w, h, screen_w, screen_h):
    size = subprocess.run(
        ["magick", "identify", "-format", "%w %h", f"{path}[0]"],
        capture_output=True, text=True, check=True,
    ).stdout.split()
    pic_w, pic_h = int(size[0]), int(size[1])

    # Cover: scale until both sides reach the screen, centre the overflow.
    scale = max(screen_w / pic_w, screen_h / pic_h)
    shown_w, shown_h = screen_w / scale, screen_h / scale
    left = (pic_w - shown_w) / 2 + x * shown_w
    top = (pic_h - shown_h) / 2 + y * shown_h
    box_w = max(1, round(w * shown_w))
    box_h = max(1, round(h * shown_h))

    mean = subprocess.run(
        ["magick", f"{path}[0]", "-crop", f"{box_w}x{box_h}+{round(left)}+{round(top)}",
         "+repage", "-colorspace", "Gray", "-format", "%[fx:mean]", "info:"],
        capture_output=True, text=True, check=True,
    ).stdout.strip()
    print(f"{float(mean):.3f}")


if __name__ == "__main__":
    try:
        main(sys.argv[1], *(float(arg) for arg in sys.argv[2:8]))
    except Exception as error:  # a widget must never take the shell down
        sys.stderr.write(f"luma failed: {error}\n")
