extends Node
class_name ShaderGridDisplayer

@export var grid_view: CanvasItem
var sim : GridSim
@export var palette_colors: Array[Color] = [
	Color8(13, 27, 43),    # deep navy
	Color8(42, 111, 223),  # royal blue
	Color8(34, 211, 238),  # cyan
	Color8(52, 211, 153),  # aqua green
	Color8(163, 230, 53),  # lime
	Color8(250, 204, 21),  # yellow
	Color8(251, 146, 60),  # orange
	Color8(217, 70, 239)   # magenta
]



var mat: ShaderMaterial
var img: Image
var tex: ImageTexture

func _ready() -> void:
	sim = GridSim.new(40,40)
	_init_shader()
	

func _physics_process(delta: float) -> void:
	sim.simulation_step()
	update_display()
	
func _input(event):
	sim._input(event)

func _init_shader():
	mat = grid_view.material as ShaderMaterial
	var pal_tex := make_palette_texture(palette_colors)
	mat.set_shader_parameter("palette_tex", pal_tex)
	mat.set_shader_parameter("palette_count", palette_colors.size())	
	img = Image.create(sim.grid_width, sim.grid_height, false, Image.FORMAT_RGB8)
	tex = ImageTexture.create_from_image(img)	
	
	

func update_display():
	update_amount_texture(tex,sim.mass,sim.grid_width, sim.grid_height)
	#update_speed_texture(tex,speeds_x,speeds_y,grid_width,grid_height)
	#apply_friction(new_grid,size)
	mat.set_shader_parameter("speed_tex", tex)
	#swap_buffers()


static func update_amount_texture(tex: ImageTexture,  g: Array, grid_width:int, grid_height: int) :
	var img := tex.get_image()
	#img.lock()
	for j in grid_height:
		for i in grid_width:
			var v :float= g[GridIndexingCalc.idx(i, j, grid_width)]
			#v = (v-1.0)*0.5+ 0.5
			#v = (v-1.0) * 10.0 + 1.0
			v = clampf(v, 0.0, 1.0)
			img.set_pixel(i, j, Color(0, v/2, v)) 			
			
	tex.update(img)
	
static func update_speed_texture(tex: ImageTexture,  speeds_x: Array,speeds_y: Array, grid_width:int, grid_height: int) :
	var img := tex.get_image()
	#img.lock()
	for j in grid_height-1:
		for i in grid_width-1:
			var vx :float= speeds_x[GridIndexingCalc.idx(i, j, grid_width-1)]
			var vy :float= speeds_y[GridIndexingCalc.idx(i, j, grid_width)]
			#v = (v-1.0)*0.5+ 0.5
			#v = (v-1.0) * 10.0 + 1.0
			var vx_pos = clampf(vx, 0.0, 1.0)
			var vx_neg = clampf(-vx, 0.0, 1.0)
			vy = clampf(vy, 0.0, 1.0)
			img.set_pixel(i, j, Color(vx_pos, vy, vx_neg)) 			
			
	tex.update(img)
	
static func make_palette_texture(palette_colors: Array[Color] ) -> ImageTexture:
	var n :int= max(1, palette_colors.size())
	var img := Image.create(n, 1, false, Image.FORMAT_RGBA8)
	#img.lock()
	for i in n:
		img.set_pixel(i, 0, palette_colors[i])
	#img.unlock()
	return ImageTexture.create_from_image(img)
	
	
