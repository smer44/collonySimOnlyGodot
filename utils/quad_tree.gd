class_name QuadTree
extends RefCounted

var boundary: Rect2
var capacity: int
var points: Array[Vector2] = []
var divided: bool = false

var nw: QuadTree
var ne: QuadTree
var sw: QuadTree
var se: QuadTree



func _init(b: Rect2, c: int = 4, pts: Array[Vector2] = []):
	boundary = b.abs()
	capacity = c	
	insert_all(pts)
	
func find_all_inside_rectangle(range: Rect2, out: Array[Vector2] = []) -> Array[Vector2]:
	if not boundary.intersects(range): return out
	for p in points:
		if range.has_point(p): out.append(p)
	if divided:
		nw.find_all_inside_rectangle(range, out)
		ne.find_all_inside_rectangle(range, out)
		sw.find_all_inside_rectangle(range, out)
		se.find_all_inside_rectangle(range, out)
	return out
	
func distance_squared_to_rect_outside(point: Vector2, rect: Rect2) -> float:

	# Calculate the closest point on the rectangle to the given point
	#clamp is a put between b and c 

	var closest_x = clamp(point.x, rect.position.x, rect.position.x + rect.size.x)
	var closest_y = clamp(point.y, rect.position.y, rect.position.y + rect.size.y)
	var closest_point = Vector2(closest_x, closest_y)


	# Return the distance between the point and the closest point on the rectangle
	return point.distance_squared_to(closest_point)
	
func _children_in_near_order(target: Vector2) -> Array:
	var arr := [nw, ne, sw, se]
	arr.sort_custom(func(a, b):
		return distance_squared_to_rect_outside(target, a.boundary) < distance_squared_to_rect_outside(target, b.boundary)
	)
	return arr
	
func nearest(target: Vector2, best_point: Vector2 = Vector2.ZERO, best_d2: float = INF) -> Vector2:

	var rd2 := distance_squared_to_rect_outside(target,boundary)
	if rd2 >= best_d2:
		return best_point
	for p in points:
		var d2 := target.distance_squared_to(p)
		if d2 < best_d2:
			best_d2 = d2
			best_point = p
	if divided:
		for child in _children_in_near_order(target):		
			best_point = child.nearest(target, best_point, best_d2)
			best_d2 = target.distance_squared_to(best_point)

	return best_point



func insert_all(pts: Array[Vector2]) -> void:
	for p in pts: insert(p)
	
func clear() -> void:
	points.clear()
	divided = false
	nw = null; ne = null; sw = null; se = null
	
func insert(p: Vector2):
	if not boundary.has_point(p): return false
	if points.size() < capacity:
		points.append(p)
		return true
	if not divided:
		_subdivide()
	return _insert_child(p)
		




		
# --- internals ---
func _subdivide() -> void:
	var m := boundary.position + boundary.size * 0.5
	var p := boundary.position
	var s := boundary.size * 0.5
	nw = QuadTree.new(Rect2(p, s), capacity)
	ne = QuadTree.new(Rect2(Vector2(m.x, p.y), s), capacity)
	sw = QuadTree.new(Rect2(Vector2(p.x, m.y), s), capacity)
	se = QuadTree.new(Rect2(m, s), capacity)
	divided = true
		
func _insert_child(p: Vector2) -> bool:
	return nw.insert(p) or ne.insert(p) or sw.insert(p) or se.insert(p)
	
func size_deep():
	if divided:
		return capacity + nw.size_deep() + ne.size_deep() + sw.size_deep() + se.size_deep()
	else:
		return points.size()
		
func points_with_depth(depth : int = 0, arr : Array[Array] = []):
	for p in points:
		arr.append([p,depth])
	if divided:
		depth +=1
		nw.points_with_depth(depth,arr)
		ne.points_with_depth(depth,arr)
		sw.points_with_depth(depth,arr)
		se.points_with_depth(depth,arr)
	return arr
		
	
	
	
