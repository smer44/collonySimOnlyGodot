extends State
class_name MovingState

var tolerance = 0.1

func update(unit, delta):
	print("MovingState update", unit.current_index)
	if unit.current_index >= unit.path.size():
		unit.enter_state(unit.idle_state)
		return

	var target_cell = unit.path[unit.current_index]
	if unit.can_move_to(target_cell):
		var target_pos = unit.grid_map.get_cell_position(target_cell)
		unit.global_transform.origin = unit.global_transform.origin.linear_interpolate(target_pos, unit.move_speed * delta)
		if unit.global_transform.origin.distance_to(target_pos) < tolerance:
			unit.global_transform.origin = target_pos
			unit.current_index += 1
	else:
		unit.enter_state(unit.idle_state)
