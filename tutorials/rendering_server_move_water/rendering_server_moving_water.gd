extends Node3D
class_name WaterSimOnRenderingServer

var speed_shader: RID
var speed_pipeline: RID
var speed_uniform_set: RID
var speed_params_ubo: RID

var surface_tex_rd: RID         # storage texture for surface (read-only)
var speed_tex_rd: RID           # storage texture for velocity (RG32F)

# For mass move shader (we’ll keep old names but extend semantics):
var mass_shader: RID
var mass_pipeline: RID
var mass_uniform_set: RID
var mass_params_ubo: RID

var mass_in_tex_rd: RID
var mass_out_tex_rd: RID

var mass_tex_rd: Texture2DRD    # already present (used by water material)
var surface_tex_tex_rd: Texture2DRD

var grid_width: int
var grid_height: int
var grid_size: int
var speeds_x_size: int
var speeds_y_size: int

var rd: RenderingDevice

var mass: PackedFloat32Array = PackedFloat32Array()
#var surface: PackedFloat32Array = PackedFloat32Array()
var speeds_x: PackedFloat32Array = PackedFloat32Array()
var speeds_y: PackedFloat32Array = PackedFloat32Array()

var dt_mass := 2.0 / 60
var dt_speed := 2.0 / 60

var water_mat : ShaderMaterial
var ground_mat : ShaderMaterial
var do_noice := true

func _ready() -> void:
	var sz := 200
	_init_sizes(sz,sz)
	print("_init_sizes done")
	_init_arrays()
	print("_init_arrays done")
	_init_rendering_device()
	print("_init_rendering_device done")
	_init_mesh_instance_with_shader_material()
	print("_init_mesh_instance_with_shader_material done")

func _init_sizes(w:int, h:int):
	grid_width = w
	grid_height = h
	grid_size = grid_width * grid_height
	speeds_x_size = (grid_width -1) * grid_height
	speeds_y_size = grid_width * (grid_height -1)
	
func _init_arrays():	
	GridVectorMath. fill_all(mass,grid_size, 0)
	#GridVectorMath. fill_all(surface,grid_size, 0)
	GridVectorMath. fill_all(speeds_x,speeds_x_size, 0)
	GridVectorMath. fill_all(speeds_y,speeds_y_size, 0)
	GridVectorMath. fill_rect(mass,grid_width, grid_height,grid_width/2, 0,grid_width/5,grid_height/10, 5.0)
	
	#if do_noice:
		#var noise :=SimpleHashNoise2D.new(13)
		#noise.populate_packed(surface,grid_width,grid_height,Vector2.ONE*5.1)
		#GridVectorMath.mult_with_scalar(surface,3)
	
	#GridVectorMath.add_x_add_y(surface,grid_width,grid_height, .1)
	#GridVectorMath.fill_rect(surface,grid_width, grid_height,grid_width/4, grid_height/4,3,3, (grid_width/4+grid_height/4) * 0.1 + 1.0)


"""
Creates mass_in / mass_out storage textures (R32_SFLOAT).
Creates surface_tex_rd storage texture (R32_SFLOAT, read-only at runtime).
Creates speed_tex_rd storage texture (R32G32_SFLOAT, RG float).
Creates two shader + pipeline pairs:
speed_shader (update_speed_for_surface)
mass_shader (move_mass_on_surface)
Creates two params UBOs (dt_speed, dt_mass).
Builds both uniform sets.
"""



