Minesweeper for GFOS
====================

Stephen Brennan's Minesweeper: a 16 x 30 field hides 99 mines. Dig a
cell to see how many mines touch it; flag the cells you know are mines.
The first dig is never a mine. Dig a mine and the game is over; open
every safe cell and you win.

The cursor keys (or H, J, K and L) move the cursor. D digs, F flags,
U takes a flag away, R digs every neighbour of a number whose mines are
all flagged, Z undoes a move, A lets the game's own solver make a move
(and say why, beside the board). Q ends the game, as does the window's
close gadget. Minesweeper cli, from a Shell, plays the line-by-line
version (d ROW,COL, f ROW,COL and so on).

What it needs
-------------
GFOS (AmigaOS 3.2 with GFOpenUp) on a 68040 or 68060; the FPU is not
needed. The game runs in an 80 x 24 console window on any screen with
eight colours or more: no SDL, no ACGame, no GFOpenGPU.

How it was ported
-----------------
The game is built from upstream as it is, with one patch
(amiga/patches/0001): with no arguments (a Workbench start) it is the
curses game; the cursor keys move as H J K L do; the messages beside the
board take the window's width that is left (upstream's 60 columns would
not fit 80); a win now ends the game (upstream's curses game never
noticed one) and the end stays in the window until a key; the flags and
the mines get a red pair of their own (upstream put them in pair 0, which
curses never colours); the GTK game is not built; and the neighbour loop
no longer reads one entry past its tables.

amiga/curses.c is the part of ncurses the game uses: the layer of
DalsinAI/amiga2048 and amiganinvaders (windows in memory, a refresh that
sends the console only what changed, as ANSI that console.device reads,
colour pairs on the screen's first eight pens). amiga/console_amiga.c
opens the window, puts it in raw mode and reads the keys (amiga/keys.c:
the cursor keys as curses' KEY_*).

Tests: tests/host/test_minesweeper.sh builds the game on the build
machine over a plain terminal, plays it with keys sent over time and
reads back the screen: the board at start, the cursor keys and H J K L,
the first dig, flags and their colour, the solver's message, a mine
ending the game until a key, Q, the usage, and (with AddressSanitizer)
a whole game with no bad reads.

Credits
-------
Minesweeper (in C) (c) 2015 Stephen Brennan, BSD-3-Clause (LICENSE.txt).
Amiga port: Designed, tested and delivered by The AmiCradle Team.
Copyright (c) 2026 AmiCradle Team; the port's own files MIT.
