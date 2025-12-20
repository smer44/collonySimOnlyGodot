extends RefCounted 
class_name FiboSphereUtils


	

# Triangle indices into the supplied points array (which must match all_points(rows, cols) order).
# Every 3 consecutive ints form one triangle.
#TODO - now returns wrong indexes
static func triangle_indices_from_points(points: PackedVector3Array, rows: int, cols: int) -> PackedInt32Array:
	var out := PackedInt32Array()
	if rows < 2 or cols < 3:
		return out
	if points.size() != rows * cols:
		push_error("triangle_indices_from_points: points.size() must equal rows*cols.")
		return out

	for i in range(rows - 1):
		for j in range(cols):
			var jn := (j + 1) % cols

			var a := i * cols + j
			var b := (i + 1) * cols + j
			var c := (i + 1) * cols + jn
			var d := i * cols + jn

			_push_oriented_triangle(out, points, a, b, c)
			_push_oriented_triangle(out, points, a, c, d)

	return out

static func _push_oriented_triangle(out: PackedInt32Array, pts: PackedVector3Array, a: int, b: int, c: int) -> void:
	var pa := pts[a]
	var pb := pts[b]
	var pc := pts[c]

	var n := (pb - pa).cross(pc - pa)
	var center := (pa + pb + pc) / 3.0
	if n.dot(center) < 0.0:
		var tmp := b
		b = c
		c = tmp

	out.push_back(a)
	out.push_back(b)
	out.push_back(c)

static func triangle_indices(rows: int, cols: int) -> PackedInt32Array:
	""" Topology: a wrapped strip grid in (i,j):
	Quad (i,j)-(i+1,j)-(i+1,j+1)-(i,j+1) becomes 2 triangles.
	j wraps around (so j = cols-1 connects to j = 0).
	"""
	var out := PackedInt32Array()
	if rows < 2 or cols < 3:
		return out
		
	for i in range(rows - 1):
		for j in range(cols):
			var jn := (j + 1) % cols
			var a := i * cols + j
			var b := (i + 1) * cols + j
			var c := (i + 1) * cols + jn
			var d := i * cols + jn
			# Two triangles: (a,b,c) and (a,c,d)
			_push_triangle(out,a,b,c)
			_push_triangle(out,a,c,d)
	
	return out 


static func _push_triangle(out : PackedInt32Array, a: int, b: int, c: int) -> void:
	out.push_back(a)
	out.push_back(b)
	out.push_back(c)
	
	

static func all_points(rows: int, cols: int) -> PackedVector3Array:
	var ret := PackedVector3Array()
	for i in range(rows):
		for j in range(cols):
			ret.push_back(unit_sphere_point_from_ij(i,j,rows,cols))
	return ret 
	
	

# Returns a point on the unit sphere for a 2D index (i,j), with (0,0) at the “top” (0,1,0).
# The points are distributed using a Fibonacci (golden-angle) spiral; (i,j) is a row/column label.
static func unit_sphere_point_from_ij(i: int, j: int, rows: int, cols: int) -> Vector3:
	"""
	Returns a point on the unit sphere for a 2D index (i,j), with (0,0) at the “top” (0,1,0).
	The points are distributed using a Fibonacci (golden-angle) spiral; (i,j) is a row/column label.
	To cover the entire set of unique points that this function can generate 
	(with no duplication and no reliance on clamping/wrapping), use:
		i in [0, rows - 1]
		j in [0, cols - 1]
	"""
	if rows <= 0 or cols <= 0:
		return Vector3.UP

	var n: int = rows * cols
	if n == 1:
		return Vector3.UP

	var ii: int = clampi(i, 0, rows - 1)
	var jj: int = posmod(j, cols) # wraps around horizontally

	var k: int = ii * cols + jj # 0 .. n-1

	# Place endpoints exactly at poles
	var y: float = 1.0 - 2.0 * float(k) / float(n - 1)  # k=0 -> y=1, k=n-1 -> y=-1
	var r: float = sqrt(max(0.0, 1.0 - y * y))

	var golden_angle: float = PI * (3.0 - sqrt(5.0))
	var phi: float = golden_angle * float(k)

	var x: float = cos(phi) * r
	var z: float = sin(phi) * r

	return Vector3(x, y, z) # already unit length (up to float error)