func _init_rendering_device() -> void:
	rd = RenderingServer.get_rendering_device()
	print("RenderingServer :", rd)
	# --- Load shaders
	var speed_shader_path :="res://tutorials/rendering_server_move_water/change_speed.glsl"
	var mass_shader_path  := "res://tutorials/rendering_server_move_water/move_mass.glsl"
	
	var speed_shader_file: RDShaderFile = load(speed_shader_path)
	var speed_spirv: RDShaderSPIRV = speed_shader_file.get_spirv()
	speed_shader = rd.shader_create_from_spirv(speed_spirv)
	print("speed_shader :" , speed_shader)
	
	var mass_shader_file: RDShaderFile = load(mass_shader_path)
	var mass_spirv: RDShaderSPIRV = mass_shader_file.get_spirv()
	mass_shader = rd.shader_create_from_spirv(mass_spirv)
	print("mass_shader :" , mass_shader)
	
	# --- Common texture format for R32F images (mass, surface) ---	
	var fmt_r32 := RDTextureFormat.new()
	fmt_r32.width = grid_width
	fmt_r32.height = grid_height
	fmt_r32.texture_type = RenderingDevice.TEXTURE_TYPE_2D
	fmt_r32.format = RenderingDevice.DATA_FORMAT_R32_SFLOAT
	fmt_r32.mipmaps = 1
	fmt_r32.usage_bits = (
		RenderingDevice.TEXTURE_USAGE_STORAGE_BIT |
		RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT |
		RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT |
		RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT
	)
	
	var view := RDTextureView.new()
	# --- Mass textures: ping-pong (in/out) ---
	# mass_image already filled in _set_init_images()
	var mass_bytes := mass.to_byte_array()
	var zero_floats := PackedFloat32Array()
	zero_floats.resize(mass.size())
	var zero_bytes := zero_floats.to_byte_array()
	
	mass_in_tex_rd  = rd.texture_create(fmt_r32, view, [mass_bytes])
	mass_out_tex_rd = rd.texture_create(fmt_r32, view, [zero_bytes])
	
	# Wrap mass_in_tex_rd for sampling in water shader
	mass_tex_rd = Texture2DRD.new()
	mass_tex_rd.texture_rd_rid = mass_in_tex_rd
	
	# --- Surface texture: read-only (as far as compute is concerned) ---
	var noise_gpu = SimpleHashNoise2DGPU.new(grid_width,grid_height,Vector2.ONE*0.1,10 , 13)
	
	noise_gpu.generate_noise()
	
	surface_tex_rd = noise_gpu.out_noise
	
	surface_tex_tex_rd = Texture2DRD.new()
	surface_tex_tex_rd.texture_rd_rid = surface_tex_rd
	
	# --- Speed texture: RG32F (from speeds_x & speeds_y arrays) ---
	var fmt_rg32 := RDTextureFormat.new()
	fmt_rg32.width = grid_width
	fmt_rg32.height = grid_height
	fmt_rg32.texture_type = RenderingDevice.TEXTURE_TYPE_2D
	fmt_rg32.format = RenderingDevice.DATA_FORMAT_R32G32_SFLOAT
	fmt_rg32.mipmaps = 1
	fmt_rg32.usage_bits = (
		RenderingDevice.TEXTURE_USAGE_STORAGE_BIT |
		RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT |
		RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT |
		RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT
	)
	
	var speed_bytes := _build_initial_speed_bytes()  # from speeds_x, speeds_y
	speed_tex_rd = rd.texture_create(fmt_rg32, view, [speed_bytes])
	
	# --- Params UBOs ---
	# Mass movement params
	var clamp_factor := 0.5
	var mass_params_floats := PackedFloat32Array([
		float(grid_width),
		float(grid_height),
		dt_mass,
		clamp_factor
	])
	
	var mass_params_bytes := mass_params_floats.to_byte_array()
	mass_params_ubo = rd.uniform_buffer_create(mass_params_bytes.size(), mass_params_bytes)
	
	var speed_params_floats := PackedFloat32Array([
		float(grid_width),
		float(grid_height),
		dt_speed,
		0.0
	])
	
	var speed_params_bytes := speed_params_floats.to_byte_array()
	speed_params_ubo = rd.uniform_buffer_create(speed_params_bytes.size(), speed_params_bytes)
	
	# --- Uniform sets for both pipelines ---
	_rebuild_uniform_sets()
	# --- Create pipelines ---
	speed_pipeline = rd.compute_pipeline_create(speed_shader)
	mass_pipeline  = rd.compute_pipeline_create(mass_shader)
	
	
