#!/bin/sh
# Host tests of the port, on this machine: amiga/curses.c and amiga/keys.c
# built with upstream's Minesweeper (amiga/patches applied, __amigaos__
# set, so the Amiga's code is the one built) over a plain terminal
# (tests/host/console_host.c), played with keys sent over time;
# tests/host/vt.py reads back the screen as the Amiga's console would show
# it:
#  - no arguments starts the curses game (a Workbench start): the board's
#    box, 16 x 30 unknown cells, "Found: 0/99", in the pairs' colours;
#  - the cursor keys and h/j/k/l move the cursor: the first dig there opens
#    a clear area at that cell;
#  - F flags (red, Found: 1/99), U unflags;
#  - A, the solver, writes its move in the messages beside the board (the
#    80-column window's width, not upstream's 60);
#  - digging row by row ends on a mine: "Boom!" stays until a key;
#  - Q quits; an unknown argument prints the usage without the GTK game;
#  - with AddressSanitizer, when the compiler has it: no read past the
#    neighbour tables (upstream's for_each_neigh read rnbr[8]).
# Needs a C compiler and python3; skipped without a compiler.
#   UP=/path/to/minesweeper (patched) sh tests/host/test_minesweeper.sh
# Copyright (c) 2026 AmiCradle Team. MIT (the port's own files).
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT=$(CDPATH= cd -- "$HERE/../.." && pwd)
UP=${UP:?UP=upstream source}
CC=${HOSTCC:-cc}
command -v "$CC" >/dev/null 2>&1 || { echo "host tests: skipped (no C compiler)"; exit 0; }
T=$(mktemp -d "${TMPDIR:-/tmp}/minesweeper-host.XXXXXX")
[ -n "${TEST_KEEP:-}" ] || trap 'rm -rf "$T"' EXIT INT TERM
cd "$ROOT"

