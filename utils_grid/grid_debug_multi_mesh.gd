extends MultiMeshInstance3D
class_name GridDebugMultiMesh

@export var grid2d: Array2D
@export var elevation_scale := 1
@export var cube_scale := 1
@export var boundary_start := Vector2i(4,1)

var point_precalc_set := {}

func _ready():
	assert (grid2d != null)
	_create_multimesh()
	

func _process(delta: float) -> void:
	_update_multimesh()

func _update_multimesh():	
	pass
	
func _create_multimesh():
	multimesh = MultiMesh.new()
	
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	
	var mesh = BoxMesh.new()
	mesh.size = Vector3.ONE * cube_scale

	var m := StandardMaterial3D.new()
	m.albedo_color = Color.WHITE
	m.vertex_color_use_as_albedo = true
	mesh.material = m	

	



	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true	
	#mm.color_format = MultiMesh.COLOR_FLOAT      # enables per-instance color
	#mm.custom_data_format = MultiMesh.CUSTOM_DATA_NONE


	
	multimesh.mesh = mesh	
	self.multimesh = multimesh
	
	
	#self.color_format = MultiMesh.COLOR_8BIT
	#self.custom_data_format = MultiMesh.CUSTOM_DATA_NONE
	var shp := grid2d.shape()
	var boundary = shp - Vector2i.ONE
	multimesh.instance_count = grid2d.instance_count()
	var index = 0
	
	# test precalc:
	_test_select_region(boundary_start,boundary)
	
	for x in range(shp.x):
		for y in range(shp.y):
			var p:= Vector2i(x,y)
			#_add_cell(index,p)
			#var test_result := _test_cell(p,boundary)
			var test_result := _test_precalc(p)
			var transform := _get_instance_transform(p)
			multimesh.set_instance_transform(index, transform)
			var color := _get_color_for_cell(test_result)			
			multimesh.set_instance_color(index, color)
			index +=1
			#print("spawned," , index)
		

	
func _test_select_region( p: Vector2i ,  boundary: Vector2i):
	var cells := GridBorderSelect.border_along(grid2d.grid, p, 0,   Vector2i.ZERO, boundary)
	for cell in cells:
		point_precalc_set[cell] = true
	

func _test_precalc(p: Vector2i)-> bool:
	return p in point_precalc_set
			
			
func _get_instance_transform(p : Vector2i) -> Transform3D:
	return Transform3D(Basis(), Vector3(p.x, grid2d.grid[p.x][p.y]*elevation_scale, p.y))
	#multimesh.set_instance_transform(index, transform)


func _test_is_on_boundary(p : Vector2i, shp : Vector2i) -> bool :
	return GridCheck.is_on_boundary(p, Vector2i.ZERO, shp)
	
func _test_is_on_elevation(p : Vector2i,elevation: int) -> bool:
	return grid2d.grid[p.x][p.y] == elevation
	
func _test_cell(p : Vector2i, shp : Vector2i)-> bool:
	return _test_is_on_elevation(p,2) 


	
func _get_color_for_cell(test: bool)-> Color:
	if test:
		return Color.GREEN
	else:
		return Color.RED
	
	
	
	
