# IcoSpherePointViz.gd
# Attach to a Node3D. Assign a Mesh (e.g., SphereMesh/CubeMesh) and a material if desired.
extends Node3D

@export var rows: int = 32
@export var sphere_scale: float = 10
@export var instance_mesh: Mesh
@export var instance_material: Material
@export var instance_scale: float = 0.03
@export var radius_noise_scale : float = 10.0
@export var regenerate_on_ready: bool = true

var _mmi: MultiMeshInstance3D
var _mm: MultiMesh

func _ready() -> void:
	if regenerate_on_ready:
		regenerate()

func regenerate() -> void:
	# Clean up previous viz
	if is_instance_valid(_mmi):
		_mmi.queue_free()

	if instance_mesh == null:
		push_error("Assign 'instance_mesh' (e.g. SphereMesh) in the inspector.")
		return

	var pts: PackedVector3Array = CubeSphereUtils.all_points(rows)
	if pts.is_empty():
		return

	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.instance_count = pts.size()
	_mm.mesh = instance_mesh

	_mmi = MultiMeshInstance3D.new()
	_mmi.multimesh = _mm
	if instance_material != null:
		_mmi.material_override = instance_material
	add_child(_mmi)

	var s := Vector3.ONE * instance_scale
	
	var r_noise := SimpleHashNoise3D.new()
	
	var radius_noise_scale3d : Vector3 = Vector3(radius_noise_scale,radius_noise_scale,radius_noise_scale)
	for idx in range(pts.size()):
		var p: Vector3 = pts[idx]
		var r := sphere_scale * (r_noise.get_at(p,radius_noise_scale3d)*0.5+0.5)
		
		var t := Transform3D(Basis().scaled(s), p*r) # point on unit sphere
		_mm.set_instance_transform(idx, t)

# Optional: call this if you change rows/cols at runtime.
"""func _notification(what: int) -> void:
	if what == NOTIFICATION_EDITOR_PROPERTY_CHANGED:
		# Avoid heavy regeneration in-editor unless you want it.
		pass"""
