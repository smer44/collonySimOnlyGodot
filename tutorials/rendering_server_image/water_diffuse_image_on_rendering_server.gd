extends Node3D
class_name WaterImageOnRenderingServer

var grid_width: int
var grid_height: int
var grid_size : int
var speeds_x_size : int
var speeds_y_size : int
var do_noice := true


var mass: PackedFloat32Array = PackedFloat32Array()
var temp_mass: PackedFloat32Array = PackedFloat32Array()
var surface: PackedFloat32Array = PackedFloat32Array()
var speeds_x: PackedFloat32Array = PackedFloat32Array()
var speeds_y: PackedFloat32Array = PackedFloat32Array()

var surface_image : Image
#var surface_image_out : Image
var mass_image : Image
#var mass_image_out : Image
var surface_tex : ImageTexture
var mass_tex : ImageTexture


var dt_mass := 2.0 / 60
var dt_speed := 2.0 / 60
# Diffusion coefficient used by the shader's Params block.
var diffusion: float = 0.05


#rendering device variables:

var rd: RenderingDevice

var mass_shader: RID
var mass_pipeline: RID
var mass_uniform_set: RID
var mass_params_ubo: RID

var mass_in_tex_rd: RID
var mass_out_tex_rd: RID

var mass_tex_rd: Texture2DRD
var water_mat : ShaderMaterial
var ground_mat : ShaderMaterial



func _ready() -> void:
	var sz := 2000
	_init_sizes(sz,sz)
	_init_arrays()
	_init_images_and_texs()
	_set_init_images()	
	_init_rendering_device()
	_init_mesh_instance_with_shader_material()
	
	

	

func _init_sizes(w:int, h:int):
	grid_width = w
	grid_height = h
	grid_size = grid_width * grid_height
	speeds_x_size = (grid_width -1) * grid_height
	speeds_y_size = grid_width * (grid_height -1)
	
func _init_arrays():	
	GridVectorMath. fill_all(mass,grid_size, 0)
	GridVectorMath. fill_all(temp_mass,grid_size, 0)
	GridVectorMath. fill_all(surface,grid_size, 0)
	GridVectorMath. fill_all(speeds_x,speeds_x_size, 0)
	GridVectorMath. fill_all(speeds_y,speeds_y_size, 0)
	GridVectorMath. fill_rect(mass,grid_width, grid_height,grid_width/2, 0,grid_width/5,grid_height/10, 5.0)
		
	if do_noice:
		var noise :=SimpleHashNoise2D.new(13)
		noise.populate_packed(surface,grid_width,grid_height,Vector2.ONE*5.1)
		#GridVectorMath.mult_with_scalar(surface,3)

	GridVectorMath.add_x_add_y(surface,grid_width,grid_height, .1)
	GridVectorMath.fill_rect(surface,grid_width, grid_height,grid_width/4, grid_height/4,3,3, (grid_width/4+grid_height/4) * 0.1 + 1.0)


func _init_images_and_texs():
	surface_image = Image.create(grid_width,grid_height, false, Image.FORMAT_RF)	
	mass_image = Image.create(grid_width,grid_height, false, Image.FORMAT_RF)
	
	#surface_image_out = Image.create(grid_width,grid_height, false, Image.FORMAT_RF)
	#mass_image_out = Image.create(grid_width,grid_height, false, Image.FORMAT_RF)
	
	surface_tex = ImageTexture.create_from_image(surface_image)
	mass_tex = ImageTexture.create_from_image(mass_image)
	
	#print("")
	
	
	

func _set_init_images():
	ImageTextureUtils.update_surface_and_mass_textures(surface,surface_image,surface_tex,mass,mass_image,mass_tex,grid_width,grid_height)


