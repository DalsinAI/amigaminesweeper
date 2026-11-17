#!/usr/bin/env python3
"""Minesweeper's picture for its GlowIcons (art/minesweeper.png), drawn
here: upstream has none. A corner of the board on the console's black:
unknown cells, opened cells with their numbers' colours, a red flag and a
mine. 64 x 64, RGBA.
    python3 amiga/icons/draw_art.py amiga/icons/art
Pure Python. MIT, Copyright (c) 2026 AmiCradle Team."""
import struct, sys, zlib
from pathlib import Path

W = H = 64
INK = (16, 18, 22, 255)
BG = (8, 8, 12, 255)
CELL = (120, 124, 132, 255)
LIGHT = (180, 184, 190, 255)
OPEN = (40, 42, 48, 255)
RED = (220, 50, 40, 255)
BLUE = (70, 110, 230, 255)
GREEN = (70, 200, 80, 255)
YELLOW = (230, 210, 60, 255)
WHITE = (235, 235, 235, 255)
DIGITS = {  # 3 x 5
    "1": [".X.", "XX.", ".X.", ".X.", "XXX"],
    "2": ["XX.", "..X", ".X.", "X..", "XXX"],
    "3": ["XX.", "..X", ".X.", "..X", "XX."],
}
# the board: # unknown, digits opened, F flag, * mine, space open
BOARD = ["##F#",
         "#3#1",
         "*2 1",
         "11  "]


def png(px, path):
    raw = b"".join(b"\0" + bytes(v for p in row for v in p) for row in px)
    def chunk(t, d):
        return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff)
    Path(path).write_bytes(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", W, H, 8, 6, 0, 0, 0))
                           + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))


def draw():
    px = [[(0, 0, 0, 0)] * W for _ in range(H)]
    def rect(x0, y0, x1, y1, c):
        for y in range(max(0, y0), min(H, y1)):
            for x in range(max(0, x0), min(W, x1)):
                px[y][x] = c
    def sprite(rows, x0, y0, scale, c):
        for r, row in enumerate(rows):
            for k, ch in enumerate(row):
                if ch == "X":
                    rect(x0 + k * scale, y0 + r * scale, x0 + (k + 1) * scale, y0 + (r + 1) * scale, c)
    rect(2, 2, 62, 62, INK)
    rect(4, 4, 60, 60, BG)
    colour = {"1": BLUE, "2": GREEN, "3": YELLOW}
    for r, row in enumerate(BOARD):
        for c, ch in enumerate(row):
            x, y = 6 + c * 13, 6 + r * 13
            if ch in "#F":
                rect(x, y, x + 12, y + 12, CELL)
                rect(x, y, x + 12, y + 2, LIGHT)
                rect(x, y, x + 2, y + 12, LIGHT)
                if ch == "F":
                    rect(x + 5, y + 2, x + 7, y + 10, WHITE)      # the pole
                    rect(x + 7, y + 2, x + 11, y + 6, RED)        # the flag
                    rect(x + 3, y + 9, x + 10, y + 11, INK)       # its foot
            else:
                rect(x, y, x + 12, y + 12, OPEN)
                if ch in DIGITS:
                    sprite(DIGITS[ch], x + 3, y + 1, 2, colour[ch])
                elif ch == "*":
                    rect(x + 3, y + 3, x + 9, y + 9, RED)
                    rect(x + 5, y + 1, x + 7, y + 11, RED)
                    rect(x + 1, y + 5, x + 11, y + 7, RED)
                    rect(x + 4, y + 4, x + 6, y + 6, WHITE)
    return px


if __name__ == "__main__":
    out = Path(sys.argv[1] if len(sys.argv) > 1 else "art")
    out.mkdir(parents=True, exist_ok=True)
    png(draw(), out / "minesweeper.png")
