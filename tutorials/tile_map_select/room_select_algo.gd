extends RefCounted
class_name RoomSelectAlgo

# Offsets for the 8 neighbors (including diagonals)
const NEIGHBORS_8: Array[Vector2i] = [
	Vector2i(-1, -1),
	Vector2i( 0, -1),
	Vector2i( 1, -1),
	Vector2i(-1,  0),
	Vector2i( 1,  0),
	Vector2i(-1,  1),
	Vector2i( 0,  1),
	Vector2i( 1,  1),
]

## Given a set of cells (Array[Vector2i]), returns those that lie on the outline.
## A cell is considered boundary if at least one of its 8 neighbors is NOT in the set.

static func get_boundary_cells(cells: Dictionary) -> Array[Vector2i]:
	var result:= {}
	var result_array :Array[Vector2i]= []
	for c in cells.keys():
		cells[c] = 0
		for offset in NEIGHBORS_8:
			var n: Vector2i = c + offset
			if not cells.has(n):
				result_array.append(c)
				result[c] = 1
				cells[c] = 1
				break
	
	return result_array
	
static func update_distance_to_border(cell_set: Dictionary, boundary_cells: Array[Vector2i]):
	var temp_list = boundary_cells 
	while not temp_list.is_empty():
		var next_temp_list: Array[Vector2i] = []
		for c in temp_list:
			var c_val: int = int(cell_set.get(c, 0))
			var c_val_p_1 := c_val + 1
			for offset in NEIGHBORS_8:
				var n: Vector2i = c + offset
				if cell_set.has(n):
					var n_val: int = int(cell_set[n])
					if n_val == 0 or n_val > c_val_p_1:
						cell_set[n] = c_val_p_1
						next_temp_list.append(n)
		temp_list = next_temp_list
					
		
 
static func get_max_distance_cells(cell_set: Dictionary, min_val :int=-1) -> Dictionary:
	var result: Dictionary = {}
	var max_val: int = min_val
	# Find max value and collect cells with that value in one pass
	for c in cell_set.keys():
		var v: int = int(cell_set[c])
		if v > max_val:
			max_val = v
			result.clear()
			result[c] = v
		elif v == max_val:
			result[c] = v
			
			
	return result
			
	
