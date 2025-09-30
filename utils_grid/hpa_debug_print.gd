extends AbstractTerrainColoring
class_name HPADebugShow

@export var terrain : AbstractTerrainElevationGenerator
@export var block_start : Vector2i
@export var block_dim : Vector2i
@export var grid_start :=Vector2i.ZERO
@export var grid_end := Vector2i(32,32)
@export var ele:=6
var algo = HPA
var path := {}

func precalc() -> void:
	terrain.precalc()
	algo = HPA.new(terrain)
	algo.set_ele(ele)
	var windows = algo.find_all_windows(block_start,block_dim,grid_start,grid_end)
	var pts = algo.all_windows_to_all_border_points(windows)
	path.clear()
	for p in pts:
		path[p] = true 	
	print(pts)
			

	
func get_color_at(x:int, y:int, z:int) -> Color:
	#push_error("TerrainFunction.get_color_at must be implemented in subclass : %s" % self)
	var p := Vector2i(x,z)
	if p in path:
		return Color.RED
	#return terrain.get_color_at(x,y,z)
	return Color.GRAY
		
		
