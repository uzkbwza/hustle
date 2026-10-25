/* Decoy header. godot_headers/gdnative/string.h includes <wchar.h> only to
 * get the wchar_t type. The real wchar.h comes from the operating system's C
 * library, and which one clang finds depends on what LLVM the machine has
 * installed — that made builds break differently per machine. clang's own
 * built-in stddef.h defines wchar_t correctly for whatever platform we tell
 * it to target, so that is all this file pulls in. build.rs points clang at
 * this folder so this file is found instead of the system's.
 */
#include <stddef.h>
