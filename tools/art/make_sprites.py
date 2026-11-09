"""Generates sample top-down pixel-art sprites for Last Light (all face right, angle 0).
Run: python3 make_sprites.py  -> writes PNGs next to this file."""
import os, random
from PIL import Image, ImageDraw

OUT = os.path.dirname(os.path.abspath(__file__))
OUTLINE = (14, 10, 12, 255)
random.seed(7)


def canvas(n=32):
    img = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def ell(d, cx, cy, rx, ry, col):
    d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=col)


def outline(img):
    px = img.load()
    w, h = img.size
    add = []
    for y in range(h):
        for x in range(w):
            if px[x, y][3] == 0:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] > 0 and px[nx, ny] != OUTLINE:
                        add.append((x, y))
                        break
    for p in add:
        px[p] = OUTLINE
    return img


def splatter(img, n, cols, box):
    px = img.load()
    x0, y0, x1, y1 = box
    for _ in range(n):
        x, y = random.randint(x0, x1), random.randint(y0, y1)
        if px[x, y][3] > 0:
            px[x, y] = random.choice(cols)


BLOOD = [(110, 14, 18, 255), (80, 8, 12, 255), (140, 22, 24, 255)]


def player():
    img, d = canvas()
    d.rectangle([18, 14, 29, 17], fill=(44, 46, 52, 255))      # rifle body
    d.rectangle([27, 15, 30, 16], fill=(30, 30, 34, 255))      # muzzle
    d.rectangle([16, 10, 22, 12], fill=(70, 62, 48, 255))      # left arm
    d.rectangle([16, 19, 21, 21], fill=(70, 62, 48, 255))      # right arm
    d.rectangle([21, 12, 22, 13], fill=(196, 150, 120, 255))   # hands
    d.rectangle([20, 18, 21, 19], fill=(196, 150, 120, 255))
    ell(d, 14, 16, 6, 9, (64, 72, 52, 255))                    # jacket shoulders
    ell(d, 13, 13, 3, 4, (86, 96, 70, 255))                    # highlight
    d.rectangle([9, 9, 11, 22], fill=(52, 44, 36, 255))        # backpack
    ell(d, 15, 16, 4, 4, (58, 40, 30, 255))                    # hair
    d.rectangle([18, 15, 19, 17], fill=(196, 150, 120, 255))   # face edge
    d.point((19, 14), fill=(255, 236, 170, 255))               # head torch
    return outline(img)


