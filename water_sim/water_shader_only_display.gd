extends Node
@export var sim_size := Vector2i(256, 256)
@export var dt_mass := 0.1 /60
@export var dt_speed := 0.1 /60

var vp_mass_a: SubViewport
var vp_mass_b: SubViewport
var vp_speed_a: SubViewport
var vp_speed_b: SubViewport

var mat_move_mass: ShaderMaterial
var mat_update_speed: ShaderMaterial
var cell_step := 1.0

var surface_tex: Texture2D   
var surface_image: Image

var water_tex: Texture2D   
var water_image: Image


var water_mesh: MeshInstance3D 
var sim = WaterSimTopDownOnSurace.new(sim_size.x, sim_size.y)


			
			
func init_surface_tex():
	surface_image = Image.create(sim_size.x, sim_size.y, false, Image.FORMAT_RF)	

	ImageTextureUtils.array_to_image(sim.surface,surface_image, sim_size.x, sim_size.y)
	#create texture with filled image, means after grid_2d_to_image:
	surface_tex = ImageTexture.create_from_image(surface_image)
	
	water_image = Image.create(sim_size.x, sim_size.y, false, Image.FORMAT_RF)	
	ImageTextureUtils.array_to_image(sim.mass,water_image, sim_size.x, sim_size.y)
	water_tex = ImageTexture.create_from_image(water_image)
	
	
	
	
	
func init_mesh_instance():
	var arrays := ArrayMeshBuilder.build_grid_plane(sim_size.x, sim_size.y,cell_step,cell_step)
	var grid_mesh := ArrayMesh.new()
	grid_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	water_mesh = MeshInstance3D.new()
	water_mesh.mesh = grid_mesh
	
	add_child(water_mesh)
	

func init_shaders():
	mat_move_mass = ShaderMaterial.new()
	mat_move_mass.shader = load("res://water_sim/move_water.gdshader")
	mat_move_mass.set_shader_parameter("texel", Vector2(1.0/sim_size.x, 1.0/sim_size.y))
	mat_move_mass.set_shader_parameter("dt_mass", dt_mass)

	mat_update_speed = ShaderMaterial.new()
	mat_update_speed.shader = load("res://water_sim/update_speeds.gdshader")
	mat_update_speed.set_shader_parameter("texel", Vector2(1.0/sim_size.x, 1.0/sim_size.y))
	mat_update_speed.set_shader_parameter("dt_speed", dt_speed)
	mat_update_speed.set_shader_parameter("surface_tex", surface_tex)
	
	

func _ready():
	#create shapes:

	init_surface_tex()
	init_mesh_instance()
	init_shaders()
	
	# --- Build subviewports ---
	vp_mass_a = make_viewport(sim_size)
	vp_mass_b = make_viewport(sim_size)
	vp_speed_a = make_viewport(sim_size)
	vp_speed_b = make_viewport(sim_size)

	add_child(vp_mass_a)
	add_child(vp_mass_b)
	add_child(vp_speed_a)
	add_child(vp_speed_b)

	# --- Bootstrap textures ---
	# Start with zero mass & zero speeds
	#fill_viewport(vp_mass_a, Color(0.0,0,0,1),sim_size)
	#fill_viewport_with_elevation(vp_mass_a,water_tex,surface_tex,sim_size)
	fill_viewport_with_mass_texture(vp_mass_a, water_tex, sim_size)
	fill_viewport(vp_speed_a, Color(0.0,0,0,1),sim_size)
	await get_tree().process_frame

	# --- Materials for the two passes ---

	# Each viewport draws a ColorRect with the pass material
	# 
	vp_mass_a.add_child(make_fullscreen_rect(mat_move_mass, sim_size))
	vp_speed_a.add_child(make_fullscreen_rect(mat_update_speed, sim_size))
	vp_mass_b.add_child(make_fullscreen_rect(mat_move_mass, sim_size))
	vp_speed_b.add_child(make_fullscreen_rect(mat_update_speed, sim_size))

	# Hook water mesh material to sim textures
	var water_mat := ShaderMaterial.new()
	#shader missing ? 
	water_mat.shader = load("res://water_sim/water_displace.gdshader")
	water_mat.set_shader_parameter("surface_tex", surface_tex)
	water_mat.set_shader_parameter("mass_tex", vp_mass_a.get_texture())
	water_mesh.set_surface_override_material(0, water_mat)
		
	set_physics_process(true)
	
	
