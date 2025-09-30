extends Node3D
class_name DummyGrid

# --- Exported parameters ---
@export var dims: Vector3i		# Dimensions of the grid (half-extent, centered around origin)

var grid: Array = [] # 3D: _grid[x][y][z] -> Array[Node3D]

var nbrs_x = [Vector3i(1,0,0),Vector3i(-1,0,0)]
var nbrs_y = [Vector3i(0,1,0),Vector3i(0,-1,0)]
var nbrs_z = [Vector3i(0,0,1),Vector3i(0,0,-1)]
# Ordered neighbors in XZ plane: front, left, back, right
var nbrs_xz = [Vector3i(0,0,1),Vector3i(-1,0,0),Vector3i(0,0,-1),Vector3i(1,0,0)]#order is front, left, back, right

func _ready() -> void:
	# Initialize grid with size = dims * 2 (to allow indexing with +/- offsets)
	grid = init_grid(dims*2)
	
# --- Get cell at given coordinates (relative to grid center) ---
func get_cell(vec: Vector3i) -> Array:
	var pos : Vector3i = vec + dims
	return grid[pos.x][pos.y][pos.z]

# --- Get cell at real array coordinates (no offset) ---	
func get_real_pos_cell(pos: Vector3i)-> Array:
	return grid[pos.x][pos.y][pos.z]

# --- Check if vector is within given bounds ---
func in_bounds(vec: Vector3i, vec_min: Vector3i, vec_max : Vector3i):
	var x := vec.x
	var y := vec.y 
	var z := vec.z
	
	var x0 := vec_min.x
	var y0 := vec_min.y 
	var z0 := vec_min.z
	
	var x1 := vec_max.x
	var y1 := vec_max.y 
	var z1 := vec_max.z
	
	
	return  x0 <= x and x < x1 and y0 <= y  and y < y1 and z0 <= z  and z < z1 

# --- Add a node to the given grid cell ---
func add_item(node: Node3D, vec: Vector3i):
	var cell := get_cell(vec)
	cell.append(node)

# --- Check if a node exists in the given grid cell ---	
func has_item(node: Node3D, vec: Vector3i) -> bool:
	var cell := get_cell(vec)
	return cell.has(node)
	
# --- Remove a node from the given grid cell ---
func remove_item(node: Node3D, vec: Vector3i):
	var cell := get_cell(vec)
	cell.erase(node)

# --- Initialize a 3D array of empty cells ---
func init_grid(vec: Vector3i) -> Array:
	var dx := vec.x
	var dy := vec.y 
	var dz := vec.z	
	
	var ret := Array()
	ret.resize(dx)
	for x in range(dx):
		var rx := Array()
		rx.resize(dy)		
		ret[x] = rx
		for y in range(dy):
			var rxy := Array()
			rxy.resize(dz)
			rx[y] = rxy 
			for z in range(dz):
				var cell := Array() # Each cell holds Node3D elements
				#do not set cell's size
				rxy[z] = cell 
	
	return ret 
	
