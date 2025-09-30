extends Camera3D



# Movement parameters
@export var move_speed: float = 15.0
@export var mouse_sensitivity: float = 0.002
@export var hide_cursor: bool = false
@export var shift_speed: float = 4.0


var yaw: float = 0.0   # horizontal rotation
var pitch: float = 0.0 # vertical rotation
var grid_cell:= Vector2i.ZERO
var grid_tracking_enabled: bool = false

func _ready():
	if hide_cursor:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_CAPSLOCK:
		grid_tracking_enabled = !grid_tracking_enabled
		#print("Grid tracking:", grid_tracking_enabled)	
	if event is InputEventMouseMotion:
		yaw   -= event.relative.x * mouse_sensitivity
		pitch -= event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, deg_to_rad(-89), deg_to_rad(89))
		update_rotation_by_yaw_and_pitch()
		

		
func update_rotation_by_yaw_and_pitch():
	rotation.y = yaw
	rotation.x = pitch	
		
func _process(delta: float) -> void:
	var movement := InputCalc.wasd_move(delta,self.basis,move_speed,shift_speed)
	#wasd_move(delta)	
	movement.y += InputCalc.up_down_move(delta,move_speed,shift_speed)
	
	global_position+= movement
	
	if grid_tracking_enabled:
		#var hit = RayCastCalc.horizontal_plane_intersect_floor(global_transform)
		#if hit:
		#	print(hit)
		var raycast = RayCastCalc.raycast_forward(self)
		if raycast:
			print(raycast.position)
		


		
