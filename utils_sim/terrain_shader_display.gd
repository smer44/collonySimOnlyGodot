extends Node
@export var cell_step: float = 1.0
@export var height_scale: float = 2.0
@export var start_size_x: int = 40
@export var start_size_y: int = 40
@export var auto_run: bool = true


var sim: WaterSimTopDownOnSurace
var grid_mesh: ArrayMesh
var ground_instance: MeshInstance3D
var ground_mat: ShaderMaterial
var ground_image: Image
var ground_tex: ImageTexture


func _ready() -> void:
	# Initialize simulation
	sim = WaterSimTopDownOnSurace.new(start_size_x, start_size_y)
	new_images_and_tex()
	new_grid_mesh()
	new_mesh_instance_and_shader_material()
	
func new_images_and_tex():
	var tuple := TerrainSimUtils.new_images_and_tex(start_size_x, start_size_y)
	ground_image = tuple[0]
	ground_tex = tuple[1]
	
func new_grid_mesh():
	var arrays := ArrayMeshBuilder.build_grid_plane(sim.grid_width, sim.grid_height, cell_step, cell_step)
	grid_mesh = ArrayMesh.new()
	grid_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	

	

func new_mesh_instance_and_shader_material() -> void:
	ground_mat = ShaderMaterial.new()
	ground_mat.shader = WaterAndGroundSimUtils.make_water_shader()
	ground_instance = MeshUtils. mesh_instance_child(self, grid_mesh, ground_mat)
	
func _physics_process(_delta: float) -> void:
	if auto_run:
		sim.simulation_step()
	TerrainSimUtils. update_image_from_array(sim.mass,ground_image,sim.grid_width,sim.grid_height)
	ground_tex.update(ground_image)
	update_shader_params(ground_mat, ground_tex)
	
	


func update_shader_params(ground_mat: ShaderMaterial, ground_tex: ImageTexture) -> void:
		ground_mat.set_shader_parameter("surface_tex", ground_tex)
		ground_mat.set_shader_parameter("height_scale", height_scale)
