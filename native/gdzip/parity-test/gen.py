import io, os, random, struct, subprocess, sys, zipfile, zlib, shutil

OUT = sys.argv[1]
N_FUZZ = int(sys.argv[2]) if len(sys.argv) > 2 else 3000
shutil.rmtree(OUT, ignore_errors=True)
os.makedirs(OUT)
rng = random.Random(1234)
made = []

def save(name, data):
    p = os.path.join(OUT, name + ".zip")
    with open(p, "wb") as f:
        f.write(data)
    made.append(p)
    return p

def text(n, seed=0):
    r = random.Random(seed)
    words = ["func", "var", "extends", "Node", "position", "velocity", "_ready", "\n", "\t", "return", "if", "else:"]
    return " ".join(r.choice(words) for _ in range(n)).encode()

def noise(n, seed=0):
    return random.Random(seed).randbytes(n)

FILES = [
    ("mod/_metadata", b'{"name": "test", "friendly_name": "Test", "requires": [""]}'),
    ("mod/ModMain.gd", text(3000, 1)),
    ("mod/chars/a.png", noise(5000, 2)),
    ("mod/chars/big.txt", text(60000, 3)),
    ("mod/empty.txt", b""),
    ("mod/one.txt", b"x"),
    ("mod/rep.bin", b"\0" * 200000),
    ("mod/ユニコード.txt", "テキスト".encode()),
    ("mod/emoji_😀.txt", b"emoji name"),
]

def pyzip(files, compression=zipfile.ZIP_DEFLATED, level=None, comment=b"", **kw):
    b = io.BytesIO()
    with zipfile.ZipFile(b, "w", compression, compresslevel=level, **kw) as z:
        for n, d in files:
            z.writestr(n, d)
        z.comment = comment
    return b.getvalue()

# python zipfile at every level, stored, with dirs
for lvl in range(0, 10):
    save(f"py_deflate_l{lvl}", pyzip(FILES, level=lvl))
save("py_stored", pyzip(FILES, zipfile.ZIP_STORED))
save("py_dirs", pyzip([("mod/", b""), ("mod/sub/", b"")] + FILES))
save("py_comment", pyzip(FILES, comment=b"hello comment"))
save("py_comment_max", pyzip(FILES, comment=b"c" * 65535))
# a fake end record inside the comment (gdunzip finds the last one)
save("py_comment_fake_eocd", pyzip(FILES, comment=b"xx" + b"PK\x05\x06" + b"\0" * 30))
save("py_dupes", pyzip([("a.txt", b"one"), ("b.txt", b"two"), ("a.txt", b"three")]))
save("py_bom_name", pyzip([("﻿bom.txt", b"bom"), ("ok.txt", b"ok")]))
save("py_many_files", pyzip([(f"mod/f{i:05}.txt", text(20, i)) for i in range(12000)]))
save("py_single_empty", pyzip([("e.txt", b"")]))
save("py_bzip2", pyzip(FILES[:3], zipfile.ZIP_BZIP2))
save("py_lzma", pyzip(FILES[:3], zipfile.ZIP_LZMA))
save("py_zip64", pyzip(FILES[:4], force_zip64=True) if False else b"")  # replaced below
b = io.BytesIO()
with zipfile.ZipFile(b, "w", zipfile.ZIP_DEFLATED) as z:
    for n, d in FILES[:4]:
        with z.open(n, "w", force_zip64=True) as f:
            f.write(d)
save("py_zip64", b.getvalue())

# streaming zip (data descriptors), written to an unseekable stream
class Unseekable(io.RawIOBase):
    def __init__(self): self.buf = bytearray()
    def writable(self): return True
    def write(self, b): self.buf += b; return len(b)
u = Unseekable()
with zipfile.ZipFile(u, "w", zipfile.ZIP_DEFLATED) as z:
    for n, d in FILES:
        with z.open(n, "w") as f:
            f.write(d)
save("py_streaming", bytes(u.buf))

# raw names that python can't make: NUL, invalid utf8, latin-1, overlong, 5-byte sequences
def raw_zip(entries, comment=b""):
    """entries: list of (name_bytes, data, method, extra, cd_comment)"""
    out = bytearray(); cd = bytearray()
    for name, data, method, extra, ccom in entries:
        body = data if method == 0 else zlib.compress(data, 6)[2:-4]
        crc = zlib.crc32(data)
        off = len(out)
        out += struct.pack("<IHHHHHIIIHH", 0x04034B50, 20, 0, method, 0, 0x21, crc, len(body), len(data), len(name), len(extra)) + name + extra + body
        cd += struct.pack("<IHHHHHHIIIHHHHHII", 0x02014B50, 20, 20, 0, method, 0, 0x21, crc, len(body), len(data), len(name), len(extra), len(ccom), 0, 0, 0, off) + name + extra + ccom
    cdoff = len(out)
    out += cd
    out += struct.pack("<IHHHHIIH", 0x06054B50, 0, 0, len(entries), len(entries), len(cd), cdoff, len(comment)) + comment
    return bytes(out)