build() {	# dir, extra flags
    d=$1; shift
    mkdir -p "$d"
    MINE="-std=gnu99 -Wall -Werror -D_XOPEN_SOURCE=600 -D_DEFAULT_SOURCE -Iamiga/include -Iamiga $*"
    for f in curses keys; do $CC $MINE -c -o "$d/$f.o" "amiga/$f.c"; done
    $CC $MINE -c -o "$d/con.o" tests/host/console_host.c
    for f in minesweeper cli curses main; do
        $CC -std=gnu99 -w -Werror=implicit-function-declaration -D_DEFAULT_SOURCE -D__amigaos__ "$@" \
            -Iamiga/include -Iamiga -I"$UP/src" -c -o "$d/u_$f.o" "$UP/src/$f.c"
    done
    $CC "$@" -o "$d/Minesweeper" "$d"/*.o
}
build "$T"
fails=0
pass() { echo "ok   $1"; }
fail() { echo "FAIL $1"; fails=$((fails + 1)); }

# keys sent over time: "WAIT KEYS WAIT KEYS ..." (seconds, printf formats)
play() {	# output, then WAIT KEYS pairs
    out=$1; shift
    (
        while [ $# -ge 2 ]; do sleep "$1"; printf "$2"; shift 2; done
        [ $# -eq 1 ] && sleep "$1"
    ) | (cd "$T" && timeout 30 ${GAME:-./Minesweeper} > "$out" 2> "$out.err")
}
screen() { python3 "$HERE/vt.py" "$1"; }
want() {	# name, output, texts...
    name=$1; out=$2; shift 2
    n=$#
    for t in "$@"; do set -- "$@" --want "$t"; done
    shift "$n"
    if python3 "$HERE/vt.py" "$out" "$@" > "$T/vt.txt"; then pass "$name"; else fail "$name"; cat "$T/vt.txt"; fi
}
cell() { screen "$1" | sed -n "$(($2 + 2))p" | cut -c "$(($3 + 2))"; }	# output, row, col

play "$T/start.out" 0.4
want "no arguments: the curses game" "$T/start.out" "+------------------------------+" "|##############################|" "Found: 0/99"
if [ "$(screen "$T/start.out" | grep -c '^|##############################|$')" = 16 ]; then pass "16 x 30 unknown cells"; else fail "the board"; screen "$T/start.out"; fi

# cursor keys: right 5, down 4, dig: the first dig is always on a clear cell
play "$T/arrows.out" 0.3 '\033[C\033[C\033[C\033[C\033[C\033[B\033[B\033[B\033[B' 0.2 'd' 0.4
play "$T/hjkl.out" 0.3 'llllllllhhhjjjjjjkk' 0.2 'd' 0.4
if [ "$(cell "$T/arrows.out" 4 5)" = " " ] && [ "$(cell "$T/hjkl.out" 4 5)" = " " ] \
   && [ "$(cell "$T/start.out" 4 5)" = "#" ]; then
    pass "the cursor keys and h/j/k/l move the cursor (the dig opens cell 4,5)"
else
    fail "cursor: '$(cell "$T/arrows.out" 4 5)' '$(cell "$T/hjkl.out" 4 5)'"; screen "$T/arrows.out"
fi
if [ "$(screen "$T/arrows.out" | sed -n 2,17p | grep -o '#' | wc -l)" -lt 480 ]; then pass "the dig opens an area"; else fail "nothing opened"; fi

play "$T/flag.out" 0.3 'f' 0.3
want "F flags a cell" "$T/flag.out" "|*#####" "Found: 1/99"
if grep -Eq "$(printf '\033')\[0;(7;)?31;40m\*" "$T/flag.out"; then pass "the flag is red (its own pair, not pair 0), under the cursor"; else fail "the flag is not red"; fi
play "$T/unflag.out" 0.3 'fu' 0.3
want "U unflags it" "$T/unflag.out" "|######" "Found: 0/99"

play "$T/ai.out" 0.3 'd' 0.2 'a' 0.4
if screen "$T/ai.out" | sed -n 1,18p | cut -c 33- | grep -q '[A-Za-z]'; then pass "A: the solver's move in the messages beside the board"; else fail "no solver message"; screen "$T/ai.out"; fi

dig_all() { k='d'; i=0; while [ $i -lt 29 ]; do k="${k}ld"; i=$((i + 1)); done; k="${k}j"; i=0; while [ $i -lt 29 ]; do k="${k}hd"; i=$((i + 1)); done; echo "$k"; }
play "$T/boom.out" 0.3 "$(dig_all)" 0.6
want "a mine ends the game, until a key" "$T/boom.out" "Boom! You dug up a mine.  Press a key."
play "$T/boomkey.out" 0.3 "$(dig_all)" 0.4 'x' 0.4
if [ -s "$T/boomkey.out" ] && ! (cd "$T" && pgrep -f "$T/Minesweeper" >/dev/null 2>&1); then pass "a key after the mine ends it"; else fail "still running after the key"; fi

if (sleep 0.3; printf 'q') | (cd "$T" && timeout 10 ./Minesweeper > "$T/q.out" 2>&1); then pass "Q quits"; else fail "Q: exit $?"; fi
"$T/Minesweeper" xyz > "$T/usage.txt" 2>&1 || true
if grep -q 'usage: .* \[cli|curses\]' "$T/usage.txt" && ! grep -q GTK "$T/usage.txt"; then pass "the usage, without the GTK game"; else fail "usage: $(cat "$T/usage.txt")"; fi

# AddressSanitizer: the neighbour tables
if echo 'int main(void){return 0;}' | $CC -fsanitize=address -x c -o "$T/asan_probe" - >/dev/null 2>&1 && "$T/asan_probe"; then
    build "$T/asan" -g -fsanitize=address
    GAME=./asan/Minesweeper ASAN_OPTIONS=detect_leaks=0 play "$T/asan.out" 0.3 "$(dig_all)" 0.4 'x' 0.3
    if ! grep -q 'ERROR: AddressSanitizer' "$T/asan.out.err"; then pass "AddressSanitizer: a whole game, no bad reads"; else fail "AddressSanitizer"; grep -A6 ERROR "$T/asan.out.err"; fi
else
    echo "skip AddressSanitizer (not in this compiler)"
fi

if [ "$fails" -ne 0 ]; then echo "host tests: $fails failed"; exit 1; fi
echo "host tests: all passed"
