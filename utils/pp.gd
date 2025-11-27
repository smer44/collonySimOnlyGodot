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
	
static func print_array_2d(arr: Array, width: int) -> void:
	var i := 0  # start index in the flat array
	var sz := arr.size()
	var row_id = 0
	while i < sz:
		var row_text := "Row: " + str(row_id) + "  "
		var row_end := i+width
		row_end = sz if row_end > sz else row_end
		while i < row_end:
			row_text += str(arr[i]) + " "
			i += 1 # move to the next row start index
			
		print(row_text)
		row_id+=1
		
