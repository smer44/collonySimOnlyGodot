class_name Noise2D
extends RefCounted


func get_at(p: Vector2, scale: Vector2) -> float:
	push_error("Noise2D.get_at must be implemented in subclass of: %s" % self)
	return 0.0
