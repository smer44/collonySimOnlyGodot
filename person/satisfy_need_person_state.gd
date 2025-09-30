extends AbstractPersonState
class_name SatisfyNeedState

var time_left := 0.0
var satisfy_per_second := 10.0
var need : Need
const name = "SatisfyNeedState"
var color: Color = Color.SKY_BLUE

func process(owner : Person, delta: float):
	need.value = need.value - satisfy_per_second * delta
	time_left -= delta
	if time_left <= 0.0:
		owner.set_state(owner.idleState)
		
		
	
func pp():
	return name + ":" +need.pp()+ ", time_left :" + str(time_left)