#----- Creating byte array for speeds texture with r and g values
func _build_initial_speed_bytes() -> PackedByteArray:
	var w := grid_width
	var h := grid_height

	var speed_floats := PackedFloat32Array()
	speed_floats.resize(w * h * 2)

	var idx := 0
	for y in range(h):
		for x in range(w):
			var sx := 0.0
			var sy := 0.0

			if x < w - 1:
				var i_speed_x := y * (w - 1) + x
				sx = speeds_x[i_speed_x]

			if y < h - 1:
				var i_speed_y := y * w + x
				sy = speeds_y[i_speed_y]

			speed_floats[idx]     = sx
			speed_floats[idx + 1] = sy
			idx += 2

	return speed_floats.to_byte_array()
	
	
#---
func _rebuild_uniform_sets():
	# Mass move shader (set=0)
	var u_mass_in := RDUniform.new()
	u_mass_in.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	u_mass_in.binding = 0
	u_mass_in.add_id(mass_in_tex_rd)

	var u_mass_out := RDUniform.new()
	u_mass_out.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	u_mass_out.binding = 1
	u_mass_out.add_id(mass_out_tex_rd)

	var u_mass_speed := RDUniform.new()
	u_mass_speed.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	u_mass_speed.binding = 2
	u_mass_speed.add_id(speed_tex_rd)

	var u_mass_params := RDUniform.new()
	u_mass_params.uniform_type = RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER
	u_mass_params.binding = 3
	u_mass_params.add_id(mass_params_ubo)

	mass_uniform_set = rd.uniform_set_create(
		[u_mass_in, u_mass_out, u_mass_speed, u_mass_params],
		mass_shader, 0
	)

	# Speed update shader (set=0)
	var u_speed_mass := RDUniform.new()
	u_speed_mass.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	u_speed_mass.binding = 0
	u_speed_mass.add_id(mass_in_tex_rd)

	var u_speed_surface := RDUniform.new()
	u_speed_surface.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	u_speed_surface.binding = 1
	u_speed_surface.add_id(surface_tex_rd)

	var u_speed_speed := RDUniform.new()
	u_speed_speed.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	u_speed_speed.binding = 2
	u_speed_speed.add_id(speed_tex_rd)

	var u_speed_params := RDUniform.new()
	u_speed_params.uniform_type = RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER
	u_speed_params.binding = 3
	u_speed_params.add_id(speed_params_ubo)

	speed_uniform_set = rd.uniform_set_create(
		[u_speed_mass, u_speed_surface, u_speed_speed, u_speed_params],
		speed_shader, 0
	)
	
func _physics_process(delta: float) -> void:
	simulation_step()
	#_update_visual_shader_params()
		
	
func simulation_step():
	var groups_x := IntCalc.div_round_up(grid_width, 8)
	var groups_y := IntCalc.div_round_up(grid_height, 8)
	
	# Compute list:
	var cl := rd.compute_list_begin()
	# --- pass 1: update speeds ---
	rd.compute_list_bind_compute_pipeline(cl, speed_pipeline)
	rd.compute_list_bind_uniform_set(cl, speed_uniform_set, 0)
	rd.compute_list_dispatch(cl, groups_x, groups_y, 1)
	# --- pass 2: move mass (uses updated speeds) ---
	rd.compute_list_bind_compute_pipeline(cl, mass_pipeline)
	rd.compute_list_bind_uniform_set(cl, mass_uniform_set, 0)
	rd.compute_list_dispatch(cl, groups_x, groups_y, 1)
	rd.compute_list_end()
	
	# 3) Latest mass is now in mass_out_tex_rd -> swap
	var tmp := mass_in_tex_rd
	mass_in_tex_rd = mass_out_tex_rd
	mass_out_tex_rd = tmp
	#3.5 ) rebuild uniform sets:
	_rebuild_uniform_sets()
	#4 )For rendering water: use updated input RID
	mass_tex_rd.texture_rd_rid = mass_in_tex_rd


func _update_visual_shader_params():
	# Use Texture2DRD for both:
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
	
# using Texture2DRD in visual shaders:
func _init_mesh_instance_with_shader_material():
	var cell_step := 1.0
	var grid_mesh := ArrayMeshBuilder.new_grid_array_mesh(grid_width, grid_height, cell_step, cell_step)
	water_mat = WaterAndGroundSimUtils.new_water_shader_visuals(self, grid_mesh)
	ground_mat = WaterAndGroundSimUtils.new_ground_shader_visuals(self, grid_mesh)
	_update_visual_shader_params()

	
