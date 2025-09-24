# MultiMesh-based terrain chunk (replaces ArrayMeshChunk)
class_name MultiMeshGridDisplay
extends MultiMeshInstance3D

@export var surface_data: TerrainFunction
@export var origin_x: int = 0
@export var origin_z: int = 0
@export var width: int = 32
@export var depth: int = 32

# Prefab to multiply: provide a PackedScene whose root is a MeshInstance3D.
# Its .mesh is used as the MultiMesh prototype (the scene itself isn't added to the tree).
@export var prefab: PackedScene

# Placement & appearance tweaks
@export var center_on_tile := true         # place at cell center (x+0.5, z+0.5)
@export var y_offset: float = 0.0          # optional vertical offset
@export var per_instance_scale := Vector3.ONE

func _ready() -> void:
	if surface_data == null:
		push_error("MultiMeshChunk: 'surface_data' is null.")
		return
	if prefab == null:
		push_error("MultiMeshChunk: 'prefab' is null (expect a MeshInstance3D PackedScene).")
		return

	# Extract prototype mesh from the prefab
	var inst := prefab.instantiate() as MeshInstance3D

	#inst.queue_free()
	var m := StandardMaterial3D.new()
	m.albedo_color = Color.WHITE
	m.vertex_color_use_as_albedo = true
	inst.mesh.material = m	
	


	# Set the prototype mesh that MultiMesh will multiply
	

	# Build MultiMesh
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = inst.mesh
	
	#mm.color_format = MultiMesh.COLOR_FLOAT      # enables per-instance color
	#mm.custom_data_format = MultiMesh.CUSTOM_DATA_NONE
	mm.instance_count = width * depth
	self.multimesh = mm

	var i := 0
	var center_delta := 0.5 if center_on_tile else 0.0

	for dz in depth:
		for dx in width:
			var x := origin_x + dx
			var z := origin_z + dz
			var y := surface_data.get_elevation_at(x, z)

			# Per-instance transform
			var pos := Vector3(x + center_delta, y + y_offset, z + center_delta)
			var basis := Basis.IDENTITY.scaled(per_instance_scale)
			var xf := Transform3D(basis, pos)
			mm.set_instance_transform(i, xf)

			# Per-instance color
			var c: Color = surface_data.get_color_at(x, y, z)
			mm.set_instance_color(i, c)

			i += 1
