extends AbstractTerrainColoring
class_name HPADebugGatewayPointsShow

@export var terrain : AbstractTerrainElevationGenerator
@export var cluster_size := Vector2i(8,8)
@export var grid_size:= Vector2i(32,32)
@export var ele:=6
var algo = HPA
var marked := {}

func precalc() -> void:
	terrain.precalc()
	algo = HPA.new(terrain)
	algo.set_ele(ele)
	var gateways_per_clusters = algo.find_all_gateways(grid_size.x,grid_size.y,cluster_size.x,cluster_size.y)
	marked.clear()
	for gateways_per_cluster in gateways_per_clusters:
		for gateway in gateways_per_cluster:
			marked[gateway] = true 	
			print(gateway)
			

	
func get_color_at(x:int, y:int, z:int) -> Color:
	var p := Vector2i(x,z)
	if p in marked:
		return Color.RED
	if  (x % cluster_size.x) == 0 or  (z % cluster_size.y) == 0:
		return Color.GREEN
	return Color.GRAY
