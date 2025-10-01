extends RefCounted
class_name TriangulateCalc

"""
Preudocode of triangulation, suggested by ChatGpt:
function BowyerWatson(pointList):
	
    Initialize triangulation with a super‑triangle that contains all points. ( bouding_box_2d ->super_triangle_for_bounding_box)
    For each point p in pointList:
        Find all triangles whose circumcircles contain p (bad_trianges). ( loop for all triangles in triangulation -> triangle_circumcircle_contains_point -> append to bad_trianges if true)
        Find the boundary (polygon) formed by the edges of bad_trianges that are not shared by another bad triangle. (boundary_edges)
        Remove bad_trianges from the triangulation.
        For each boundary edge e:
            Form a new triangle from e to p and add it to the triangulation.
    Remove any triangle that uses a vertex from the super‑triangle.
    Return triangulation.


"""

static func triangulate (points: Array[Vector2]) -> Array:
	var bbox : Rect2 =  bouding_box_2d(points)
	var super_triangle : Array[Vector2]  = super_triangle_for_bounding_box(bbox)
	var triangulation = [super_triangle]
	for p in points:
		var bad_trianges  := []
		var new_triangulation := []
		for tri in triangulation:
			if triangle_circumcircle_contains_point(tri, p):
				bad_trianges.append(tri)
			else:
				new_triangulation.append(tri)
		
		var boundary = boundary_edges(bad_trianges)
		for edge in boundary:
			var new_tri :=triangle_from_edge_and_point(edge,p)
			new_triangulation.append(new_tri)
		triangulation = new_triangulation
	var final_triangulation  = remove_super_triangle(triangulation, super_triangle)
	return final_triangulation



static func almost_equal(p1: Vector2, p2: Vector2, eps: float = 1e-7) -> bool:
	return p1.distance_to(p2) < eps
	
static func triangle_from_edge_and_point(edge: PackedFloat64Array, p: Vector2) -> Array[Vector2]:
# Edge is [ax, ay, bx, by] from to_packed_float64_array
	var a := Vector2(edge[0], edge[1])
	var b := Vector2(edge[2], edge[3])
	return [a, b, p]


static func remove_super_triangle(triangulation: Array, super_triangle: Array[Vector2], epsilon: float = 1e-7) -> Array:
	# Returns a filtered triangulation without any triangle that shares a vertex with super_triangle
	var result := []
	for tri in triangulation:
		var keep := true
		for v in tri:
			for sv in super_triangle:
				if almost_equal(v, sv, epsilon):
					keep = false
					break
			if not keep:
				break
		if keep:
			result.append(tri)
	return result

#Rect2 has : position top-left corner , end  bottom-right corner and size
static func bouding_box_2d(points: Array)->Rect2:
	var min_x :float = points[0].x
	var max_x :float = points[0].x
	var min_y :float = points[0].y
	var max_y :float = points[0].y
	for p in points:
		if p.x < min_x: min_x = p.x
		if p.x > max_x: max_x = p.x
		if p.y < min_y: min_y = p.y
		if p.y > max_y: max_y = p.y
		
	return Rect2(min_x,min_y,max_x-min_x, max_y-min_y)
		
	
static func super_triangle_for_bounding_box(bbox : Rect2) -> Array[Vector2]:
	var min_x := bbox.position.x
	var max_x := bbox.end.x
	var min_y := bbox.position.y
	var max_y := bbox.end.y
	var dx := bbox.size.x
	var dy := bbox.size.y	
	var delta_max :float= max(dx, dy)
	var mid_x := (min_x + max_x) / 2.0
	var mid_y := (min_y + max_y) / 2.0		
	var v1 := Vector2(mid_x - 20.0 * delta_max, mid_y - delta_max)
	var v2 := Vector2(mid_x,                 mid_y + 20.0 * delta_max)
	var v3 := Vector2(mid_x + 20.0 * delta_max, mid_y - delta_max)
	return [v1,v2,v3]
	
static func triangle_circumcircle_contains_point(tri: Array[Vector2], p: Vector2) -> bool:
	# Unpack vertices
	var a := tri[0]
	var b := tri[1]
	var c := tri[2]

	# Translate so that p becomes the origin
	var ax := a.x - p.x
	var ay := a.y - p.y
	var bx := b.x - p.x
	var by := b.y - p.y
	var cx := c.x - p.x
	var cy := c.y - p.y
	
	# Compute the determinant (from Bowyer–Watson in‑circle test)
	var det := (ax * ax + ay * ay) * (bx * cy - by * cx) \
				- (bx * bx + by * by) * (ax * cy - ay * cx) \
				+ (cx * cx + cy * cy) * (ax * by - ay * bx)
				
	# Determine orientation of triangle ABC (cross product of AB × AC)
	var orient := (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)

	# For counter‑clockwise triangles, det > 0 means p is inside;
	# for clockwise triangles, det < 0 means p is inside.
	return  det > 0.0  if orient > 0.0  else det < 0.0
	
	
static func to_canonical(p1: Vector2, p2: Vector2) -> Array[Vector2]:
# Returns edge as [a,b] with canonical ordering
	if p1.x < p2.x:
		return [p1, p2]
	elif p1.x > p2.x:
		return [p2, p1]
	else:
	# x equal, compare y
		if p1.y <= p2.y:
			return [p1, p2]
		else:
			return [p2, p1]

static func to_packed_float64_array(edge: Array[Vector2]) -> PackedFloat64Array:
# Convert canonical edge [a,b] to a PackedFloat64Array key [ax, ay, bx, by]
	var a: Vector2 = edge[0]
	var b: Vector2 = edge[1]
	return PackedFloat64Array([float(a.x), float(a.y), float(b.x), float(b.y)])	

static func boundary_edges(bad_triangles: Array) -> Array:
	var edge_count := {}
	# Count edges from all bad triangles
	for tri in bad_triangles:
		var edges = [
			to_packed_float64_array(to_canonical(tri[0], tri[1])),
			to_packed_float64_array(to_canonical(tri[1], tri[2])),
			to_packed_float64_array(to_canonical(tri[2], tri[0]))
		]	
		for e in edges:
			var key = e
			if edge_count.has(key):
				edge_count[key] += 1
			else:
				edge_count[key] = 1
	# Select edges appearing only once
	var boundary := []
	for edge in edge_count.keys():
		var count = edge_count[edge]
		if count == 1:
			boundary.append(edge)		
	return boundary
		
				
		
