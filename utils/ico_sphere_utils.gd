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

const HEX_TRI_LAYOUT_4TRI: PackedInt32Array = [
	0, 1, 2,
	0, 2, 3,
	0, 3, 4,
	0, 4, 5,
]

# Reversed winding (swap b<->c in each tri)
const HEX_TRI_LAYOUT_4TRI_CCW: PackedInt32Array = [
	0, 2, 1,
	0, 3, 2,
	0, 4, 3,
	0, 5, 4,
]

# Pentagon (5 verts) triangulated into 3 triangles:
# (0,1,2), (0,2,3), (0,3,4)
const PENT_TRI_LAYOUT_3TRI: PackedInt32Array = [
	0, 1, 2,
	0, 2, 3,
	0, 3, 4,
]

# Reversed winding (swap b<->c in each tri)
const PENT_TRI_LAYOUT_3TRI_CCW: PackedInt32Array = [
	0, 2, 1,
	0, 3, 2,
	0, 4, 3,
]


const HEX_UV_POINTY_R1: PackedVector2Array = [
	Vector2(0.5, 0.0),                 # top
	Vector2(0.5 + 0.4330127019, 0.25),  # top-right  (sqrt(3)/4, 1/4)
	Vector2(0.5 + 0.4330127019, 0.75),  # bottom-right
	Vector2(0.5, 1.0),                 # bottom
	Vector2(0.5 - 0.4330127019, 0.75),  # bottom-left
	Vector2(0.5 - 0.4330127019, 0.25),  # top-left
]

const hex_uv_flipped: PackedVector2Array = [
	Vector2(0.5, 1.0),                 # top
	Vector2(0.5 + 0.4330127019, 0.75),  # top-right  (sqrt(3)/4, 1/4)
	Vector2(0.5 + 0.4330127019, 0.25),  # bottom-right
	Vector2(0.5, 0.0),                 # bottom
	Vector2(0.5 - 0.4330127019, 0.25),  # bottom-left
	Vector2(0.5 - 0.4330127019, 0.75),  # top-left
]

const PENT_UV_POINTY_R1: PackedVector2Array = [
	Vector2(0.5, 0.0),                    # top
	Vector2(0.9755282581, 0.3454917419),   # top-right
	Vector2(0.7938926261, 0.9045082581),   # bottom-right
	Vector2(0.2061073739, 0.9045082581),   # bottom-left
	Vector2(0.0244717419, 0.3454917419),   # top-left
]

# Vertical flip (v -> 1 - v), order unchanged (same pattern as your hex_uv_flipped)
const PENT_UV_POINTY_R1_FLIPPED: PackedVector2Array = [
	Vector2(0.5, 1.0),                    # top
	Vector2(0.9755282581, 0.6545082581),   # top-right
	Vector2(0.7938926261, 0.0954917419),   # bottom-right
	Vector2(0.2061073739, 0.0954917419),   # bottom-left
	Vector2(0.0244717419, 0.6545082581),   # top-left
]

const top_mid_angle := 4*TAU / 40.0
const bot_mid_angle := 0*TAU / 40.0

const PENT_START_ANGLE: PackedFloat32Array = [
		1*TAU / 40.0,        # 0  (N)   = -36°
	  top_mid_angle,  # 1  (U0)  = +126°
	 top_mid_angle,  # 2  (U1)
	 top_mid_angle,  # 3  (U2)
	 top_mid_angle,  # 4  (U3)
	 top_mid_angle,  # 5  (U4)
	bot_mid_angle,  # 6  (D0)  = -126°
	bot_mid_angle,  # 7  (D1)
	bot_mid_angle,  # 8  (D2)
	bot_mid_angle,  # 9  (D3)
	bot_mid_angle,  # 10 (D4)
	 3*TAU / 40.0 + TAU_DIV_5,#-3.0 * TAU / 10.0,  # 11 (S)   = -108°
]

static func hex_corner_radius_unit_sphere(subdiv: int) -> float:
	# "Hex radius" = center-to-corner (circumradius) for a tight planar hex grid,
	# using typical neighbor spacing from the subdivided icosahedron edge.
	var alpha := acos(1.0 / sqrt(5.0)) # base icosahedron edge angle on unit sphere
	var d := 2.0 * sin(alpha / (2.0 * float(subdiv))) # chord length between adjacent centers
	return d / sqrt(3.0)
	
