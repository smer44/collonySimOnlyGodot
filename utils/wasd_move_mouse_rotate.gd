extends Camera3D



# --- Movement parameters ---
@export var move_speed: float = 15.0    		# Base movement speed
@export var mouse_sensitivity: float = 0.002  	# Mouse look sensitivity
@export var hide_cursor: bool = false   		# Whether to hide/capture the cursor
@export var shift_speed: float = 4.0   			# Multiplier when Shift is held

# --- Internal state ---
var yaw: float = 0.0  					 # Horizontal rotation (around Y-axis)
var pitch: float = 0.0 					 # Vertical rotation (around X-axis)
var grid_cell:= Vector2i.ZERO  			 # Current integer grid cell under camera
var grid_tracking_enabled: bool = false  # Whether to track grid cell

func _ready():
	if hide_cursor:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
# --- Handle input events ---
func _unhandled_input(event: InputEvent) -> void:
	# Toggle grid tracking with CapsLock
	if event is InputEventKey and event.pressed and event.keycode == KEY_CAPSLOCK:
		grid_tracking_enabled = !grid_tracking_enabled
		#print("Grid tracking:", grid_tracking_enabled)	
	
	# Mouse look
	if event is InputEventMouseMotion:
		yaw   -= event.relative.x * mouse_sensitivity
		pitch -= event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, deg_to_rad(-89), deg_to_rad(89))
		
		rotation.y = yaw
		rotation.x = pitch

# --- Main frame update ---	
func _process(delta: float) -> void:
	wasd_move(delta)			# Handle horizontal movement (WASD)
	up_down_move(delta)			# Handle vertical movement (Space/Ctrl)
	if grid_tracking_enabled:
		update_grid_cell()		# Track grid cell if enabled

# --- Horizontal movement (WASD) ---
func wasd_move(delta: float) -> void:
	var axis = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") 
	
	# Build a horizontal move vector relative to current yaw
	var forward := self.basis.z        # local forward
	var right   :=  self.basis.x        # local right
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
		global_position += world_dir * speed * delta

# --- Vertical movement (Space / Ctrl) ---	
func up_down_move(delta:float) :
	var direction := 0.0

	if Input.is_action_pressed("ui_accept"): # By default, Space is mapped to ui_accept
		direction += 1.0
	if Input.is_key_pressed(KEY_CTRL): # Specifically left control key
		direction -= 1.0	
	if direction != 0.0:
		var speed := move_speed
		if Input.is_key_pressed(KEY_SHIFT):
			speed *= shift_speed			
		global_position.y += direction * speed * delta	
		
# --- Cast a ray downwards to intersect the Y=0 plane ---
func ray_intersect_y0() -> Variant:
	var o: Vector3 = global_transform.origin
	var d: Vector3 = (-global_transform.basis.z).normalized() # camera forward
	if abs(d.y) < 0.000001:
		return null # ray parallel to plane
	var t: float = -o.y / d.y
	if t <= 0.0:
		return null # intersection is behind the camera or at origin
	var p: Vector3 = o + d * t
	return Vector2(p.x, p.z)
	
# --- Added: update stored integer grid cell and print on change ---
func update_grid_cell() -> void:
	var hit_2d = ray_intersect_y0()
	if hit_2d == null:
		return
	var cell := Vector2i(floor(hit_2d.x), floor(hit_2d.y))
	if cell != grid_cell:
		grid_cell = cell
		print(grid_cell)


# --- Added: handle CapsLock toggle ---
