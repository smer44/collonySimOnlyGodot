extends Camera2D
class_name DebugCamera2D

@export var zoom_step: float = 0.1
@export var min_zoom: float = 0.2
@export var max_zoom: float = 2.0

var middle_dragging: bool = false

func _input(event: InputEvent) -> void:
	# Mouse button events (press/release + wheel)
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		# Middle mouse drag start/stop
		if mb.button_index == MouseButton.MOUSE_BUTTON_MIDDLE:
			middle_dragging = mb.pressed
		 # Zoom in (wheel up) / out (wheel down)
		elif mb.button_index == MouseButton.MOUSE_BUTTON_WHEEL_DOWN:
			_change_zoom(-zoom_step)  # zoom in
		elif  mb.button_index == MouseButton.MOUSE_BUTTON_WHEEL_UP:
			_change_zoom(zoom_step)   # zoom out
	# Mouse motion while middle button is held -> pan
	elif middle_dragging and event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		position -= mm.relative/ zoom
		

			
func _change_zoom(delta: float) -> void:
	var z := zoom.x
	z = clamp(z + delta, min_zoom, max_zoom)
	zoom = Vector2(z, z)
	#print("new zoom : " , zoom)
		
	
