#!/bin/bash
# Compares the new gdunzip (Rust) against the original GDScript gdunzip.
#
#   ./run.sh <godot 3.5.1 headless binary> synthetic       generated edge cases + 3000 fuzzed zips
#   ./run.sh <godot 3.5.1 headless binary> <list.txt>      zips listed one absolute path per line
#   ./run.sh <godot 3.5.1 headless binary> writer          gdzip.gd round trip through the original
#
# Results land in ./results/. Look for MISMATCH lines; TOTALS is the summary.
# OK = identical. NAMEFIX-OK = only invalid-utf8 names differ (the deliberate
# fix). NONDET-OK / NONDET-INFLATE-OK = the original gives different results
# depending on leftover memory, so there is nothing fixed to match.
#
# The python check only means something on valid zips: on corrupt or bzip2
# ones it disagrees with the original too (gdunzip trusts the sizes in the
# file list and has no bzip2), which is fine as long as MISMATCH stays 0.
#
# Godot runs from a temp copy with its own user:// dir, so the game's real
# user data (modded.json etc.) is never touched. Needs python3 (and 7z, zip,
# bsdtar for the synthetic set).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
PROJECT="$(cd "$HERE/../../.." && pwd)"
GODOT="$(realpath "$1")"
WHAT="$2"
OUT="$HERE/results"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$OUT" "$TMP/run/mods" "$TMP/xdg"
cp "$GODOT" "$TMP/run/godot"
python3 "$HERE/make_filled.py" "$PROJECT/modloader/gdunzip/gdunzip_gdscript.gd" "$TMP/gdunzip_filled.gd"

godot() { XDG_DATA_HOME="$TMP/xdg" "$TMP/run/godot" --path "$PROJECT" -s "$@"; }

if [ "$WHAT" = writer ]; then
	mkdir -p "$TMP/wz"
	godot "$HERE/writer_test.gd" out="$TMP/wz" 2>&1 | grep -a "write\|load\|DIFF\|FAILS"
	exit
fi

if [ "$WHAT" = synthetic ]; then
	python3 "$HERE/gen.py" "$TMP/corpus" 3000
	ls "$TMP"/corpus/*.zip > "$TMP/list.txt"
	LIST="$TMP/list.txt"
	NAME=synthetic
else
	LIST="$(realpath "$WHAT")"
	NAME="$(basename "$WHAT" .txt)"
fi

# the original's inflate is slow (~50KB/s on real data): only compare it on
# entries up to 256KB, 2MB per zip. Every entry is still checked against
# python's zipfile below.
godot "$HERE/compare.gd" "$LIST" "$OUT/$NAME.log" 2097152 262144 filled="$TMP/gdunzip_filled.gd" > "$OUT/$NAME.godot.log" 2>&1 || true
python3 "$HERE/pycheck.py" "$OUT/$NAME.log.hashes.jsonl" > "$OUT/$NAME.pycheck.txt" 2>&1 || true

echo "vs original:  $(grep -a '^TOTALS' "$OUT/$NAME.log")"
echo "mismatches:   $(grep -a -c '^MISMATCH' "$OUT/$NAME.log" || true)"
echo "vs python:"
grep -a -E "^ +[0-9]+  " "$OUT/$NAME.pycheck.txt" || true
