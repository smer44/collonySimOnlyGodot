extends AbstractPersonState
class_name MovingAlongPathState

#the state unit will transit at the end off path:
var to_state_at_destination : AbstractPersonState

#path unit will move along:
var path : Array[Vector3]
var current_index := 0

var speed : float = 4.0
var epsilon : float = 0.01


const name = "MovingAlongPathState"
var color: Color = Color.YELLOW	

func start_path(path_input : Array[Vector3]):
	path = path_input
	current_index = 0

func process(owner : Person, delta: float) -> void:
	var current_pos = owner.global_position
	var current_target = path[current_index]
	# move_toward will not go pass destination
	var next_pos = current_pos.move_toward(current_target, speed * delta)
	owner.global_position = next_pos
	print('MovingAlongPathState.owner.global_position:', owner.global_position)
	if next_pos.distance_to(current_target) <= epsilon:
		current_index+=1		
		if current_index >= path.size():
			owner.set_state(to_state_at_destination)

func pp():
	return name + " → path:" + str(path) + ", speed:" + str(speed)
