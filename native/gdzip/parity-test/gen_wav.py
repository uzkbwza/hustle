# Synthetic WAVs (+ .import with options) to compare the Rust WAV importer port
# against Godot 3.5.1's own importer.
import math, os, random, struct, sys

out = sys.argv[1]
os.makedirs(out, exist_ok=True)
rng = random.Random(42)

DEFAULTS = {
    "force/8_bit": "false", "force/mono": "false", "force/max_rate": "false",
    "force/max_rate_hz": "44100", "edit/trim": "false", "edit/normalize": "false",
    "edit/loop_mode": "0", "edit/loop_begin": "0", "edit/loop_end": "-1", "compress/mode": "0",
}

def signal(n, ch, kind):
    s = []
    for i in range(n):
        for c in range(ch):
            if kind == "quiet_edges" and (i < n // 5 or i > n * 4 // 5):
                v = 0.0
            else:
                v = 0.8 * math.sin(i * 0.05 * (c + 1)) + 0.15 * rng.uniform(-1, 1)
            if kind == "loud":
                v *= 1.6  # clips
            s.append(v)
    return s

def encode(samples, bits, code):
    b = bytearray()
    for v in samples:
        if code == 3:
            b += struct.pack("<f" if bits == 32 else "<d", v)
        else:
            x = max(-1.0, min(1.0, v))
            if bits == 8:
                b += struct.pack("<B", int(x * 127) + 128)
            elif bits == 16:
                b += struct.pack("<h", int(x * 32767))
            elif bits == 24:
                b += struct.pack("<i", int(x * 8388607))[:3]
            else:
                b += struct.pack("<i", int(x * 2147483647))
    return bytes(b)

def wav(ch, rate, bits, code, data, extra_before=b"", extra_after=b"", smpl=None, data_first=False, truncate=0, fmt_code=None):
    fmt = struct.pack("<HHIIHH", fmt_code or code, ch, rate, rate * ch * bits // 8, ch * bits // 8, bits)
    chunks = [b"fmt " + struct.pack("<I", len(fmt)) + fmt]
    if smpl:
        kind, a, z = smpl
        body = struct.pack("<9I", 0, 0, 0, 60, 0, 0, 0, 1, 0) + struct.pack("<I", 0) + struct.pack("<IIIII", kind, a, z, 0, 0)
        # the importer skips 10 u32s then reads type, begin, end
        body = struct.pack("<10I", 0, 0, 0, 60, 0, 0, 0, 1, 0, 0) + struct.pack("<III", kind, a, z) + struct.pack("<II", 0, 0)
        chunks.append(b"smpl" + struct.pack("<I", len(body)) + body)
    d = b"data" + struct.pack("<I", len(data)) + data
    body = extra_before + (d + b"".join(chunks) if data_first else b"".join(chunks) + d) + extra_after
    w = b"RIFF" + struct.pack("<I", len(body) + 4) + b"WAVE" + body
    return w[: len(w) - truncate] if truncate else w

cases = []
def add(name, w, **opts):
    cases.append((name, w, opts))

n = 3000
for bits, code in [(8, 1), (16, 1), (24, 1), (32, 1), (32, 3), (64, 3)]:
    for ch in (1, 2):
        for rate in (22050, 48000):
            s = signal(n, ch, "plain")
            add(f"f{code}_{bits}b_{ch}ch_{rate}", wav(ch, rate, bits, code, encode(s, bits, code)))

base = lambda ch=2, rate=48000, kind="plain", smpl=None: wav(ch, rate, 16, 1, encode(signal(n, ch, kind), 16, 1), smpl=smpl)
# options
add("opt_maxrate_96k", wav(2, 96000, 16, 1, encode(signal(n, 2, "plain"), 16, 1)), **{"force/max_rate": "true"})
add("opt_maxrate_22k", wav(1, 48000, 16, 1, encode(signal(n, 1, "plain"), 16, 1)), **{"force/max_rate": "true", "force/max_rate_hz": "22050"})
add("opt_maxrate_float_hz", wav(1, 48000, 24, 1, encode(signal(n, 1, "plain"), 24, 1)), **{"force/max_rate": "true", "force/max_rate_hz": "32000.7"})
add("opt_normalize", base(kind="plain"), **{"edit/normalize": "true"})
add("opt_trim_loop", base(kind="quiet_edges", smpl=(0, 100, 2000)), **{"edit/trim": "true"})
add("opt_trim_noloop", base(kind="quiet_edges"), **{"edit/trim": "true"})
add("opt_mono", base(), **{"force/mono": "true"})
add("opt_8bit", base(), **{"force/8_bit": "true"})
add("opt_ima_mono", base(ch=1), **{"compress/mode": "1"})
add("opt_ima_stereo", base(ch=2), **{"compress/mode": "1"})
add("opt_ima_odd", wav(1, 44100, 16, 1, encode(signal(n + 1, 1, "plain"), 16, 1)), **{"compress/mode": "1"})
add("opt_ima_loud", wav(1, 44100, 32, 3, encode(signal(n, 1, "loud"), 32, 3)), **{"compress/mode": "1"})
for lm in (1, 2, 3, 4):
    add(f"opt_loopmode{lm}", base(), **{"edit/loop_mode": str(lm), "edit/loop_begin": "10", "edit/loop_end": "-1"})
add("opt_loop_negative", base(), **{"edit/loop_mode": "2", "edit/loop_begin": "-100", "edit/loop_end": "-50"})
add("opt_everything", base(kind="quiet_edges", smpl=(1, 50, 2500)), **{"force/max_rate": "true", "force/max_rate_hz": "22050", "edit/normalize": "true", "edit/trim": "true", "force/mono": "true", "compress/mode": "1"})
add("opt_everything_8bit", base(kind="quiet_edges", smpl=(2, 50, 2500)), **{"force/max_rate": "true", "force/max_rate_hz": "16000", "edit/normalize": "true", "edit/trim": "true", "force/8_bit": "true"})
# smpl loops
for t in (0, 1, 2, 7):
    add(f"smpl_type{t}", base(smpl=(t, 123, 2345)))
add("smpl_ignored_when_loop_mode1", base(smpl=(0, 5, 6)), **{"edit/loop_mode": "1"})
# chunk layout quirks
add("odd_list_chunk", wav(2, 44100, 16, 1, encode(signal(n, 2, "plain"), 16, 1), extra_before=b"LIST" + struct.pack("<I", 5) + b"abcde\0"))
add("odd_chunk_unpadded", wav(2, 44100, 16, 1, encode(signal(n, 2, "plain"), 16, 1), extra_before=b"junk" + struct.pack("<I", 3) + b"xyz"))
add("trailing_chunk", wav(1, 44100, 16, 1, encode(signal(n, 1, "plain"), 16, 1), extra_after=b"id3 " + struct.pack("<I", 4) + b"tag!"))
add("data_before_fmt", wav(1, 44100, 16, 1, encode(signal(n, 1, "plain"), 16, 1), data_first=True))
add("truncated", wav(1, 44100, 16, 1, encode(signal(n, 1, "plain"), 16, 1), truncate=100))
add("extensible", wav(2, 44100, 16, 1, encode(signal(n, 2, "plain"), 16, 1), fmt_code=0xFFFE))
add("float_specials", wav(1, 44100, 32, 3, struct.pack("<8f", float("nan"), float("inf"), -float("inf"), 1.5, -1.5, 0.99999, -1.0, 1e-30)))
add("pcm8_extremes", wav(1, 8000, 8, 1, bytes([0, 1, 127, 128, 129, 254, 255])))
add("empty_data", wav(1, 44100, 16, 1, b""))

for name, w, opts in cases:
    open(os.path.join(out, name + ".wav"), "wb").write(w)
    p = dict(DEFAULTS)
    p.update(opts)
    with open(os.path.join(out, name + ".wav.import"), "w") as f:
        f.write('[remap]\n\nimporter="wav"\ntype="AudioStreamSample"\n\n[params]\n\n')
        for k, v in p.items():
            f.write(f"{k}={v}\n")
print(len(cases), "synthetic wavs")
