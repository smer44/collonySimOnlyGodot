extends Node3D
class_name WaterSimOnRenderingServer

# --- Compute shader RIDs ---
var speed_shader: RID
var speed_pipeline: RID
var speed_uniform_set: RID
var speed_params_ubo: RID

var surface_tex_rd: RID         # storage texture for surface (read-only)
var speed_tex_rd: RID           # storage texture for velocity (RG32F)
var speed_out_tex_rd: RID       # second speed texture for ping-pong

var speed_diffuse_shader: RID
var speed_diffuse_pipeline: RID
var speed_diffuse_uniform_set: RID
var speed_diffuse_params_ubo: RID

# For mass move shader:
var mass_shader: RID
var mass_pipeline: RID
var mass_uniform_set: RID
var mass_params_ubo: RID

var mass_in_tex_rd: RID
var mass_out_tex_rd: RID

var mass_tex_rd: Texture2DRD    # used by water material
var surface_tex_tex_rd: Texture2DRD

# --- Grid sizes ---
var grid_width: int
var grid_height: int
var grid_size: int
var speeds_x_size: int
var speeds_y_size: int

# --- Data / RD ---
var rd: RenderingDevice

var mass: PackedFloat32Array = PackedFloat32Array()
var speeds_x: PackedFloat32Array = PackedFloat32Array()
var speeds_y: PackedFloat32Array = PackedFloat32Array()

var dt_mass := 2.0 / 60
var dt_speed := 2.0 / 60
var speed_diffusion := 0.003     # diffusion coefficient for speed smoothing

# --- Visual materials ---
var water_mat : ShaderMaterial
var ground_mat : ShaderMaterial


# -------------------------------------------------------------------
# Lifecycle
# -------------------------------------------------------------------
func _ready() -> void:
	var sz := 200
	_init_sizes(sz, sz)
	print("_init_sizes done")
	
	_init_arrays()
	print("_init_arrays done")
	
	_init_rendering_device()
	print("_init_rendering_device done")
	
	_init_mesh_instance_with_shader_material()
	print("_init_mesh_instance_with_shader_material done")


func _physics_process(delta: float) -> void:
	_step_simulation()

# -------------------------------------------------------------------
# Initialization helpers
# -------------------------------------------------------------------
func _init_sizes(w:int, h:int) -> void:
	grid_width = w
	grid_height = h
	grid_size = grid_width * grid_height
	speeds_x_size = (grid_width - 1) * grid_height
	speeds_y_size = grid_width * (grid_height - 1)


func _init_arrays() -> void:
	GridVectorMath.fill_all(mass, grid_size, 0)
	GridVectorMath.fill_all(speeds_x, speeds_x_size, 0)
	GridVectorMath.fill_all(speeds_y, speeds_y_size, 0)
	GridVectorMath.fill_rect(
		mass,
		grid_width, grid_height,
		grid_width / 2, 0,
		grid_width / 5, grid_height / 10,
		5.0
	)


func _init_rendering_device() -> void:
	rd = RenderingServer.get_rendering_device()
	print("RenderingServer :", rd)
	
	_load_compute_shaders()
	_create_mass_textures()
	_create_surface_texture()
	_create_speed_textures()
	_create_param_buffers()
	
	# Build uniform sets after all textures / UBOs exist
	_rebuild_uniform_sets()	
	_create_pipelines()


# -------------------------------------------------------------------
# Shader + pipeline creation
# -------------------------------------------------------------------

func _load_compute_shaders() -> void:
	var speed_shader_path := "res://tutorials/rendering_server_move_water/change_speed.glsl"
	speed_shader = RDUtils.load_shader(rd,speed_shader_path)
	var mass_shader_path  := "res://tutorials/rendering_server_move_water/move_mass.glsl"
	mass_shader = RDUtils.load_shader(rd,mass_shader_path)
	var speed_diffuse_shader_path := "res://tutorials/rendering_server_move_water/diffuse_speed.glsl"
	speed_diffuse_shader =  RDUtils.load_shader(rd,speed_diffuse_shader_path)



func _create_pipelines() -> void:
	speed_pipeline = rd.compute_pipeline_create(speed_shader)
	mass_pipeline  = rd.compute_pipeline_create(mass_shader)
	speed_diffuse_pipeline = rd.compute_pipeline_create(speed_diffuse_shader)


