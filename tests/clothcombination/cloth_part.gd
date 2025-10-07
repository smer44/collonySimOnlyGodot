extends Node
class_name ClothPart

@export var min_priority: int
@export var max_priority: int

func _ready() -> void:
	assert(min_priority <= max_priority, "Max priority is less then min priority for : " + pp())

func covers(other: ClothPart):
	return min_priority > other.max_priority
	
	
	

func pp():
	return "ClothPart %s : %s:  %s : %s" % [self.name, self.get_parent().name, min_priority, max_priority]
