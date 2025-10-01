extends RefCounted
class_name Random2dCalc

static var rng := RandomNumberGenerator.new()

static func sample_naive(max_points: int, r: float, stop_koef: int) -> Array[Vector2]:
	"""
	Naive Poisson-disc-style sampler in the unit square [0,1] x [0,1].
	- Tries to place up to `max_points` points such that pairwise distance >= r.
	- On each failed placement attempt, decrements a remaining retry budget.
	- If `stop_koef` failures accumulate before reaching `max_points`, returns
	whatever points were placed so far.


	Parameters:
	max_points: desired upper bound on number of samples
	r: minimum separation distance between any two points
	stop_koef: max number of failed attempts before giving up


	Returns:
	Array[Vector2] of samples within [0,1]^2
	"""
	var points: Array[Vector2] = []
	var attempts_left: int = max(0, stop_koef)
	var r2 := r * r


	
	rng.randomize()


	while points.size() < max_points and attempts_left > 0:
		# Propose a random point uniformly in the unit square
		var p := Vector2(rng.randf(), rng.randf())


		# Check against all existing points (naive O(N) check)
		var ok := true
		for q in points:
			if p.distance_squared_to(q) < r2:
				ok = false
				break
		if ok:
			points.append(p)
		else:
			attempts_left -= 1

	return points
