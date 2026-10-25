# Checks every entry the native gdunzip produced against python's zipfile
# (independent inflate, CRC checked). usage: pycheck.py <hashes.jsonl>...
import collections, hashlib, json, sys, zipfile

by_zip = collections.defaultdict(dict)
for path in sys.argv[1:]:
    for line in open(path, encoding="utf-8"):
        r = json.loads(line, strict=False)  # Godot's JSON.print leaves control characters unescaped
        by_zip[r["zip"]][r["name"]] = r["got"]

stats = collections.Counter()
for zp, got in by_zip.items():
    try:
        z = zipfile.ZipFile(zp)
    except Exception as e:
        stats["zip unreadable by python: " + type(e).__name__] += 1
        continue
    expected = {}
    for info in z.infolist():
        raw = info.orig_filename.encode("utf-8" if info.flag_bits & 0x800 else "cp437")
        name = raw.decode("utf-8", "replace")
        if name.startswith("﻿"):
            name = name[1:]
        name = name.split("\0")[0]
        expected[name] = info  # last one wins, like the Godot dictionary
    for name, desc in got.items():
        info = expected.get(name)
        if info is None:
            stats["name not in python's list"] += 1
            print("MISSING", zp, repr(name))
            continue
        try:
            data = z.read(info)
        except NotImplementedError:
            stats["python can't decompress method %d" % info.compress_type] += 1
            continue
        except Exception as e:
            stats["python error: " + type(e).__name__] += 1
            continue
        want = "PoolByteArray(size=%d sha256=%s)" % (len(data), hashlib.sha256(data).hexdigest())
        if desc == want:
            stats["match"] += 1
        else:
            stats["DIFFERENT"] += 1
            print("DIFF", zp, repr(name), desc, want)

for k, v in sorted(stats.items()):
    print(f"{v:9d}  {k}")
