extends RefCounted
class_name WaterCell
var vel: Vector2 = Vector2.ZERO # velocity at cell center
var pressure: Vector2 = Vector2.ZERO # pressure as a vector (e.g., cached delta p)
var amount: float = 1.0 # volume fraction (1 = full)


func reset():
	vel = Vector2.ZERO
	pressure = Vector2.ZERO
	amount = 0.0
