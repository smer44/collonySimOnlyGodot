extends RefCounted
class_name WaterSimTopDownOnSurace

var grid_width: int
var grid_height: int

var grid_size
var speeds_x_size
var speeds_y_size

var mass: PackedFloat32Array = PackedFloat32Array()
var temp_mass: PackedFloat32Array = PackedFloat32Array()
var surface: PackedFloat32Array = PackedFloat32Array()
var speeds_x: PackedFloat32Array = PackedFloat32Array()
var speeds_y: PackedFloat32Array = PackedFloat32Array()

var dt_mass := 2.0 / 60
var dt_speed := 2.0 / 60

func _init(w:int, h:int)  -> void:	
	_init_sizes(w,h)
	_init_arrays()
	
func _input(event):
	pass

func _init_sizes(w:int, h:int):
	grid_width = w
	grid_height = h
	grid_size = grid_width * grid_height
	speeds_x_size = (grid_width -1) * grid_height
	speeds_y_size = grid_width * (grid_height -1)
	
func _init_arrays():	
	GridVectorMath. fill_all(mass,grid_size, 0)
	GridVectorMath. fill_all(temp_mass,grid_size, 0)
	GridVectorMath. fill_all(surface,grid_size, 0)
	GridVectorMath.fill_all(speeds_x,speeds_x_size, 0)
	GridVectorMath.fill_all(speeds_y,speeds_y_size, 0)
	GridVectorMath.fill_rect(mass,grid_width, grid_height,grid_width/2, 0,grid_width/5,grid_height/10, 5.0)
	
	
	var do_noice :=true
	if do_noice:
		var noise :=SimpleHashNoise2D.new(13)
		noise.populate_packed(surface,grid_width,grid_height,Vector2.ONE*0.1)
		#GridVectorMath.mult_with_scalar(surface,3)

	GridVectorMath.add_x_add_y(surface,grid_width,grid_height, .1)
	GridVectorMath.fill_rect(surface,grid_width, grid_height,grid_width/4, grid_height/4,3,3, (grid_width/4+grid_height/4) * 0.1 + 1.0)
 
	
func simulation_step():
	WaterSimCalc.move_mass_on_surface(mass,temp_mass,speeds_x,speeds_y,grid_width,grid_height,dt_mass)
	var tmp :=mass
	mass = temp_mass 
	temp_mass = tmp
	WaterSimCalc.update_speed_for_surface(mass,surface, speeds_x,speeds_y,grid_width,grid_height,dt_speed)
	var total_mass = GridVectorMath.sum_of_all(mass)
	print("total_mass:" , total_mass)	
	
