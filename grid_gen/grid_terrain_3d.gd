extends Node3D
class_name GridTerrain3D

# --- Config ---
@export var spawn_parent: Node3D = null
@export var width: int = 32
@export var height: int = 32
@export var depth: int = 32
@export var seed_2d: int = 1337
@export var seed_3d: int = 4242

# Domain scaling (bigger => lower frequency)
@export var elevation_scale: Vector2 = Vector2(24.0, 24.0)  # XZ noise scale
@export var ground_scale: Vector3 = Vector3(12.0, 12.0, 12.0)  # XYZ noise scale for ground types

# Thresholds for mapping *ground* cells (inside rock/soil) to colors via StepChooser
# values.size() must equal levels.size() + 1
@export var levels: Array[float] = [0.25, 0.5, 0.75]
@export var values: Array = [
	Color(0.45, 0.35, 0.2),   # dirt
	Color(0.5, 0.5, 0.5),     # stone
	Color(0.7, 0.65, 0.55),   # gravel
	Color(0.9, 0.85, 0.7)     # sand
]

@export var water_color: Color = Color(0.2, 0.6, 1.0)

# Box geometry params
@export var box_size: Vector3 = Vector3(1, 1, 1)
@export var box_spacing: Vector3 = Vector3(1.0, 1.0, 1.0)

# --- Internals ---
var grid: Array = []  # 3D array: grid[x][y][z] = Color or null
var noise2d: SimpleHashNoise2D
var noise3d: SimpleHashNoise3D

func _ready() -> void:
	# Optional check (if you have StepChooser.steps_check in your project)
	if (Engine.has_singleton("StepChooser") == false) and (values.size() != levels.size() + 1):
		push_error("GridTerrain3D: values.size must equal levels.size + 1")
		return

	init_grid()
	noise2d = SimpleHashNoise2D.new(seed_2d)
	noise3d = SimpleHashNoise3D.new(seed_3d)

	# Spawn for a quick preview; comment out if you only need data
	spawn_boxes_multi_mesh(spawn_parent)

func init_grid() -> void:
	grid.resize(width)
	for x in width:
		grid[x] = []
		(grid[x] as Array).resize(height)
		for y in height:
			grid[x][y] = []
			(grid[x][y] as Array).resize(depth)
			for z in depth:
				grid[x][y][z] = null

func check_bounds(x: int, y: int, z: int) -> bool:
	return x >= 0 and y >= 0 and z >= 0 and x < width and y < height and z < depth




func get_at_fast(x: int, y: int, z: int) -> Color:
	var p_xz := Vector2(x + 0.5, z + 0.5)
	var elevation_level := noise2d.get_at(p_xz,  elevation_scale)
	var elevation_y := elevation_level * float(height)
	var fly := float(y)
	if fly <= elevation_y:
		var p3 := Vector3(x + 0.5, y + 0.5, z + 0.5)
		var level3 := noise3d.get_at(p3,  ground_scale) 
		var color :Color= StepChooser.steps(levels, values, level3)
		return color 
	elif fly <= float(height) * 0.5:
		return water_color
	return Color.BLACK
		




# Returns a Color for the voxel at (x,y,z).
# Logic:
#   1) Elevation from 2D noise on XZ plane -> elevation_y = elevation_level * height
#   2) If y <= elevation_y  => solid ground: color via 3D noise + StepChooser
#   3) Else if elevation_y <= height/2 => water cell
#   4) Else => air (Color.BLACK)




func get_at(x: int, y: int, z: int) -> Color:
	if not check_bounds(x, y, z):
		push_error("GridTerrain3D.get_at: indices out of bounds %s:%s:%s" % [x, y, z])
		return Color(1, 0, 1)

	var cached = grid[x][y][z]
	if cached != null:
		return cached

	# 1) Elevation via 2D noise on XZ
	var p_xz := Vector2(x + 0.5, z + 0.5)
	var elevation_level := noise2d.get_at(p_xz,  elevation_scale)  # [0,1]
	var elevation_y := elevation_level * float(height)

	# 2) Ground / 3) Water / 4) Air decision
	var color: Color
	var fly := float(y)
	if fly <= elevation_y:
		# Inside ground: classify material via 3D noise
		var p3 := Vector3(x + 0.5, y + 0.5, z + 0.5)
		var level3 := noise3d.get_at(p3,  ground_scale)  # [0,1]
		color = StepChooser.steps(levels, values, level3)
		if color == null:
			push_error("GridTerrain3D.get_at: StepChooser returned null at %s:%s:%s" % [x, y, z])
			#color = values.back() if values.size() > 0 else Color(0.5, 0.5, 0.5)
	elif fly <= float(height) * 0.5:
		# Below sea level but above ground (i.e., water column)
		color = water_color
	else:
		# Air cell; caller may skip spawning for BLACK
		color = Color.BLACK
	grid[x][y][z] = color
	return color

# Material helper
func _make_colored_material(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	return m

# MultiMesh spawning for performance (skips air/BLACK)
# MultiMesh version for performance (one node, many instances)
func spawn_boxes_multi_mesh(parent: Node3D = null) -> void:
	if parent == null:
		parent = self

	var mesh := BoxMesh.new()
	mesh.size = box_size

	var material = _make_colored_material(Color.WHITE)
	material.vertex_color_use_as_albedo = true
	mesh.material = material

	var total := width * height * depth
	var mm := MultiMesh.new()
	mm.mesh = mesh
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.instance_count = total

	var idx := 0
	for z in depth:
		for y in height:
			for x in width:
				#var color = get_at(x, y, z)
				var color = get_at_fast(x,y,z)
				if  color != Color.BLACK:
					var xform := Transform3D()
					xform.origin = Vector3(x * box_spacing.x, y * box_spacing.y, z * box_spacing.z)
					mm.set_instance_transform(idx, xform)
					mm.set_instance_color(idx, color)
					idx += 1

	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	parent.add_child(mmi)
