extends State
class_name FallingState

var tolerance = 0.1

func update(unit, delta):
	var below_pos = unit.get_cell_below()

	if below_pos.y <= -1000:
		unit.global_transform.origin.y = -1000
		unit.enter_state(unit.idle_state)
		return

	var new_pos = unit.global_transform.origin.linear_interpolate(below_pos, unit.fall_speed * delta)
	unit.global_transform.origin = new_pos

	if abs(unit.global_transform.origin.y - below_pos.y) < tolerance:
		unit.global_transform.origin.y = below_pos.y
		unit.enter_state(unit.idle_state)
