extends Node3D

@export var cache: TerrainCache
var cells = []

func _ready() -> void:
	if not cache:
		push_error("No TerrainCache assigned")
		return
		
	for x in range(cache.size_x):
		var row = []
		for z in range(cache.size_z):
			var y = cache.get_elevation_at(x, z)
			var cell = {
				"position": Vector3(x, y, z),
				"occupied": false
			}
			row.append(cell)
		cells.append(row)

func is_cell_valid(cell_pos: Vector3) -> bool:
	var x = int(cell_pos.x)
	var z = int(cell_pos.z)
	if x < 0 or x >= cells.size():
		return false
	if z < 0 or z >= cells[0].size():
		return false
	return true

func is_cell_blocked(cell_pos: Vector3, unit) -> bool:
	var x = int(cell_pos.x)
	var z = int(cell_pos.z)
	return cells[x][z]["occupied"]

func get_cell_position(cell_pos: Vector3) -> Vector3:
	var x = int(cell_pos.x)
	var z = int(cell_pos.z)
	return cells[x][z]["position"]
