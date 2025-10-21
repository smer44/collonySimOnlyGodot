extends RefCounted
class_name GridSim

var grid_width: int
var grid_height: int

var grid_size
var speeds_x_size
var speeds_y_size

var mass: PackedFloat32Array = PackedFloat32Array()
var speeds_x: PackedFloat32Array = PackedFloat32Array()
var speeds_y: PackedFloat32Array = PackedFloat32Array()
var pressure: PackedFloat32Array = PackedFloat32Array()
var div: PackedFloat32Array = PackedFloat32Array()

var dt_mass := 10.0 / 60
var dt_speed := 10.0 / 60
var dt_pressure := 10.0 / 60
var add_mode := 0

var temp := PackedFloat32Array()
var temp_speeds_x: PackedFloat32Array = PackedFloat32Array()
var temp_speeds_y: PackedFloat32Array = PackedFloat32Array()

func _init(w:int, h:int)  -> void:	
	_init_sizes(w,h)
	_init_arrays()
	#print("GridSim_ ready done")
	
func _init_sizes(w:int, h:int):
	grid_width = w
	grid_height = h
	grid_size = grid_width * grid_height
	speeds_x_size = (grid_width -1) * grid_height
	speeds_y_size = grid_width * (grid_height -1)
	#print("GridSim_ _update_sizes done")
	 
func simulation_step():
	update_mass()
	update_speed_by_mass()
	#apply_gravity(0.1)
	#print_max_mass()
	#blur_speed(0.0)
	
func _simulation_step_v2():
	update_mass()
	update_pressure_by_divergence(1)
	
	
	
func update_mass():
	WaterSimCalc.move_mass(mass,temp,speeds_x,speeds_y,grid_width,grid_height,dt_mass)
	#WaterSimCalc.move_mass_momentum(mass,temp,temp_speeds_x, temp_speeds_y, speeds_x,speeds_y,grid_width,grid_height,dt_mass)
	
	

func print_max_mass():
	var max_mass = GridVectorMath.max_of_all(mass)
	
	var total_mass = GridVectorMath.sum_of_all(mass)
	print("max mass:" , max_mass, ", total mass:" , total_mass)
	
func update_speed_by_mass():
	WaterSimCalc.update_speed(mass,speeds_x,speeds_y,grid_width,grid_height,dt_speed)
	
func update_pressure_by_divergence(n:int):
	GridPhysicks2D.divergence_2d(div,speeds_x,speeds_y,grid_width,grid_height)
	for i in range(n):
		WaterSimCalc.pressure_update_at_index(pressure,temp,div, grid_width,grid_height,dt_pressure)
		#now, temp is new values, swap them:
		var swap:= pressure
		pressure = temp
		temp = swap
	WaterSimCalc.apply_pressure_to_speeds(pressure,speeds_x,speeds_y,grid_width,grid_height,dt_speed)

	
		
	
	
func apply_gravity(dg : float):
	GridVectorMath.add_to_all(speeds_y, dg)
	
func blur_speed(rate : float):
	GridPhysicks2D.diffuse_scalar(speeds_x,temp_speeds_x, grid_width-1,grid_height,rate)
	var tmp := speeds_x
	speeds_x = temp_speeds_x
	temp_speeds_x = tmp	
	GridPhysicks2D.diffuse_scalar(speeds_y,temp_speeds_y, grid_width,grid_height-1,rate)
	tmp = speeds_y
	speeds_y = temp_speeds_y
	temp_speeds_y = tmp		
	
func test_change():
	GridVectorMath.decay_to_all(mass,grid_width,grid_height,dt_mass)
	



func _init_arrays():
	
	GridVectorMath. fill_all(mass,grid_size, 0)
	GridVectorMath.fill_all(pressure,grid_size, 0)
	GridVectorMath.fill_all(div,grid_size, 0)
	GridVectorMath.fill_all(temp,grid_size , 0)
	GridVectorMath.fill_all(speeds_x,speeds_x_size, 0)
	GridVectorMath.fill_all(speeds_y,speeds_y_size, 0)
	GridVectorMath.fill_all(temp_speeds_x,speeds_x_size, 0)
	GridVectorMath.fill_all(temp_speeds_y,speeds_y_size, 0)
	#rectangle of mass inside:
	GridVectorMath.fill_rect(mass,grid_width, grid_height,grid_width/2, grid_height/2,grid_width/5,grid_height/5, 1.0)
	#line of speed inside:
	#fill_rect(speeds_x,grid_width, grid_height,grid_width/2, grid_height/2,grid_width/3,grid_height/10, 0.5)
	#fill_rect(speeds_y,grid_width, grid_height,grid_width/2, grid_height/2,grid_width/3,grid_height/10, 0.1)
	
	
func _input(event):
	if event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		var cell := WaterSimCalc.grid_cell_from_mouse_click(grid_width,grid_height,event)
		var spd := WaterSimCalc.grid_velocity_from_mouse_click(grid_width,grid_height,event, 10.0)
		_mouse_click_reaction(cell,spd)
	if event is InputEventKey:
		var e := event as InputEventKey
		if e.pressed and not e.echo and e.keycode == KEY_TAB:
			add_mode =  (add_mode + 1) % 3

func _mouse_click_reaction(cell : Vector2i, spd : Vector2):
	
		match  add_mode:
			0:
				GridVectorMath.fill_rect(mass,grid_width,grid_height,cell.x,cell.y,2,2,1.0)
			1:
				GridVectorMath.fill_rect(mass,grid_width,grid_height,cell.x,cell.y,2,2,0.0)
			2:
				GridVectorMath.fill_rect(speeds_x,grid_width,grid_height,cell.x,cell.y,2,2,spd.x)
				GridVectorMath.fill_rect(speeds_y,grid_width,grid_height,cell.x,cell.y,2,2,spd.y)		
			


		



	

	
