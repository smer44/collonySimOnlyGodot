extends AbstractCameraState
class_name PointOnDistanceCameraState 

@export var debug_mesh: MeshInstance3D

func _ready() -> void:
	debug_mesh.visible = false 

func enter(owner : CameraStatefull) -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	pass


func exit(owner : CameraStatefull) -> void:
	pass
	
	
func input(owner: CameraStatefull, event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var raycast = RayCastCalc.raycast_from_cursor(owner)
			var ipos :Vector3= Vector3.ZERO
			if raycast:
				ipos = raycast.position
			else:
				ipos = RayCastCalc.point_from_cursor_distance(owner,10)
			print("PointOnDistanceCameraState :" , ipos)
			debug_mesh.global_position = ipos
			debug_mesh.visible = true
				
