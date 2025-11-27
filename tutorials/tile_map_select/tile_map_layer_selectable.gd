extends TileMapLayer
class_name TileMapLayerSelectable

var _selected_cells := {}
var _is_dragging := false
const selected_id := 8
const boundary_id := 13
const boundary_amount := 6
const chair_id := 6


func _unhandled_input(event: InputEvent) -> void:
	
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_BACKSPACE:
			clear()
			_selected_cells.clear()
			return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:	
			var cells_array = _selected_cells.keys()
			print("Selected cells:", cells_array)
			
			
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_is_dragging = true
			_add_event_coords(event)
		else:
			assert (_is_dragging, "not event.pressed but not _is_dragging")
			_is_dragging = false
			var boundary_cells = RoomSelectAlgo.get_boundary_cells(_selected_cells)
			RoomSelectAlgo.update_distance_to_border(_selected_cells, boundary_cells)
			
			
			for cell in _selected_cells:
				var dist_to_border = _selected_cells[cell]
				if dist_to_border == 0 :
					set_cell(cell, selected_id, Vector2i(0, 0), 0)
				else:
					dist_to_border = dist_to_border % boundary_amount
					set_cell(cell, boundary_id+ dist_to_border, Vector2i(0, 0), 0)
					
			var max_cells = RoomSelectAlgo.get_max_distance_cells(_selected_cells,2)
			for cell in max_cells:
				set_cell(cell, chair_id, Vector2i(0, 0), 0)
				
				
			
	elif _is_dragging and event is InputEventMouseMotion:
		_add_event_coords(event)

			
func _add_event_coords(event: InputEvent):
		var global_pos: Vector2 = get_global_mouse_position()
		var local_pos: Vector2 = to_local(global_pos)
		var cell: Vector2i = local_to_map(local_pos)
		_selected_cells[cell] = 0
		set_cell(cell, selected_id, Vector2i(0, 0), 0)
		



func _unhandled_input_print_cell_id(event: InputEvent) -> void:
	# Check for left mouse button press
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:
		var global_pos: Vector2 = event.position
		var local_pos: Vector2 = to_local(global_pos)
		var cell: Vector2i = local_to_map(local_pos)
		print("Clicked cell:", cell)