func _physics_process(_dt):
	# ----- PASS 1: move mass -----
	mat_move_mass.set_shader_parameter("mass_tex",  vp_mass_a.get_texture())
	mat_move_mass.set_shader_parameter("speed_tex", vp_speed_a.get_texture())
	vp_mass_b.render_target_update_mode = SubViewport.UPDATE_ONCE
	await get_tree().process_frame

	# swap mass ping-pong
	var tmp_vp = vp_mass_a; vp_mass_a = vp_mass_b; vp_mass_b = tmp_vp

	# ----- PASS 2: update speeds -----
	mat_update_speed.set_shader_parameter("mass_tex",  vp_mass_a.get_texture()) # new mass
	mat_update_speed.set_shader_parameter("speed_tex", vp_speed_a.get_texture())
	vp_speed_b.render_target_update_mode = SubViewport.UPDATE_ONCE
	await get_tree().process_frame

	# swap speed ping-pong
	tmp_vp = vp_speed_a; vp_speed_a = vp_speed_b; vp_speed_b = tmp_vp

	# Feed water material with current textures
	var water_mat := water_mesh.get_active_material(0) as ShaderMaterial
	water_mat.set_shader_parameter("mass_tex", vp_mass_a.get_texture())



static func make_viewport(sizei : Vector2i ) -> SubViewport:
	var vp := SubViewport.new()
	vp.size = sizei
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	vp.msaa_2d = Viewport.MSAA_DISABLED
	#vp.render_target_format = SubViewport.RENDER_TARGET_FORMAT_RGBA16F

	vp.transparent_bg = true # optional (for alpha)
	return vp
	
	
static func make_fullscreen_rect(mat: Material, sizei : Vector2i ) -> ColorRect:
	var r := ColorRect.new()
	r.color = Color.BLACK
	r.material = mat
	r.size = sizei
	r.position = Vector2.ZERO
	r.anchor_right = 1.0
	r.anchor_bottom = 1.0
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return r	
	
	
static func fill_viewport(vp: SubViewport, color: Color, sizei : Vector2i) -> void:
	var rect := ColorRect.new()
	rect.color = color
	rect.size = sizei
	vp.add_child(rect)
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE

static func make_canvas_elevation_blit_shader() -> Shader:
	var sh := Shader.new()
	sh.code = """
shader_type canvas_item;
uniform sampler2D water_tex;    // R = water mass
uniform sampler2D surface_tex;  // R = ground height
void fragment() {
    float w = texture(water_tex,   UV).r;
    float s = texture(surface_tex, UV).r;
    float elev = s ;//+ w;                 // water sits above ground
    COLOR = vec4(elev, 0.0, 0.0, 1.0);  // write elevation into R
}
"""
	return sh
	
static func make_canvas_mass_blit_shader() -> Shader:
	var sh := Shader.new()
	sh.code = """
shader_type canvas_item;
uniform sampler2D water_tex; // R = water mass
void fragment() {
    float w = texture(water_tex, UV).r;
    COLOR = vec4(w, 0.0, 0.0, 1.0); // write MASS into R
}
"""
	return sh
	
static func make_mass_blit_material(water_tex: Texture2D) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = make_canvas_mass_blit_shader()
	mat.set_shader_parameter("water_tex", water_tex)
	return mat
	



static func make_elevation_blit_material(water_tex: Texture2D, surface_tex: Texture2D) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = make_canvas_elevation_blit_shader()
	mat.set_shader_parameter("water_tex",   water_tex)
	mat.set_shader_parameter("surface_tex", surface_tex)
	return mat
	

static func fill_viewport_with_elevation(vp: SubViewport, water_tex: Texture2D, surface_tex: Texture2D, sizei: Vector2i) -> void:
	var r := ColorRect.new()
	r.color = Color.BLACK
	r.size = sizei
	r.position = Vector2.ZERO
	r.anchor_right = 1.0
	r.anchor_bottom = 1.0
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.size_flags_vertical = Control.SIZE_EXPAND_FILL
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED

	r.material = make_elevation_blit_material(water_tex, surface_tex)
	vp.add_child(r)
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	
static func fill_viewport_with_mass_texture(vp: SubViewport, water_tex: Texture2D, sizei: Vector2i) -> void:
	var r := ColorRect.new()
	r.color = Color.BLACK
	r.size = sizei
	r.anchor_right = 1.0
	r.anchor_bottom = 1.0
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.size_flags_vertical = Control.SIZE_EXPAND_FILL
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
	r.material = make_mass_blit_material(water_tex)
	vp.add_child(r)
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