def zombie(skin, shirt, arm_reach=27, thin=0, eyes=(170, 20, 20, 255)):
    img, d = canvas()
    d.rectangle([15, 9 + thin, arm_reach, 11 + thin], fill=shirt)
    d.rectangle([15, 20 - thin, arm_reach - 2, 22 - thin], fill=shirt)
    d.rectangle([arm_reach - 2, 9 + thin, arm_reach, 11 + thin], fill=skin)
    d.rectangle([arm_reach - 4, 20 - thin, arm_reach - 2, 22 - thin], fill=skin)
    ell(d, 13, 16, 6 - thin // 2, 9 - thin, shirt)
    ell(d, 12, 13, 3, 3, tuple(min(255, c + 18) for c in shirt[:3]) + (255,))
    ell(d, 15, 17, 4, 4, skin)                                 # head
    d.point((13, 15), fill=(40, 40, 30, 255))                  # rot patches
    d.point((14, 19), fill=(40, 40, 30, 255))
    d.point((18, 15), fill=eyes)
    d.point((18, 18), fill=eyes)
    splatter(img, 14, BLOOD, (6, 6, 28, 26))
    return outline(img)


def bloater():
    img, d = canvas()
    d.rectangle([20, 12, 25, 13], fill=(96, 110, 70, 255))
    d.rectangle([20, 19, 25, 20], fill=(96, 110, 70, 255))
    ell(d, 13, 16, 11, 12, (112, 128, 76, 255))                # belly
    ell(d, 10, 12, 5, 5, (132, 150, 92, 255))
    for (x, y) in [(8, 20), (12, 8), (17, 22), (6, 14), (15, 11), (11, 17)]:
        ell(d, x, y, 1, 1, (196, 190, 70, 255))                # pustules
        d.point((x, y), fill=(236, 230, 120, 255))
    ell(d, 23, 16, 3, 3, (130, 140, 100, 255))                 # small head
    d.point((25, 15), fill=(170, 20, 20, 255))
    d.point((25, 17), fill=(170, 20, 20, 255))
    splatter(img, 8, BLOOD, (4, 6, 24, 26))
    return outline(img)


def spitter():
    img, d = canvas()
    d.rectangle([15, 11, 21, 12], fill=(60, 52, 70, 255))
    d.rectangle([15, 20, 21, 21], fill=(60, 52, 70, 255))
    ell(d, 12, 16, 6, 8, (60, 52, 70, 255))
    ell(d, 17, 16, 5, 5, (128, 136, 118, 255))                 # swollen head
    ell(d, 21, 16, 3, 3, (90, 200, 60, 255))                   # acid sac / mouth
    d.point((22, 15), fill=(190, 255, 120, 255))
    d.point((22, 16), fill=(190, 255, 120, 255))
    d.point((24, 18), fill=(90, 200, 60, 255))                 # drip
    d.point((25, 14), fill=(90, 200, 60, 255))
    splatter(img, 10, BLOOD, (6, 8, 20, 24))
    return outline(img)


def brute():
    img, d = canvas(48)
    for y0 in (8, 32):                                         # massive arms + fists
        d.rectangle([22, y0, 38, y0 + 6], fill=(92, 98, 84, 255))
        ell(d, 40, y0 + 3, 5, 5, (120, 110, 96, 255))
        d.point((42, y0 + 2), fill=(150, 140, 120, 255))
    ell(d, 20, 24, 13, 17, (72, 60, 56, 255))                  # torn overalls
    ell(d, 17, 18, 6, 6, (94, 80, 74, 255))
    d.rectangle([12, 12, 14, 36], fill=(58, 48, 44, 255))      # strap
    ell(d, 27, 24, 5, 5, (118, 124, 104, 255))                 # small head
    d.point((31, 22), fill=(220, 30, 30, 255))
    d.point((31, 26), fill=(220, 30, 30, 255))
    splatter(img, 30, BLOOD, (8, 6, 44, 42))
    return outline(img)


sprites = {
    "player": player(),
    "zombie_shambler": zombie((120, 132, 104, 255), (78, 70, 86, 255)),
    "zombie_runner": zombie((150, 140, 120, 255), (110, 46, 40, 255), arm_reach=22, thin=2),
    "zombie_bloater": bloater(),
    "zombie_spitter": spitter(),
    "zombie_brute": brute(),
}
for name, im in sprites.items():
    im.save(os.path.join(OUT, f"{name}.png"))

# ---- preview sheet: each sprite at 6x on a dark tile, with labels ----
S = 6
cells = list(sprites.items())
sheet = Image.new("RGBA", (len(cells) * 200 + 20, 250), (18, 16, 20, 255))
from PIL import ImageFont
font = ImageFont.load_default()
sd = ImageDraw.Draw(sheet)
x = 20
for name, im in cells:
    k = S // 2 if im.size[0] == 48 else S // 2
    big = im.resize((im.size[0] * 4, im.size[1] * 4), Image.NEAREST)
    sheet.alpha_composite(big, (x + (192 - big.size[0]) // 2, 20 + (192 - big.size[1]) // 2))
    sd.text((x, 220), name.replace("zombie_", ""), fill=(200, 190, 180, 255), font=font)
    x += 200
sheet.save(os.path.join(OUT, "preview_sheet.png"))

# ---- mood mock-up: dark asphalt, flashlight around player, zombies closing in ----
W, H = 320, 180
scene = Image.new("RGBA", (W, H), (34, 34, 38, 255))
spx = scene.load()
for _ in range(2500):
    x, y = random.randrange(W), random.randrange(H)
    v = random.choice([28, 30, 40, 44])
    spx[x, y] = (v, v, v + 3, 255)
sdr = ImageDraw.Draw(scene)
for x in range(10, W, 40):                                    # faded road markings
    sdr.rectangle([x, 88, x + 18, 90], fill=(120, 110, 70, 255))
for (x, y) in [(60, 40), (230, 130), (250, 50)]:              # blood pools
    sdr.ellipse([x, y, x + 22, y + 12], fill=(70, 8, 10, 255))
sdr.rectangle([20, 130, 84, 160], fill=(50, 56, 66, 255))    # wrecked car
sdr.rectangle([26, 134, 78, 156], fill=(36, 40, 48, 255))
place = [("player", 150, 74), ("zombie_shambler", 214, 64), ("zombie_shambler", 196, 112),
         ("zombie_runner", 92, 40), ("zombie_bloater", 248, 100), ("zombie_spitter", 70, 96),
         ("zombie_brute", 262, 18)]
for name, x, y in place:
    im = sprites[name]
    if name != "player":
        im = im.rotate({"zombie_shambler": 180, "zombie_runner": -30, "zombie_bloater": 180,
                        "zombie_spitter": 0, "zombie_brute": 210}[name], resample=Image.NEAREST, expand=True)
    scene.alpha_composite(im, (x, y))
# darkness with a light cone pointing right from the player
dark = Image.new("L", (W, H), 0)
dd = ImageDraw.Draw(dark)
cx, cy = 166, 90
for r in range(110, 0, -2):
    dd.ellipse([cx - r, cy - r, cx + r, cy + r], fill=int(200 * (1 - r / 110) ** 0.6))
dd.polygon([(cx, cy), (cx + 170, cy - 60), (cx + 170, cy + 60)], fill=170)
dark = dark.point(lambda v: min(255, v + 40))
black = Image.new("RGBA", (W, H), (4, 3, 6, 255))
scene = Image.composite(scene, black, dark)
scene = scene.resize((W * 4, H * 4), Image.NEAREST)
scene.save(os.path.join(OUT, "preview_scene.png"))
print("done")