static func pent_corner_radius_unit_sphere(subdiv: int) -> float:
	var alpha := acos(1.0 / sqrt(5.0))
	var a := sin(alpha / (2.0 * float(subdiv))) # inradius
	return a / cos(PI / 5.0)                    # circumradius
	
static func pent_angular_radious(subdiv: int)-> float:
	var corner_radius_chord := pent_corner_radius_unit_sphere(subdiv)
	var half :float= clamp(corner_radius_chord * 0.5, 0.0, 1.0)
	var angular_rad := 2.0 * asin(half)
	return angular_rad
	
	
static func hex_inradius_unit_sphere(subdiv: int) -> float:
	var alpha := acos(1.0 / sqrt(5.0))
	return sin(alpha / (2.0 * float(subdiv))) # = d/2

static func is_pentagon_index(subdiv : int, n: int) -> bool:
	var total := amount_of_points(subdiv)
	assert ( subdiv > 0 , "is_pentagon_index : wrong subdiv" )
	assert (n >= 0 and  n < total , "is_pentagon_index : wrong n :" + str(n) )
	# Poles are always pentagons, also if subdiv = 1, all points are pentagon corners:
	if subdiv == 1 or n == 0 or n == total - 1:
		return true
		
	# Per "up" face block size and the offset of (u=subdiv, v=0) within that block.
	# Use integer arithmetic (avoid float division).
	var t := (subdiv * (subdiv + 1)) >> 1          # subdiv*(subdiv+1)/2
	var b := (subdiv * (subdiv - 1)) >> 1          # subdiv*(subdiv-1)/2
	
# 	The 10 ring pentagon vertices are the B-corners in planes 0..9:
	# index = 1 + plane_rn*t + b, plane_rn in [0..9]
	var first := 1 + b
	var limit := 1 + 10 * t                        # one past the last index covered by planes 0..9
	
	if n < first or n >= limit:
		return false

		
	return ((n - 1 - b) % t) == 0
		
	

static func amount_of_points(subdiv : int) -> int:
	"""
	Expected amount of points without doubles is 10*n^2+2
	Starting from icosahedron : 12 vertices, 30 edges, 20 faces.
	
	"""
	return 10 * subdiv* subdiv + 2

static func plane_04(plane_rn: int, u: int, v: int)-> Vector2i:
	var max_j := u * 5
	var j := plane_rn*u+v
	j = j if j < max_j else 0
	return Vector2i(u,j)
	
static func plane_510(plane_rn: int, u: int, v: int, subdiv : int)-> Vector2i:
	var max_nr := subdiv * 5
	return Vector2i(subdiv+u,(max_nr +(plane_rn-5)*subdiv+v - u) % max_nr )
	
static func plane_1014(plane_rn: int, u: int, v: int, subdiv : int)-> Vector2i:
	var max_nr := subdiv * 5
	return Vector2i(subdiv+u,((plane_rn-10)*subdiv+v) % max_nr )
	

static func plane_1520(plane_rn: int, u: int, v: int, subdiv : int)-> Vector2i:
	var max_j := (subdiv - u) * 5
	var j := (plane_rn -15 )*subdiv + v 
	j = j if j < max_j else 0
	return Vector2i(2 * subdiv + u, j)	


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
static func _point_on_face_from_uv(A: Vector3, B: Vector3, C: Vector3, u: int, v: int, subdiv_: int) -> Vector3:
	var fu := float(u) / float(subdiv_)
	var fv := float(v) / float(subdiv_)
	var wa := 1.0 - fu
	var wb := fu - fv
	var wc := fv
	return _point_on_face_from_weights(A,B,C,wa,wb,wc)
	
static func _point_on_face_from_weights(A: Vector3, B: Vector3, C: Vector3, wa: float, wb: float, wc: float) -> Vector3:
	# wa+wb+wc should be 1 (up to tiny floating error)
	return (A * wa + B * wb + C * wc).normalized()
	
	
