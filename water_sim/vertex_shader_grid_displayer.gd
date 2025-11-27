extends Node3D
class_name MyShaderGridDisplayer


@export var cell_step: float = 1.0
@export var height_scale: float = 2.0
@export var start_size_x: int = 40
@export var start_size_y: int = 40
@export var auto_run: bool = true

@export var z_bias_water: float = -0.01 # tweak if you see z-fighting

var sim: WaterSimTopDownOnSurace
var grid_mesh: ArrayMesh
#var ground_instance: MeshInstance3D
#var water_instance: MeshInstance3D


var ground_mat: Material
var water_mat: Material

var surface_image: Image
var mass_image: Image
var surface_tex: ImageTexture
var mass_tex: ImageTexture
@export var use_shaders := true

func _ready() -> void:
	# Initialize simulation
	sim = WaterSimTopDownOnSurace.new(start_size_x, start_size_y)
	
	new_images_and_tex_not_static()
	# Build a single shared grid mesh with one vertex per *cell center*
	grid_mesh = ArrayMeshBuilder.new_grid_array_mesh(sim.grid_width,sim.grid_height,cell_step,cell_step)
	new_instances_and_materials_not_static()

	
func new_instances_and_materials_not_static():
	if use_shaders:
		ground_mat = WaterAndGroundSimUtils.new_ground_shader_visuals(self, grid_mesh)
		water_mat = WaterAndGroundSimUtils.new_water_shader_visuals(self, grid_mesh)
		
	else:
		ground_mat = WaterAndGroundSimUtils.new_ground_standart_visuals(self,grid_mesh)		
		water_mat = WaterAndGroundSimUtils.new_water_standart_visuals(self,grid_mesh)



func _physics_process(_delta: float) -> void:
	if auto_run:
		sim.simulation_step()
	# Update texture data from the CPU arrays to the GPU textures each tick

	ImageTextureUtils. update_surface_and_mass_textures(sim.surface,surface_image,surface_tex, sim.mass,mass_image,mass_tex,sim.grid_width,sim.grid_height)
	WaterAndGroundSimUtils. update_material_params(ground_mat,water_mat,surface_tex,mass_tex,height_scale,z_bias_water)
	


func new_images_and_tex_not_static():
	var items := ImageTextureUtils. new_surface_and_mass_images_and_tex(sim.grid_width,sim.grid_height)
	surface_image = items[0]
	surface_tex = items[1]
	mass_image = items[2]
	mass_tex = items[3]
