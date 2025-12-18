extends RefCounted 
class_name PointsToMeshUtils

static func preprocess_duplicates_toward_direction(
	points: Array[Vector3],
	direction : Vector3,
	layer_step: float = 0.3,
	min_distance: float = 2.0
	) -> Array[Vector3]:
		
	if points.is_empty():
		return []

	var counts: Dictionary = {}   
	var out: Array[Vector3] = []
	for p in points:
		if not counts.has(p):
			counts[p] = 1
			out.append(p)
			
		else:
			var old_amount :int= counts[p]
			var p_shifted := p - direction * old_amount
			counts[p] = old_amount+ 1
			out.append(p_shifted)
	

		
	return out
	
