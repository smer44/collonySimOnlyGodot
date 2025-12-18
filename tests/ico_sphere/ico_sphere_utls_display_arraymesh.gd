extends Node3D

@export var subdiv: int = 1
@export var mesh_scale: float = 10.0
@export var unique_uv : bool = true
@export var radius_noise_scale : float = 10.5
@export var apply_noise : bool = true
@export var mat : Material


func _ready() -> void:
	_create_icosa_mesh_child()


func _create_icosa_mesh_child() -> void:
	# Build the mesh (expects IcoArrayMeshUtils.build_icosa_mesh(subdiv) to exist)
	var arrays: Array = IcoSphereUtils.build_icosphere(mesh_scale, subdiv, unique_uv)
	

	
	var r_noise := SimpleHashNoise3D.new()
	
	var radius_noise_scale3d : Vector3 = Vector3(radius_noise_scale,radius_noise_scale,radius_noise_scale)
	
	var vertices :PackedVector3Array= arrays[Mesh.ARRAY_VERTEX]
	
	if apply_noise:
		for i in range(len(vertices)):
			var p := vertices[i]
			var noise:= r_noise.get_at(p,radius_noise_scale3d)
			noise = 1.0 + noise * 0.25
			p *= noise
			vertices[i] = p
	
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	

	# Create a child MeshInstance3D to display it
	var mi := MeshInstance3D.new()
	mi.name = "IcoMesh"
	mi.mesh = mesh
	mi.material_override = mat
	add_child(mi)
