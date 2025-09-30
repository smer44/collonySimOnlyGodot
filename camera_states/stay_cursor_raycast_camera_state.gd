extends AbstractCameraState
class_name StayCursorRaycastCameraState


func enter(owner : CameraStatefull) -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)	
	pass


func exit(owner : CameraStatefull) -> void:
	pass


func input(owner : CameraStatefull, event: InputEvent) -> void:
	pass


func process(owner : CameraStatefull, delta: float) -> void:
	var raycast = RayCastCalc.raycast_from_cursor(owner)
	if raycast:
		var ipos:= RayCastCalc.to_floor_3d(raycast.position)
		print(ipos)	
	
	
