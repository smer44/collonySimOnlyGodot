extends Resource
class_name Need

@export var name : StringName
@export_range(0.0, 100.0, 0.1) var value: float = 0.0 : set = _set_value
enum PriorityCurve { LINEAR, QUADRATIC, EXPONENTIAL }

@export var time_to_satisfy : float = 5.0
@export var growth_rate_per_sec: float = 5.0
@export var priority_curve: PriorityCurve = PriorityCurve.LINEAR
@export var exp_factor : float = 0.5
@export var sq_koeff : float = 0.5
@export var lin_koeff : float = 1.0
@export var bias_koeff : float = 0.0
var priority: float = 0.0

func _set_value(v: float) -> void:
	value = clampf(v, 0.0, 100.0)
	priority = compute_priority(value)
	


func process(delta: float):
	_set_value( value + growth_rate_per_sec * delta)
	
	
func compute_priority(value: float) -> float:
	match priority_curve:
		PriorityCurve.LINEAR:
			return value * lin_koeff + bias_koeff
		PriorityCurve.QUADRATIC:
			return sq_koeff * value * value + value * lin_koeff + bias_koeff
		PriorityCurve.EXPONENTIAL:
			return exp(value *exp_factor)
	return value		
	
func pp() -> String:
	return "%s | value=%.1f | priority=%.1f" % [name, value, priority]
