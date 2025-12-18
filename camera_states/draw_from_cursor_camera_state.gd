extends AbstractCameraState
class_name DrawOnDistanceCameraState

@export var debug_mesh: Mesh
@export var start_distance: float = 10.0
@export var min_distance: float = 2.0
#@export var distance_step: float = 0.3
@export var snap_step :Vector3 = Vector3(1.3,1.3,1.3)

var stroke_points: Array[Vector3] = []
#var stroke_point_set: Dictionary = {} # Vector3i -> true
var _is_drawing: bool = false
var _current_distance : float
var _last_key: Vector3
var _debug_instance : MeshInstance3D

func _ready() -> void:
	set_physics_process(false)
	_create_mesh_insstance()
	
func _create_mesh_insstance()-> void:
	_debug_instance = MeshInstance3D.new()
	_debug_instance.name = "DebugMeshInstance"
	_debug_instance.mesh = debug_mesh
	_debug_instance.visible = false
	add_child(_debug_instance)
	
func enter(owner: CameraStatefull) -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	set_physics_process(true)
	
	
	
func exit(owner: CameraStatefull) -> void:
	set_physics_process(false)
	


func input(owner: CameraStatefull, event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_stroke(owner)
		else:
			_end_stroke(owner)


func _begin_stroke(owner: CameraStatefull) -> void:
	print("DrawOnDistanceCameraState: begin stroke")
	_is_drawing = true
	_debug_instance.visible = true
	_last_key = Vector3(INF,INF,INF)
	_current_distance = start_distance
	stroke_points.clear()
	
func _end_stroke(owner: CameraStatefull) -> void:
	print("DrawOnDistanceCameraState: end stroke : ", stroke_points)
	_is_drawing = false
	_debug_instance.visible = false
	var direction := owner.global_transform.basis.z.normalized()
	var points := PointsToMeshUtils.preprocess_duplicates_toward_direction(stroke_points,direction,snap_step.z)
	#var mmi :MultiMeshInstance3D= MultiMeshUtils.build_multimesh_from_points(debug_mesh,points)
	#add_child(mmi)
	#add arraymesh:
	var array_mesh := ArrayMeshBuilder.build_culled_cube_mesh_from_points(points,snap_step.z)
	#var array_mesh := ArrayMeshBuilder.build_boundary_edge_mesh (points,snap_step.z)
	var ami: MeshInstance3D = MeshInstance3D.new()
	ami.mesh = array_mesh
	add_child(ami)
	
	
	

func process(owner : CameraStatefull, delta: float) -> void:
	if not _is_drawing:
		return 
	var sample := _sample_cursor_point(owner, _current_distance)
	sample = sample.snapped(snap_step)
	
	if sample != _last_key:
		#print("DrawOnDistanceCameraState: sample : ", sample)
		stroke_points.append(sample)
		_last_key = sample
		_debug_instance.global_position = sample
		
			
	
	
	
func _sample_cursor_point(owner: CameraStatefull, dist: float) -> Vector3:
	var raycast = RayCastCalc.raycast_from_cursor(owner, [],start_distance)
	if raycast:
		return raycast.position
	return RayCastCalc.point_from_cursor_distance(owner,dist)
	
