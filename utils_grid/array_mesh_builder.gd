extends RefCounted
class_name ArrayMeshBuilder

const dirs := [
		Vector3i( 1, 0, 0), # +X
		Vector3i(-1, 0, 0), # -X
		Vector3i( 0, 1, 0), # +Y
		Vector3i( 0,-1, 0), # -Y
		Vector3i( 0, 0, 1), # +Z
		Vector3i( 0, 0,-1)  # -Z
	]
	
const frames := [
		[ Vector3( 1, 0, 0),  Vector3( 0, 0,-1), Vector3( 0, 1, 0) ], # +X
		[  Vector3(-1, 0, 0),  Vector3( 0, 0, 1),  Vector3( 0, 1, 0) ], # -X
		[  Vector3( 0, 1, 0),  Vector3( 1, 0, 0), Vector3( 0, 0,-1) ], # +Y
		[  Vector3( 0,-1, 0),  Vector3( 1, 0, 0),  Vector3( 0, 0, 1) ], # -Y
		[  Vector3( 0, 0, 1),  Vector3( 1, 0, 0),  Vector3( 0, 1, 0) ], # +Z
		[  Vector3( 0, 0,-1),  Vector3(-1, 0, 0),  Vector3( 0, 1, 0) ]  # -Z
	]	


static func new_grid_array_mesh(w: int, h: int, w_step : float, h_step : float) -> ArrayMesh:
	var arrays := ArrayMeshBuilder.build_grid_plane(w,h,w_step,h_step)
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

static func build_grid_plane(w: int, h: int, w_step : float, h_step : float) -> Array:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices_and_uv :=build_grid_plane_vertices_and_uv(w,h,w_step,h_step)
	var indices := build_grid_plane_indexes(w,h,w_step,h_step)	
	arrays[Mesh.ARRAY_VERTEX] = vertices_and_uv[0]
	arrays[Mesh.ARRAY_TEX_UV] = vertices_and_uv[1]
	arrays[Mesh.ARRAY_INDEX] = indices
	return arrays 	

static func build_grid_plane_vertices_and_uv(w: int, h: int, w_step : float, h_step : float) -> Array:
	
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	
	vertices.resize(w * h)
	uvs.resize(w * h)
	
	var i := 0
	for gy in range(h):
		var z := float(gy) * h_step
		for gx in range(w):
			var x := float(gx) * w_step			
			vertices[i] = Vector3(x, 0.0, z)
			# UVs sample at cell *centers*
			#if you want layout the same uv for any cell do not delete on w, h:
			var u := (float(gx) + 0.5) / float(w)
			var v := (float(gy) + 0.5) / float(h)
			uvs[i] = Vector2(u, v)
			i += 1
			
	return [vertices, uvs] 
	#grid_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	#print("Build grid mesh done : vertices :" , arrays[Mesh.ARRAY_VERTEX] )
	#print("Indexes:" , arrays[Mesh.ARRAY_INDEX] )


static func build_grid_plane_indexes(w: int, h: int, w_step : float, h_step : float) -> PackedInt32Array:
	var indices := PackedInt32Array()
	# Build triangle indices over the (w x h) vertex grid
	for gy in range(h - 1):
		for gx in range(w - 1):
			var a := gy * w + gx
			var b := a + 1
			var c := a + w
			var d := c + 1
			# Two triangles per quad: a,c,b and b,c,d
			indices.push_back(a) 
			indices.push_back(b)
			indices.push_back(c) 

			
			indices.push_back(b)
			indices.push_back(d)
			indices.push_back(c)
	return indices	


