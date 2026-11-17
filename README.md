# Minesweeper for GFOS

The AmiCradle Team's port of Stephen Brennan's Minesweeper (in C), the
mine-finding game, to GFOS: AmigaOS 3.2 with GFOpenUp, 68040/68060. It
runs in its own 80 x 24 console window, in colour: no SDL, no ACGame and
no GFOpenGPU. It ships as a release archive with an Installer and as the
GFOpenUp part Parts/Minesweeper.

Upstream is fetched at build time (package/minesweeper.lock) and patched
(amiga/patches); this repository holds only the Amiga port. See
[AMIGA_PORT.md](AMIGA_PORT.md).

Minesweeper (in C) is BSD-3-Clause (LICENSE.txt in the drawer); the
port's own files (amiga/, tests/, package/, tools/) are MIT. Copyright (c)
2026 AmiCradle Team.
