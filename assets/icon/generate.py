#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 lillelilje
#
# Generates the Dollfin app icon at the sizes Sailfish expects:
#   icons/<size>/harbour-dollfin.png
# Run from the repo root:  python3 assets/icon/generate.py

from PIL import Image, ImageDraw, ImageFilter
import os

SIZES = [86, 108, 128, 172]

TOP = (91, 206, 250)    # light blue
BOTTOM = (245, 169, 184)  # pink
INK = (34, 40, 58, 255)
BLUSH = (255, 120, 160, 95)


def render(size):
    s = size * 4
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))

    # Rounded-square background with a soft blue -> pink gradient.
    grad = Image.new("RGB", (1, s))
    for y in range(s):
        t = y / (s - 1)
        grad.putpixel((0, y), tuple(int(TOP[i] + (BOTTOM[i] - TOP[i]) * t) for i in range(3)))
    grad = grad.resize((s, s))
    mask = Image.new("L", (s, s), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, s - 1, s - 1], radius=int(s * 0.23), fill=255)
    img.paste(grad.convert("RGBA"), (0, 0), mask)

    # Capsule, rotated diagonally.
    width, length = int(s * 0.27), int(s * 0.66)
    capsule = Image.new("RGBA", (length, width), (0, 0, 0, 0))
    ImageDraw.Draw(capsule).rounded_rectangle([0, 0, length - 1, width - 1],
                                              radius=width // 2, fill=(255, 255, 255, 255))
    capsule = capsule.rotate(45, resample=Image.BICUBIC, expand=True)

    px = (s - capsule.width) // 2
    py = (s - capsule.height) // 2

    shadow = Image.new("RGBA", capsule.size, (0, 0, 0, 0))
    shadow.paste((0, 0, 0, 70), (0, 0), capsule.split()[3])
    shadow = shadow.filter(ImageFilter.GaussianBlur(s * 0.018))
    img.alpha_composite(shadow, (px + int(s * 0.012), py + int(s * 0.022)))
    img.alpha_composite(capsule, (px, py))

    # A cute face on the capsule.
    draw = ImageDraw.Draw(img)
    cx, cy = s // 2, s // 2
    eye_r, eye_dx, eye_dy = int(s * 0.027), int(s * 0.072), int(s * 0.045)
    for sign in (-1, 1):
        ex = cx + sign * eye_dx
        draw.ellipse([ex - eye_r, cy - eye_dy - eye_r, ex + eye_r, cy - eye_dy + eye_r], fill=INK)

    smile_r = int(s * 0.085)
    draw.arc([cx - smile_r, cy - smile_r + int(s * 0.025),
              cx + smile_r, cy + smile_r + int(s * 0.025)],
             start=25, end=155, fill=INK, width=max(2, int(s * 0.015)))

    blush = Image.new("RGBA", img.size, (0, 0, 0, 0))
    bdraw = ImageDraw.Draw(blush)
    br = int(s * 0.034)
    for sign in (-1, 1):
        bx = cx + sign * int(s * 0.13)
        bdraw.ellipse([bx - br, cy + int(s * 0.012) - br, bx + br, cy + int(s * 0.012) + br], fill=BLUSH)
    blush = blush.filter(ImageFilter.GaussianBlur(s * 0.012))
    img.alpha_composite(blush)

    return img.resize((size, size), Image.LANCZOS)


def main():
    for size in SIZES:
        out_dir = os.path.join("icons", "%dx%d" % (size, size))
        os.makedirs(out_dir, exist_ok=True)
        path = os.path.join(out_dir, "harbour-dollfin.png")
        render(size).save(path)
        print("wrote", path)


if __name__ == "__main__":
    main()
