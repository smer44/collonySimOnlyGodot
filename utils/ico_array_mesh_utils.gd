extends RefCounted
class_name IcoSphereUtils

const INV_SQRT5: float = 1.0 / sqrt(5.0)
const Y: float = INV_SQRT5
const R: float = 2.0 * INV_SQRT5

const N: Vector3 = Vector3(0.0,  1.0, 0.0)
const S: Vector3 = Vector3(0.0, -1.0, 0.0)

const TAU_DIV_5 := TAU / 5.0
const TAU_DIV_10 := TAU / 10.0


# Upper ring (y = +1/sqrt(5)), angles: 0, 72, 144, 216, 288 degrees
const U: PackedVector3Array = [
	Vector3(R * cos(0.0), Y, R * sin(0.0)),
	Vector3(R * cos(TAU_DIV_5), Y, R * sin(TAU_DIV_5)),
	Vector3(R * cos(2.0 * TAU_DIV_5), Y, R * sin(2.0 * TAU_DIV_5)),
	Vector3(R * cos(3.0 * TAU_DIV_5), Y, R * sin(3.0 * TAU_DIV_5)),
	Vector3(R * cos(4.0 * TAU_DIV_5), Y, R * sin(4.0 * TAU_DIV_5)),
]

const D: PackedVector3Array = [
	Vector3(R * cos((0.0 * TAU_DIV_5) + TAU_DIV_10), -Y, R * sin((0.0 * TAU_DIV_5) + TAU_DIV_10)),
	Vector3(R * cos((1.0 * TAU_DIV_5) + TAU_DIV_10), -Y, R * sin((1.0 * TAU_DIV_5) + TAU_DIV_10)),
	Vector3(R * cos((2.0 * TAU_DIV_5) + TAU_DIV_10), -Y, R * sin((2.0 * TAU_DIV_5) + TAU_DIV_10)),
	Vector3(R * cos((3.0 * TAU_DIV_5) + TAU_DIV_10), -Y, R * sin((3.0 * TAU_DIV_5) + TAU_DIV_10)),
	Vector3(R * cos((4.0 * TAU_DIV_5) + TAU_DIV_10), -Y, R * sin((4.0 * TAU_DIV_5) + TAU_DIV_10)),
]


static func _wrap_index_5(x: int) -> int:
	return (x % 5 + 5) % 5

static func _get_icosahedral_triangle_corners(plane_rn: int) -> PackedVector3Array:
	# Regular icosahedron on radius-1 sphere.
	# Two rings at y = ±(1/sqrt(5)), ring radius r = 2/sqrt(5), with 36° twist.

	assert(plane_rn >= 0 and plane_rn < 20)



	# Planes 0..4: top cap (up-triangles)
	# A = N (apex), B = U[k], C = U[k+1]
	match plane_rn / 5:
		0:
			var k := plane_rn
			return PackedVector3Array([N, U[_wrap_index_5(k)], U[_wrap_index_5(k + 1)]])
		1:
			var k := plane_rn - 5
			return PackedVector3Array([U[_wrap_index_5(k)], D[_wrap_index_5(k - 1)], D[_wrap_index_5(k)]])
		2:
			var k := plane_rn - 10
			return PackedVector3Array([U[_wrap_index_5(k)], U[_wrap_index_5(k + 1)], D[_wrap_index_5(k)]])

		_:
			var k := plane_rn - 15
			return PackedVector3Array([D[_wrap_index_5(k)], D[_wrap_index_5(k + 1)], S])
	


static func _triangle_uv_to_index(u: int, v: int) -> int:
	return (u * (u + 1)) / 2 + v

	# Point on face using your (u,v) convention, then projected to radius 1.
static func point_on_face(A: Vector3, B: Vector3, C: Vector3, u: int, v: int, subdiv_: int) -> Vector3:
	var fu := float(u) / float(subdiv_)
	var fv := float(v) / float(subdiv_)
	var wa := 1.0 - fu
	var wb := fu - fv
	var wc := fv
	return (A * wa + B * wb + C * wc).normalized()
	
	
static func point_and_uv_on_face(A: Vector3, B: Vector3, C: Vector3, u: int, v: int, subdiv_: int) -> Array:
	var fu := float(u) / float(subdiv_)
	var fv := float(v) / float(subdiv_)
	var wa := 1.0 - fu
	var wb := fu - fv
	var wc := fv
	var p := (A * wa + B * wb + C * wc).normalized()
	# Per-face UVs in [0,1]:
	# A=(0,0), B=(1,0), C=(0,1)
	var uv := Vector2(wb, wc)
	return [p, uv]
	
	
static func _append_point_shared_uv(
	u:int, 
	v: int,
	A: Vector3,
	B: Vector3,
	C: Vector3,
	scale: float,
	subdiv: int,
	vertices: PackedVector3Array,
	normals: PackedVector3Array,
	uvs : PackedVector2Array
) -> void:
		var p_uv := point_and_uv_on_face(A, B, C, u, v, subdiv)
		var p: Vector3 = p_uv[0]
		var uv: Vector2 = p_uv[1]
		vertices.append(p * scale)
		normals.append(p) # already unit length
		uvs.append(uv)
		
		
static func _append_point_unique_uv(
	u: int,
	v: int,
	A: Vector3,
	B: Vector3,
	C: Vector3,
	scale: float,
	subdiv: int,
	vertices: PackedVector3Array,
	normals: PackedVector3Array
) -> void:
	var p := point_on_face(A, B, C, u, v, subdiv)
	vertices.append(p * scale)
	normals.append(p) # already unit length
	
