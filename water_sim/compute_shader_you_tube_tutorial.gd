extends Node

func _ready() -> void:
	
	# abstractions of lower level API like Opengl or Vulcan
	var  rd:RenderingDevice= RenderingServer.get_rendering_device()
	print(rd)
	#RID are shaders, textures or other data 
	#RID are not ffreed automatically, to ffree it you call:
	#free_rid(RID)
	#if you do not free it you create a memory leak
	
	var shader_file := preload("res://water_sim/compute_shader_you_tube.glsl")
	#compile shader:
	var shader := rd.shader_create_from_spirv(shader_file.get_spirv())
	#create shader pipeline:
	var pipeline := rd.compute_pipeline_create(shader)
	
	#Uniforms- shader input and shader output 
	var input_data := PackedFloat32Array([0.9,1.2,0.5]).to_byte_array()
	var storage_buffer := rd.storage_buffer_create(input_data.size(), input_data)
	
	var image := preload("res://water_sim/sample_image.png")
	image.convert(Image.FORMAT_RGBAF)
	
	#Create texture view and ormat rd- objects:
	var texture_view :=RDTextureView.new()
	var texture_format := RDTextureFormat.new()
	texture_format.width = 1024
	texture_format.height = 1024 
	texture_format.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
	
	#flags:
	texture_format.usage_bits = (
		RenderingDevice.TEXTURE_USAGE_STORAGE_BIT + 
		RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT +
		RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT
		)
		
	
		
		
	
	
	
	
	
