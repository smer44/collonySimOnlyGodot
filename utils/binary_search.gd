extends RefCounted
class_name BinarySearch

static func search_floor(acc: PackedFloat32Array, t: float) -> int:
	"""
	Binary search (floor): returns index i such that acc[i] <= t < acc[i+1]
	Returns -1 if t < acc[0].
	"""
	if acc.is_empty():
		return -1
	if t < acc[0]:
		return -1
	
	var lo := 0
	var hi := acc.size() - 1
	while lo <= hi:
		var mid := (lo + hi) >> 1
		var v := acc[mid]
		if is_equal_approx(v, t):
			return mid
		elif v < t:
			lo = mid + 1
		else:
			hi = mid - 1
	return hi  # floor index
