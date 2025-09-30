extends RefCounted
class_name InputCalc


static func wasd_move(delta: float, basis: Basis,  move_speed : float, shift_speed : float) -> Vector3:
	var axis = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Build a horizontal move vector relative to current yaw
	var forward := basis.z        # local forward
	var right   :=  basis.x        # local right
	forward.y = 0
	right.y = 0
	forward = forward.normalized()
	right = right.normalized()
	
	if axis != Vector2.ZERO:
		var world_dir = right * axis.x + forward * axis.y
		var drawFrom = Vector3.ZERO
		var speed := move_speed
		if Input.is_key_pressed(KEY_SHIFT):
			speed *= shift_speed
		#DebugDraw3D.draw_line(drawFrom, drawFrom+direction*5, Color.GREEN)
		return world_dir * speed * delta
	return Vector3.ZERO


static func up_down_move(delta:float, move_speed : float, shift_speed : float)  -> float:
	var direction := 0.0

	if Input.is_action_pressed("ui_accept"): # By default, Space is mapped to ui_accept
		direction += 1.0
	if Input.is_key_pressed(KEY_CTRL): # Specifically left control key
		direction -= 1.0	
	if direction != 0.0:
		var speed := move_speed
		if Input.is_key_pressed(KEY_SHIFT):
			speed *= shift_speed			
		return direction * speed * delta	
	return 0.0
	