static func hex_corners_on_face(A: Vector3, B: Vector3, C: Vector3, subdiv: int, u: int, v: int) -> PackedVector3Array:
	
	assert(subdiv >= 1)
	
	# cube coords (i,j,k) with i+j+k = s
	var i := u - v
	var j := v
	var k := subdiv - u
	# 1/3 step in cube coords:
	const ONE_THIRD := 1.0 / 3.0
	const TWO_THIRDS := 2.0 / 3.0
	
	# Corner cube coords, ordered "pointy-top" toward A (max k first)
	var corners_ijk :PackedVector3Array= [
		Vector3(float(i) - ONE_THIRD, float(j) - ONE_THIRD, float(k) + TWO_THIRDS),
		Vector3(float(i) - TWO_THIRDS, float(j) + ONE_THIRD, float(k) + ONE_THIRD),
		Vector3(float(i) - ONE_THIRD, float(j) + TWO_THIRDS, float(k) - ONE_THIRD),
		Vector3(float(i) + ONE_THIRD, float(j) + ONE_THIRD, float(k) - TWO_THIRDS),
		Vector3(float(i) + TWO_THIRDS, float(j) - ONE_THIRD, float(k) - ONE_THIRD),
		Vector3(float(i) + ONE_THIRD, float(j) - TWO_THIRDS, float(k) + ONE_THIRD),
	]
	
	var out := PackedVector3Array()
	out.resize(6)
	var s := float(subdiv)
	for idx in range(6):
		var ijk := corners_ijk[idx]
		var wb := ijk.x / s  # B weight
		var wc := ijk.y / s  # C weight
		var wa := ijk.z / s  # A weight
		out[idx] = _point_on_face_from_weights(A, B, C, wa, wb, wc)
	
	return out 



	
	
	
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
	subdiv: int,
	vertices: PackedVector3Array,
	normals: PackedVector3Array,
	uvs : PackedVector2Array
) -> void:
		var p_uv := point_and_uv_on_face(A, B, C, u, v, subdiv)
		var p: Vector3 = p_uv[0]
		var uv: Vector2 = p_uv[1]
		vertices.append(p)
		normals.append(p) # already unit length
		uvs.append(uv)
		
		
static func _append_point_unique_uv(
	u: int,
	v: int,
	A: Vector3,
	B: Vector3,
	C: Vector3,
	subdiv: int,
	vertices: PackedVector3Array,
	normals: PackedVector3Array
) -> void:
	var p := _point_on_face_from_uv(A, B, C, u, v, subdiv)
	vertices.append(p)
	normals.append(p) # already unit length


static func _append_face_vertices_only_up(
	plane_rn: int,
	subdiv: int,
	vertices: PackedVector3Array,
	) -> void:
	var abc := _get_icosahedral_triangle_corners(plane_rn)
	var A: Vector3 = abc[0]
	var B: Vector3 = abc[1]
	var C: Vector3 = abc[2]
	
	for u in range(1, subdiv + 1): # skip first row (u == 0)
		for v in range(u):          # skip last point in row (v == u)
			var p := _point_on_face_from_uv(A, B, C, u, v, subdiv)
			vertices.append(p)
			
			
static func _append_face_hexagons_up(
	plane_rn: int,
	subdiv: int,
	vertices: PackedVector3Array,
	indices  : PackedInt32Array,
	normals : PackedVector3Array,
	uvs:PackedVector2Array) -> void:
	var abc := _get_icosahedral_triangle_corners(plane_rn)
	var A: Vector3 = abc[0]
	var B: Vector3 = abc[1]
	var C: Vector3 = abc[2]
	
	for u in range(1, subdiv + 1): # skip first row (u == 0)
		var v_start := 1 if u == subdiv else 0
		for v in range(v_start, u):   # skip first point if corner and last point in row (v == u)
			var base_vertex_index := vertices.size()
			var new_vertices := hex_corners_on_face(A,B,C,subdiv,u,v)
			vertices.append_array(new_vertices)
			normals.append_array(new_vertices)
			for i in range(HEX_TRI_LAYOUT_4TRI_CCW.size()):
				indices.append(base_vertex_index + HEX_TRI_LAYOUT_4TRI_CCW[i])
			uvs.append_array(HEX_UV_POINTY_R1)
			
			
	
			
