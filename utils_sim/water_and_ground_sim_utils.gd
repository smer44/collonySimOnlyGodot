extends Node
class_name WaterAndGroundSimUtils


static func new_ground_standart_visuals(parent: Node, input_mesh : Mesh ) -> StandardMaterial3D:
	var ground_mat := StandardMaterial3D.new()
	ground_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ground_mat.albedo_color = Color(0.6, 0.6, 0.6)

	var ground_instance := MeshUtils.mesh_instance_child(parent, input_mesh,ground_mat)

	return 	ground_mat

static func new_water_standart_visuals(parent: Node, input_mesh : Mesh ) -> StandardMaterial3D:
	var water_mat := StandardMaterial3D.new()
	water_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	water_mat.albedo_color = Color(0.2, 0.4, 0.8, 0.6)  # semi-transparent
	water_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var water_instance := MeshUtils.mesh_instance_child(parent, input_mesh,water_mat)
	#water_instance.set_surface_override_material(0, water_mat)		
	water_instance.transform.origin.y = 0.001  # tiny offset to avoid z-fighting
	return 	water_mat
	

	
static func new_ground_shader_visuals(parent: Node, input_mesh : Mesh ) -> ShaderMaterial:
	var ground_mat := ShaderMaterial.new()
	ground_mat.shader = make_ground_shader()
	var ground_instance :=MeshUtils. mesh_instance_child(parent, input_mesh, ground_mat)
	return ground_mat
	
	
static func new_water_shader_visuals(parent: Node, input_mesh : Mesh ) -> ShaderMaterial:
	var water_mat := ShaderMaterial.new()
	water_mat.shader = make_water_shader()
	var water_instance :=MeshUtils. mesh_instance_child(parent, input_mesh, water_mat)
	return water_mat

	
	

	
	
static func make_ground_shader() -> Shader:
	var s := Shader.new()
	s.code = """
shader_type spatial;
render_mode cull_back, depth_prepass_alpha;
uniform sampler2D surface_tex;
uniform float height_scale = 1.0;

void vertex() {
	float s = texture(surface_tex, UV).r;
	VERTEX.y = s * height_scale;
}

void fragment() {
// ground color:
ALBEDO = vec3(0.1, 0.15, 0.15);
}
"""
	return s
	
static func make_water_shader() -> Shader:
	var s := Shader.new()
	s.code = """
shader_type spatial;
render_mode cull_back, blend_mix, depth_prepass_alpha;

uniform sampler2D surface_tex;
uniform sampler2D mass_tex;
uniform float height_scale = 1.0;
uniform float bias = 0.0;

void vertex() {
float m = texture(mass_tex, UV).r;
float s = texture(surface_tex, UV).r;
VERTEX.y = (m + s) * height_scale + bias;
}
void fragment() {
// simple translucent blue water; can be replaced with PBR if desired
ALBEDO = vec3(0.2, 0.4, 0.8);
ALPHA = 0.6;
}
"""
	return s
	
static func update_material_params(ground_mat : ShaderMaterial, water_mat : ShaderMaterial , surface_tex: ImageTexture, mass_tex : ImageTexture , height_scale:float , z_bias_water:float) -> void:
	if ground_mat:
		ground_mat.set_shader_parameter("surface_tex", surface_tex)
		ground_mat.set_shader_parameter("height_scale", height_scale)
		#ground_mat.set_shader_parameter("bias", z_bias_ground)
	if water_mat:
		water_mat.set_shader_parameter("surface_tex", surface_tex)
		water_mat.set_shader_parameter("mass_tex", mass_tex)
		water_mat.set_shader_parameter("height_scale", height_scale)
		water_mat.set_shader_parameter("bias", z_bias_water)
	
static func update_ground_shader_params(ground_mat : ShaderMaterial , surface_tex: Texture,height_scale:float):
	ground_mat.set_shader_parameter("surface_tex", surface_tex)
	ground_mat.set_shader_parameter("height_scale", height_scale)
		
static func update_water_shader_params(water_mat : ShaderMaterial , surface_tex: Texture, mass_tex : Texture ,height_scale:float , z_bias_water:float):
	water_mat.set_shader_parameter("surface_tex", surface_tex)
	water_mat.set_shader_parameter("mass_tex", mass_tex)
	water_mat.set_shader_parameter("height_scale", height_scale)
	water_mat.set_shader_parameter("bias", z_bias_water)	
		


	
