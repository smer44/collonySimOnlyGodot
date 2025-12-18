extends RefCounted 
class_name MultiMeshUtils

# Constructs a MultiMeshInstance3D that renders one instance of `base_mesh`
# at each position in `points` (translation only; aligned with global axes).
#
# Returns the created MultiMeshInstance3D (not added to scene automatically).
static func build_multimesh_from_points(
		base_mesh: Mesh,
		points: Array[Vector3]
	) -> MultiMeshInstance3D:

	var mmi := MultiMeshInstance3D.new()

	if base_mesh == null:
		push_error("build_multimesh_from_points: base_mesh is null")
		return mmi

	var mm := MultiMesh.new()
	mm.mesh = base_mesh
	mm.transform_format = MultiMesh.TRANSFORM_3D
	#mm.use_colors = false
	#mm.use_custom_data = false

	var n := points.size()
	mm.instance_count = n
	mm.visible_instance_count = n

	var basis := Basis.IDENTITY
	for i in range(n):
		mm.set_instance_transform(i, Transform3D(basis, points[i]))

	mmi.multimesh = mm
	return mmi