static func _append_face_vertices_only_down(
	plane_rn: int,
	subdiv: int,
	vertices: PackedVector3Array,
	) -> void:
	var abc := _get_icosahedral_triangle_corners(plane_rn)
	var A: Vector3 = abc[2]
	var B: Vector3 = abc[0]
	var C: Vector3 = abc[1]
	#print("plane: ", plane_rn)
	for u in range(1, subdiv + 1): # skip first row (u == 0)
		var ud := subdiv - u
		#var v_start := 1 if ud == subdiv else 0 # this is always 0 with current loops# no need?
		for v in range(ud):          # skip last point in row (v == u)
			#print(" - point: ", ud, ", ",  v)
			var p := _point_on_face_from_uv(A, B, C, ud, v, subdiv)
			vertices.append(p)
			
static func _append_face_hexagons_down(
	plane_rn: int,
	subdiv: int,
	vertices: PackedVector3Array,
	indices  : PackedInt32Array,
	normals : PackedVector3Array,
	uvs:PackedVector2Array) -> void:
	var abc := _get_icosahedral_triangle_corners(plane_rn)
	var A: Vector3 = abc[2]
	var B: Vector3 = abc[0]
	var C: Vector3 = abc[1]
	
	for u in range(1, subdiv + 1): # skip first row (u == 0)
		var ud := subdiv - u
		for v in range(ud):          # skip last point in row (v == u)
			var base_vertex_index := vertices.size()
			var new_vertices := hex_corners_on_face(A,B,C,subdiv,ud,v)
			vertices.append_array(new_vertices)
			normals.append_array(new_vertices)
			for i in range(HEX_TRI_LAYOUT_4TRI.size()):
				indices.append(base_vertex_index + HEX_TRI_LAYOUT_4TRI[i])
			uvs.append_array(hex_uv_flipped)
			

	
	
