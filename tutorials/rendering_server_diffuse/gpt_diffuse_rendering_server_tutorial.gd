extends Node
var sim: WaterSimTopDownOnSurace


@export var start_size_x: int = 20
@export var start_size_y: int = 20


func _ready() -> void:
	sim = WaterSimTopDownOnSurace.new(start_size_x, start_size_y)
	
	
	var rd := RenderingServer.create_local_rendering_device()
	var file_path := "res://tutorials/rebdering_server_diffuse/compute_diffuse.glsl"
	var shader_file := load(file_path) as RDShaderFile
	var spirv := shader_file.get_spirv()
	var shader := rd.shader_create_from_spirv(spirv)

	var diffusion := 0.25

	# 1D input (size = width * height)

	var input := sim.surface
	print("input size:" , input.size())
	PP.print_array_2d(input, start_size_x )


	# ...fill input with some values...
	var in_bytes := input.to_byte_array()
	var out_bytes := PackedByteArray()
	out_bytes.resize(in_bytes.size())

	var in_buffer := rd.storage_buffer_create(in_bytes.size(), in_bytes)
	var out_buffer := rd.storage_buffer_create(out_bytes.size(), out_bytes)

	# uniform bufer has to be x16 bytes, so we pad it with zeros:
	# Params uniform buffer (width, height, diffusion, padding)
	var params_bytes := PackedFloat32Array([float(start_size_x), float(start_size_y), diffusion, 0.0]).to_byte_array()
	var params_buffer := rd.uniform_buffer_create(params_bytes.size(), params_bytes)

	var u_in := RDUniform.new()
	u_in.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	u_in.binding = 0
	u_in.add_id(in_buffer)

	var u_out := RDUniform.new()
	u_out.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	u_out.binding = 1
	u_out.add_id(out_buffer)

	var u_params := RDUniform.new()
	u_params.uniform_type = RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER
	u_params.binding = 2
	u_params.add_id(params_buffer)

	var uniform_set := rd.uniform_set_create([u_in, u_out, u_params], shader, 0)
	var pipeline := rd.compute_pipeline_create(shader)

	var groups_x :=  IntCalc.div_round_up(start_size_x , 8)  
	var groups_y :=  IntCalc.div_round_up(start_size_y , 8)
	
	print("groups:",  groups_x, groups_y, "size:" , in_bytes.size())
	
	var cl := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(cl, pipeline)
	rd.compute_list_bind_uniform_set(cl, uniform_set, 0)
	rd.compute_list_dispatch(cl, groups_x, groups_y, 1)
	rd.compute_list_end()

	rd.submit()
	rd.sync()

	var result_bytes := rd.buffer_get_data(out_buffer)
	var result := result_bytes.to_float32_array()
	print("Result size:", result.size())
	PP.print_array_2d(result, start_size_x )