func _init_rendering_device() -> void:
	rd = RenderingServer.get_rendering_device()
	print("RenderingServer :" , rd)
	var shader_path := "res://tutorials/rendering_server_image/compute_diffuse_image.glsl"
	var shader_file: RDShaderFile = load(shader_path)
	var spirv: RDShaderSPIRV = shader_file.get_spirv()
	
	mass_shader = rd.shader_create_from_spirv(spirv)
	
	# 3) Make sure our Images are RF (float, 1 channel).
	#do not worry they are RF.
	
	# 4) Create RD textures for input and output (R32_SFLOAT, storage-capable).
	var fmt := RDTextureFormat.new()
	fmt.width = grid_width
	fmt.height = grid_height
	fmt.texture_type = RenderingDevice.TEXTURE_TYPE_2D
	fmt.format = RenderingDevice.DATA_FORMAT_R32_SFLOAT  # matches layout(r32f)
	fmt.mipmaps = 1
	fmt.usage_bits = (
		RenderingDevice.TEXTURE_USAGE_STORAGE_BIT          # image2D read/write in compute
		| RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT       # can be sampled in other shaders
		| RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT  # CPU readback
		| RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT     # CPU upload
	)
	var view := RDTextureView.new()
	
	#4.5: Initialize input with current mass_image, output with mass_image_out.
	
	mass_in_tex_rd = rd.texture_create(fmt, view, [mass_image.get_data()])
	#mass_out_tex_rd = rd.texture_create(fmt, view, [mass_image_out.get_data()])
	mass_out_tex_rd = rd.texture_create(fmt, view, [mass_image.get_data()])
	#create Texture2DRD
	mass_tex_rd = Texture2DRD.new()
	mass_tex_rd.texture_rd_rid = mass_in_tex_rd  # current state visible to water shader	
	
	
	# 5) Uniform buffer (Params block: width, height, diffusion, pad).
	var params_floats := PackedFloat32Array([
		float(grid_width),
		float(grid_height),
		diffusion,
		0.0  # padding
	])
	
	var params_bytes := params_floats.to_byte_array()
	mass_params_ubo = rd.uniform_buffer_create(params_bytes.size(), params_bytes)
	
	# 6) Create the uniform set: in_image, out_image, Params.
	_rebuild_uniform_set()
	# 7) create pipeline:
	mass_pipeline = rd.compute_pipeline_create(mass_shader)

	
	
func _rebuild_uniform_set():
	var u_in := RDUniform.new()
	u_in.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	u_in.binding = 0
	u_in.add_id(mass_in_tex_rd)
	
	var u_out := RDUniform.new()
	u_out.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	u_out.binding = 1
	u_out.add_id(mass_out_tex_rd)
	
	var u_params := RDUniform.new()
	u_params.uniform_type = RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER
	u_params.binding = 2
	u_params.add_id(mass_params_ubo)	
	
	mass_uniform_set = rd.uniform_set_create([u_in, u_out, u_params], mass_shader, 0)
	
	
	
	
func _physics_process(delta: float) -> void:
	simulation_step()
	WaterAndGroundSimUtils.update_water_shader_params(water_mat,surface_tex,mass_tex_rd,2.0, -0.01)
	



func simulation_step():
	# rd should be not null
	#1 ) no need to update params
	
	# 2) Record compute commands.
	#print("rd: " , rd)
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, mass_pipeline)
	rd.compute_list_bind_uniform_set(compute_list, mass_uniform_set, 0)
	
	# Work group counts for local_size_x = 8, local_size_y = 8
	
	var groups_x := IntCalc.div_round_up(grid_width, 8 )  # (a + b - 1) / b
	var groups_y  := IntCalc.div_round_up(grid_height , 8 )  
	
	rd.compute_list_dispatch(compute_list, groups_x, groups_y, 1)
	rd.compute_list_end()
	
	# 3) Ensure compute writes are visible this frame.
	#deprecated barriers are autimatically inserted by rendering device.
	#rd.barrier(RenderingDevice.BARRIER_MASK_COMPUTE)
	# Now the latest result is in mass_out_tex_rd.
	# Swap so that next frame reads from the latest result:
	_swap_mass_textures_and_uniforms()
	# After swap, mass_in_tex_rd == "current state".
	# Tell the Texture2DRD to show that texture:
	mass_tex_rd.texture_rd_rid = mass_in_tex_rd
	
	
func _swap_mass_textures_and_uniforms():
	# Swap RIDs
	var tmp := mass_in_tex_rd
	mass_in_tex_rd = mass_out_tex_rd
	mass_out_tex_rd = tmp
	_rebuild_uniform_set()
	
	
	
	
func _init_mesh_instance_with_shader_material():
	var cell_step := 1.0
	var grid_mesh := ArrayMeshBuilder.new_grid_array_mesh(grid_width,grid_height,cell_step,cell_step)
	
	water_mat = WaterAndGroundSimUtils.new_water_shader_visuals(self, grid_mesh)
	ground_mat = WaterAndGroundSimUtils.new_ground_shader_visuals(self, grid_mesh)
	
	WaterAndGroundSimUtils.update_ground_shader_params(ground_mat, surface_tex,2.0)
