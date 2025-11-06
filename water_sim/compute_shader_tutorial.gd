extends Node

@export var sim_size := Vector2i(256, 256)
@export var height_scale := 1.0

# Example sim container (replace with your real one if already present)
var sim := WaterSimTopDownOnSurace.new(sim_size.x, sim_size.y)

var surface_tex: Texture2D
var mass_out_tex: ImageTexture # what we bind to the water material each frame

var water_mesh: MeshInstance3D

# --- RenderingDevice / Compute handles ---

var rd: RenderingDevice
var shader_rid: RID
var pipeline_rid: RID

var mass_tex_a: RID # RD texture (R32F): current input
var mass_tex_b: RID # RD texture (R32F): current output

#RID - A handle for a Resource's unique identifier.

var uset_a_to_b: RID # uniform set: mass_in = A, mass_out = B
var uset_b_to_a: RID # uniform set: mass_in = B, mass_out = A
var use_a_to_b := true

var sampler_rid: RID

func _ready():
	_init_surface_texture()
	_init_mesh_and_material()
	_init_rd_and_compute()
	_init_mass_textures_from_sim()
	_build_uniform_sets()


	set_process(true)
	
func _process(_dt):
	_run_compute_step()
	_read_back_into_temp_mass_and_texture()
	_swap_sim_arrays_and_rids()
	
# ------------------------------------------------------------
# Setup helpers
# ------------------------------------------------------------

static func grid_2d_to_image(grid: PackedFloat32Array, image: Image, w: int, h: int) -> void:
	var i := 0
	#image.lock()
	for y in range(h):
		for x in range(w):
			image.set_pixel(x, y, Color(grid[i], 0, 0, 1))
			i += 1
	#image.unlock()
	
func _init_surface_texture() -> void:
	var img := Image.create(sim_size.x, sim_size.y, false, Image.FORMAT_RF)
	grid_2d_to_image(sim.surface, img, sim_size.x, sim_size.y)
	surface_tex = ImageTexture.create_from_image(img)	
	
	
func _init_mesh_and_material() -> void:
	var arrays := ArrayMeshBuilder._build_grid_plane(sim_size.x, sim_size.y, 1.0, 1.0)
	var grid_mesh := ArrayMesh.new()
	grid_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)


	water_mesh = MeshInstance3D.new()
	water_mesh.mesh = grid_mesh
	add_child(water_mesh)


	# We update this texture every frame from the compute output
	var out_img := Image.create(sim_size.x, sim_size.y, false, Image.FORMAT_RF)
	mass_out_tex = ImageTexture.create_from_image(out_img)


	var mat := ShaderMaterial.new()
	mat.shader = load("res://water_sim/water_displace.gdshader")
	mat.set_shader_parameter("surface_tex", surface_tex)
	mat.set_shader_parameter("mass_tex", mass_out_tex)
	mat.set_shader_parameter("height_scale", height_scale)


	water_mesh.set_surface_override_material(0, mat)
	
	
	
func _init_rd_and_compute() -> void:
	rd = RenderingServer.get_rendering_device()


	# Optional: create an explicit NEAREST/CLAMP sampler for the input sampler2D
	var samp := RDSamplerState.new()
	samp.min_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
	samp.mag_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
	samp.repeat_u = RenderingDevice.SAMPLER_REPEAT_MODE_CLAMP_TO_EDGE
	samp.repeat_v = RenderingDevice.SAMPLER_REPEAT_MODE_CLAMP_TO_EDGE
	#samp.repeat_w = RenderingDevice.SAMPLER_REPEAT_MODE_CLAMP_TO_EDGE
	sampler_rid = rd.sampler_create(samp)

	#var compute_shader_path := "res://water_sim/example_compute_shader.gdshader"
	var compute_shader_path :=  "res://water_sim/mass_op.glsl"

	var sh_res :RDShaderFile= load(compute_shader_path)
	var spirv :  = sh_res.get_spirv()
	#rd.shader_create_from_bytecode()
	shader_rid = rd.shader_create_from_spirv(spirv)
	pipeline_rid = rd.compute_pipeline_create(shader_rid)
	
func _init_mass_textures_from_sim() -> void:
	# Create two RD textures in R32F, one seeded from sim.mass, one empty
	var fmt := RDTextureFormat.new()
	fmt.width = sim_size.x
	fmt.height = sim_size.y
	fmt.format = RenderingDevice.DATA_FORMAT_R32_SFLOAT
	fmt.usage_bits = (
	RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT |
	RenderingDevice.TEXTURE_USAGE_STORAGE_BIT |
	RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT |
	RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	)


	var view := RDTextureView.new()


	var img := Image.create(sim_size.x, sim_size.y, false, Image.FORMAT_RF)
	grid_2d_to_image(sim.mass, img, sim_size.x, sim_size.y)
	var bytes := img.get_data()


	mass_tex_a = rd.texture_create(fmt, view, [bytes])
	mass_tex_b = rd.texture_create(fmt, view)
	
	
func _build_uniform_sets() -> void:
	# Build two uniform sets: A→B and B→A (so we can ping‑pong)
	uset_a_to_b = _make_uniform_set(mass_tex_a, mass_tex_b)
	uset_b_to_a = _make_uniform_set(mass_tex_b, mass_tex_a)
	
func _make_uniform_set(tex_in: RID, img_out: RID) -> RID:
	var u_sampler := RDUniform.new()
	u_sampler.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	u_sampler.binding = 0
	# Order for SAMPLER_WITH_TEXTURE: first sampler RID, then texture RID
	u_sampler.add_id(sampler_rid)
	u_sampler.add_id(tex_in)


	var u_image := RDUniform.new()
	u_image.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	u_image.binding = 1
	u_image.add_id(img_out)


	return rd.uniform_set_create([u_sampler, u_image], shader_rid, 0)
	
# ------------------------------------------------------------
# Compute step
# ------------------------------------------------------------

func _run_compute_step() -> void:
	var cl := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(cl, pipeline_rid)


	var uset := uset_a_to_b  if use_a_to_b else uset_b_to_a
	rd.compute_list_bind_uniform_set(cl, uset, 0)


	var gx := int(ceil(float(sim_size.x) / 8.0))
	var gy := int(ceil(float(sim_size.y) / 8.0))
	rd.compute_list_dispatch(cl, gx, gy, 1)


	rd.compute_list_end()
	rd.submit()
	rd.sync() # block until the GPU work is done so we can read back


func _read_back_into_temp_mass_and_texture() -> void:
	# Read whichever texture the shader wrote *to* this frame
	var wrote_to :=  mass_tex_b  if use_a_to_b else mass_tex_a
	var bytes: PackedByteArray  = rd.texture_get_data(wrote_to, 0)
	var out_img := Image.create_from_data(
		sim_size.x, sim_size.y,
		false,
		Image.FORMAT_RF,   # use Image.FORMAT_RH if your RD texture is R16F
		bytes
	)	


	# Update the on‑screen texture for the mesh material
	mass_out_tex.update(out_img)


	# Also copy into sim.temp_mass (simple example; optimize as needed)
	#out_img.lock()
	var i := 0
	for y in range(sim_size.y):
		for x in range(sim_size.x):
			sim.temp_mass[i] = out_img.get_pixel(x, y).r
			i += 1
	#out_img.unlock()
	
	
func _swap_sim_arrays_and_rids() -> void:
	# Swap CPU arrays
	var tmp := sim.mass
	sim.mass = sim.temp_mass
	sim.temp_mass = tmp


	# Flip the ping‑pong direction for next dispatch
	use_a_to_b = !use_a_to_b
