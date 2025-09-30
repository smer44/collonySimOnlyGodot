extends AbstractTerrainElevationGenerator
class_name  TerrainSmartFunction



@export var seed_2d: int = 1337


# Domain scaling (bigger => lower frequency)
@export var elevation_scale: Vector2 = Vector2(24.0, 24.0)  # XZ noise scale

@export var dims: Vector3i = Vector3i(12, 12, 12)  # XYZ noise scale for ground types
@export var discrete_y : bool = true
@export var water_level := 6.1




var noise2d: SimpleHashNoise2D  = SimpleHashNoise2D.new(seed_2d)

var maxp_xz: Vector2
var maxp_xyz: Vector3

func _ready():
		return

	
	#noise2d = SimpleHashNoise2D.new(seed_2d)
	#noise3d = SimpleHashNoise3D.new(seed_3d)
func precalc()-> void:
	pass
	
func get_elevation_at(x:int, z:int) -> float:
	var p_xz := Vector2(x, z )
	var elevation_value := noise2d.get_at(p_xz, elevation_scale)
	

	var elevation_level := elevation_value * dims.y - 0.001 * dims.y
	
	if elevation_level <= water_level:
		elevation_level = water_level
		
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
	
	



		
	
	
	
