extends RefCounted
class_name SimpleHashNoise2DGPU

# GPU state
var rd: RenderingDevice
var noise_shader: RID
var noise_pipeline: RID
var noise_uniform_set: RID
var noise_params_ubo: RID
var out_noise: RID

# Noise params
var noise_width: int
var noise_height: int
var amplitude: float
var seed: int
var scale: Vector2

var shader_path: String = "res://tutorials/rendering_server_move_water/simple_hash_noise.glsl"

const LOCAL_SIZE_X := 8
const LOCAL_SIZE_Y := 8

func _init(
		width: int,
		height: int,
		scale: Vector2,
		amplitude: float,
		seed: int = 1234
	) -> void:
	_init_params(width, height, scale, amplitude, seed)
	_init_device()
	_load_compute_shader()
	_create_noise_texture()
	_create_params_ubo()
	_create_uniform_set()

# ------------------------------------------------------------
# INIT HELPERS
# ------------------------------------------------------------

func _init_params(
		width: int,
		height: int,
		in_scale: Vector2,
		in_amplitude: float,
		in_seed: int
	) -> void:
	noise_width = width
	noise_height = height
	amplitude = in_amplitude
	seed = in_seed
	scale = in_scale

func _init_device() -> void:
	rd = RenderingServer.get_rendering_device()

func _load_compute_shader() -> void:
	var shader_file: RDShaderFile = load(shader_path)
	RDUtils.print_errors_for_shader(shader_file)
	var spirv: RDShaderSPIRV = shader_file.get_spirv()
	noise_shader = rd.shader_create_from_spirv(spirv)
	print("SimpleHashNoise2DGPU shader:", noise_shader)
	noise_pipeline = rd.compute_pipeline_create(noise_shader)




func _create_noise_texture() -> void:
	var fmt := RDUtils.new_single_value_rd_texture_format(noise_width , noise_height)
	var view := RDTextureView.new()
	var zero_bytes := PackedByteArray()
	zero_bytes.resize(noise_width * noise_height*4)

	out_noise = rd.texture_create(fmt, view, [zero_bytes])

func _create_params_ubo() -> void:
	var params_floats := PackedFloat32Array([
		float(noise_width),
		float(noise_height),
		scale.x,
		scale.y,
		float(seed),
		amplitude,
	])

	noise_params_ubo = RDUtils.new_floats_ubo(rd,params_floats)



func _create_uniform_set() -> void:
	var u_image := RDUniform.new()
	u_image.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	u_image.binding = 0
	u_image.add_id(out_noise)

	var u_params := RDUniform.new()
	u_params.uniform_type = RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER
	u_params.binding = 1
	u_params.add_id(noise_params_ubo)

	noise_uniform_set = rd.uniform_set_create(
		[u_image, u_params],
		noise_shader,
		0
	)

# ------------------------------------------------------------
# PUBLIC API
# ------------------------------------------------------------

func generate_noise() -> void:
	var groups_x := IntCalc.div_round_up(noise_width, LOCAL_SIZE_X)
	var groups_y := IntCalc.div_round_up(noise_height, LOCAL_SIZE_Y)

	var cl := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(cl, noise_pipeline)
	rd.compute_list_bind_uniform_set(cl, noise_uniform_set, 0)
	rd.compute_list_dispatch(cl, groups_x, groups_y, 1)
	rd.compute_list_end()

# Optional helper if you ever want to change params at runtime
func update_params(new_scale: Vector2, new_amplitude: float, new_seed: int) -> void:
	scale = new_scale
	amplitude = new_amplitude
	seed = new_seed
	_create_params_ubo()
	_create_uniform_set()
