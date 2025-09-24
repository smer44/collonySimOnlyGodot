class_name Noise3D
extends RefCounted


func get_at(p: Vector3, scale: Vector3) -> float:
	push_error("Noise3D.get_at must be implemented in subclass for : %s" % self )
	return 0.0
