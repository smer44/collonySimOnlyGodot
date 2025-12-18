class_name ArrayMeshGridDisplay
extends MeshInstance3D

#ArrayMesh

@export var surface_generator: AbstractTerrainElevationGenerator
@export var coloring_generator: AbstractTerrainColoring

@export var origin_x := 0
@export var origin_z := 0
@export var width := 32
@export var depth := 32
@export var epsilon: float = 0.0001 # threshold for elevation difference
@export var collisionShape3D : CollisionShape3D


func _ready() -> void:
	assert(surface_generator != null, "ArrayMeshGridDisplay: surface_generator is not set")
	assert(coloring_generator != null, "ArrayMeshGridDisplay: coloring_generator is not set")
	
	surface_generator.precalc()
	coloring_generator.precalc_for(surface_generator)	
	
	var  m := ArrayMesh.new()
	self.material_override = new_mat_with_vertex_color()

	build_chunk(m,origin_x,origin_z,width,depth)
	
	if collisionShape3D:
		var concave_shape: ConcavePolygonShape3D = m.create_trimesh_shape()
		collisionShape3D.shape = concave_shape
	
	self.mesh = m
	
func new_mat_with_vertex_color() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true	
	return mat
	


	


func build_chunk(mesh : ArrayMesh, origin_x:int, origin_z:int, width:int, depth:int) -> void:
# Clear any existing surfaces
	mesh.clear_surfaces()


	var num_quads := width * depth
	var num_verts := num_quads * 4
	var num_indices := num_quads * 6
	#var num_verts_with_left_face = 


	var vertices := PackedVector3Array()
	#vertices.reserve(num_verts)
	var normals := PackedVector3Array()
	#normals.reserve(num_verts)
	var colors := PackedColorArray()
	#colors.reserve(num_verts)
	var uvs := PackedVector2Array()
	#uvs.reserve(num_verts)
	var indices := PackedInt32Array()
	#indices.resize(num_indices)


	var up := Vector3.UP
	var v_i := 0
	var i_i := 0


	# For Z adjacency we need per-column history (size = width)
	var prev_y_z := PackedFloat32Array()
	prev_y_z.resize(width)
	var prev_color_z :Array[Color]= []
	prev_color_z.resize(width)

# Iterate cells; each cell forms a quad with two triangles.
	for dz in depth:
		var last_left_y: float = NAN # reset at each new row
		var last_left_color : Color = Color.BLACK
		for dx in width:
			var x := origin_x + dx
			var z := origin_z + dz


			# Flat elevation per cell (you can switch to per-corner later)
			var y := surface_generator.get_elevation_at(x, z)
			#print("ArrayMeshGridDisplay : elevation : %s "  %[  y ])
			var cell_color : Color = coloring_generator.get_color_at(x, y, z)
			#print("ArrayMeshGridDisplay cell_color : %s" % cell_color)
			#var cell_color : Color = Color.RED


# 4 vertices in local order: (x,z) (x+1,z) (x+1,z+1) (x,z+1)
# All at height y
			#vertices[v_i + 0] = Vector3(x + 0.0, y, z + 0.0)
			#vertices[v_i + 1] = Vector3(x + 1.0, y, z + 0.0)
			#vertices[v_i + 2] = Vector3(x + 1.0, y, z + 1.0)
			#vertices[v_i + 3] = Vector3(x + 0.0, y, z + 1.0)
			vertices.append(Vector3(x + 0.0, y, z + 0.0))
			vertices.append(Vector3(x + 1.0, y, z + 0.0))
			vertices.append(Vector3(x + 1.0, y, z + 1.0))
			vertices.append(Vector3(x + 0.0, y, z + 1.0))


			# Flat-shaded: constant upward normal for now
			#normals[v_i + 0] = up
			#normals[v_i + 1] = up
			#normals[v_i + 2] = up
			#normals[v_i + 3] = up
			normals.append(up)
			normals.append(up)
			normals.append(up)
			normals.append(up)


			# Simple per-quad color: same color on all 4 verts
			#colors[v_i + 0] = cell_color
			#colors[v_i + 1] = cell_color
			#colors[v_i + 2] = cell_color
			#colors[v_i + 3] = cell_color
			colors.append(cell_color)
			colors.append(cell_color)
			colors.append(cell_color)
			colors.append(cell_color)


			# Basic UVs per quad (0..1)
			#uvs[v_i + 0] = Vector2(0.0, 0.0)
			#uvs[v_i + 1] = Vector2(1.0, 0.0)
			#uvs[v_i + 2] = Vector2(1.0, 1.0)
			#uvs[v_i + 3] = Vector2(0.0, 1.0)
			
			uvs.append(Vector2(0.0, 0.0))
			uvs.append(Vector2(1.0, 0.0))
			uvs.append(Vector2(1.0, 1.0))
			uvs.append(Vector2(0.0, 1.0))


			# Indices for two triangles: (0,1,2) and (0,2,3)
			# Note: ArrayMesh updates its AABB from the provided vertices.
			#indices[i_i + 0] = v_i + 0
			#indices[i_i + 1] = v_i + 1
			#indices[i_i + 2] = v_i + 2
			#indices[i_i + 3] = v_i + 0
			#indices[i_i + 4] = v_i + 2
			#indices[i_i + 5] = v_i + 3
			indices.append(v_i + 0)
			indices.append(v_i + 1)
			indices.append(v_i + 2)
			indices.append(v_i + 0)
			indices.append(v_i + 2)
			indices.append(v_i + 3)


			v_i += 4
			i_i += 6
			
			if not is_nan(last_left_y) and abs(y-last_left_y) > epsilon:
				#var min_y :float= min(y, last_left_y)
				#var max_y :float= max(y, last_left_y)				
				vertices.append(Vector3(x, y, z))
				vertices.append(Vector3(x, y, z+1))		
				vertices.append(Vector3(x, last_left_y, z+1))
				vertices.append(Vector3(x, last_left_y, z))
				
				var normal := Vector3.LEFT if y < last_left_y else Vector3.RIGHT
				normals.append_array([normal, normal, normal, normal])
				colors.append_array([cell_color, cell_color, last_left_color, last_left_color])
				uvs.append_array([Vector2(0,0), Vector2(1,0), Vector2(1,1), Vector2(0,1)])
				indices.append_array([v_i+0, v_i+1, v_i+2, v_i+0, v_i+2, v_i+3])
				v_i += 4
				i_i += 6				

			if dz > 0:
				var last_back_y := prev_y_z[dx]
				var last_back_color := prev_color_z[dx]				
				
				vertices.append(Vector3(x, y, z))
				vertices.append(Vector3(x, last_back_y, z))	
				vertices.append(Vector3(x+1, last_back_y, z))
				vertices.append(Vector3(x+1, y, z))		
				
						
				
				var normal := Vector3.BACK #if y < last_back_y else Vector3.FORWARD	
				normals.append_array([normal, normal, normal, normal])
				colors.append_array([cell_color, last_back_color, last_back_color, cell_color])
				uvs.append_array([Vector2(0,0), Vector2(1,0), Vector2(1,1), Vector2(0,1)])
				indices.append_array([v_i+0, v_i+1, v_i+2, v_i+0, v_i+2, v_i+3])
				v_i += 4
				i_i += 6					
				
			last_left_y = y	
			last_left_color = cell_color
			prev_y_z[dx] = y 
			prev_color_z[dx] = cell_color
				
						
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices


	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
