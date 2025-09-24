class_name StepChooser
extends RefCounted


static func steps_check(levels: Array[float], values: Array) -> bool:
	return values.size() == levels.size() + 1


static func steps(levels: Array[float], values: Array, level: float):
	# Linear scan (simple and clear). For many thresholds, consider a binary search.
	if values.size() != levels.size() + 1:
		push_error("StepChooser.steps: values.size() must equal levels.size() + 1")
		return null
	var n := levels.size()
	for i in n:
		if level < levels[i]:
			return values[i]
	# If not less than any threshold, return the last bucket.
	return values[n]
