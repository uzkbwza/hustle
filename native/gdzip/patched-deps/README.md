# what is this folder

`gdnative-sys` is the lowest-level piece of the gdnative crate — it reads
godot's C headers at build time and generates rust code from them.

The version on crates.io (0.11.3, from 2022) uses an old header-reading tool
(bindgen 0.63) that breaks with clang/LLVM 16 or newer. The symptom is a wall
of ~750 errors like `no field 'type_' on type 'godot_gdnative_api_struct'`.
Since gdnative is no longer maintained, no fixed version will ever be
published, so we keep a fixed copy here. The `[patch.crates-io]` section in
the main `Cargo.toml` tells cargo to use this copy instead.

## what changed vs the official 0.11.3

1. `Cargo.toml`: bindgen (the header-reading tool) bumped 0.63 -> 0.72.1,
   which understands both old and new clang. This fixes the ~750 errors.
2. `build.rs`: now always tells clang exactly which platform it's building
   for. The original never did (except for iPhones), so clang guessed based
   on whichever LLVM the machine had installed — one wrong guess and you get
   errors like `expected *const u16, found *const u32`.
3. `build.rs` + `stub-headers/wchar.h`: godot's `string.h` includes
   `<wchar.h>`, the only header that came from the machine's own C library.
   We serve a one-line decoy instead. The generated code now never depends
   on what compiler/LLVM the machine has installed.
4. `src/lib.rs`: `wchar_t` (one character of godot text; 16-bit on windows,
   32-bit on linux/mac) is now defined from rust's libc, which always knows
   the real answer for the platform being built, instead of being guessed
   by clang.

The `godot_headers/` folder (the actual description of godot 3.x's API) is
byte-for-byte identical to the official release. The game still targets
godot 3.5.1, nothing about that changed.

## do I need to install anything?

You need LLVM installed (you already had it if you ever built this project —
bindgen uses its libclang to read the headers). Any version from roughly 9
through 22 works now. Before this patch, only versions below 16 worked, and
some LLVM installs (embedded/ARM toolchains) broke the build in weirder ways.

After pulling this for the first time, run `cargo clean` once before
building, so no stale generated files stick around.
