extends Node


func _ready():
	# 1) Create local rendering device
	var rd := RenderingServer.create_local_rendering_device()

	# 2) Load compute shader
	var shader_file_path := "res://tutorials/rendering_server_basic/mult_2_shader.glsl"
	var shader_file := load(shader_file_path)
	
	print("shader_file: ", shader_file)
	print("shader_file class: ", shader_file.get_class())


	var spirv = shader_file.get_spirv()

	print("spirv dict:", spirv)
	print("bytecode_compute len:", spirv.bytecode_compute.size())
	#if bytecode len is 0 , 
	#Delete the old .glsl.import file so Godot reimports.
	print("compile_error_compute: ", spirv.compile_error_compute)
		
	var shader := rd.shader_create_from_spirv(spirv)
	print("shader RID:", shader)
	# 3) Input data: 4 numbers
	var input := PackedFloat32Array([1.0, 2.0, 3.0, 4.0])
	var input_bytes := input.to_byte_array()

	# 4) Create storage buffer on GPU
	var buffer := rd.storage_buffer_create(input_bytes.size(), input_bytes)

	# 5) Bind buffer as uniform set 0, binding 0
	var uniform := RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform.binding = 0
	uniform.add_id(buffer)

	var uniform_set := rd.uniform_set_create([uniform], shader, 0)
	print("uniform_set RID:", uniform_set)
	# 6) Create compute pipeline
	var pipeline := rd.compute_pipeline_create(shader)
	print("pipeline RID:", pipeline)
	
	# 7) Record commands: use pipeline + uniforms + dispatch
	var compute_list_id := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list_id, pipeline)
	rd.compute_list_bind_uniform_set(compute_list_id, uniform_set, 0)
	rd.compute_list_dispatch(compute_list_id, 1, 1, 1) # 1 group * 4 threads = 4 values
	rd.compute_list_end()

	# 8) Run and wait for result
	rd.submit()
	rd.sync()

	# 9) Read back and print
	var output_bytes := rd.buffer_get_data(buffer)
	var output := output_bytes.to_float32_array()
	print("Input:  ", input)
	print("Output: ", output)

	# 10) Cleanup
	
	#pipeline → uniform_set → buffer → shader.
	rd.free_rid(pipeline)
	rd.free_rid(uniform_set)
	rd.free_rid(buffer)
	rd.free_rid(shader)
