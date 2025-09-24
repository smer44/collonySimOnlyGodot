extends Node3D
class_name DummyGrid


@export var dims: Vector3i

var grid: Array = [] # 3D: _grid[x][y][z] -> Array[Node3D]

var nbrs_x = [Vector3i(1,0,0),Vector3i(-1,0,0)]
var nbrs_y = [Vector3i(0,1,0),Vector3i(0,-1,0)]
var nbrs_z = [Vector3i(0,0,1),Vector3i(0,0,-1)]
var nbrs_xz = [Vector3i(0,0,1),Vector3i(-1,0,0),Vector3i(0,0,-1),Vector3i(1,0,0)]#order is front, left, back, right

func _ready() -> void:
	grid = init_grid(dims*2)
	

func get_cell(vec: Vector3i) -> Array:
	var pos : Vector3i = vec + dims
	return grid[pos.x][pos.y][pos.z]
	
func get_real_pos_cell(pos: Vector3i)-> Array:
	return grid[pos.x][pos.y][pos.z]
	
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
	
func add_item(node: Node3D, vec: Vector3i):
	var cell := get_cell(vec)
	cell.append(node)
	
func has_item(node: Node3D, vec: Vector3i) -> bool:
	var cell := get_cell(vec)
	return cell.has(node)
	
	
func remove_item(node: Node3D, vec: Vector3i):
	var cell := get_cell(vec)
	cell.erase(node)

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
				var cell := Array() 
				#do not set cell's size
				rxy[z] = cell 
	
	return ret 
	
