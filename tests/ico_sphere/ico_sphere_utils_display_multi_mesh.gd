extends Node3D
class_name DisplayMultiMesh

@export var hexagon_mesh: CylinderMesh
@export var pentagon_mesh: CylinderMesh

@export var subdiv: int = 8
@export var mesh_scale: float = 0.1
@export var radius: float = 1.0

var _mm_instance: MultiMeshInstance3D

func _ready() -> void:
	if hexagon_mesh == null:
		push_error("IcoSphereMultiMeshPlacer: Assign 'hexagon_mesh' in the Inspector.")
		return
	if pentagon_mesh == null:
		push_error("IcoSphereMultiMeshPlacer: Assign 'pentagon_mesh' in the Inspector.")
		return
	if subdiv < 1:
		push_error("IcoSphereMultiMeshPlacer: 'subdiv' must be >= 1.")
		return

	var cell_scale := IcoSphereUtils.hex_corner_radius_unit_sphere(subdiv) *radius
	var cell_penta_scale = IcoSphereUtils.pent_corner_radius_unit_sphere(subdiv) * radius
	
	hexagon_mesh.top_radius = cell_scale
	hexagon_mesh.bottom_radius = cell_scale
	pentagon_mesh.top_radius = cell_penta_scale
	pentagon_mesh.bottom_radius = cell_penta_scale
	
	# 1) Get points (unit sphere) and scale to desired radius.
	var points: PackedVector3Array = IcoSphereUtils.build_icosphere_only_vertices(subdiv)

	# 2) Create MultiMesh
	var mm := MultiMesh.new()
	mm.mesh = hexagon_mesh
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = false
	mm.use_custom_data = false
	mm.instance_count = points.size() - 12
	
	var mm2 := MultiMesh.new()
	mm2.mesh = pentagon_mesh
	mm2.transform_format = MultiMesh.TRANSFORM_3D
	mm2.use_colors = false
	mm2.use_custom_data = false
	mm2.instance_count = 12
	
	
	var scale3d:= Vector3.ONE * mesh_scale
	# 3) Fill transforms
	var n := 0
	var n2 := 0
	for i in range(points.size()):
		
		var p: Vector3 = points[i].normalized()
		var basis := _basis_from_normal(p,false)
		# Position only
		var t := Transform3D(basis, p*radius)
		if IcoSphereUtils.is_pentagon_index(subdiv,i):
			mm2.set_instance_transform(n2, t)
			n2+=1
		else:
			mm.set_instance_transform(n, t)
			n+=1	


	# 4) Create / attach MultiMeshInstance3D
	_mm_instance = MultiMeshInstance3D.new()
	_mm_instance.multimesh = mm
	#_mm_instance.top_level = true
	#_mm_instance.global_transform = self.global_transform
	add_child(_mm_instance)
	var mm_instance_2 = MultiMeshInstance3D.new()
	mm_instance_2.multimesh = mm2
	add_child(mm_instance_2)

	# Optional: name it for clarity in the scene tree
	_mm_instance.name = "IcoSphereMultiMesh"
	mm_instance_2.name = "IcoSphereMultiMeshPentaagons"
	
	var must_be_point_amount := IcoSphereUtils.amount_of_points(subdiv)
	var actual_points := len(points)
	print("must_be_point_amount: " , must_be_point_amount , ", actual_points: " , actual_points)


# --- Optional orientation variant ---
# If you want each instance to "face outward" (local +Y along the normal),
# replace the transform assignment in the loop with:
#
#   var up := p.normalized()
#   var basis := Basis()
#   basis = basis.looking_at(up, Vector3.FORWARD) # choose your preferred forward axis
#   var t := Transform3D(basis, p)
#   mm.set_instance_transform(i, t)
#
# (Depending on your mesh's authored axis, you may want FORWARD/UP swapped or add a corrective rotation.)
# Builds an orthonormal Basis where:
#   basis.y == n (your normalized p)
# and basis.x/basis.z are stable tangents around it.
static func _basis_from_normal(n: Vector3, mirrored: bool) -> Basis:
	"""A mirrored basis (negative determinant) 
	effectively introduces a reflection (similar to negative scale), 
	which can look like “rotation/popping” 
	as the camera moves due to winding/culling/normal 
	effects in the renderer.
	"""
	var y := n.normalized()

	# Pick a reference vector that is not parallel to y (to avoid degeneracy).
	var ref := Vector3.UP
	if abs(y.dot(ref)) > 0.999:
		ref = Vector3.RIGHT

	var x := ref.cross(y).normalized()
	var z := y.cross(x).normalized() if mirrored else x.cross(y).normalized()

	return Basis(x, y, z)
