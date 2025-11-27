extends RefCounted
class_name MeshUtils


static func mesh_instance_child(parent: Node, input_mesh : Mesh, mat: Material ) -> MeshInstance3D:
	var meshInstance := MeshInstance3D.new()
	meshInstance.mesh = input_mesh
	parent.add_child(meshInstance)	
	meshInstance.set_surface_override_material(0, mat)	
	return meshInstance