static func build_culled_cube_mesh_from_points(
	points: Array[Vector3],
	grid_size: float = 1.0
	) -> ArrayMesh:
	assert(grid_size > 0.0)
	var mesh := ArrayMesh.new()
	if points.is_empty():
		return mesh
		
	var half := grid_size * 0.5
	# Occupancy set keyed by integer grid coords
	var occ: Dictionary = {} # Vector3i -> true
	for p in points:
		var sp := p.snapped(Vector3.ONE * grid_size)
		var k := Vector3i(
			int(round(sp.x / grid_size)),
			int(round(sp.y / grid_size)),
			int(round(sp.z / grid_size))
		)
		occ[k] = true
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var idx: int = 0
	
	for k in occ.keys():
		var center := Vector3(k.x, k.y, k.z) * grid_size
		for i in range(6):
			var nk: Vector3i = k + dirs[i]
			if occ.has(nk):
				continue # neighbor exists -> internal face, skip
			var n: Vector3 = frames[i][0]
			var u: Vector3 = frames[i][1]
			var v: Vector3 = frames[i][2]
			
			# Face vertices (quad) in CCW order relative to outward normal n
			var p0 := center + n * half + (-u - v) * half
			var p1 := center + n * half + (-u + v) * half
			var p2 := center + n * half + ( u + v) * half
			var p3 := center + n * half + ( u - v) * half
			
			vertices.append(p0)
			vertices.append(p1)
			vertices.append(p2)
			vertices.append(p3)
			
			normals.append(n)
			normals.append(n)
			normals.append(n)
			normals.append(n)
			
			# Simple per-face UVs (optional but useful)
			uvs.append(Vector2(0, 0))
			uvs.append(Vector2(0, 1))
			uvs.append(Vector2(1, 1))
			uvs.append(Vector2(1, 0))
			
			# Two triangles: (0,1,2) and (0,2,3)
			
			indices.append(idx + 0)
			indices.append(idx + 1)
			indices.append(idx + 2)
			indices.append(idx + 0)
			indices.append(idx + 2)
			indices.append(idx + 3)
			idx += 4
			
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
		

static func _lex_less(a: Vector3i, b: Vector3i) -> bool:
	if a.x != b.x: return a.x < b.x
	if a.y != b.y: return a.y < b.y
	return a.z < b.z

static func build_boundary_edge_mesh(
		points: Array[Vector3],
		grid_size: float = 0.3,
		use_26_neighbors_for_culling: bool = true,
		use_26_neighbors_for_edges: bool = true
	) -> ArrayMesh:

	var mesh := ArrayMesh.new()
	if points.is_empty() or grid_size <= 0.0:
		return mesh

	# --- 1) Occupancy set (snap to Vector3i keys) ---
	var occ: Dictionary = {} # Vector3i -> true
	for p in points:
		var sp := p.snapped(Vector3.ONE * grid_size)
		var k := Vector3i(
			int(round(sp.x / grid_size)),
			int(round(sp.y / grid_size)),
			int(round(sp.z / grid_size))
		)
		occ[k] = true

	# Neighbor offsets
	var offsets6: Array[Vector3i] = [
		Vector3i( 1, 0, 0), Vector3i(-1, 0, 0),
		Vector3i( 0, 1, 0), Vector3i( 0,-1, 0),
		Vector3i( 0, 0, 1), Vector3i( 0, 0,-1)
	]

	var offsets26: Array[Vector3i] = []
	offsets26.resize(0)
	for dz in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			for dx in [-1, 0, 1]:
				if dx == 0 and dy == 0 and dz == 0:
					continue
				offsets26.append(Vector3i(dx, dy, dz))

	var cull_offsets :=  offsets26  if use_26_neighbors_for_culling  else offsets6
	var edge_offsets := offsets26 if use_26_neighbors_for_edges else offsets6

	# --- 2) Boundary culling: exclude inner points ---
	var boundary: Dictionary = {} # Vector3i -> true
	for k in occ.keys():
		var is_boundary := false
		for o in cull_offsets:
			if not occ.has(k + o):
				is_boundary = true
				break
		if is_boundary:
			boundary[k] = true

	if boundary.is_empty():
		return mesh

	# --- 3) Build edges between neighboring boundary points (incl. diagonals) ---
	# We avoid duplicates by only adding edge if k < nk lexicographically.


	var verts := PackedVector3Array()
	var indices := PackedInt32Array()
	var idx := 0

	for k in boundary.keys():
		for o in edge_offsets:
			var nk: Vector3i = k + o
			if not boundary.has(nk):
				continue
			if not _lex_less(k, nk):
				continue

			var p0 := Vector3(k.x, k.y, k.z) * grid_size
			var p1 := Vector3(nk.x, nk.y, nk.z) * grid_size

			verts.append(p0)
			verts.append(p1)
			indices.append(idx + 0)
			indices.append(idx + 1)
			idx += 2

	# --- 4) Emit as line mesh ---
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_INDEX] = indices

	if verts.size() > 0:
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)

	return mesh
	
	
	
	
