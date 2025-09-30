extends AbstractPersonState
class_name IdlePersonState

const name = "IdlePersonState"

var color: Color = Color.GRAY

func process (owner : Person, delta: float):
	var need:= owner.max_need()
	if need.priority > owner.action_threshold:
		owner.satisfyNeedState.need = need
		owner.satisfyNeedState.time_left = need.time_to_satisfy
		owner.movingState.to_state_at_destination = owner.satisfyNeedState
		var device = UsableDeviceQuery.find_first_device_to_satisfy(need)
		owner.movingState.destination = device.global_position
		owner.set_state(owner.movingState)
		
		
func pp():
	return name
