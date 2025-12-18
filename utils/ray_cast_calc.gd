extends RefCounted
class_name RayCastCalc


static var debug_draw: bool = true

static func horizontal_plane_intersect(global_transform : Transform3D, y_plane:float = 0.0) -> Variant:
	var o: Vector3 = global_transform.origin
	var d: Vector3 = (-global_transform.basis.z).normalized() # camera forward
	if abs(d.y) < 0.000001:
		return null # ray parallel to plane
	var t: float = (y_plane-o.y) / d.y
	if t <= 0.0:
		return null # intersection is behind the camera or at origin
	var p: Vector3 = o + d * t
	return Vector2(p.x, p.z)
	
# --- Added: update stored integer grid cell and print on change ---
static func to_floor_2d(hit_2d : Vector2) -> Vector2i:
	var grid_cell := Vector2i(floor(hit_2d.x), floor(hit_2d.y))
	#print(grid_cell)
	return grid_cell
	
static func to_floor_3d(hit_3d : Vector3) -> Vector3i:
	var grid_cell := Vector3i(floor(hit_3d.x), floor(hit_3d.y), floor(hit_3d.z))
	return grid_cell
	


static func horizontal_plane_intersect_floor(global_transform : Transform3D) -> Variant:
	var hit = horizontal_plane_intersect(global_transform)
	if hit == null:
		return null 
	return to_floor_2d(hit)


static func raycast_forward(node : Node3D, exclude: Array = [], ray_length: float = 100000.0 , collision_mask: int = 0xFFFFFFFF) -> Dictionary:
	# Start at this node's global origin ("middle"/pivot of the object)
	var start: Vector3 = node.global_transform.origin
	# Cast along this node's +Z in world space
	var dir: Vector3 = -node.global_transform.basis.z.normalized()
	var finish: Vector3 = start + dir * ray_length
	# Make sure we don't hit ourselves
	exclude.append(node)
	var space_state: PhysicsDirectSpaceState3D = node.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(start, finish)
	query.exclude = exclude
	query.collision_mask = collision_mask
	query.hit_from_inside = true


	var result: Dictionary = space_state.intersect_ray(query)

	return result # Empty {} if no collision
	

static func raycast_from_cursor(camera: Camera3D, exclude: Array = [], ray_length: float = 100000.0 , collision_mask: int = 0xFFFFFFFF) -> Dictionary:
	var viewport := camera.get_viewport()
	# Mouse position in the current viewport
	var mouse_pos: Vector2 = viewport.get_mouse_position()
	# Build a world-space ray from the cursor via the camera
	var origin: Vector3 = camera.project_ray_origin(mouse_pos)
	var direction: Vector3 = camera.project_ray_normal(mouse_pos).normalized()
	var finish: Vector3 = origin + direction * ray_length
	# Avoid self-hits
	exclude.append(camera)
	# Raycast
	var space_state: PhysicsDirectSpaceState3D = camera.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(origin, finish)
	
	query.exclude = exclude
	query.collision_mask = collision_mask
	query.hit_from_inside = true
	
	var result: Dictionary = space_state.intersect_ray(query)
	return result
	
	
static func point_from_cursor_distance(
		camera: Camera3D,
		distance: float,
		clamp_nonnegative: bool = true
	) -> Vector3:
	var viewport := camera.get_viewport()
	var mouse_pos: Vector2 = viewport.get_mouse_position()

	var origin: Vector3 = camera.project_ray_origin(mouse_pos)
	var dir: Vector3 = camera.project_ray_normal(mouse_pos).normalized()

	if clamp_nonnegative and distance < 0.0:
		distance = 0.0

	return origin + dir * distance
	
	
	
static func _debug_draw_ray(node : Node3D, start: Vector3, finish: Vector3, result: Dictionary) -> void:
# Simple transient gizmo using ImmediateMesh in a MeshInstance3D child named "RayGizmo"

	var gizmo := MeshInstance3D.new()
	gizmo.name = "RayGizmo"
	gizmo.mesh = ImmediateMesh.new()
	node.add_child(gizmo)
		
	var im := gizmo.mesh as ImmediateMesh
	im.clear_surfaces()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	im.surface_add_vertex(start)
	im.surface_add_vertex(result.position if result.has("position") else finish)
	im.surface_end()
	
	
