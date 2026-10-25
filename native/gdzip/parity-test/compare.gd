extends SceneTree
# Runs the original gdunzip (gdunzip_gdscript.gd) and the new one (gdunzip.gd)
# on every zip listed in a text file and compares everything observable.
# args: <list file> <out file> [byte budget per zip] [max entry size for the
# slow original inflate] filled=<path to gdunzip_filled.gd>
# Run it through run.sh, which sets all of that up.

var out
var filled_script = ""

func _init():
	var args = OS.get_cmdline_args()
	var list_path = ""
	var out_path = ""
	var budget = 4 * 1024 * 1024
	var max_entry = 1 << 62
	var rest = []
	for a in args:
		if a.begins_with("filled="):
			filled_script = a.substr(7)
			continue
		if a.ends_with(".txt") or a.ends_with(".log") or a.is_valid_integer():
			rest.append(a)
	list_path = rest[0]
	out_path = rest[1]
	if rest.size() > 2:
		budget = int(rest[2])
	if rest.size() > 3:
		max_entry = int(rest[3])
	var hashes = File.new()
	hashes.open(out_path + ".hashes.jsonl", File.WRITE)

	var lf = File.new()
	lf.open(list_path, File.READ)
	var paths = lf.get_as_text().split("\n", false)
	lf.close()

	out = File.new()
	out.open(out_path, File.WRITE)

	var Ref = ResourceLoader.load("res://modloader/gdunzip/gdunzip_gdscript.gd")
	var Nat = ResourceLoader.load("res://modloader/gdunzip/gdunzip.gd")
	if Nat.new()._native == null:
		_line("FATAL native library did not load")
		quit()
		return

	var totals = {"zips": 0, "mismatch": 0, "entries": 0, "compared": 0, "load_fallback": 0,
		"inflate_native": 0, "inflate_fallback": 0, "t_ref_load": 0, "t_nat_load": 0,
		"t_ref_unz": 0, "t_nat_unz": 0, "nondet": 0, "namefix": 0, "nondet_inflate": 0, "skipped_big": 0, "hashed": 0}
	for p in paths:
		totals.zips += 1
		var problems = []

		var ref = Ref.new()
		var nat = Nat.new()
		var t0 = OS.get_ticks_usec()
		var r1 = ref.load(p)
		var t1 = OS.get_ticks_usec()
		var r2 = nat.load(p)
		var t2 = OS.get_ticks_usec()
		totals.t_ref_load += t1 - t0
		totals.t_nat_load += t2 - t1
		var fell_back = nat.buffer != null
		if fell_back:
			totals.load_fallback += 1

		_cmp(problems, "load()", r1, r2)
		var nondet = false
		var namefix = false
		var nondet_inflate = false
		if _desc(ref.files) != _desc(nat.files):
			# is the original even consistent with itself on this zip?
			for i in 3:
				var again = Ref.new()
				again.load(p)
				if _desc(again.files) != _desc(ref.files):
					nondet = true
			if nondet:
				totals.nondet += 1
				for i in 3:
					var again = Nat.new()
					again.load(p)
					_cmp(problems, "native consistent with itself", _desc(nat.files), _desc(again.files))
				_cmp(problems, "non-name fields", _fields(ref.files), _fields(nat.files))
			elif _only_fixed_names_differ(ref.files, nat.files):
				namefix = true
				totals.namefix += 1
			else:
				_cmp(problems, "files", ref.files, nat.files)
		_cmp(problems, "pos", ref.pos, nat.pos)
		_cmp(problems, "path", ref.path, nat.path)
		_cmp(problems, "buffer_size", ref.buffer_size, nat.buffer_size)
		totals.entries += ref.files.size()

		# every entry: get_compressed + uncompress, until the byte budget runs out
		var spent = 0
		var names = ref.files.keys()
		var nat_names = nat.files.keys()
		names.append("__does_not_exist__")
		nat_names.append("__does_not_exist__")
		if ref.files.size() != nat.files.size():
			names = []
			for k in ref.files:
				if nat.files.has(k):
					names.append(k)
			nat_names = names
		for ni in min(names.size(), nat_names.size()):
			var name = names[ni]
			var nname = nat_names[ni]
			if spent > budget:
				break
			if name in ref.files and (ref.files[name].uncompressed_size > max_entry or ref.files[name].compressed_size > max_entry):
				totals.skipped_big += 1
				continue
			var c1 = ref.get_compressed(name)
			var c2 = nat.get_compressed(nname)
			_cmp(problems, "get_compressed(%s)" % name, c1, c2)
			var u0 = OS.get_ticks_usec()
			var u1 = ref.uncompress(name)
			var u_mid = OS.get_ticks_usec()
			var u2 = nat.uncompress(nname)
			var u_end = OS.get_ticks_usec()
			totals.t_ref_unz += u_mid - u0
			totals.t_nat_unz += u_end - u_mid
			if _desc(u1) != _desc(u2) and _memory_dependent(p, name):
				# the original reads uninitialized memory on this input
				totals.nondet_inflate += 1
				nondet_inflate = true
			else:
				_cmp(problems, "uncompress(%s)" % name, u1, u2)
			_cmp(problems, "pos after uncompress(%s)" % name, ref.pos, nat.pos)
			if typeof(u1) == TYPE_RAW_ARRAY:
				spent += u1.size()
			if name in ref.files:
				totals.compared += 1
				var h = ref.files[name]
				if h.compression_method != -1 and typeof(c2) == TYPE_RAW_ARRAY and nat._native != null:
					if nat._native.inflate(c2, h.uncompressed_size) == null:
						totals.inflate_fallback += 1
					else:
						totals.inflate_native += 1

		if r2 == true:
			var check = Nat.new()
			check.load(p)
			for k in check.files:
				totals.hashed += 1
				hashes.store_line(JSON.print({"zip": p, "name": k, "got": _desc(check.uncompress(k))}))
		if problems.size() > 0:
			totals.mismatch += 1
			_line("MISMATCH %s" % p)
			for pr in problems:
				_line("    " + pr)
		else:
			_line("%s %s entries=%d fallback=%s" % ["NONDET-OK" if nondet else ("NAMEFIX-OK" if namefix else ("NONDET-INFLATE-OK" if nondet_inflate else "OK")), p, ref.files.size(), fell_back])
	if totals.entries == 0:
		_line("FATAL no entries were read at all, check the paths")
	_line("TOTALS " + JSON.print(totals))
	out.close()
	hashes.close()
	quit()

