"""Draws the placeholder 16 px tileset and writes the Gas Station map as a
Tiled .tmx file. Both are meant to be opened and edited in Tiled afterwards;
this script only made the first version.

Run from the repo root:  python3 tools/maps/make_gas_station.py
"""
import os
import random
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "tiles")
T = 16
COLS, ROWS = 60, 34
random.seed(11)

# ---------------------------------------------------------------- tileset ---
NAMES = [
    "asphalt", "asphalt_crack", "asphalt_oil", "road_line",
    "concrete", "concrete_crack", "shop_floor", "dead_grass",
    "brick_wall", "roof", "island_curb", "fuel_pump",
    "parking_line", "asphalt_blood", "curb", "dirt",
]
GID = {n: i + 1 for i, n in enumerate(NAMES)}


def noise(d, x0, y0, base, spread, n=40):
    for _ in range(n):
        v = base + random.randint(-spread, spread)
        d.point((x0 + random.randrange(T), y0 + random.randrange(T)), fill=(v, v, v + 3))


def tile(i):
    return (i % 8) * T, (i // 8) * T


sheet = Image.new("RGBA", (8 * T, 2 * T), (0, 0, 0, 0))
d = ImageDraw.Draw(sheet)
for i, name in enumerate(NAMES):
    x, y = tile(i)
    box = [x, y, x + T - 1, y + T - 1]
    if name.startswith("asphalt") or name in ("road_line", "parking_line"):
        d.rectangle(box, fill=(36, 36, 40))
        noise(d, x, y, 40, 8, 50)
        if name == "asphalt_crack":
            d.line([x + 2, y + 5, x + 7, y + 8, x + 13, y + 7], fill=(22, 22, 25))
        if name == "asphalt_oil":
            d.ellipse([x + 3, y + 4, x + 12, y + 11], fill=(24, 22, 30))
        if name == "asphalt_blood":
            d.ellipse([x + 2, y + 5, x + 13, y + 12], fill=(70, 10, 12))
            d.point((x + 5, y + 3), fill=(90, 14, 16))
        if name == "road_line":
            d.rectangle([x + 2, y + 7, x + 13, y + 8], fill=(150, 132, 70))
        if name == "parking_line":
            d.rectangle([x + 7, y, x + 8, y + T - 1], fill=(150, 150, 140))
    elif name.startswith("concrete"):
        d.rectangle(box, fill=(70, 70, 72))
        noise(d, x, y, 74, 8, 40)
        d.line([x, y + T - 1, x + T - 1, y + T - 1], fill=(56, 56, 58))
        d.line([x + T - 1, y, x + T - 1, y + T - 1], fill=(56, 56, 58))
        if name == "concrete_crack":
            d.line([x + 3, y + 2, x + 6, y + 9, x + 5, y + 14], fill=(44, 44, 46))
    elif name == "shop_floor":
        for yy in range(2):
            for xx in range(2):
                c = (92, 86, 80) if (xx + yy) % 2 == 0 else (70, 66, 62)
                d.rectangle([x + xx * 8, y + yy * 8, x + xx * 8 + 7, y + yy * 8 + 7], fill=c)
    elif name == "dead_grass":
        d.rectangle(box, fill=(48, 46, 32))
        for _ in range(14):
            px, py = x + random.randrange(T), y + random.randrange(T)
            d.line([px, py, px, py - 2], fill=(78, 72, 44))
    elif name == "brick_wall":
        d.rectangle(box, fill=(72, 40, 34))
        for r in range(4):
            d.line([x, y + r * 4 + 3, x + T - 1, y + r * 4 + 3], fill=(40, 22, 20))
            off = 0 if r % 2 == 0 else 4
            for c in range(off, T, 8):
                d.line([x + c, y + r * 4, x + c, y + r * 4 + 3], fill=(40, 22, 20))
    elif name == "roof":
        d.rectangle(box, fill=(44, 46, 52))
        for r in range(0, T, 4):
            d.line([x, y + r, x + T - 1, y + r], fill=(34, 36, 40))
    elif name == "island_curb":
        d.rectangle(box, fill=(150, 130, 40))
        for c in range(0, T, 6):
            d.rectangle([x + c, y, x + c + 2, y + T - 1], fill=(30, 30, 30))
    elif name == "fuel_pump":
        d.rectangle(box, fill=(150, 130, 40))
        d.rectangle([x + 3, y + 2, x + 12, y + 13], fill=(140, 30, 30))
        d.rectangle([x + 5, y + 4, x + 10, y + 7], fill=(190, 200, 170))
        d.point((x + 13, y + 9), fill=(20, 20, 20))
    elif name == "curb":
        d.rectangle(box, fill=(90, 90, 92))
        d.line([x, y + T - 2, x + T - 1, y + T - 2], fill=(50, 50, 52))
    elif name == "dirt":
        d.rectangle(box, fill=(42, 34, 26))
        noise(d, x, y, 40, 10, 30)

os.makedirs(OUT, exist_ok=True)
sheet.save(os.path.join(OUT, "gas_station_tiles.png"))

# -------------------------------------------------------------------- map ---
ground = [[GID["dead_grass"]] * COLS for _ in range(ROWS)]
walls = [[0] * COLS for _ in range(ROWS)]


def fill(layer, c0, r0, c1, r1, gid):
    for r in range(r0, r1 + 1):
        for c in range(c0, c1 + 1):
            layer[r][c] = gid(c, r) if callable(gid) else gid


def asphalt(c, r):
    roll = random.random()
    if roll < 0.06:
        return GID["asphalt_crack"]
    if roll < 0.09:
        return GID["asphalt_oil"]
    if roll < 0.098:
        return GID["asphalt_blood"]
    return GID["asphalt"]


def concrete(c, r):
    return GID["concrete_crack"] if random.random() < 0.08 else GID["concrete"]


# Dirt patches in the top strip, road along the bottom.
fill(ground, 0, 0, COLS - 1, 5, lambda c, r: GID["dirt"] if random.random() < 0.3 else GID["dead_grass"])
fill(ground, 0, 25, COLS - 1, ROWS - 1, asphalt)
for c in range(0, COLS, 3):
    ground[29][c] = GID["road_line"]
fill(ground, 0, 24, COLS - 1, 24, GID["curb"])
# Forecourt.
fill(ground, 6, 6, 53, 23, concrete)
# Parking bays left of the shop.
fill(ground, 6, 6, 18, 11, asphalt)
for c in range(7, 18, 3):
    for r in range(6, 11):
        ground[r][c] = GID["parking_line"]
# Shop: brick walls around a roof, door gap facing the pumps.
fill(walls, 36, 2, 51, 10, GID["roof"])
fill(walls, 36, 10, 51, 10, GID["brick_wall"])
walls[10][43] = 0
walls[10][44] = 0
fill(ground, 43, 10, 44, 10, GID["shop_floor"])
# Two pump islands.
for c0 in (16, 28):
    fill(walls, c0, 15, c0 + 7, 16, GID["island_curb"])
    walls[15][c0 + 2] = GID["fuel_pump"]
    walls[15][c0 + 5] = GID["fuel_pump"]


def csv(layer):
    return ",\n".join(",".join(str(v) for v in row) for row in layer)


collision = []
# Shop block (walls + roof, minus nothing: the door is just decoration for now).
collision.append(("shop", 36 * T, 2 * T, 16 * T, 9 * T, "wall"))
for c0 in (16, 28):
    collision.append(("pump_island", c0 * T, 15 * T, 8 * T, 2 * T, "wall"))
# Wrecked cars and a dumpster, drawn by the game.
for name, x, y, w, h in [
    ("car", 9 * T, 7 * T + 4, 30, 56),
    ("car", 15 * T, 8 * T, 30, 56),
    ("car", 30 * T, 26 * T, 64, 30),
    ("car", 46 * T, 30 * T, 64, 30),
    ("car", 6 * T, 19 * T, 64, 30),
    ("dumpster", 52 * T + 4, 4 * T, 26, 40),
    ("car", 41 * T, 18 * T, 30, 60),
]:
    collision.append((name, x, y, w, h, "prop"))

spawns = [(0, 27 * T), (0, 31 * T), (COLS * T, 26 * T), (COLS * T, 32 * T),
          (8 * T, 0), (24 * T, 0), (56 * T, 0), (30 * T, ROWS * T)]
pickups = [(12 * T, 21 * T), (24 * T, 20 * T), (48 * T, 15 * T), (22 * T, 9 * T), (34 * T, 28 * T)]
crate = (43 * T + 8, 12 * T)
start = (30 * T, 20 * T)

oid = [1]
coll_xml, spawn_xml, pick_xml, other_xml = [], [], [], []
for name, x, y, w, h, kind in collision:
    i = oid[0]; oid[0] += 1
    coll_xml.append(f'<object id="{i}" name="{name}" type="{kind}" x="{x}" y="{y}" width="{w}" height="{h}"/>')
for x, y in spawns:
    i = oid[0]; oid[0] += 1
    spawn_xml.append(f'<object id="{i}" name="spawn" x="{x}" y="{y}"><point/></object>')
for x, y in pickups:
    i = oid[0]; oid[0] += 1
    pick_xml.append(f'<object id="{i}" name="pickup" x="{x}" y="{y}"><point/></object>')
i = oid[0]; oid[0] += 1
other_xml.append(f'<object id="{i}" name="supply_crate" x="{crate[0]}" y="{crate[1]}"><point/></object>')
i = oid[0]; oid[0] += 1
other_xml.append(f'<object id="{i}" name="player_start" x="{start[0]}" y="{start[1]}"><point/></object>')

groups = []
for gi, (gname, items) in enumerate([("collision", coll_xml), ("spawns", spawn_xml), ("pickups", pick_xml), ("markers", other_xml)]):
    groups.append(f' <objectgroup id="{gi + 3}" name="{gname}">\n' + "\n".join("  " + o for o in items) + "\n </objectgroup>")

tmx = f'''<?xml version="1.0" encoding="UTF-8"?>
<map version="1.10" tiledversion="1.10.2" orientation="orthogonal" renderorder="right-down" width="{COLS}" height="{ROWS}" tilewidth="{T}" tileheight="{T}" infinite="0" nextlayerid="7" nextobjectid="{oid[0]}">
 <tileset firstgid="1" name="gas_station_tiles" tilewidth="{T}" tileheight="{T}" tilecount="16" columns="8">
  <image source="gas_station_tiles.png" width="{8 * T}" height="{2 * T}"/>
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
with open(os.path.join(OUT, "gas_station.tmx"), "w") as f:
    f.write(tmx)
print("wrote tileset and map")
