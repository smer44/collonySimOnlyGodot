extends AbstractTerrainColoring
class_name Noice3DColoring


@export var seed_3d: int = 4242
#@export var terrain_generator : AbstractTerrainElevationGenerator 
# Noise thresholds in ascending order; values must have len == levels.len + 1
@export var levels: Array[float] = [0.25, 0.5, 0.75]
@export var values: Array = [
	Color(0.45, 0.35, 0.2),   # dirt
	Color(0.5, 0.5, 0.5),     # stone
	Color(0.7, 0.65, 0.55),   # gravel
	Color(0.9, 0.85, 0.7)     # sand
]


@export var water_color: Color = Color(0.2, 0.6, 1.0)

@export var noise3d_scale: Vector3 = Vector3(0.05, 0.05, 0.05)  # XYZ noise scale for ground types


var noise3d: SimpleHashNoise3D = SimpleHashNoise3D.new(seed_3d)

func _ready():
	if not StepChooser.steps_check(levels, values):
		push_error("Noice3DColoring._ready: values.size must equal levels.size + 1")

	
func get_color_at(x:int, y:int, z:int) -> Color:
	var elevation_y := terrain_generator.get_elevation_at(x,z)
	var fy := float(y)
	var scaled_water_level = terrain_generator.water_level #* dims.y
	
	if  fy <= scaled_water_level:
		return water_color	
	elif fy <= elevation_y:
		#solid cell:
		var p3 := Vector3(x , y , z )
		
		var level3 := noise3d.get_at(p3,  noise3d_scale) 
		#print("Noice3DColoring:level3 : %s" %level3)
		var color :Color= StepChooser.steps(levels, values, level3)
		return color 
	else :
		return Color.BLACK
