# IcoSphereArrayMeshViz.gd
# Attach to a Node3D. Assign an optional material.
extends Node3D

@export var rows: int = 32
@export var sphere_scale: float = 10
@export var material: Material
@export var radius_noise_scale : float = 10.0


var _mesh_instance: MeshInstance3D

func _ready() -> void:
	_build_mesh()

func _build_mesh() -> void:
	if is_instance_valid(_mesh_instance):
		_mesh_instance.queue_free()

	var points: PackedVector3Array = CubeSphereUtils.all_points(rows)
	var indices: PackedInt32Array = CubeSphereUtils.triangle_indices(rows)
	
	var r_noise := SimpleHashNoise3D.new()
	
	var radius_noise_scale3d : Vector3 = Vector3(radius_noise_scale,radius_noise_scale,radius_noise_scale)
	
	for idx in range(len(points)):
		var p: Vector3 = points[idx]
		var r := sphere_scale * (r_noise.get_at(p,radius_noise_scale3d)*0.5+0.5)
		points[idx] *=r
		
		
		
	
	# Normals for a unit sphere are the same as positions (already unit length).
	var normals := PackedVector3Array()
	normals.resize(points.size())
	for i in range(points.size()):
		normals[i] = points[i]

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	if material != null:
		mesh.surface_set_material(0, material)

	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.mesh = mesh
	add_child(_mesh_instance)
