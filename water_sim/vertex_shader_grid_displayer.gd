extends Node3D
class_name MyShaderGridDisplayer


@export var cell_step: float = 1.0
@export var height_scale: float = 2.0
@export var start_size_x: int = 40
@export var start_size_y: int = 40
@export var auto_run: bool = true

@export var z_bias_water: float = -0.01 # tweak if you see z-fighting

var sim: WaterSimTopDownOnSurace
var grid_mesh: ArrayMesh
var ground_instance: MeshInstance3D
var water_instance: MeshInstance3D


var ground_mat: ShaderMaterial
var water_mat: ShaderMaterial

var surface_image: Image
var mass_image: Image
var surface_tex: ImageTexture
var mass_tex: ImageTexture
@export var use_shaders := true

func _ready() -> void:
	# Initialize simulation
	sim = WaterSimTopDownOnSurace.new(start_size_x, start_size_y)
	# Build a single shared grid mesh with one vertex per *cell center*
	#todo - extract to grid utils
	var arrays := ArrayMeshBuilder._build_grid_plane(sim.grid_width,sim.grid_height,cell_step,cell_step)
	grid_mesh = ArrayMesh.new()
	grid_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	if use_shaders:
		_build_instances_and_shader_materials()
	else:
		_build_instances_and_standart_materials()  
	
	
	
func _build_instances_and_shader_materials() -> void:
	ground_instance = MeshInstance3D.new()
	ground_instance.mesh = grid_mesh
	add_child(ground_instance)	
	ground_mat = ShaderMaterial.new()
	ground_mat.shader = _make_ground_shader()
	ground_instance.set_surface_override_material(0, ground_mat)	
	water_instance = MeshInstance3D.new()
	water_instance.mesh = grid_mesh
	add_child(water_instance)


	water_mat = ShaderMaterial.new()
	water_mat.shader = _make_water_shader()
	water_instance.set_surface_override_material(0, water_mat)
	
func _build_instances_and_standart_materials() -> void:
	# Ground
	ground_instance = MeshInstance3D.new()
	ground_instance.mesh = grid_mesh
	add_child(ground_instance)

	var ground_mat := StandardMaterial3D.new()
	ground_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ground_mat.albedo_color = Color(0.6, 0.6, 0.6)
	ground_instance.set_surface_override_material(0, ground_mat)

	# Water (second plane)
	water_instance = MeshInstance3D.new()
	water_instance.mesh = grid_mesh
	add_child(water_instance)
	water_instance.transform.origin.y = 0.001  # tiny offset to avoid z-fighting

	var water_mat := StandardMaterial3D.new()
	water_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	water_mat.albedo_color = Color(0.2, 0.4, 0.8, 0.6)  # semi-transparent
	water_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water_instance.set_surface_override_material(0, water_mat)	


func _physics_process(_delta: float) -> void:
	if auto_run:
		sim.simulation_step()
	# Update texture data from the CPU arrays to the GPU textures each tick
	_update_textures()
	_update_material_params(ground_mat,water_mat,surface_tex,mass_tex)
	
func _update_material_params(ground_mat : ShaderMaterial, water_mat : ShaderMaterial , surface_tex: ImageTexture, mass_tex : ImageTexture) -> void:
	if ground_mat:
		ground_mat.set_shader_parameter("surface_tex", surface_tex)
		ground_mat.set_shader_parameter("height_scale", height_scale)
		#ground_mat.set_shader_parameter("bias", z_bias_ground)
	if water_mat:
		water_mat.set_shader_parameter("surface_tex", surface_tex)
		water_mat.set_shader_parameter("mass_tex", mass_tex)
		water_mat.set_shader_parameter("height_scale", height_scale)
		water_mat.set_shader_parameter("bias", z_bias_water)


	

		

func _make_ground_shader() -> Shader:
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
"""
	return s
	
func _make_water_shader() -> Shader:
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
	
func _ensure_images_and_textures(surface_image :Image, surface_tex :ImageTexture,mass_image: Image,  mass_tex : ImageTexture ) -> void:
# Create images/textures on first use or when the grid size changes
	if surface_image == null or surface_image.get_width() != sim.grid_width or surface_image.get_height() != sim.grid_height:
		surface_image = Image.create(sim.grid_width, sim.grid_height, false, Image.FORMAT_RF)
		surface_tex = ImageTexture.create_from_image(surface_image)
	if mass_image == null or mass_image.get_width() != sim.grid_width or mass_image.get_height() != sim.grid_height:
		mass_image = Image.create(sim.grid_width, sim.grid_height, false, Image.FORMAT_RF)
		mass_tex = ImageTexture.create_from_image(mass_image)	

static func _ensure_texture_from_image(surface_image :Image, surface_tex :ImageTexture, w : int , h : int )-> Array:
	if surface_image == null or surface_image.get_width() != w or surface_image.get_height() != h:	
		surface_image = Image.create(w, h, false, Image.FORMAT_RF)
		surface_tex = ImageTexture.create_from_image(surface_image)
	return [surface_image, surface_tex]
		
		

func _update_textures( ) -> void:
	var image_and_tex := _ensure_texture_from_image(surface_image,surface_tex,sim.grid_width, sim.grid_height )
	surface_image = image_and_tex[0]
	surface_tex = image_and_tex [1]
	image_and_tex = _ensure_texture_from_image(mass_image,mass_tex,sim.grid_width, sim.grid_height )
	mass_image = image_and_tex[0]
	mass_tex = image_and_tex [1]	
	
	
	# Write floats into the R channel of both images
	#surface_image.lock()
	#mass_image.lock()	
	var i := 0
	for gy in range(sim.grid_height):
		for gx in range(sim.grid_width):	
			surface_image.set_pixel(gx, gy, Color(sim.surface[i], 0, 0, 1))
			mass_image.set_pixel(gx, gy, Color(sim.mass[i], 0, 0, 1))
			i += 1
	#surface_image.unlock()
	#mass_image.unlock()	
		
	# Push to GPU
	surface_tex.update(surface_image)
	mass_tex.update(mass_image)
	
	
