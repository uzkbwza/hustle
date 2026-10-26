# Saves a mod's text scenes/resources (.tscn/.tres) as binary for char
# loader's cache, like Godot's exporter does for exported games: the binary
# copy goes next to the original as <path>.converted.res, plus a <path>.remap
# that ResourceLoader follows. Binary loads many times faster than text.
#
# Every conversion is checked: the binary is loaded back and compared with
# the text version (all nodes, properties and built-in sub-resources). Only an
# exact match is used; anything else stays text.

extends Reference


# Saves `res` (already loaded from `path`) as binary to `bin_tmp` and its
# .remap to `remap_tmp` (temp files to pack as path + ".converted.res" and
# path + ".remap"). Returns true only if the binary loads back identical.
static func convert(path, res, bin_tmp, remap_tmp):
	if res == null:
		return false
	if ResourceSaver.save(bin_tmp, res) != OK:
		return false
	var back = ResourceLoader.load(bin_tmp, "", true)
	if back == null or not same_contents(res, back, {}):
		return false
	var f = File.new()
	if f.open(remap_tmp, File.WRITE) != OK:
		return false
	f.store_string('[remap]\n\npath="%s"\n' % (path + ".converted.res"))
	f.close()
	return true


# Deep equality of two loaded resources/values. External resources (with a
# real path) are compared by path; built-in ones (no path, or "file::id")
# by class and every stored property.
static func same(a, b, seen):
	if typeof(a) != typeof(b):
		return false
	match typeof(a):
		TYPE_OBJECT:
			if a == null or b == null:
				return a == b
			if not (a is Resource) or not (b is Resource):
				return a == b
			var pa = a.resource_path
			var pb = b.resource_path
			var a_external = pa != "" and pa.find("::") == -1
			var b_external = pb != "" and pb.find("::") == -1
			if a_external or b_external:
				return a_external and b_external and pa == pb
			return same_contents(a, b, seen)
		TYPE_ARRAY:
			if a.size() != b.size():
				return false
			for i in a.size():
				if not same(a[i], b[i], seen):
					return false
			return true
		TYPE_DICTIONARY:
			if a.size() != b.size():
				return false
			for k in a:
				var kb = _matching_key(b, k, seen)
				if kb == null or not same(a[k], b[kb[0]], seen):
					return false
			return true
		_:
			return a == b


# Two resources' class and stored properties, whatever their own paths.
static func same_contents(a, b, seen):
	if a.get_class() != b.get_class():
		return false
	var key = str(a.get_instance_id()) + ":" + str(b.get_instance_id())
	if seen.has(key):
		return true # already being compared further up (a cycle)
	seen[key] = true
	var result = _same_properties(a, b, seen)
	if not result:
		seen.erase(key) # a failed comparison must not count as a match later
	return result


static func _same_properties(a, b, seen):
	# built-in scripts are new objects in every load; compare like resources
	if not same(a.get_script(), b.get_script(), seen):
		return false
	if a is PackedScene:
		return same(a.get("_bundled"), b.get("_bundled"), seen)
	for p in a.get_property_list():
		if p.usage & PROPERTY_USAGE_STORAGE == 0:
			continue
		if p.name in ["resource_path", "resource_name", "script"]:
			continue
		if not same(a.get(p.name), b.get(p.name), seen):
			return false
	return a.resource_name == b.resource_name


# The key in `b` that matches key `k` of the other dictionary, as [key], or
# null. Built-in resources used as keys are different objects in each load,
# so those match by contents.
static func _matching_key(b, k, seen):
	if b.has(k):
		return [k]
	if typeof(k) == TYPE_OBJECT and k is Resource:
		for kb in b:
			if typeof(kb) == TYPE_OBJECT and kb is Resource and same(k, kb, seen.duplicate()):
				return [kb]
	return null
