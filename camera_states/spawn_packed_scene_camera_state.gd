extends AbstractCameraState
class_name SpawningCameraState

@export var scene_to_spawn: PackedScene

# Optional: where to add spawned nodes. If empty, uses owner root.
@export var spawn_parent: Node

# Optional behavior
@export var snap_to_floor: bool = true
@export var align_to_hit_normal: bool = false

func enter(owner: CameraStatefull) -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	

func input(owner: CameraStatefull, event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var raycast = RayCastCalc.raycast_from_cursor(owner)
			if raycast:
				var ipos :Vector3= raycast.position
				#var ipos:= RayCastCalc.to_floor_3d(raycast.position)
				var inst: Node = scene_to_spawn.instantiate()
				var current_parent := spawn_parent if spawn_parent else owner.get_tree().current_scene
				current_parent.add_child(inst)
				inst.global_position = ipos
				
			
		
	
