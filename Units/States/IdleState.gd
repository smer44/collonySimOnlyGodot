extends State
class_name IdleState

func update(unit, delta):
	var below_pos = unit.get_cell_below()
	if below_pos.y < unit.global_transform.origin.y:
		unit.enter_state(unit.falling_state)
