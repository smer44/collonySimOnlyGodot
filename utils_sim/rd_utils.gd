extends RefCounted
class_name RDUtils

const DEFAULT_USAGE_BITS := \
	RenderingDevice.TEXTURE_USAGE_STORAGE_BIT |\
	RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT |\
	RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT |\
	RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT

static func new_single_value_rd_texture_format(w:int, h:int)-> RDTextureFormat:
	var fmt := RDTextureFormat.new()
	fmt.width = w
	fmt.height = h
	fmt.texture_type = RenderingDevice.TEXTURE_TYPE_2D
	fmt.format = RenderingDevice.DATA_FORMAT_R32_SFLOAT
	fmt.mipmaps = 1
	fmt.usage_bits = DEFAULT_USAGE_BITS
	return fmt
	
static func new_double_value_rd_texture_format(w:int, h:int)-> RDTextureFormat:
	var fmt := RDTextureFormat.new()
	fmt.width = w
	fmt.height = h
	fmt.texture_type = RenderingDevice.TEXTURE_TYPE_2D
	fmt.format = RenderingDevice.DATA_FORMAT_R32G32_SFLOAT
	fmt.mipmaps = 1
	fmt.usage_bits = DEFAULT_USAGE_BITS
	return fmt	
	
	


	
	
static func new_floats_ubo(rd: RenderingDevice, floats: PackedFloat32Array) -> RID:
	var data := floats.duplicate()
	
	# Pad to a multiple of 4 floats (16 bytes) for std140 alignment.
	var remainder := data.size() % 4
	if remainder != 0:
		var pad_count := 4 - remainder
		data.resize(data.size() + pad_count) # new entries are 0.0 by default
	
	var bytes := data.to_byte_array()
	return rd.uniform_buffer_create(bytes.size(), bytes)




static func print_errors_for_shader(shader_file: RDShaderFile) -> void:
	var shader_path := shader_file.resource_path
	if shader_file.base_error != "":
		push_error("Shader base error in %s:\n%s" % [shader_path, shader_file.base_error])
		return

	var versions := shader_file.get_version_list()
	if versions.is_empty():
		push_error("Shader '%s' has no compiled versions (check base_error or stage errors)" % shader_path)
		return

	for version in versions:
		var spirv: RDShaderSPIRV = shader_file.get_spirv(version)
		if spirv == null:
			push_error("Shader '%s' version '%s' has no SPIR-V (get_spirv() returned null)" % [shader_path, str(version)])
			continue

		var errors := {
			"compute":   spirv.compile_error_compute,
			"vertex":    spirv.compile_error_vertex,
			"fragment":  spirv.compile_error_fragment,
			"tess_ctrl": spirv.compile_error_tesselation_control,
			"tess_eval": spirv.compile_error_tesselation_evaluation,
		}

		for stage_name in errors.keys():
			var err: String = errors[stage_name]
			if err != "":
				push_error("Shader error in %s (version: %s, stage: %s):\n%s" % [
					shader_path, version, stage_name, err
				])
				
# Creating byte array for speeds texture with r and g values
static func _build_initial_speed_bytes(w:int , h:int, speeds_x :PackedFloat32Array, speeds_y :PackedFloat32Array,) -> PackedByteArray:
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
	
	
static func load_shader(rd : RenderingDevice , shader_path: String) -> RID:
	var shader_file: RDShaderFile = load(shader_path)
	RDUtils.print_errors_for_shader(shader_file)
	var spirv: RDShaderSPIRV = shader_file.get_spirv()
	var shader :RID = rd.shader_create_from_spirv(spirv)
	print("loaded shader :", shader_path , " : ",  shader)
	return shader
	
	
	
static func new_uniform_image(binding: int, array: RID , type : RenderingDevice.UniformType)-> RDUniform:
	var rdu := RDUniform.new()
	rdu.uniform_type = type
	rdu.binding = binding
	rdu.add_id(array)
	return rdu
	
static func new_uniform_set(rd:RenderingDevice,  arrays: Array[RID], types :Array[RenderingDevice.UniformType], shader_rid : RID) -> RID:
	var uniforms : Array[RDUniform] = []
	for i in range(arrays.size()):
		var rduniform := new_uniform_image(i,arrays[i], types[i])
		uniforms.append(rduniform)

	var uniform_set := rd.uniform_set_create(
		uniforms,
		shader_rid, 0
	)
	return uniform_set
