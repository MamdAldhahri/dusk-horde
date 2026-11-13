"""Draws the placeholder 16 px tileset and writes the Crash Site map (Level 2)
as a Tiled .tmx file. Open and edit it in Tiled afterwards; this script only
made the first version.

Run from the repo root:  python3 tools/maps/make_crash_site.py
"""
import math
import os
import random
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "tiles")
T = 16
COLS, ROWS = 60, 40
random.seed(23)

NAMES = [
    "cobble", "cobble_crack", "asphalt", "road_line",
    "sidewalk", "grass", "scorched", "crater",
    "hive", "hive_vein", "roof", "wall",
    "hull", "hull_light", "rubble", "planter",
]
GID = {n: i + 1 for i, n in enumerate(NAMES)}


def noise(d, x0, y0, base, spread, n=40, tint=(0, 0, 3)):
    for _ in range(n):
        v = base + random.randint(-spread, spread)
        d.point((x0 + random.randrange(T), y0 + random.randrange(T)),
                fill=(v + tint[0], v + tint[1], v + tint[2]))


sheet = Image.new("RGBA", (8 * T, 2 * T), (0, 0, 0, 0))
d = ImageDraw.Draw(sheet)
for i, name in enumerate(NAMES):
    x, y = (i % 8) * T, (i // 8) * T
    box = [x, y, x + T - 1, y + T - 1]
    if name.startswith("cobble"):
        d.rectangle(box, fill=(52, 50, 56))
        for yy in range(0, T, 4):
            off = 0 if (yy // 4) % 2 == 0 else 2
            for xx in range(off, T, 4):
                v = 62 + random.randint(-6, 6)
                d.rectangle([x + xx, y + yy, x + xx + 2, y + yy + 2], fill=(v, v - 2, v + 4))
        if name == "cobble_crack":
            d.line([x + 2, y + 3, x + 8, y + 9, x + 14, y + 8], fill=(26, 24, 30))
    elif name in ("asphalt", "road_line"):
        d.rectangle(box, fill=(34, 34, 40))
        noise(d, x, y, 40, 8, 50)
        if name == "road_line":
            d.rectangle([x + 2, y + 7, x + 13, y + 8], fill=(140, 130, 80))
    elif name == "sidewalk":
        d.rectangle(box, fill=(76, 74, 78))
        noise(d, x, y, 78, 6, 30)
        d.line([x, y + T - 1, x + T - 1, y + T - 1], fill=(56, 54, 58))
        d.line([x + T - 1, y, x + T - 1, y + T - 1], fill=(56, 54, 58))
    elif name == "grass":
        d.rectangle(box, fill=(36, 44, 34))
        for _ in range(14):
            px, py = x + random.randrange(T), y + random.randrange(T)
            d.line([px, py, px, py - 2], fill=(58, 70, 48))
    elif name == "scorched":
        d.rectangle(box, fill=(30, 26, 26))
        noise(d, x, y, 26, 8, 40, (2, 0, 0))
        d.point((x + 5, y + 9), fill=(120, 60, 30))
    elif name == "crater":
        d.rectangle(box, fill=(22, 18, 20))
        noise(d, x, y, 18, 6, 30)
    elif name.startswith("hive"):
        d.rectangle(box, fill=(54, 22, 62))
        noise(d, x, y, 50, 10, 40, (14, -26, 22))
        if name == "hive_vein":
            d.line([x, y + 4, x + 6, y + 8, x + 15, y + 6], fill=(150, 60, 170))
            d.line([x + 6, y + 8, x + 8, y + 15], fill=(150, 60, 170))
            d.point((x + 6, y + 8), fill=(120, 255, 140))
    elif name == "roof":
        d.rectangle(box, fill=(48, 40, 44))
        for r in range(0, T, 4):
            d.line([x, y + r, x + T - 1, y + r], fill=(36, 30, 34))
    elif name == "wall":
        d.rectangle(box, fill=(84, 74, 66))
        for r in range(4):
            d.line([x, y + r * 4 + 3, x + T - 1, y + r * 4 + 3], fill=(50, 44, 40))
    elif name.startswith("hull"):
        d.rectangle(box, fill=(70, 78, 92))
        d.line([x, y, x + T - 1, y], fill=(100, 110, 128))
        d.line([x, y + 8, x + T - 1, y + 8], fill=(52, 58, 70))
        d.point((x + 3, y + 3), fill=(40, 44, 52))
        d.point((x + 12, y + 11), fill=(40, 44, 52))
        if name == "hull_light":
            d.rectangle([x + 5, y + 3, x + 10, y + 5], fill=(120, 255, 160))
    elif name == "rubble":
        d.rectangle(box, fill=(44, 40, 42))
        for _ in range(6):
            px, py = x + random.randrange(2, T - 3), y + random.randrange(2, T - 3)
            v = random.randint(60, 90)
            d.rectangle([px, py, px + 2, py + 1], fill=(v, v - 4, v - 6))
    elif name == "planter":
        d.rectangle(box, fill=(70, 66, 62))
        d.rectangle([x + 2, y + 2, x + 13, y + 13], fill=(40, 34, 28))
        d.ellipse([x + 4, y + 4, x + 11, y + 11], fill=(44, 56, 38))

os.makedirs(OUT, exist_ok=True)
sheet.save(os.path.join(OUT, "crash_site_tiles.png"))

ground = [[GID["grass"]] * COLS for _ in range(ROWS)]
walls = [[0] * COLS for _ in range(ROWS)]


def fill(layer, c0, r0, c1, r1, gid):
    for r in range(r0, r1 + 1):
        for c in range(c0, c1 + 1):
            layer[r][c] = gid(c, r) if callable(gid) else gid


def cobble(c, r):
    return GID["cobble_crack"] if random.random() < 0.08 else GID["cobble"]


# Streets around a town square.
fill(ground, 0, 0, COLS - 1, ROWS - 1, GID["asphalt"])
fill(ground, 6, 6, 53, 33, GID["sidewalk"])
fill(ground, 8, 8, 51, 31, cobble)
for c in range(0, COLS, 3):
    ground[3][c] = GID["road_line"]
    ground[36][c] = GID["road_line"]

# Buildings in the four corners of the square block, with alleys between.
buildings = [(8, 8, 17, 14), (42, 8, 51, 13), (8, 26, 16, 31), (43, 25, 51, 31)]
for c0, r0, c1, r1 in buildings:
    fill(walls, c0, r0, c1, r1 - 1, GID["roof"])
    fill(walls, c0, r1, c1, r1, GID["wall"])

# The downed ship, nose-first into the square, with a scorched crater and a
# trail of hive growth spreading out from it.
cx, cy = 31, 19
for r in range(ROWS):
    for c in range(COLS):
        dist = math.hypot((c - cx) / 1.4, r - cy)
        if dist < 9 and ground[r][c] != GID["asphalt"]:
            ground[r][c] = GID["scorched"] if dist > 6.5 else GID["crater"]
fill(walls, 26, 17, 37, 21, GID["hull"])
fill(walls, 24, 18, 25, 20, GID["hull"])
walls[19][23] = GID["hull"]
for c in (28, 31, 34):
    walls[17][c] = GID["hull_light"]
    walls[21][c] = GID["hull_light"]

hive_spots = [(20, 12), (40, 22), (22, 27), (36, 11), (47, 18)]
for hc, hr in hive_spots:
    for r in range(hr - 3, hr + 4):
        for c in range(hc - 4, hc + 5):
            if 0 <= r < ROWS and 0 <= c < COLS and walls[r][c] == 0:
                if math.hypot((c - hc) / 1.3, r - hr) + random.random() < 3.6:
                    ground[r][c] = GID["hive_vein"] if random.random() < 0.3 else GID["hive"]

# Rubble and planters for texture.
for _ in range(40):
    c, r = random.randrange(8, 52), random.randrange(8, 32)
    if walls[r][c] == 0 and ground[r][c] in (GID["cobble"], GID["cobble_crack"]):
        ground[r][c] = GID["rubble"]
for c, r in [(22, 9), (37, 9), (22, 30), (37, 30)]:
    walls[r][c] = GID["planter"]


def csv(layer):
    return ",\n".join(",".join(str(v) for v in row) for row in layer)


collision = []
for c0, r0, c1, r1 in buildings:
    collision.append(("building", c0 * T, r0 * T, (c1 - c0 + 1) * T, (r1 - r0 + 1) * T, "wall"))
collision.append(("ship", 26 * T, 17 * T, 12 * T, 5 * T, "wall"))
collision.append(("ship", 24 * T, 18 * T, 2 * T, 3 * T, "wall"))
for c, r in [(22, 9), (37, 9), (22, 30), (37, 30)]:
    collision.append(("planter", c * T, r * T, T, T, "wall"))
for name, x, y, w, h in [
    ("car", 3 * T, 10 * T, 30, 56),
    ("car", 55 * T, 24 * T, 30, 56),
    ("car", 20 * T, 2 * T, 64, 30),
    ("car", 40 * T, 35 * T, 64, 30),
    ("debris", 15 * T, 19 * T, 40, 22),
    ("debris", 44 * T, 16 * T, 22, 40),
    ("debris", 30 * T, 27 * T, 44, 20),
    ("debris", 29 * T, 11 * T, 36, 18),
]:
    collision.append((name, x, y, w, h, "prop"))

spawns = [(0, 4 * T), (0, 35 * T), (COLS * T, 4 * T), (COLS * T, 35 * T),
          (30 * T, 0), (30 * T, ROWS * T)]
hives = [(c * T + 8, r * T + 8) for c, r in hive_spots]
pickups = [(12 * T, 20 * T), (48 * T, 21 * T), (30 * T, 8 * T), (30 * T, 32 * T), (20 * T, 24 * T)]
crate = (19 * T, 17 * T)
start = (31 * T, 25 * T)

oid = [1]


def obj(name, x, y, extra=""):
    i = oid[0]
    oid[0] += 1
    return f'<object id="{i}" name="{name}" {extra}x="{x}" y="{y}"><point/></object>'


coll_xml = []
for name, x, y, w, h, kind in collision:
    i = oid[0]
    oid[0] += 1
    coll_xml.append(f'<object id="{i}" name="{name}" type="{kind}" x="{x}" y="{y}" width="{w}" height="{h}"/>')
spawn_xml = [obj("spawn", x, y) for x, y in spawns]
hive_xml = [obj("hive", x, y) for x, y in hives]
pick_xml = [obj("pickup", x, y) for x, y in pickups]
other_xml = [obj("supply_crate", *crate), obj("player_start", *start)]

groups = []
for gi, (gname, items) in enumerate([("collision", coll_xml), ("spawns", spawn_xml), ("hives", hive_xml),
                                     ("pickups", pick_xml), ("markers", other_xml)]):
    groups.append(f' <objectgroup id="{gi + 3}" name="{gname}">\n' + "\n".join("  " + o for o in items) + "\n </objectgroup>")

tmx = f'''<?xml version="1.0" encoding="UTF-8"?>
<map version="1.10" tiledversion="1.10.2" orientation="orthogonal" renderorder="right-down" width="{COLS}" height="{ROWS}" tilewidth="{T}" tileheight="{T}" infinite="0" nextlayerid="8" nextobjectid="{oid[0]}">
 <tileset firstgid="1" name="crash_site_tiles" tilewidth="{T}" tileheight="{T}" tilecount="16" columns="8">
  <image source="crash_site_tiles.png" width="{8 * T}" height="{2 * T}"/>
 </tileset>
 <layer id="1" name="ground" width="{COLS}" height="{ROWS}">
  <data encoding="csv">
{csv(ground)}
</data>
 </layer>
 <layer id="2" name="walls" width="{COLS}" height="{ROWS}">
  <data encoding="csv">
{csv(walls)}
</data>
 </layer>
{chr(10).join(groups)}
</map>
'''
with open(os.path.join(OUT, "crash_site.tmx"), "w") as f:
    f.write(tmx)
print("wrote tileset and map")
