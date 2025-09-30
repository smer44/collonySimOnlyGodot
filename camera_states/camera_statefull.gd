extends Camera3D
class_name CameraStatefull

var state: CameraState


func _ready() -> void:
	state.enter()


func _unhandled_input(event: InputEvent) -> void:
	state.unhandled_input(event)


func change_state(new_state: CameraState):
	state.exit()
	state = new_state
	state.enter()
	

func _process(delta: float) -> void:
	state.process(delta)
	
	
