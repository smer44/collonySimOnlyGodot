extends Camera3D
class_name CameraStatefull

var state: AbstractCameraState
var state_map: Dictionary 

var yaw: float = 0.0   # horizontal rotation
var pitch: float = 0.0 # vertical rotation
var init_state_type = AbstractCameraState.StateType.Hover

@export var move_speed: float = 15.0
@export var mouse_sensitivity: float = 0.002
@export var hide_cursor: bool = true
@export var shift_speed: float = 4.0

@export var choose_ui_root: Control

func _ready() -> void:

	_update_states_map()
	print(state_map)
	state = state_map[init_state_type]
	state.enter(self)
	
	
func _update_states_map():
	for child in get_children():
		if child is AbstractCameraState:
			assert (not child.stateType in state_map , "CameraStatefull: state type enum doubled")
			state_map[child.stateType] = child
	
		
	
func _input(event: InputEvent) -> void:
	state.input(self,event)
	var newState :AbstractCameraState = null
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			if state.stateType == AbstractCameraState.StateType.ChooseUI:
				newState = state_map[AbstractCameraState.StateType.Hover]
			else:
				newState= state_map[AbstractCameraState.StateType.ChooseUI]
			
		if event.keycode == KEY_BACKSPACE:			
			if state.stateType == AbstractCameraState.StateType.Stay:
				newState = state_map[AbstractCameraState.StateType.Hover]
			else:
				newState= state_map[AbstractCameraState.StateType.Stay]

		elif  event.keycode == KEY_CAPSLOCK:
			if state.stateType == AbstractCameraState.StateType.RaycastPrint:
				newState = state_map[AbstractCameraState.StateType.Hover]
			else:
				newState = state_map[AbstractCameraState.StateType.RaycastPrint]
			
		elif event.keycode == KEY_TAB:
			if state.stateType == AbstractCameraState.StateType.StayCursorRaycast:
				newState = state_map[AbstractCameraState.StateType.Hover]
			else:
				newState = state_map[AbstractCameraState.StateType.StayCursorRaycast]
	if newState:
		change_state(newState)					
				



func update_rotation_by_yaw_and_pitch():
	rotation.y = yaw
	rotation.x = pitch	
	

func change_state(new_state: AbstractCameraState):
	state.exit(self)
	state = new_state
	state.enter(self)
	print('CameraStatefull: state changed to %s' % state)
	

func _process(delta: float) -> void:
	state.process(self,delta)
	
	
