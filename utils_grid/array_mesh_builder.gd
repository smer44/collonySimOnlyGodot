extends RefCounted
class_name ArrayMeshBuilder



static func _build_grid_plane(w: int, h: int, w_step : float, h_step : float) -> Array:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices_and_uv :=_build_grid_plane_vertices_and_uv(w,h,w_step,h_step)
	var indices := _build_grid_plane_indexes(w,h,w_step,h_step)	
	arrays[Mesh.ARRAY_VERTEX] = vertices_and_uv[0]
	arrays[Mesh.ARRAY_TEX_UV] = vertices_and_uv[1]
	arrays[Mesh.ARRAY_INDEX] = indices
	return arrays 	

static func _build_grid_plane_vertices_and_uv(w: int, h: int, w_step : float, h_step : float) -> Array:
	
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


static func _build_grid_plane_indexes(w: int, h: int, w_step : float, h_step : float) -> PackedInt32Array:
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



	
	
	
	
