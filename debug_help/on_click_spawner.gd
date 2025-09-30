extends Node3D
class_name OnClickPivotSpawner


@export var packed_scene: PackedScene


# Spawn when left mouse button is pressed
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		spawn()


func spawn():
	if not packed_scene:
		push_warning("OnClickPivotSpawner %s: packed_scene is not set" % self)
		return null
	
	var instance := packed_scene.instantiate()
	(instance as Node3D).global_transform.origin = global_transform.origin
	instance.get_child(0).linear_velocity.x = 1
	#instance.get_child(0).apply_impulse(Vector3.ZERO, Vector3(1, 0, 0))
	# Add to the active scene root ("world" root)
	var world_root: Node = get_tree().current_scene
	if world_root == null:
		world_root = get_tree().root	
	world_root.add_child(instance)
	
	
	
	
