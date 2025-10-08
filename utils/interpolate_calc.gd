extends Node
class_name InterpolateCalc

static func metric(a,b)-> float:
	return a.distance_to(b)

static func accumulate_distance(points: Array , is_loop: bool = false) -> PackedFloat32Array:
	var acc:=PackedFloat32Array()
	acc.resize(points.size())
	acc[0] = 0.0
	var s := 0.0
	for i in range(1, points.size()):
		var dist := metric(points[i-1], points[i])
		s +=dist
		acc[i] = s    
	if is_loop and points.size() > 1:
		var dist := metric(points[-1], points[0])
		s +=dist
		acc.append(s)	
		
	return acc 
	

	
static func position_at_time(points: Array, acc:PackedFloat32Array, t: float, is_loop: bool = false):
	
	var loop_time = acc[-1]
	if is_loop and t > loop_time:
		t = fmod (t,loop_time)
	
	var idx:= acc.bsearch(t)
	# correction:
	if idx >= acc.size() or acc[idx] > t:
		idx -= 1	
	if idx < 0:
		idx = 0
	if not is_loop and idx == acc.size() - 1: 
		return points[-1]
	
	var t0 :float= acc[idx]
	var t1 :float= acc[idx + 1]	
	var p0= points[idx]
	var p1= points[(idx + 1) % points.size()]
	
	var dist:= t1-t0
	
	var u := (t-t0) / dist
	return p0.lerp(p1, u)
	
	
	
	
		

static func ease_in_bouncy_out(t: float) -> float:
	# Start slower than linear
	var start = t * t  # ease-in-quadratic base
	
	# Bouncy tail near the end (classic bounce formula adjusted)
	if t < 0.7:
		return start  # smooth start portion
	else:
		# Normalize last section (0.7–1.0) to [0,1]
		var x = (t - 0.7) / 0.3
		# Bounce equation: simulates small decaying oscillations
		var bounce = 1.0 - pow(2.71828, -6.0 * x) * abs(sin(10.0 * PI * x))
		# Blend it smoothly into the early part
		return lerp(start, bounce, x)
		
		

static func ease_in_out_cubic(t: float) -> float:
	if t < 0.5: 
		return 4.0 * t * t * t 
	else: 
		return (t - 1.0) * (2.0 * t - 2.0) * (2.0 * t - 2.0) + 1.0
		
static func ease_in_out_sine(t: float) -> float:
	return (1.0 - cos(PI * t)) * 0.5

static func array(points: Array, value: float) -> float:
	if points.is_empty():
		return 0.0
	
	var i := int(floor(value))
	var t := value - i  # fractional part
	
	# Clamp to valid indices
	if i < 0:
		return points[0]
	elif i >= points.size() - 1:
		return points[-1]
	
	return lerp(points[i], points[i + 1], t)
	
	
static func array_easing(points: Array, value: float, easing : Callable) -> float:
	if points.is_empty():
		return 0.0
	
	var i := int(floor(value))
	var t := value - i  # fractional part
	t = easing.call(t)
	# Clamp to valid indices
	if i < 0:
		return points[0]
	elif i >= points.size() - 1:
		return points[-1]
	
	return lerp(points[i], points[i + 1], t)
