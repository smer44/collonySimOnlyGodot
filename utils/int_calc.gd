extends RefCounted
class_name IntCalc

static func div_round_up(a: int, b: int) -> int:
	return (a + b - 1) / b
