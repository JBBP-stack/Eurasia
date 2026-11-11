"""Genera los atlas PNG pixel art usados por las escenas de Eurasia.

No requiere Pillow: escribe PNG RGBA con la biblioteca estandar de Python.
Los rectangulos de cada objeto se documentan tambien en las escenas Godot.
"""
from __future__ import annotations

import struct
import zlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "godot" / "assets" / "escenarios" / "decoracion"

INK = (43, 29, 43, 255)
INK2 = (69, 42, 54, 255)
WOOD_D = (94, 49, 42, 255)
WOOD = (145, 78, 49, 255)
WOOD_L = (198, 119, 62, 255)
GOLD = (242, 187, 91, 255)
GOLD_L = (255, 222, 151, 255)
CREAM = (250, 230, 190, 255)
WALL = (179, 124, 139, 255)
WALL_L = (207, 150, 158, 255)
PLUM = (76, 49, 79, 255)
BLUE = (46, 59, 101, 255)
BLUE_L = (89, 111, 159, 255)
GREEN = (71, 123, 65, 255)
GREEN_L = (119, 168, 84, 255)
POT = (166, 78, 49, 255)


class Canvas:
    def __init__(self, width: int, height: int):
        self.width, self.height = width, height
        self.pixels = bytearray(width * height * 4)

    def rect(self, x: int, y: int, w: int, h: int, color):
        x0, y0 = max(0, int(x)), max(0, int(y))
        x1, y1 = min(self.width, int(x + w)), min(self.height, int(y + h))
        if x1 <= x0 or y1 <= y0:
            return
        row = bytes(color) * (x1 - x0)
        for py in range(y0, y1):
            start = (py * self.width + x0) * 4
            self.pixels[start:start + len(row)] = row

    def box(self, x, y, w, h, fill, edge=INK, border=2):
        self.rect(x, y, w, h, edge)
        self.rect(x + border, y + border, w - 2 * border, h - 2 * border, fill)

    def line(self, x0, y0, x1, y1, color, width=1):
        dx, dy = abs(x1 - x0), abs(y1 - y0)
        sx, sy = (1 if x0 < x1 else -1), (1 if y0 < y1 else -1)
        err = dx - dy
        while True:
            self.rect(x0 - width // 2, y0 - width // 2, width, width, color)
            if x0 == x1 and y0 == y1:
                break
            e2 = 2 * err
            if e2 > -dy:
                err -= dy
                x0 += sx
            if e2 < dx:
                err += dx
                y0 += sy

    def poly(self, points, color):
        ymin = max(0, min(p[1] for p in points))
        ymax = min(self.height - 1, max(p[1] for p in points))
        for y in range(ymin, ymax + 1):
            xs = []
            for i, (x1, y1) in enumerate(points):
                x2, y2 = points[(i + 1) % len(points)]
                if (y1 <= y < y2) or (y2 <= y < y1):
                    xs.append(round(x1 + (y - y1) * (x2 - x1) / (y2 - y1)))
            xs.sort()
            for i in range(0, len(xs) - 1, 2):
                self.rect(xs[i], y, xs[i + 1] - xs[i] + 1, 1, color)

    def ellipse(self, x, y, w, h, color):
        rx, ry = w / 2.0, h / 2.0
        cx, cy = x + rx, y + ry
        for py in range(max(0, y), min(self.height, y + h)):
            for px in range(max(0, x), min(self.width, x + w)):
                if ((px + 0.5 - cx) / rx) ** 2 + ((py + 0.5 - cy) / ry) ** 2 <= 1:
                    self.rect(px, py, 1, 1, color)

    def save(self, path: Path):
        path.parent.mkdir(parents=True, exist_ok=True)
        scanlines = bytearray()
        stride = self.width * 4
        for y in range(self.height):
            scanlines.append(0)
            scanlines.extend(self.pixels[y * stride:(y + 1) * stride])

        def chunk(name: bytes, payload: bytes):
            return (struct.pack(">I", len(payload)) + name + payload
                    + struct.pack(">I", zlib.crc32(name + payload) & 0xFFFFFFFF))

        png = (b"\x89PNG\r\n\x1a\n"
               + chunk(b"IHDR", struct.pack(">IIBBBBB", self.width, self.height, 8, 6, 0, 0, 0))
               + chunk(b"IDAT", zlib.compress(bytes(scanlines), 9))
               + chunk(b"IEND", b""))
        path.write_bytes(png)


class Part:
    def __init__(self, canvas: Canvas, x: int, y: int):
        self.c, self.x, self.y = canvas, x, y

    def rect(self, x, y, w, h, color):
        self.c.rect(self.x + x, self.y + y, w, h, color)

    def box(self, x, y, w, h, fill, edge=INK, border=2):
        self.c.box(self.x + x, self.y + y, w, h, fill, edge, border)

    def line(self, x0, y0, x1, y1, color, width=1):
        self.c.line(self.x + x0, self.y + y0, self.x + x1, self.y + y1, color, width)

    def poly(self, points, color):
        self.c.poly([(self.x + x, self.y + y) for x, y in points], color)

    def ellipse(self, x, y, w, h, color):
        self.c.ellipse(self.x + x, self.y + y, w, h, color)


FONT = {
    "A": "010/101/111/101/101", "B": "110/101/110/101/110", "C": "011/100/100/100/011",
    "D": "110/101/101/101/110", "E": "111/100/110/100/111", "F": "111/100/110/100/100",
    "G": "011/100/101/101/011", "H": "101/101/111/101/101", "I": "111/010/010/010/111",
    "J": "001/001/001/101/010", "K": "101/101/110/101/101", "L": "100/100/100/100/111",
    "M": "101/111/111/101/101", "N": "101/111/111/111/101", "O": "010/101/101/101/010",
    "P": "110/101/110/100/100", "Q": "010/101/101/111/011", "R": "110/101/110/101/101",
    "S": "011/100/010/001/110", "T": "111/010/010/010/010", "U": "101/101/101/101/111",
    "V": "101/101/101/101/010", "W": "101/101/111/111/101", "X": "101/101/010/101/101",
    "Y": "101/101/010/010/010", "Z": "111/001/010/100/111", "+": "000/010/111/010/000",
    "0": "111/101/101/101/111", "1": "010/110/010/010/111", "2": "110/001/010/100/111",
    "3": "110/001/010/001/110", "4": "101/101/111/001/001", "5": "111/100/110/001/110",
    "6": "011/100/110/101/010", "7": "111/001/010/010/010", "8": "010/101/010/101/010",
    "9": "010/101/011/001/110", ".": "000/000/000/000/010", ":": "000/010/000/010/000",
}


def text(p: Part, x: int, y: int, value: str, color, scale=2):
    cursor = x
    for ch in value.upper():
        glyph = FONT.get(ch)
        if glyph:
            for gy, row in enumerate(glyph.split("/")):
                for gx, bit in enumerate(row):
                    if bit == "1":
                        p.rect(cursor + gx * scale, y + gy * scale, scale, scale, color)
        cursor += 4 * scale


def center_text(p, y, value, color, scale=2):
    text(p, (p.c.width - p.x - len(value) * 4 * scale + scale) // 2, y, value, color, scale)


def draw_picture_city(p):
    p.box(0, 0, 80, 56, WOOD_D, INK, 3)
    p.box(5, 5, 70, 46, GOLD, WOOD, 2)
    p.rect(9, 9, 62, 38, (79, 78, 113, 255))
    p.rect(9, 34, 62, 13, (106, 73, 93, 255))
    buildings = [(13, 27, 9, 20), (23, 20, 12, 27), (36, 29, 8, 18), (45, 16, 13, 31), (59, 25, 9, 22)]
    for x, y, w, h in buildings:
        p.rect(x, y, w, h, (48, 48, 74, 255))
        for wx in range(x + 2, x + w - 1, 4):
            for wy in range(y + 4, 43, 6):
                p.rect(wx, wy, 2, 2, GOLD)
    p.rect(19, 14, 2, 2, GOLD_L)
    p.rect(56, 13, 2, 2, GOLD_L)


def draw_picture_map(p):
    p.box(0, 0, 88, 56, WOOD_D, INK, 3)
    p.box(5, 5, 78, 46, GOLD, WOOD, 2)
    p.rect(9, 9, 70, 38, (68, 83, 111, 255))
    p.poly([(18, 20), (27, 12), (38, 15), (40, 22), (34, 27), (39, 34), (29, 42), (21, 37), (17, 29)], (184, 161, 111, 255))
    p.poly([(49, 17), (59, 13), (70, 18), (68, 23), (73, 28), (65, 32), (62, 40), (54, 37), (51, 29), (45, 25)], (184, 161, 111, 255))
    p.line(12, 43, 76, 43, (93, 117, 145, 255))


def draw_coat(p):
    p.rect(8, 5, 56, 5, WOOD_D)
    p.rect(12, 4, 3, 9, GOLD)
    p.rect(57, 4, 3, 9, GOLD)
    p.line(22, 10, 22, 28, GOLD, 3)
    p.line(49, 10, 49, 28, GOLD, 3)
    p.poly([(29, 19), (35, 15), (41, 19), (53, 23), (49, 33), (51, 78), (43, 86), (35, 81), (27, 86), (19, 78), (22, 34), (17, 26)], WOOD_D)
    p.poly([(31, 21), (35, 18), (39, 21), (47, 25), (44, 34), (46, 76), (40, 80), (35, 76), (29, 81), (24, 76), (27, 34), (22, 27)], WOOD)
    p.poly([(30, 21), (35, 29), (40, 21), (38, 35), (33, 35)], GOLD)
    p.line(35, 37, 35, 74, WOOD_L, 2)
    p.rect(37, 51, 3, 3, GOLD_L)
    p.line(22, 36, 13, 52, WOOD_D, 5)
    p.line(48, 36, 57, 52, WOOD_D, 5)


def draw_rug(p):
    p.box(0, 0, 232, 120, PLUM, INK, 4)
    p.box(7, 7, 218, 106, (101, 58, 84, 255), GOLD, 3)
    p.box(14, 14, 204, 92, (78, 50, 77, 255), WOOD_L, 2)
    p.line(18, 21, 213, 21, GOLD)
    p.line(18, 99, 213, 99, GOLD)
    for x in range(28, 210, 24):
        p.poly([(x, 60), (x + 8, 52), (x + 16, 60), (x + 8, 68)], GOLD)
        p.rect(x + 6, 58, 4, 4, WOOD_L)
    for x, y in [(21, 26), (198, 26), (21, 84), (198, 84)]:
        p.poly([(x, y + 5), (x + 5, y), (x + 10, y + 5), (x + 5, y + 10)], WOOD_L)


def draw_desk(p):
    p.rect(22, 70, 10, 17, WOOD_D)
    p.rect(128, 70, 10, 17, WOOD_D)
    p.box(8, 11, 144, 64, WOOD, INK, 3)
    p.rect(13, 16, 134, 4, WOOD_L)
    p.rect(13, 21, 134, 43, (165, 92, 51, 255))
    for x in range(20, 142, 18):
        p.line(x, 24, x + 8, 61, (174, 100, 56, 255))
    p.rect(8, 62, 144, 11, WOOD_D)
    p.rect(12, 64, 136, 3, WOOD_L)
    p.box(57, 66, 46, 13, WOOD, WOOD_D, 2)
    p.rect(77, 71, 7, 2, GOLD)
    p.rect(31, 78, 7, 8, WOOD_D)
    p.rect(122, 78, 7, 8, WOOD_D)
    p.rect(18, 8, 124, 2, GOLD_L)


def draw_stool(p):
    p.rect(12, 19, 5, 15, WOOD_D)
    p.rect(35, 19, 5, 15, WOOD_D)
    p.line(14, 25, 38, 25, WOOD_L, 2)
    p.box(5, 5, 43, 17, WOOD, INK, 3)
    p.rect(10, 8, 33, 3, WOOD_L)
    p.rect(22, 13, 8, 2, GOLD)


def draw_bookcase(p):
    p.box(0, 0, 224, 60, WOOD_D, INK, 3)
    p.rect(5, 5, 214, 5, WOOD_L)
    p.rect(5, 28, 214, 5, WOOD_L)
    p.rect(5, 52, 214, 4, WOOD_L)
    colors = [(152, 58, 58, 255), (53, 79, 120, 255), (213, 157, 72, 255), (74, 119, 75, 255), (124, 68, 87, 255)]
    for row, base_y in enumerate((11, 35)):
        x = 10 + (row % 2) * 5
        i = 0
        while x < 208:
            w = 7 + ((i * 3 + row) % 4)
            h = 14 if (i % 3) else 17
            p.rect(x, base_y + (17 - h), w, h, INK)
            p.rect(x + 1, base_y + (18 - h), w - 2, h - 2, colors[i % len(colors)])
            p.rect(x + 2, base_y + (19 - h), 1, h - 4, GOLD_L)
            x += w + 3
            i += 1


def draw_bedside(p):
    p.rect(18, 4, 36, 5, GOLD)
    p.poly([(15, 9), (57, 9), (51, 29), (21, 29)], GOLD_L)
    p.rect(32, 28, 5, 9, WOOD_D)
    p.box(7, 39, 58, 37, WOOD, INK, 3)
    p.rect(11, 43, 50, 5, WOOD_L)
    p.box(18, 51, 36, 15, (164, 91, 52, 255), WOOD_D, 2)
    p.rect(32, 57, 8, 3, GOLD)
    p.rect(12, 73, 6, 10, WOOD_D)
    p.rect(54, 73, 6, 10, WOOD_D)
    p.rect(21, 31, 30, 4, GOLD_L)


def draw_plant(p):
    p.line(31, 49, 30, 26, GREEN, 3)
    p.line(31, 43, 15, 26, GREEN, 3)
    p.line(31, 39, 48, 20, GREEN, 3)
    p.poly([(30, 29), (18, 18), (8, 18), (12, 29), (27, 36)], GREEN)
    p.poly([(31, 28), (36, 11), (47, 8), (49, 16), (37, 32)], GREEN_L)
    p.poly([(30, 39), (10, 34), (7, 27), (18, 27), (34, 37)], GREEN_L)
    p.poly([(32, 38), (46, 29), (57, 31), (52, 40), (34, 45)], GREEN)
    p.poly([(19, 52), (46, 52), (42, 82), (23, 82)], POT)
    p.rect(16, 50, 33, 5, (205, 111, 64, 255))
    p.rect(23, 60, 3, 17, (193, 95, 57, 255))
    p.rect(40, 60, 3, 17, (193, 95, 57, 255))


def draw_bed(p):
    p.box(4, 4, 96, 160, WOOD_D, INK, 4)
    p.rect(10, 11, 84, 9, WOOD_L)
    p.box(11, 22, 82, 132, (227, 213, 188, 255), WOOD, 3)
    p.box(15, 28, 74, 31, CREAM, (153, 124, 112, 255), 2)
    p.rect(20, 33, 63, 2, (255, 242, 213, 255))
    p.box(12, 61, 80, 87, BLUE, (34, 43, 78, 255), 2)
    for y in range(65, 145, 12):
        for x in range(16 + ((y // 12) % 2) * 6, 88, 12):
            p.rect(x, y, 4, 4, BLUE_L)
            p.rect(x + 1, y + 1, 2, 2, (117, 129, 175, 255))
    p.rect(9, 150, 86, 7, WOOD)
    p.rect(13, 158, 7, 7, WOOD_D)
    p.rect(84, 158, 7, 7, WOOD_D)
    p.rect(6, 4, 92, 4, GOLD)


def draw_mailbox(p):
    p.box(8, 9, 64, 56, (203, 139, 38, 255), INK, 3)
    p.rect(13, 14, 54, 6, GOLD_L)
    p.box(22, 38, 36, 20, CREAM, WOOD_D, 2)
    p.line(23, 39, 40, 50, WOOD, 2)
    p.line(57, 39, 40, 50, WOOD, 2)
    p.rect(25, 28, 30, 4, INK2)
    p.rect(4, 4, 72, 5, GOLD)
    p.rect(19, 62, 42, 3, WOOD_D)


def draw_bank_sign(p):
    p.poly([(10, 14), (186, 14), (196, 24), (196, 62), (186, 72), (10, 72), (0, 62), (0, 24)], WOOD_D)
    p.poly([(14, 18), (182, 18), (190, 26), (190, 60), (182, 68), (14, 68), (6, 60), (6, 26)], GOLD)
    p.poly([(18, 22), (178, 22), (186, 30), (186, 56), (178, 64), (18, 64), (10, 56), (10, 30)], (101, 49, 59, 255))
    p.poly([(32, 44), (54, 31), (76, 44)], GOLD_L)
    p.rect(37, 44, 30, 3, GOLD_L)
    for x in (39, 49, 59):
        p.rect(x, 47, 4, 10, GOLD_L)
    p.rect(35, 57, 37, 3, GOLD_L)
    text(p, 83, 40, "BANCO EURASIA", CREAM, 2)
    p.rect(82, 56, 101, 2, GOLD)


def draw_service_board(p):
    p.box(0, 0, 144, 144, (214, 183, 136, 255), INK, 4)
    p.rect(7, 7, 130, 130, (235, 213, 172, 255))
    p.rect(11, 11, 122, 3, WOOD_L)
    text(p, 43, 18, "SERVICIOS", INK, 2)
    p.line(12, 34, 132, 34, WOOD)
    rows = [(48, "CUENTAS"), (70, "INVERSIONES"), (92, "FONDOS"), (114, "AHORRO")]
    for y, label in rows:
        p.box(13, y, 13, 13, (200, 221, 164, 255), WOOD_D, 2)
        p.line(16, y + 7, 19, y + 10, GREEN)
        p.line(19, y + 10, 24, y + 3, GREEN)
        text(p, 33, y + 3, label, INK2, 2)


def draw_market_board(p):
    p.box(0, 0, 148, 180, (68, 41, 50, 255), INK, 4)
    p.rect(7, 7, 134, 166, (35, 36, 53, 255))
    text(p, 42, 16, "MERCADOS", GOLD_L, 2)
    p.line(14, 34, 134, 34, GOLD)
    text(p, 16, 45, "EUR  IBEX", CREAM, 2)
    text(p, 16, 67, "BONOS", CREAM, 2)
    text(p, 16, 89, "ORO", CREAM, 2)
    p.box(13, 112, 122, 49, (49, 45, 68, 255), (94, 76, 98, 255), 2)
    points = [(18, 151), (31, 142), (42, 147), (56, 130), (69, 136), (83, 122), (96, 131), (111, 118), (129, 123)]
    for a, b in zip(points, points[1:]):
        p.line(a[0], a[1], b[0], b[1], GOLD, 2)


def draw_lamp(p):
    p.rect(14, 3, 4, 12, WOOD_D)
    p.rect(9, 8, 14, 4, GOLD)
    p.poly([(6, 14), (26, 14), (22, 36), (10, 36)], GOLD_L)
    p.rect(10, 36, 12, 4, GOLD)
    p.rect(13, 40, 6, 6, WOOD_D)


def draw_queue(p):
    p.rect(9, 22, 4, 9, WOOD_D)
    p.rect(83, 22, 4, 9, WOOD_D)
    p.rect(4, 27, 14, 4, GOLD)
    p.rect(78, 27, 14, 4, GOLD)
    p.line(12, 19, 28, 23, (143, 40, 50, 255), 4)
    p.line(28, 23, 48, 24, (143, 40, 50, 255), 4)
    p.line(48, 24, 68, 23, (143, 40, 50, 255), 4)
    p.line(68, 23, 85, 19, (143, 40, 50, 255), 4)
    p.rect(7, 17, 8, 4, GOLD_L)
    p.rect(81, 17, 8, 4, GOLD_L)


def draw_bench(p):
    p.box(10, 5, 124, 34, (105, 51, 58, 255), INK, 4)
    for x in (48, 88):
        p.line(x, 8, x, 36, WOOD_D, 2)
    p.rect(15, 10, 114, 4, (150, 76, 76, 255))
    p.rect(15, 34, 114, 8, WOOD_L)
    p.rect(13, 42, 7, 17, WOOD_D)
    p.rect(124, 42, 7, 17, WOOD_D)
    p.rect(8, 58, 18, 4, GOLD)
    p.rect(118, 58, 18, 4, GOLD)


def draw_table(p):
    p.rect(19, 43, 7, 17, WOOD_D)
    p.rect(94, 43, 7, 17, WOOD_D)
    p.box(4, 26, 112, 25, WOOD, INK, 3)
    p.rect(9, 30, 102, 4, WOOD_L)
    p.box(17, 9, 44, 14, CREAM, WOOD_D, 2)
    p.line(20, 13, 56, 13, WOOD_L)
    p.line(20, 17, 52, 17, WOOD_L)
    p.box(69, 11, 35, 12, (54, 73, 104, 255), INK, 2)
    p.line(73, 19, 99, 14, GREEN_L, 2)
    p.line(73, 20, 99, 20, GOLD)


def draw_rack(p):
    p.box(4, 4, 36, 72, WOOD, INK, 3)
    p.rect(8, 9, 28, 59, (114, 74, 55, 255))
    p.box(10, 12, 24, 15, CREAM, WOOD_D, 1)
    p.box(10, 31, 24, 15, (208, 174, 131, 255), WOOD_D, 1)
    p.box(10, 50, 24, 15, (226, 198, 147, 255), WOOD_D, 1)
    for y in (16, 35, 54):
        p.line(13, y, 30, y, WOOD_L)


def draw_atm(p):
    p.box(5, 3, 62, 106, (102, 95, 105, 255), INK, 4)
    p.rect(11, 8, 50, 6, WOOD_L)
    p.box(13, 20, 46, 35, (38, 48, 70, 255), (160, 127, 76, 255), 3)
    p.rect(18, 25, 36, 23, (82, 111, 158, 255))
    for x, y, w, h in [(22, 40, 4, 5), (29, 35, 4, 10), (36, 31, 4, 14), (43, 27, 4, 18)]:
        p.rect(x, y, w, h, GOLD_L)
    p.box(17, 62, 38, 13, (181, 162, 139, 255), INK2, 2)
    for y in (65, 70):
        for x in (22, 31, 40):
            p.rect(x, y, 4, 2, INK2)
    p.rect(21, 82, 30, 4, GOLD)
    p.rect(11, 94, 50, 10, (76, 70, 79, 255))


def draw_counter(p):
    p.rect(18, 71, 14, 8, WOOD_D)
    p.rect(224, 71, 14, 8, WOOD_D)
    p.box(4, 13, 248, 62, WOOD, INK, 4)
    p.rect(10, 18, 236, 8, WOOD_L)
    p.rect(10, 28, 236, 40, (113, 59, 48, 255))
    p.box(57, 35, 142, 26, (91, 51, 56, 255), GOLD, 2)
    p.poly([(73, 48), (86, 40), (99, 48)], GOLD_L)
    p.rect(76, 48, 20, 2, GOLD_L)
    for x in (78, 85, 92):
        p.rect(x, 50, 3, 7, GOLD_L)
    p.rect(75, 57, 23, 2, GOLD_L)
    text(p, 108, 44, "BANCO", CREAM, 3)
    p.rect(11, 66, 234, 5, WOOD_D)


def draw_clerk(p):
    p.ellipse(11, 3, 27, 27, INK)
    p.ellipse(14, 7, 21, 21, (235, 184, 145, 255))
    p.poly([(12, 13), (13, 5), (19, 2), (29, 7), (31, 14), (26, 11), (21, 12), (17, 10)], (67, 43, 43, 255))
    p.rect(17, 16, 3, 2, INK)
    p.rect(25, 16, 3, 2, INK)
    p.box(6, 28, 36, 33, (228, 220, 204, 255), INK, 3)
    p.poly([(6, 31), (16, 28), (24, 33), (31, 28), (42, 31), (44, 58), (4, 58)], (221, 220, 203, 255))
    p.poly([(16, 29), (24, 34), (19, 48), (13, 34)], (87, 49, 58, 255))
    p.poly([(31, 29), (24, 34), (29, 48), (35, 34)], (87, 49, 58, 255))
    p.poly([(22, 36), (26, 36), (28, 48), (24, 54), (20, 48)], (174, 52, 62, 255))
    p.rect(9, 56, 12, 6, WOOD_D)
    p.rect(28, 56, 12, 6, WOOD_D)


def build_room_atlas():
    c = Canvas(512, 416)
    parts = {
        "city": Part(c, 0, 0), "map": Part(c, 96, 0), "coat": Part(c, 192, 0),
        "rug": Part(c, 0, 112), "desk": Part(c, 240, 104), "stool": Part(c, 408, 104),
        "shelf": Part(c, 240, 200), "bedside": Part(c, 0, 240), "plant": Part(c, 80, 240),
        "bed": Part(c, 368, 200), "mailbox": Part(c, 0, 336),
    }
    draw_picture_city(parts["city"])
    draw_picture_map(parts["map"])
    draw_coat(parts["coat"])
    draw_rug(parts["rug"])
    draw_desk(parts["desk"])
    draw_stool(parts["stool"])
    draw_bookcase(parts["shelf"])
    draw_bedside(parts["bedside"])
    draw_plant(parts["plant"])
    draw_bed(parts["bed"])
    draw_mailbox(parts["mailbox"])
    c.save(OUT / "habitacion_atlas.png")


def build_bank_atlas():
    c = Canvas(512, 416)
    parts = {
        "sign": Part(c, 0, 0), "services": Part(c, 200, 0), "market": Part(c, 352, 0),
        "lamp": Part(c, 0, 80), "queue": Part(c, 0, 200), "bench": Part(c, 100, 200),
        "table": Part(c, 250, 200), "rack": Part(c, 376, 200), "atm": Part(c, 0, 240),
        "counter": Part(c, 128, 280), "clerk": Part(c, 424, 240), "plant": Part(c, 400, 320),
    }
    draw_bank_sign(parts["sign"])
    draw_service_board(parts["services"])
    draw_market_board(parts["market"])
    draw_lamp(parts["lamp"])
    draw_queue(parts["queue"])
    draw_bench(parts["bench"])
    draw_table(parts["table"])
    draw_rack(parts["rack"])
    draw_atm(parts["atm"])
    draw_counter(parts["counter"])
    draw_clerk(parts["clerk"])
    draw_plant(parts["plant"])
    c.save(OUT / "banco_atlas.png")


def build_wall_tiles():
    c = Canvas(64, 64)
    bases = [
        (132, 91, 106, 255), (148, 102, 116, 255), (122, 82, 99, 255), (158, 109, 120, 255),
    ]
    for ty in range(4):
        for tx in range(4):
            x, y = tx * 16, ty * 16
            base = bases[(tx + ty) % len(bases)]
            c.rect(x, y, 16, 16, base)
            if ty == 0:
                c.rect(x, y, 16, 2, (207, 147, 151, 255))
                c.rect(x + (tx % 2) * 5 + 3, y + 6, 5, 1, (169, 119, 130, 255))
                c.rect(x + 2, y + 12, 3, 1, (171, 117, 130, 255))
            elif ty == 1:
                c.rect(x + 2, y + 2, 12, 11, (154, 105, 118, 255))
                c.rect(x + 3, y + 3, 10, 9, (171, 120, 130, 255))
                c.rect(x + 7, y + 3, 1, 9, (126, 84, 102, 255))
            elif ty == 2:
                c.rect(x, y + 1, 16, 4, WOOD_D)
                c.rect(x, y + 1, 16, 1, GOLD)
                c.rect(x + 2, y + 6, 12, 2, WOOD_L)
                c.rect(x, y + 10, 16, 6, (105, 63, 72, 255))
            else:
                c.rect(x, y, 3, 16, WOOD_D)
                c.rect(x + 3, y, 10, 16, base)
                c.rect(x + 13, y, 3, 16, WOOD_L)
                c.rect(x + 4, y + 5, 8, 1, WALL_L)
    c.save(OUT / "pared_banco_atlas.png")


if __name__ == "__main__":
    build_room_atlas()
    build_bank_atlas()
    build_wall_tiles()
    print("Atlas creados en", OUT)
