extends RefCounted
class_name CubeSphereUtils

enum Face { POS_X, NEG_X, POS_Y, NEG_Y, POS_Z, NEG_Z }

static func _idx(face: int, u: int, v: int, res: int) -> int:
	var n := res + 1
	return face * n * n + v * n + u

# More uniform than simple normalize(). Produces a "spherified cube".
static func _spherify(p: Vector3) -> Vector3:
	var x := p.x
	var y := p.y
	var z := p.z
	var x2 := x * x
	var y2 := y * y
	var z2 := z * z

	var sx := x * sqrt(max(0.0, 1.0 - (y2 * 0.5) - (z2 * 0.5) + (y2 * z2) / 3.0))
	var sy := y * sqrt(max(0.0, 1.0 - (z2 * 0.5) - (x2 * 0.5) + (z2 * x2) / 3.0))
	var sz := z * sqrt(max(0.0, 1.0 - (x2 * 0.5) - (y2 * 0.5) + (x2 * y2) / 3.0))
	return Vector3(sx, sy, sz).normalized()

# Returns vertices in a layout that is easy to index:
# vertex_index = face*(res+1)^2 + v*(res+1) + u
static func all_points(res: int) -> PackedVector3Array:
	var out := PackedVector3Array()
	if res < 1:
		return out

	var n := res + 1
	out.resize(6 * n * n)

	for face in range(6):
		for v in range(n):
			var b := -1.0 + 2.0 * float(v) / float(res) # [-1,1]
			for u in range(n):
				var a := -1.0 + 2.0 * float(u) / float(res) # [-1,1]

				var cube := Vector3.ZERO
				match face:
					Face.POS_X: cube = Vector3( 1.0,  b, -a)
					Face.NEG_X: cube = Vector3(-1.0,  b,  a)
					Face.POS_Y: cube = Vector3( a,  1.0, -b)
					Face.NEG_Y: cube = Vector3( a, -1.0,  b)
					Face.POS_Z: cube = Vector3( a,  b,  1.0)
					Face.NEG_Z: cube = Vector3(-a,  b, -1.0)

				var p := _spherify(cube) # unit sphere
				out[_idx(face, u, v, res)] = p

	return out

# Returns an index buffer (triples = triangles) for the vertices from all_points(res).
# This triangulates each cube face as a regular grid. Edges are duplicated; for a watertight mesh,
# either weld vertices later or add explicit edge-stitching.
static func triangle_indices(res: int) -> PackedInt32Array:
	var out := PackedInt32Array()
	if res < 1:
		return out

	var pts := all_points(res)
	var n := res + 1

	for face in range(6):
		for v in range(res):
			for u in range(res):
				var a := _idx(face, u,     v,     res)
				var b := _idx(face, u + 1, v,     res)
				var c := _idx(face, u + 1, v + 1, res)
				var d := _idx(face, u,     v + 1, res)

				# Two triangles per quad: (a,b,c) and (a,c,d)
				_push_oriented_triangle(out, pts, a, b, c)
				_push_oriented_triangle(out, pts, a, c, d)

	return out

static func _push_oriented_triangle(out: PackedInt32Array, pts: PackedVector3Array, a: int, b: int, c: int) -> void:
	var pa := pts[a]
	var pb := pts[b]
	var pc := pts[c]
	var n := (pb - pa).cross(pc - pa)
	var center := (pa + pb + pc) / 3.0
	if n.dot(center) > 0.0:
		var tmp := b
		b = c
		c = tmp
	out.push_back(a)
	out.push_back(b)
	out.push_back(c)
