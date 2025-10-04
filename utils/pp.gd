extends Node
class_name PP


static func pp_quad_tree(q:QuadTree, indent : int = 0):
	var prefix := " ".repeat(indent)
	print(prefix + str(q.boundary) + " points=" + str(q.points))
	if q.divided:
		pp_quad_tree(q.nw, indent + 1)
		pp_quad_tree(q.ne, indent + 1)
		pp_quad_tree(q.sw, indent + 1)
		pp_quad_tree(q.se, indent + 1)


static func pp_dict_of_lists(d: Dictionary, indent: int = 0) -> String:
	var IND := " ".repeat(indent)
	var OUT := IND + "{\n"
	var keys: Array = d.keys()
	keys.sort() # stable enough for strings/numbers

	for k_i in keys.size():
		var k = keys[k_i]
		OUT += IND + "  " + str(k) + ": [\n"

		var arr = d[k]
		for obj in arr:
				var rendered := ""
				if obj != null and obj.has_method("pp"):
					# Ensure string, support multi-line from pp()
					rendered = str(obj.pp())
				else:
					rendered = str(obj)

				# indent each line of the object’s pretty text
				for line in rendered.split("\n"):
					OUT += IND + "    " + line + "\n"
					
					# add a trailing comma line between items
					OUT = OUT.rstrip("\n") + ",\n"

		OUT += IND + "  ]"
		if k_i < keys.size() - 1:
			OUT += ","
		OUT += "\n"

	OUT += IND + "}"
	return OUT
