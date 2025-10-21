extends Node
class_name Person

@export var needs: Array[Need] = []
@export var action_threshold: float = 30.0
var state : AbstractPersonState

var idleState := IdlePersonState.new()
var satisfyNeedState := SatisfyNeedState.new()
var movingState := MovingPersonState.new()
var movingPathState := MovingAlongPathState.new()




func _ready() -> void:
	set_state(idleState)


func _process(delta: float) -> void:
	for n in needs:
		n.process(delta)	
		
	state.process(self, delta)
	debug_print_needs()
	

func max_need() -> Need:
	var ret: Need = needs[0]
	for n in needs:
		if n.priority > ret.priority:
			ret = n	
	return ret
	

	
func debug_print_needs() -> void:
# Handy for inspection
	print("Needs:")
	for n in needs:
		print(n.pp())
	print("State:" , state.pp())


func set_state(new_state :AbstractPersonState):
	state = new_state
	state.enter(self)	
	
