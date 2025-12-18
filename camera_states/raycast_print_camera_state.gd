extends AbstractCameraState
class_name RaycastPrintCameraState


func enter(owner : CameraStatefull) -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)	
	pass


func exit(owner : CameraStatefull) -> void:
	pass


func input(owner : CameraStatefull, event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		owner.yaw   -= event.relative.x * owner.mouse_sensitivity
		owner.pitch -= event.relative.y * owner.mouse_sensitivity
		owner.pitch = clamp(owner.pitch, deg_to_rad(-89), deg_to_rad(89))
		owner.update_rotation_by_yaw_and_pitch()
		return 
	# Left click -> raycast print
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var raycast = RayCastCalc.raycast_forward(owner)
			if raycast:
				var ipos:= RayCastCalc.to_floor_3d(raycast.position)
				print("RaycastPrintCameraState : ", ipos)
		
		
	


func process(owner : CameraStatefull, delta: float) -> void:
	var movement := InputCalc.wasd_move(delta,owner.basis,owner.move_speed,owner.shift_speed)
	movement.y += InputCalc.up_down_move(delta,owner.move_speed,owner.shift_speed)	
	owner.global_position+= movement

	
