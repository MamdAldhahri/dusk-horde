"""Draws the placeholder app icon and Play Store graphics from the game's own
sprites: the survivor in a pool of light at dusk, eyes in the dark.

Run from the repo root:  python3 tools/art/make_icon.py [store_dir]
Writes the Android launcher icons into android/app/src/main/res/ and the
512 x 512 store icon and 1024 x 500 feature graphic into store_dir
(default: build/store/).
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
SPRITES = os.path.join(ROOT, "assets", "images", "sprites")
RES = os.path.join(ROOT, "android", "app", "src", "main", "res")
STORE = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "build", "store")

BG_TOP = (10, 7, 14)
BG_BOTTOM = (58, 22, 30)
EYES = (230, 40, 40)


def sprite(name, angle=0):
    im = Image.open(os.path.join(SPRITES, name + ".png")).convert("RGBA")
    return im.rotate(angle, resample=Image.NEAREST, expand=True) if angle else im


def scene(w, h, scale, player_at, extras=()):
    """Paints at low resolution (pixel art), the caller upscales."""
    img = Image.new("RGBA", (w, h))
    d = ImageDraw.Draw(img)
    for y in range(h):
        k = (y / (h - 1)) ** 1.6
        col = tuple(int(BG_TOP[i] + (BG_BOTTOM[i] - BG_TOP[i]) * k) for i in range(3))
        d.line([(0, y), (w, y)], fill=col + (255,))
    # Light: a soft glow and a cone pointing right.
    light = Image.new("L", (w, h), 0)
    ld = ImageDraw.Draw(light)
    px, py = player_at
    ld.ellipse([px - 13, py - 13, px + 13, py + 13], fill=110)
    ld.polygon([(px + 4, py), (w + 10, py - h * 0.45), (w + 10, py + h * 0.45)], fill=150)
    light = light.filter(ImageFilter.GaussianBlur(2))
    glow = Image.new("RGBA", (w, h), (236, 210, 150, 255))
    img = Image.composite(Image.blend(img, glow, 0.35), img, light)
    for name, (x, y), angle in extras:
        s = sprite(name, angle)
        img.alpha_composite(s, (int(x - s.width / 2), int(y - s.height / 2)))
    p = sprite("player")
    img.alpha_composite(p, (int(px - p.width / 2), int(py - p.height / 2)))
    d = ImageDraw.Draw(img)
    return img, d


def eyes(d, pts):
    for x, y in pts:
        d.point((x, y), fill=EYES + (255,))
        d.point((x + 2, y), fill=EYES + (255,))


def up(img, size):
    return img.resize(size, Image.NEAREST)


# Icon: 64 x 64 art, survivor slightly left, a shambler at the edge of the
# light, eyes in the dark behind.
icon, d = scene(64, 64, 1, (24, 34), [("zombie_shambler", (52, 24), 200)])
eyes(d, [(6, 10), (12, 52), (52, 54), (40, 6)])

os.makedirs(STORE, exist_ok=True)
up(icon, (512, 512)).convert("RGB").save(os.path.join(STORE, "icon_512.png"))

# Legacy launcher icons (square art; the launcher rounds it).
for folder, px in [("mdpi", 48), ("hdpi", 72), ("xhdpi", 96), ("xxhdpi", 144), ("xxxhdpi", 192)]:
    out = icon.resize((px, px), Image.NEAREST if px % 64 == 0 else Image.LANCZOS)
    out.convert("RGB").save(os.path.join(RES, f"mipmap-{folder}", "ic_launcher.png"))

# Adaptive icon (Android 8+): the same art as the foreground, scaled into
# the 72/108 safe zone, over a plain dark background.
for folder, px in [("mdpi", 108), ("hdpi", 162), ("xhdpi", 216), ("xxhdpi", 324), ("xxxhdpi", 432)]:
    fg = Image.new("RGBA", (px, px), (0, 0, 0, 0))
    inner = int(px * 72 / 108)
    art = icon.resize((inner, inner), Image.NEAREST if inner % 64 == 0 else Image.LANCZOS)
    off = (px - inner) // 2
    fg.paste(art, (off, off))
    fg.save(os.path.join(RES, f"mipmap-{folder}", "ic_launcher_foreground.png"))
os.makedirs(os.path.join(RES, "mipmap-anydpi-v26"), exist_ok=True)
with open(os.path.join(RES, "mipmap-anydpi-v26", "ic_launcher.xml"), "w") as f:
    f.write("""<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
""")
with open(os.path.join(RES, "values", "ic_launcher_background.xml"), "w") as f:
    f.write("""<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#0A070E</color>
</resources>
""")

# Feature graphic: 1024 x 500, drawn at 256 x 125 (x4), with the horde.
fg, d = scene(256, 125, 4, (70, 66), [
    ("zombie_shambler", (150, 40), 200), ("zombie_runner", (178, 86), 160),
    ("zombie_bloater", (214, 58), 180), ("alien_skitter", (128, 92), 150),
    ("alien_lancer", (236, 100), 170),
])
eyes(d, [(12, 20), (30, 100), (100, 12), (240, 16), (20, 60)])
up(fg, (1024, 500)).convert("RGB").save(os.path.join(STORE, "feature_graphic_1024x500.png"))
print("wrote launcher icons and store graphics to", STORE)