E = lambda name, data=b"data", method=8, extra=b"", ccom=b"": (name, data, method, extra, ccom)
save("raw_names_valid_odd", raw_zip([
    E(b"nul\0inside.txt"), E(b"\xef\xbb\xbfbom.txt"), E(b"ok.txt"), E("😀 emoji.txt".encode()), E("ünïcödé/ファイル.txt".encode()),
]))
# invalid utf8: godot leaves uninitialized memory in these names, so the original's output isn't deterministic
for i, bad in enumerate([b"caf\xe9.txt", b"\xff\xfe invalid.txt", b"\xc0\xafoverlong.txt", b"\xf8\x88\x80\x80\x80five.txt", b"trunc\xe3\x81", b"\xed\xa0\x80surrogate.txt"]):
    save(f"nondet_invalid_name_{i}", raw_zip([E(b"before.txt"), E(bad), E(b"after.txt")]))
save("raw_extra_and_comments", raw_zip([E(b"a.txt", extra=b"\x55\x54\x05\x00\x01\0\0\0\0", ccom=b"file comment"), E(b"b.txt", ccom=b"c2")]))
save("raw_zero_name", raw_zip([E(b"a.txt"), E(b"", extra=b"EXTRA"), E(b"c.txt")]))
save("raw_zero_all", raw_zip([E(b"a.txt"), E(b""), E(b"c.txt")]))
save("raw_method_99", raw_zip([E(b"a.txt", text(500), 99), E(b"b.txt", text(500), 8)]))
save("raw_method_stored_big", raw_zip([E(b"a.bin", noise(300000, 5), 0)]))
save("raw_empty_deflate", raw_zip([E(b"e.txt", b"", 8)]))
save("raw_no_entries", raw_zip([]))

# other compressors (different deflate encoders)
src = os.path.join(OUT, "_src")
os.makedirs(src + "/mod/chars", exist_ok=True)
for n, d in FILES:
    p = os.path.join(src, n)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    open(p, "wb").write(d)
def run(name, cmd):
    p = os.path.join(OUT, name + ".zip")
    subprocess.run(cmd(p), cwd=src, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    made.append(p)
for lvl in (0, 1, 5, 9):
    run(f"7z_mx{lvl}", lambda p, l=lvl: ["7z", "a", "-tzip", f"-mx={l}", p, "mod"])
run("7z_deflate64", lambda p: ["7z", "a", "-tzip", "-mm=Deflate64", p, "mod"])
run("7z_bzip2", lambda p: ["7z", "a", "-tzip", "-mm=BZip2", p, "mod"])
for lvl in (0, 1, 9):
    run(f"infozip_{lvl}", lambda p, l=lvl: ["zip", "-r", f"-{l}", "-q", p, "mod"])
run("infozip_fd", lambda p: ["zip", "-r", "-fd", "-q", p, "mod"])
run("bsdtar", lambda p: ["bsdtar", "-a", "-cf", p, "mod"])
shutil.rmtree(src)

# truncations and prefixes of a normal zip
base = pyzip(FILES[:5])
for cut in (0, 3, 4, 10, 21, 22, 30, len(base) // 2, len(base) - 23, len(base) - 22, len(base) - 1):
    save(f"trunc_{cut}", base[:cut])
save("prefix_junk", b"junk" * 10 + base)
save("pk_prefix_junk", b"PK\x03\x04" + b"junk" * 10 + base)
save("tiny_pk", b"PK\x03\x04" + b"\0" * 10)
save("only_magic", b"PK\x03\x04")
save("big_padding_before_cd", raw_zip([E(b"a.txt")]).replace(b"PK\x01\x02", b"PK\x01\x02", 1))

# fuzz: random corruption of small zips
seeds = [pyzip(FILES[:2] + FILES[4:6]), pyzip(FILES[:3], zipfile.ZIP_STORED),
         raw_zip([E(b"a.txt", text(300)), E(b"b/c.txt", text(50)), E(b"d.bin", noise(40), 0)]),
         pyzip([("x.txt", text(200, 9))], level=1)]
for i in range(N_FUZZ):
    d = bytearray(rng.choice(seeds))
    kind = rng.random()
    if kind < 0.6:
        for _ in range(rng.randint(1, 4)):
            d[rng.randrange(len(d))] = rng.randrange(256)
    elif kind < 0.8:
        # target the central directory / end record
        cd = d.find(b"PK\x01\x02")
        for _ in range(rng.randint(1, 3)):
            j = rng.randrange(cd, len(d))
            d[j] = rng.choice([0, 1, 0xFF, rng.randrange(256)])
    elif kind < 0.9:
        d = d[: rng.randrange(len(d))]
    else:
        # corrupt inside the compressed data of the first entry only
        j = rng.randrange(30, max(31, d.find(b"PK\x03\x04", 4) if d.find(b"PK\x03\x04", 4) > 0 else 60))
        d[j] ^= 1 << rng.randrange(8)
    save(f"fuzz_{i:05}", bytes(d))

print(len(made), "zips in", OUT)
