extends Node3D
class_name MultiMeshGridDisplayer

@export var mesh: Mesh
@export var ground_mesh: Mesh
@export var cell_step: float = 1.0
@export var height_scale: float = 1.0
@export var start_size_x: int = 40
@export var start_size_y: int = 40
@export var auto_run: bool = true

var sim: WaterSimTopDownOnSurace
var mm_instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
var mm: MultiMesh = MultiMesh.new()

var mm_ground_instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
var mm_ground: MultiMesh = MultiMesh.new()

func _ready() -> void:
	sim = WaterSimTopDownOnSurace.new(start_size_x, start_size_y)
	_init_multimeshes()
	_layout_mass_initial()
	_layout_ground_initial()
	
func _physics_process(_delta: float) -> void:
	if auto_run:
		sim.simulation_step()
	_update_heights()

func _input(event):
	if sim:
		sim._input(event)
		
func _init_multimeshes():
	_init_multimesh(self,mm,mm_instance,mesh,sim.grid_width,sim.grid_height)
	_init_multimesh(self,mm_ground,mm_ground_instance,ground_mesh,sim.grid_width,sim.grid_height)
	

static func _init_multimesh(parent : Node3D,  mm : MultiMesh,mm_instance: MultiMeshInstance3D ,mesh: Mesh , grid_width : int, grid_height : int ):
	mm.mesh = mesh
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = grid_width * grid_height
	mm_instance.multimesh = mm
	parent.add_child(mm_instance)

	

func _layout_mass_initial() -> void:
	var i := 0
	for gy in range(sim.grid_height):
		for gx in range(sim.grid_width):
			var ele = sim.mass[i] + sim.surface[i] - 0.01
			var pos := Vector3(gx * cell_step, ele * height_scale, gy * cell_step)
			var t := Transform3D(Basis(), pos)
			mm.set_instance_transform(i, t)
			i += 1
			
func _layout_ground_initial() -> void:
	var i := 0

	for gy in range(sim.grid_height):
		for gx in range(sim.grid_width):
			var pos := Vector3(gx * cell_step, sim.surface[i] * height_scale, gy * cell_step)
			var t := Transform3D(Basis(), pos)
			
			mm_ground.set_instance_transform(i, t)
			#mm_ground.set_in
			i += 1
			
			
func _update_heights() -> void:
	var i := 0

	for gy in range(sim.grid_height):
		for gx in range(sim.grid_width):
			var t := mm.get_instance_transform(i)
			var ele = sim.mass[i] + sim.surface[i] - 0.05

			t.origin.y = ele * height_scale
			
			mm.set_instance_transform(i, t)
			i += 1
			
			
