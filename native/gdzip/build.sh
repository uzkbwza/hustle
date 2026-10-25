#!/bin/bash
# Builds gdzip for every platform the game ships on and copies the results
# into ../../lib/gdzip/ (the paths lib/gdzip.tres points at).
#
#   ./build.sh            all targets
#   ./build.sh linux      just one: linux, windows, android
#
# Needs (from a Linux machine):
#   - rustup, with these targets added:
#       rustup target add x86_64-unknown-linux-gnu x86_64-pc-windows-gnu \
#         aarch64-linux-android armv7-linux-androideabi i686-linux-android x86_64-linux-android
#   - libclang (any LLVM 9-22; gdnative reads Godot's headers with it at build time)
#   - windows: zig + cargo-zigbuild (zig is used as the linker, no mingw/MSVC needed)
#   - android: the Android NDK, at $ANDROID_NDK_HOME (r27c tested)
#
# If those live in ~/.local/share/tbfg-toolchains (how they were first set up),
# this script finds them on its own.
set -euo pipefail
cd "$(dirname "$0")"

TC="${TBFG_TOOLCHAINS:-$HOME/.local/share/tbfg-toolchains}"
if [ -d "$TC/rustup" ]; then
	export RUSTUP_HOME="$TC/rustup"
	export PATH="$TC/cargo/bin:$TC/tools/bin:$PATH"
fi
for z in "$TC"/zig-*; do [ -d "$z" ] && export PATH="$z:$PATH"; done
if [ -z "${ANDROID_NDK_HOME:-}" ] && [ -d "$TC/android-ndk-r27c" ]; then
	export ANDROID_NDK_HOME="$TC/android-ndk-r27c"
fi

# --remove-destination: never overwrite a library in place while a running game has it loaded
OUT=../../lib/gdzip
mkdir -p "$OUT"
WHAT="${1:-all}"

if [ "$WHAT" = all ] || [ "$WHAT" = linux ]; then
	cargo build --release --target x86_64-unknown-linux-gnu
	cp --remove-destination target/x86_64-unknown-linux-gnu/release/libgdzip.so "$OUT/libgdzip.so"
fi

if [ "$WHAT" = all ] || [ "$WHAT" = windows ]; then
	cargo zigbuild --release --target x86_64-pc-windows-gnu
	cp --remove-destination target/x86_64-pc-windows-gnu/release/gdzip.dll "$OUT/gdzip.dll"
fi

if [ "$WHAT" = all ] || [ "$WHAT" = android ]; then
	: "${ANDROID_NDK_HOME:?set ANDROID_NDK_HOME to the Android NDK}"
	BIN="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin"
	# gdnative-sys looks for the NDK as $ANDROID_SDK_ROOT/ndk-bundle
	SDK="$(pwd)/target/android-sdk"
	mkdir -p "$SDK"
	ln -sfn "$ANDROID_NDK_HOME" "$SDK/ndk-bundle"
	export ANDROID_SDK_ROOT="$SDK"
	export CARGO_TARGET_AARCH64_LINUX_ANDROID_LINKER="$BIN/aarch64-linux-android21-clang"
	export CARGO_TARGET_ARMV7_LINUX_ANDROIDEABI_LINKER="$BIN/armv7a-linux-androideabi21-clang"
	export CARGO_TARGET_I686_LINUX_ANDROID_LINKER="$BIN/i686-linux-android21-clang"
	export CARGO_TARGET_X86_64_LINUX_ANDROID_LINKER="$BIN/x86_64-linux-android21-clang"
	for pair in aarch64-linux-android:arm64 armv7-linux-androideabi:armv7 i686-linux-android:x86 x86_64-linux-android:x86_64_android; do
		target="${pair%%:*}"
		name="${pair##*:}"
		cargo build --release --target "$target"
		cp --remove-destination "target/$target/release/libgdzip.so" "$OUT/libgdzip_$name.so"
	done
fi

ls -la "$OUT"
