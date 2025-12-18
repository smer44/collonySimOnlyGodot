extends Node
class_name AbstractCameraState

enum StateType {Stay, Hover, RaycastPrint, StayCursorRaycast, Spawning, Point, ChooseUI, Draw }
@export var stateType : AbstractCameraState.StateType

func enter(owner : CameraStatefull) -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)	
	pass


func exit(owner : CameraStatefull) -> void:
	pass


func input(owner : CameraStatefull, event: InputEvent) -> void:
	pass


func process(owner : CameraStatefull, delta: float) -> void:
	pass