static func _append_face_shared_uv(
	plane_rn: int,
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
			_append_point_shared_uv(u,v,A,B,C,subdiv,vertices,normals,uvs)
	for u in range(subdiv):
		for v in range(u + 1):
			# Emit indices for the triangular grid.
			# For each cell between row u and u+1, create 1 or 2 triangles.
			_append_triangle_indices_shared(u,v,base,flip,indices)
			
			
static func _append_face_unique_uv(
	plane_rn: int,
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
				subdiv, flip,
				vertices, normals, uvs, indices
			)

			# Micro-triangle 2 (if present): (u,v) (u+1,v+1) (u,v+1)
			if v < u:
				_append_micro_triangle_unique_uv(
					u, v,
					u + 1, v + 1,
					u, v + 1,
					A, B, C,
					subdiv, flip,
					vertices, normals, uvs, indices
				)
			
			
static func _append_micro_triangle_unique_uv(
	u0: int, v0: int,
	u1: int, v1: int,
	u2: int, v2: int,
	A: Vector3, B: Vector3, C: Vector3,
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

	_append_point_unique_uv(u0, v0, A, B, C, subdiv, vertices, normals)
	uvs.append(uv0)

	_append_point_unique_uv(u1, v1, A, B, C, subdiv, vertices, normals)
	uvs.append(uv1)

	_append_point_unique_uv(u2, v2, A, B, C, subdiv, vertices, normals)
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


	
static func build_icosphere(subdiv: int, unique_uv: bool , arrays: Array) -> void:
	assert(subdiv >= 1)

	var vertices : PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals : PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var indices : PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var uvs : PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	
	if unique_uv:		
		for plane_rn in range(20):			
			_append_face_unique_uv(plane_rn, subdiv, vertices, normals, uvs, indices)
	else:
		for plane_rn in range(20):
			_append_face_shared_uv(plane_rn,subdiv,vertices,normals,uvs,indices)
	
	
static func build_icosphere_only_vertices(subdiv: int) -> PackedVector3Array:
	var vertices := PackedVector3Array()
	# Emit poles separately (otherwise they'd be skipped by the "skip last point" rule).
	vertices.append(N)
	for plane_rn in range(0, 10):
		_append_face_vertices_only_up(plane_rn,subdiv, vertices)
	for plane_rn in range(10, 20):
		_append_face_vertices_only_down(plane_rn, subdiv, vertices)
	vertices.append(S)
	return vertices
	

static func build_icosphere_hexagons(subdiv: int, arrays : Array)-> void:
	assert(subdiv >= 1)
	var vertices :PackedVector3Array= arrays[Mesh.ARRAY_VERTEX]
	var normals :PackedVector3Array= arrays[Mesh.ARRAY_NORMAL]
	var indices :PackedInt32Array= arrays[Mesh.ARRAY_INDEX]
	var uvs :PackedVector2Array= arrays[Mesh.ARRAY_TEX_UV]
	for plane_nr in range(0, 10):
		_append_face_hexagons_up(plane_nr,subdiv,vertices,indices,normals,uvs)
	for plane_nr in range(10,20):
		_append_face_hexagons_down(plane_nr,subdiv,vertices,indices,normals,uvs)


		
static func pentagon_centers() -> PackedVector3Array:
	var out := PackedVector3Array()
	out.resize(12)

	out[0] = N
	for i in range(5):
		out[1 + i] = U[i]
	for i in range(5):
		out[6 + i] = D[i]
	out[11] = S
	return out

static func pentagon_corners_from_center_unit_sphere(
	center_normalized: Vector3,
	angular_rad: float,
	start_angle: float
) -> PackedVector3Array:
	# Build a stable tangent basis using global UP as reference.
	# If n is too close to UP/DOWN, fall back to FORWARD.
	var ref := Vector3.UP
	
	if abs(center_normalized.dot(ref)) > 0.99:
		ref = Vector3.FORWARD
	# t0 is "up" direction in tangent plane (deterministic)
	var t0 := (ref - center_normalized * center_normalized.dot(ref)).normalized()
	var t1 := center_normalized.cross(t0).normalized() # right-handed basis around n
	
	var ca := cos(angular_rad)
	var sa := sin(angular_rad)
	const STEP := TAU / 5.0
	
	var out := PackedVector3Array()
	out.resize(5)
	for i in range(5):
		var theta := start_angle + float(i) * STEP
		var dir := (t0 * cos(theta) + t1 * sin(theta)).normalized()
		out[i] = (center_normalized * cos(angular_rad) + dir * sin(angular_rad)).normalized()
		#out[i] = center_normalized + dir * angular_rad
	return out
		
	
	
static func append_pentagons(subdiv:int, arrays: Array) -> void:
	
	assert(subdiv >= 1)
	var vertices :PackedVector3Array= arrays[Mesh.ARRAY_VERTEX]
	var normals :PackedVector3Array= arrays[Mesh.ARRAY_NORMAL]
	var indices :PackedInt32Array= arrays[Mesh.ARRAY_INDEX]
	var uvs :PackedVector2Array= arrays[Mesh.ARRAY_TEX_UV]
	var angular_rad := pent_angular_radious(subdiv) * 0.7
	var points := pentagon_centers()
	for i in range(6):
		var p:= points[i]
		var a := PENT_START_ANGLE[i]
		var pentagon := pentagon_corners_from_center_unit_sphere(p,angular_rad,a)
		var base_vertex_index := vertices.size()
		
		vertices.append_array(pentagon)
		normals.append_array(pentagon)
		for j in range(PENT_TRI_LAYOUT_3TRI_CCW.size()):
			indices.append(base_vertex_index + PENT_TRI_LAYOUT_3TRI_CCW[j])
		uvs.append_array(PENT_UV_POINTY_R1)
			
	for i in range(6,12):
		var p:= points[i]
		var a := PENT_START_ANGLE[i]
		var pentagon := pentagon_corners_from_center_unit_sphere(p,angular_rad,a)
		var base_vertex_index := vertices.size()
		vertices.append_array(pentagon)
		normals.append_array(pentagon)
		for j in range(PENT_TRI_LAYOUT_3TRI_CCW.size()):
			indices.append(base_vertex_index + PENT_TRI_LAYOUT_3TRI_CCW[j])
		uvs.append_array(PENT_UV_POINTY_R1_FLIPPED)
			
		
	

	