static func _append_face_shared_uv(
	plane_rn: int,
	scale: float,
	subdiv: int,
	vertices: PackedVector3Array,
	normals: PackedVector3Array,
	uvs: PackedVector2Array,
	indices: PackedInt32Array
) -> void:
	var abc := _get_icosahedral_triangle_corners(plane_rn)
	var A: Vector3 = abc[0]
	var B: Vector3 = abc[1]
	var C: Vector3 = abc[2]

	# Determine if this plane's (A,B,C) order is inward; if so, flip triangle winding.
	var face_n := (B - A).cross(C - A)
	var face_c := (A + B + C) / 3.0
	var flip := face_n.dot(face_c) > 0.0

	var base := vertices.size()

	# 2) Extracted nested (u,v) vertex loop into a helper (logic unchanged).
	for u in range(subdiv + 1):
		for v in range(u + 1):
			_append_point_shared_uv(u,v,A,B,C,scale,subdiv,vertices,normals,uvs)
	for u in range(subdiv):
		for v in range(u + 1):
			# Emit indices for the triangular grid.
			# For each cell between row u and u+1, create 1 or 2 triangles.
			_append_triangle_indices_shared(u,v,base,flip,indices)
			
			
static func _append_face_unique_uv(
	plane_rn: int,
	scale: float,
	subdiv: int,
	vertices: PackedVector3Array,
	normals: PackedVector3Array,
	uvs: PackedVector2Array,
	indices: PackedInt32Array
) -> void:
	var abc := _get_icosahedral_triangle_corners(plane_rn)
	var A: Vector3 = abc[0]
	var B: Vector3 = abc[1]
	var C: Vector3 = abc[2]

	# Determine if this plane's (A,B,C) order is inward; if so, flip triangle winding.
	var face_n := (B - A).cross(C - A)
	var face_c := (A + B + C) / 3.0
	var flip := face_n.dot(face_c) > 0.0

	# Tessellate the face into micro-triangles and emit each as 3 unique vertices.
	
	for u in range(subdiv):
		for v in range(u + 1):
			# Micro-triangle 1: (u,v) (u+1,v) (u+1,v+1)
			_append_micro_triangle_unique_uv(
				u, v,
				u + 1, v,
				u + 1, v + 1,
				A, B, C,
				scale, subdiv, flip,
				vertices, normals, uvs, indices
			)

			# Micro-triangle 2 (if present): (u,v) (u+1,v+1) (u,v+1)
			if v < u:
				_append_micro_triangle_unique_uv(
					u, v,
					u + 1, v + 1,
					u, v + 1,
					A, B, C,
					scale, subdiv, flip,
					vertices, normals, uvs, indices
				)
			
			
static func _append_micro_triangle_unique_uv(
	u0: int, v0: int,
	u1: int, v1: int,
	u2: int, v2: int,
	A: Vector3, B: Vector3, C: Vector3,
	scale: float,
	subdiv: int,
	flip: bool,
	vertices: PackedVector3Array,
	normals: PackedVector3Array,
	uvs: PackedVector2Array,
	indices: PackedInt32Array
) -> void:
	# Canonical UVs for every micro-triangle
	var uv0 := Vector2(0.0, 0.0)
	var uv1 := Vector2(1.0, 0.0)
	var uv2 := Vector2(0.0, 1.0)

	# If winding flips, swap vertices 1 and 2 and swap their UVs to avoid mirroring.
	if flip:
		var tu := u1; u1 = u2; u2 = tu
		var tv := v1; v1 = v2; v2 = tv
		var tuv := uv1; uv1 = uv2; uv2 = tuv

	var base := vertices.size()

	_append_point_unique_uv(u0, v0, A, B, C, scale, subdiv, vertices, normals)
	uvs.append(uv0)

	_append_point_unique_uv(u1, v1, A, B, C, scale, subdiv, vertices, normals)
	uvs.append(uv1)

	_append_point_unique_uv(u2, v2, A, B, C, scale, subdiv, vertices, normals)
	uvs.append(uv2)

	indices.append(base)
	indices.append(base + 1)
	indices.append(base + 2)


static func _append_triangle_indices_shared(u:int,v:int,base: int, flip: bool,indices: PackedInt32Array)-> void:
	var a := base + _triangle_uv_to_index(u, v)
	var b := base + _triangle_uv_to_index(u + 1, v)
	var c := base + _triangle_uv_to_index(u + 1, v + 1)
	if flip:
		indices.append(a); indices.append(c); indices.append(b)
	else:
		indices.append(a); indices.append(b); indices.append(c)
	#add_tri(indices, a, b, c, flip)

	if v < u:
		var d := base + _triangle_uv_to_index(u, v + 1)
		## a,c,d
		if flip:
			indices.append(a); indices.append(d); indices.append(c)
		else:
			indices.append(a); indices.append(c); indices.append(d)
			#add_tri(indices, a, c, d, flip)


	
static func build_icosphere(scale: float, subdiv: int, unique_uv: bool) -> Array:
	assert(subdiv >= 1)

	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	var uvs := PackedVector2Array()
	
	if unique_uv:		
		for plane_rn in range(20):			
			_append_face_unique_uv(plane_rn, scale, subdiv, vertices, normals, uvs, indices)
	else:
		for plane_rn in range(20):
			_append_face_shared_uv(plane_rn,scale,subdiv,vertices,normals,uvs,indices)
			

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices

	#var mesh := ArrayMesh.new()
	#mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return arrays
