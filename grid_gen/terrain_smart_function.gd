extends TerrainFunction
class_name  TerrainSmartFunction



@export var seed_2d: int = 1337
@export var seed_3d: int = 4242

# Domain scaling (bigger => lower frequency)
@export var elevation_scale: Vector2 = Vector2(24.0, 24.0)  # XZ noise scale
@export var ground_scale: Vector3 = Vector3(12.0, 12.0, 12.0)  # XYZ noise scale for ground types
@export var dims: Vector3i = Vector3i(12, 12, 12)  # XYZ noise scale for ground types
@export var discrete_y : bool = true

# Noise thresholds in ascending order; values must have len == levels.len + 1
@export var levels: Array[float] = [0.25, 0.5, 0.75]
@export var values: Array = [
	Color(0.45, 0.35, 0.2),   # dirt
	Color(0.5, 0.5, 0.5),     # stone
	Color(0.7, 0.65, 0.55),   # gravel
	Color(0.9, 0.85, 0.7)     # sand
]

@export var water_level := 0.5
@export var water_color: Color = Color(0.2, 0.6, 1.0)


var noise2d: SimpleHashNoise2D  = SimpleHashNoise2D.new(seed_2d)
var noise3d: SimpleHashNoise3D = SimpleHashNoise3D.new(seed_3d)
var maxp_xz: Vector2
var maxp_xyz: Vector3

func _ready():
	if not StepChooser.steps_check(levels, values):
		push_error("StepChooser.steps: values.size must equal levels.size + 1")
		return

	
	#noise2d = SimpleHashNoise2D.new(seed_2d)
	#noise3d = SimpleHashNoise3D.new(seed_3d)
func precalc()-> void:
	pass
	
func get_elevation_at(x:int, z:int) -> float:
	var p_xz := Vector2(x, z )
	var elevation_value := noise2d.get_at(p_xz, elevation_scale)
	
	if elevation_value <= water_level:
		elevation_value = water_level
	var elevation_level := elevation_value * dims.y - 0.001 * dims.y
	if discrete_y:
		return round(elevation_level)
	return elevation_level
	
func get_elevation_basic_at(x:int, z:int) -> float:
	var p_xz := Vector2(x, z )
	var elevation_value := noise2d.get_at(p_xz, elevation_scale)
	var elevation_level := elevation_value * dims.y
	if discrete_y:
		return round(elevation_level)
	return elevation_value * dims.y
	
	
#func get_color_at(x:int, y:int, z:int) -> Color:
#	return Color.BLUE
	
func get_color_at(x:int, y:int, z:int) -> Color:
	var elevation_y := get_elevation_basic_at(x,z)
	var fy := float(y)
	var scaled_water_level = water_level * dims.y
	if fy <= elevation_y:
		#solid cell:
		var p3 := Vector3(x , y , z )
		var level3 := noise3d.get_at(p3,  ground_scale) 
		var color :Color= StepChooser.steps(levels, values, level3)
		return color 
	elif  fy <= scaled_water_level:
		return water_color
	else :
		return Color.BLACK
		
	
	
	