# -------------------------------------------------------------------
# Texture creation
# -------------------------------------------------------------------
func _create_mass_textures() -> void:
	# Common texture format for R32F images (mass)
	
	var fmt_r32 := RDUtils. new_single_value_rd_texture_format (grid_width, grid_height)
	
	var view := RDTextureView.new()
	
	var mass_bytes := mass.to_byte_array()
	var zero_floats := PackedFloat32Array()
	zero_floats.resize(mass.size())
	var zero_bytes := zero_floats.to_byte_array()
	
	mass_in_tex_rd  = rd.texture_create(fmt_r32, view, [mass_bytes])
	mass_out_tex_rd = rd.texture_create(fmt_r32, view, [zero_bytes])
	
	# Wrap mass_in_tex_rd for sampling in water shader
	mass_tex_rd = Texture2DRD.new()
	mass_tex_rd.texture_rd_rid = mass_in_tex_rd


func _create_surface_texture() -> void:
	var noise_gpu = SimpleHashNoise2DGPU.new(
		grid_width,
		grid_height,
		Vector2.ONE * 0.1,
		10,
		13
	)
	
	noise_gpu.generate_noise()	
	surface_tex_rd = noise_gpu.out_noise	
	surface_tex_tex_rd = Texture2DRD.new()
	surface_tex_tex_rd.texture_rd_rid = surface_tex_rd


func _create_speed_textures() -> void:
	# Speed texture: RG32F (from speeds_x & speeds_y arrays)
	var fmt_rg32 := RDUtils.new_double_value_rd_texture_format(grid_width,grid_height)
	
	var view := RDTextureView.new()
	var speed_bytes := RDUtils._build_initial_speed_bytes(grid_width,grid_height,speeds_x,speeds_y) # from speeds_x, speeds_y
	
	speed_tex_rd = rd.texture_create(fmt_rg32, view, [speed_bytes])
	speed_out_tex_rd = rd.texture_create(fmt_rg32, view, [speed_bytes])


# -------------------------------------------------------------------
# UBO creation
# -------------------------------------------------------------------
func _create_param_buffers() -> void:
	_create_mass_params_ubo()
	_create_speed_params_ubo()
	_create_speed_diffuse_params_ubo()


func _create_mass_params_ubo() -> void:
	var clamp_factor := 0.5
	mass_params_ubo = RDUtils.new_floats_ubo(rd,[
		float(grid_width),
		float(grid_height),
		dt_mass,
		clamp_factor
	])


func _create_speed_params_ubo() -> void:
	
	speed_params_ubo = RDUtils.new_floats_ubo(rd,[
		float(grid_width),
		float(grid_height),
		dt_speed,
		0.0
	])


func _create_speed_diffuse_params_ubo() -> void:
	speed_diffuse_params_ubo = RDUtils.new_floats_ubo(rd,[
		float(grid_width),
		float(grid_height),
		speed_diffusion,
		0.0
	])


# -------------------------------------------------------------------
# Uniform sets
# -------------------------------------------------------------------
func _rebuild_uniform_sets() -> void:
	_build_mass_uniform_set()
	_build_speed_uniform_set()
	_build_speed_diffuse_uniform_set()


func _build_mass_uniform_set() -> void:
	
	var mass_uniform_arrays :Array[RID]= [mass_in_tex_rd, mass_out_tex_rd, speed_tex_rd, mass_params_ubo]
	var mass_uniform_types :Array[RenderingDevice.UniformType]= [RenderingDevice.UNIFORM_TYPE_IMAGE,
														RenderingDevice.UNIFORM_TYPE_IMAGE,
														RenderingDevice.UNIFORM_TYPE_IMAGE,
														RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER]
														
	mass_uniform_set = RDUtils. new_uniform_set(rd,mass_uniform_arrays,mass_uniform_types,mass_shader)



func _build_speed_uniform_set() -> void:

	var speed_uniform_arrays :Array[RID]= [mass_in_tex_rd, surface_tex_rd, speed_tex_rd, speed_params_ubo]
	var speed_uniform_types :Array[RenderingDevice.UniformType]= [RenderingDevice.UNIFORM_TYPE_IMAGE,
														RenderingDevice.UNIFORM_TYPE_IMAGE,
														RenderingDevice.UNIFORM_TYPE_IMAGE,
														RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER]

	speed_uniform_set = RDUtils.new_uniform_set(rd,speed_uniform_arrays,speed_uniform_types,speed_shader)


