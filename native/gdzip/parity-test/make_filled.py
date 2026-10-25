# Makes a test-only copy of the original gdunzip whose never-zeroed arrays get
# filled with a chosen byte (Engine meta "tinf_fill"). compare.gd uses it to
# tell when the original's own output depends on leftover memory.
import sys
s = open(sys.argv[1]).read()
for kind in ("int", "byte"):
    old = f"""	func make_pool_{kind}_array(size):
		var pool_{kind}_array = Pool{kind.capitalize()}Array()
		pool_{kind}_array.resize(size)
		return pool_{kind}_array"""
    assert old in s, kind
    fill = "fill * 0x01010101" if kind == "int" else "fill"
    s = s.replace(old, f"""	func make_pool_{kind}_array(size):
		var pool_{kind}_array = Pool{kind.capitalize()}Array()
		pool_{kind}_array.resize(size)
		var fill = Engine.get_meta("tinf_fill") if Engine.has_meta("tinf_fill") else 0
		for i in size: pool_{kind}_array[i] = {fill}
		return pool_{kind}_array""")
open(sys.argv[2], "w").write(s)
