"""Generate the Interview Copilot launcher icon at every density.

Draws the same blue -> violet -> pink gradient as the in-app header badge,
with a white microphone glyph, and writes it to each mipmap folder.
"""

import os
from PIL import Image, ImageDraw

RES = "android/app/src/main/res"
DENSITIES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

# Header gradient stops: #5EB0FF -> #A78BFA -> #F472B6
STOPS = [(0x5E, 0xB0, 0xFF), (0xA7, 0x8B, 0xFA), (0xF4, 0x72, 0xB6)]


def lerp(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def grad_color(t):
    """t in [0,1] across the three stops."""
    if t <= 0.5:
        return lerp(STOPS[0], STOPS[1], t / 0.5)
    return lerp(STOPS[1], STOPS[2], (t - 0.5) / 0.5)


def mic_only(size):
    """White microphone glyph on a transparent canvas (no tile, no gradient)."""
    S = size
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx = S / 2
    bw = S * 0.17
    bt = S * 0.24
    bb = S * 0.56
    d.rounded_rectangle(
        [cx - bw / 2, bt, cx + bw / 2, bb],
        radius=bw / 2,
        fill=(255, 255, 255, 255),
    )
    arc_w = S * 0.34
    arc_top = S * 0.42
    arc_bot = S * 0.64
    d.arc(
        [cx - arc_w / 2, arc_top, cx + arc_w / 2, arc_bot],
        start=0, end=180,
        fill=(255, 255, 255, 255),
        width=int(S * 0.055),
    )
    stem_w = S * 0.055
    d.rectangle(
        [cx - stem_w / 2, arc_bot - S * 0.01, cx + stem_w / 2, S * 0.76],
        fill=(255, 255, 255, 255),
    )
    base_w = S * 0.24
    d.rounded_rectangle(
        [cx - base_w / 2, S * 0.74, cx + base_w / 2, S * 0.78],
        radius=S * 0.02,
        fill=(255, 255, 255, 255),
    )
    return img


def gradient_tile(size, rounded=True):
    """Full gradient square, optionally with rounded corners."""
    S = size
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    px = img.load()
    for y in range(S):
        for x in range(S):
            t = (x + y) / (2 * (S - 1))
            px[x, y] = grad_color(t) + (255,)
    if rounded:
        mask = Image.new("L", (S, S), 0)
        ImageDraw.Draw(mask).rounded_rectangle(
            [0, 0, S - 1, S - 1], radius=int(S * 0.22), fill=255
        )
        img.putalpha(mask)
    return img


def make_icon(size, ss=4):
    """Legacy icon: gradient tile + mic, rendered with supersampling."""
    S = size * ss
    tile = gradient_tile(S, rounded=True)
    mic = mic_only(S)
    out = Image.alpha_composite(tile, mic)
    return out.resize((size, size), Image.LANCZOS)


def main():
    for folder, size in DENSITIES.items():
        path = os.path.join(RES, folder)
        os.makedirs(path, exist_ok=True)
        icon = make_icon(size)
        out = os.path.join(path, "ic_launcher.png")
        icon.save(out)
        print(f"  {out}  ({size}x{size}, {os.path.getsize(out)} bytes)")

    # ---- Adaptive icon (API 26+) ----------------------------------------
    # Android expects the layers on a 108dp canvas at every density, with the
    # glyph inside the central 66dp safe zone (the system masks the rest).
    for folder, size in DENSITIES.items():
        path = os.path.join(RES, folder)
        canvas = int(round(size * 2.25))  # 48dp icon -> 108dp layer canvas
        fg = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
        glyph = mic_only(int(canvas * 0.62))
        off = (canvas - glyph.size[0]) // 2
        fg.paste(glyph, (off, off), glyph)
        fg.save(os.path.join(path, "ic_launcher_foreground.png"))

        bg = gradient_tile(canvas, rounded=False)
        bg.save(os.path.join(path, "ic_launcher_background.png"))
        print(f"  {folder}/ layers {canvas}x{canvas}")

    anydpi = os.path.join(RES, "mipmap-anydpi-v26")
    os.makedirs(anydpi, exist_ok=True)
    with open(os.path.join(anydpi, "ic_launcher.xml"), "w") as f:
        f.write(
            '<?xml version="1.0" encoding="utf-8"?>\n'
            '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
            '    <background android:drawable="@mipmap/ic_launcher_background"/>\n'
            '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
            '</adaptive-icon>\n'
        )
    print(f"  {os.path.join(anydpi, 'ic_launcher.xml')}")


if __name__ == "__main__":
    main()
