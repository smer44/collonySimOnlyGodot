extends AbstractPersonState
class_name MovingPersonState

var to_state_at_destination : AbstractPersonState
var destination : Vector3

var speed : float = 4.0
var epsilon : float = 0.01
const name = "MovingPersonState"

var color: Color = Color.YELLOW

func process(owner : Person, delta: float) -> void:
	var current_pos = owner.global_position
	var next_pos = current_pos.move_toward(destination, speed * delta)
	owner.global_position = next_pos
	print('owner.global_position:', owner.global_position)
	if current_pos.distance_to(destination) <= epsilon:
		owner.set_state(to_state_at_destination)
		
		
func pp():
	return name + " → dest:" + str(destination) + ", speed:" + str(speed)