func _build_speed_diffuse_uniform_set() -> void:
	var speed_dif_uniform_arrays :Array[RID]= [speed_tex_rd, speed_out_tex_rd, speed_diffuse_params_ubo]
	var speed_dif_uniform_types :Array[RenderingDevice.UniformType]= [RenderingDevice.UNIFORM_TYPE_IMAGE,
																RenderingDevice.UNIFORM_TYPE_IMAGE,
																RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER]
																
																
	speed_diffuse_uniform_set = RDUtils.new_uniform_set(rd,speed_dif_uniform_arrays,speed_dif_uniform_types, speed_diffuse_shader )


# -------------------------------------------------------------------
# Simulation step
# -------------------------------------------------------------------
func _step_simulation() -> void:
	var groups_x := IntCalc.div_round_up(grid_width, 8)
	var groups_y := IntCalc.div_round_up(grid_height, 8)
	
	# 0) Diffuse speeds
	_dispatch_speed_diffuse(groups_x, groups_y)
	_ping_pong_speed_textures()
	_rebuild_uniform_sets()  # speed_tex_rd changed
	
	# 1) Update speeds & move mass
	_dispatch_speed_and_mass(groups_x, groups_y)
	_ping_pong_mass_textures()
	_rebuild_uniform_sets()  # mass_in_tex_rd changed
	
	_update_mass_texture_for_rendering()


func _dispatch_speed_diffuse(groups_x: int, groups_y: int) -> void:
	var cl := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(cl, speed_diffuse_pipeline)
	rd.compute_list_bind_uniform_set(cl, speed_diffuse_uniform_set, 0)
	rd.compute_list_dispatch(cl, groups_x, groups_y, 1)
	rd.compute_list_end()


func _dispatch_speed_and_mass(groups_x: int, groups_y: int) -> void:
	var cl := rd.compute_list_begin()
	# pass 1: update speeds
	rd.compute_list_bind_compute_pipeline(cl, speed_pipeline)
	rd.compute_list_bind_uniform_set(cl, speed_uniform_set, 0)
	rd.compute_list_dispatch(cl, groups_x, groups_y, 1)
	# pass 2: move mass
	rd.compute_list_bind_compute_pipeline(cl, mass_pipeline)
	rd.compute_list_bind_uniform_set(cl, mass_uniform_set, 0)
	rd.compute_list_dispatch(cl, groups_x, groups_y, 1)
	rd.compute_list_end()


func _ping_pong_speed_textures() -> void:
	var tmp_speed := speed_tex_rd
	speed_tex_rd = speed_out_tex_rd
	speed_out_tex_rd = tmp_speed


func _ping_pong_mass_textures() -> void:
	var tmp := mass_in_tex_rd
	mass_in_tex_rd = mass_out_tex_rd
	mass_out_tex_rd = tmp


func _update_mass_texture_for_rendering() -> void:
	mass_tex_rd.texture_rd_rid = mass_in_tex_rd


# -------------------------------------------------------------------
# Visual side (unchanged logic, just isolated)
# -------------------------------------------------------------------
func _update_visual_shader_params() -> void:
	WaterAndGroundSimUtils.update_water_shader_params(
		water_mat,
		surface_tex_tex_rd, # terrain height texture
		mass_tex_rd,        # water height texture
		2.0, -0.01
	)
	
	WaterAndGroundSimUtils.update_ground_shader_params(
		ground_mat,
		surface_tex_tex_rd,
		2.0
	)


func _init_mesh_instance_with_shader_material() -> void:
	var cell_step := 1.0
	var grid_mesh := ArrayMeshBuilder.new_grid_array_mesh(
		grid_width, grid_height,
		cell_step, cell_step
	)
	water_mat = WaterAndGroundSimUtils.new_water_shader_visuals(self, grid_mesh)
	ground_mat = WaterAndGroundSimUtils.new_ground_shader_visuals(self, grid_mesh)
	_update_visual_shader_params()
