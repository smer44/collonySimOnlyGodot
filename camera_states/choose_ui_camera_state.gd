extends AbstractCameraState
class_name ChooseUIState

@export var choose_ui_vbox: VBoxContainer

func enter(owner : CameraStatefull) -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	update_ui(owner , choose_ui_vbox)
	owner.choose_ui_root.visible = true
	

static func update_ui(owner: CameraStatefull , choose_ui_vbox: VBoxContainer) -> void:
	if owner.choose_ui_root == null:
		push_warning("ChooseUIState: assign CameraStatefull.choose_ui_root : Controll node in the inspector.")
		return
		
	if choose_ui_vbox == null:
		push_warning("ChooseUIState: assign choose_ui_vbox : VBoxContainer in the inspector.")
		return
	
	for child in choose_ui_vbox.get_children():
		child.queue_free()
	var keys := owner.state_map.keys()

	for t in keys:
		#print("ChooseUIState : adding key :" , t )
		add_state_change_button(t,owner,choose_ui_vbox)


static func add_state_change_button(t : AbstractCameraState.StateType, owner: CameraStatefull , choose_ui_vbox: VBoxContainer) -> void:
	if t == AbstractCameraState.StateType.ChooseUI:
		return
	var target_state: AbstractCameraState = owner.state_map[t]
	
	var btn := Button.new()
	#btn.text = str(AbstractCameraState.StateType.keys()[t])
	btn.text = str(target_state.name)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choose_ui_vbox.add_child(btn)
	
	btn.pressed.connect(func() -> void:
		owner.change_state(target_state)
	)	

func exit(owner : CameraStatefull) -> void:
	owner.choose_ui_root.visible = false
	
