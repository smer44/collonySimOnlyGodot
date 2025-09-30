extends Node3D
class_name TileEditor

# --- Exported parameters ---
@export var ground_y: float = 0.0			# Elevation of the ground plane (y = ground_y)
@export var prefab: PackedScene				# Drag your scene here in the Inspector
@export var wireframe_prefab: PackedScene	# Prefab: wireframe cube of size 1
@export var shadow_color: Color = Color(0.2, 0.6, 1.0, 0.35)		# Color/tint for the prefab "shadow" (ghost)
@export var grid: DummyGrid			# Optional grid reference (custom)

# --- Internal state ---
#var angle_deg: float = 0.0 	# Yaw angle in degrees for spawned prefabs
var spawn_dir: int= 0 			# direction in form of 0= front, 1 = left, 2 = back, 3 = right
var wireframe : Node3D			# Wireframe preview instance
var preview_instance: Node3D	# Actual prefab preview inside the wireframe
var mouse_off = true			# Tracks whether mouse is free or captured

func _ready():
	# Instantiate wireframe preview
	wireframe = wireframe_prefab.instantiate()
	add_child(wireframe)
	wireframe.global_position = Vector3.ZERO
	_update_wireframe()
	
# --- Change the prefab being used ---
func set_prefab(new_prefab: PackedScene ):
	prefab = new_prefab
	_update_wireframe()
	
# --- Toggle mouse capture/confinement ---
func toggle_mouse_mode():
	mouse_off = not mouse_off
	if mouse_off:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
		
	
# --- Instantiate a new wireframe preview with shadow coloring ---
func _update_wireframe():
	var children  = wireframe.get_children()
	if len(children)  == 2:
		children[1].free()		# Remove previous preview
	preview_instance = prefab.instantiate()
	wireframe.add_child(preview_instance)
	set_shadow_color_all(wireframe,shadow_color)
		 
	
	
# --- Main frame update ---
func _process(delta: float) -> void:
	var hit = _get_pointer()	
	if hit:
		wireframe.global_position = hit
		
# --- Update wireframe rotation based on spawn_dir ---
func _update_wireframe_rotation() -> void:
	(wireframe as Node3D).global_rotation = Vector3(0.0, deg_to_rad(spawn_dir*90), 0.0)

# --- Recursively apply shadow color and make unshaded ---
func set_shadow_color_all(node: Node,   color: Color):
	if node is GeometryInstance3D:
		var gi := node as GeometryInstance3D
		var mat: BaseMaterial3D
		if gi.material_override and gi.material_override is BaseMaterial3D:
			mat = gi.material_override
		else:
			mat = StandardMaterial3D.new()		
		# Make it a translucent, unshaded tint that doesn't cast shadows
		mat.albedo_color = color
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA		
		gi.material_override = mat
		gi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Apply recursively to children
	for child in node.get_children():
		set_shadow_color_all(child,color)



# --- Handle mouse clicks and keyboard input ---
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:

		var hit = _get_pointer()	
		if hit == null:
			_on_no_ground_click()
		else:
			_on_ground_click(hit as Vector3)
	
	if event is InputEventKey and event.pressed and not event.echo:
		var kev := event as InputEventKey
		if kev.physical_keycode == KEY_R:
			_rotate_angle_90()
			_update_wireframe_rotation()
		if kev.physical_keycode == KEY_T:
			ground_y += 1.0
		if kev.physical_keycode == KEY_G:
			ground_y -= 1.0		 		
		if kev.physical_keycode == KEY_TAB:
			toggle_mouse_mode()
			
		
# --- Rotate spawn direction 90° clockwise ---
func _rotate_angle_90() -> void:
	#angle_deg = fposmod(deg_to_rad(spawn_dir*90), 360.0)
	spawn_dir = (spawn_dir+1) % 4
	
# --- Raycast from mouse pointer to ground plane ---
func _get_pointer():
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return null 
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var ray_origin: Vector3 = cam.project_ray_origin(mouse_pos)
	var ray_dir: Vector3 = cam.project_ray_normal(mouse_pos)  # normalized

	var ground_plane := Plane(Vector3.UP, ground_y)  # y = ground_y
	var hit = ground_plane.intersects_ray(ray_origin, ray_dir)			
	if hit == null:
		return null 
	var pos : Vector3  = (hit as Vector3)
	
	# Snap to grid centers
	pos = Vector3(floor(pos.x)+0.5, floor(pos.y)+0.5, floor(pos.z)+0.5)
	return pos
				

# --- Called when mouse clicks nothing on the ground ---
func _on_no_ground_click() -> void:
	print("Ground NOT hit ",)
	#make wireframe_prefab not visible
	#wireframe.visible = false
	
# --- Called when mouse clicks on the ground ---
func _on_ground_click(pos: Vector3) -> void:
	print("Ground hit at: ", pos)
	var base := Vector3(floor(pos.x), floor(pos.y), floor(pos.z))
	#make wireframe_prefab visible
	wireframe.global_position = base
	#wireframe.visible = true
	_spawn_prefab_at(pos)
	
# --- Spawn prefab instance at a given position ---
func _spawn_prefab_at(pos: Vector3) -> void:
	var inst := prefab.instantiate()
	get_tree().current_scene.add_child(inst)

	# Place it at the hit position (XZ on ground); ensure y is exactly ground_y
	if inst is Node3D:
		var node := inst as Node3D
		node.global_position = Vector3(pos.x, pos.y, pos.z)
		var angle := deg_to_rad(spawn_dir*90)
		node.global_rotation = Vector3(0.0, angle, 0.0)
	else:
		push_warning("Prefab's {prefab} root is not a Node3D; cannot position in 3D.")