func _line(s):
	out.store_line(s)
	out.flush()

func _desc(v):
	if typeof(v) == TYPE_RAW_ARRAY:
		var ctx = HashingContext.new()
		ctx.start(HashingContext.HASH_SHA256)
		if v.size() > 0:
			ctx.update(v)
		return "PoolByteArray(size=%d sha256=%s)" % [v.size(), ctx.finish().hex_encode()]
	if typeof(v) == TYPE_DICTIONARY:
		# var2str keeps key order and value types
		return var2str(v).sha256_text() + " (%d keys)" % v.size()
	return "%s:%s" % [typeof(v), var2str(v)]

func _cmp(problems, what, a, b):
	if typeof(a) != typeof(b):
		problems.append("%s type %d vs %d (%s vs %s)" % [what, typeof(a), typeof(b), _desc(a), _desc(b)])
		return
	var da = _desc(a)
	var db = _desc(b)
	if da != db:
		problems.append("%s: %s vs %s" % [what, da, db])

func _fields(files):
	var out = []
	for k in files:
		var h = files[k]
		out.append([h.compression_method, h.compressed_size, h.uncompressed_size, h.file_header_offset])
	return var2str(out)

# Same entries, same order, same fields; the only differences are names where
# the native side put U+FFFD for invalid utf8 (the deliberate fix).
func _only_fixed_names_differ(a, b):
	if a.size() != b.size() or _fields(a) != _fields(b):
		return _fixed_names_collided(a, b)
	var ka = a.keys()
	var kb = b.keys()
	for i in ka.size():
		if ka[i] != kb[i]:
			if kb[i].find(char(0xFFFD)) == -1 or b[kb[i]].file_name != kb[i]:
				return false
			_line("    name fixed: %s -> %s" % [var2str(ka[i]).c_escape(), kb[i]])
	return true

# Runs the original with its never-zeroed arrays filled with two different
# bytes. If that changes the result, the original's output on this input
# depends on whatever was in memory.
func _memory_dependent(p, name):
	var Filled = ResourceLoader.load(filled_script)
	var results = []
	for fill in [0x00, 0x5A]:
		Engine.set_meta("tinf_fill", fill)
		var g = Filled.new()
		g.load(p)
		results.append(_desc(g.uncompress(name)))
	Engine.remove_meta("tinf_fill")
	return results[0] != results[1]

# Invalid names that the original turned into the same string overwrite each
# other there, so the native side has more entries. Every valid name must still
# match exactly, in order.
func _fixed_names_collided(a, b):
	if b.size() <= a.size():
		return false
	var valid_b = []
	for k in b:
		if k.find(char(0xFFFD)) == -1:
			valid_b.append(k)
			if not a.has(k) or var2str(a[k]) != var2str(b[k]):
				return false
		elif b[k].file_name != k:
			return false
	var valid_a = []
	for k in a:
		if k in valid_b:
			valid_a.append(k)
	if valid_a != valid_b:
		return false
	_line("    names collided in the original: %d entries there, %d here" % [a.size(), b.size()])
	return true
