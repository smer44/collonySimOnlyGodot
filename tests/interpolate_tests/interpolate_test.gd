extends Node

func _ready() -> void:
	var arr = [0, 10, 30, 60]
	for t in range(0, 31):
		var f = t / 30.0
		print(InterpolateCalc.array_easing(arr, f * (arr.size() - 1), InterpolateCalc.ease_in_bouncy_out))
