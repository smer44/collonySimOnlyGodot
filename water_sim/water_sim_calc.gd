extends RefCounted
class_name WaterSimCalc



#this is sulution of a Poisson/Jacobi system for pressure, and can be run one or several times
static func pressure_update_at_index(pressure: PackedFloat32Array, pressure_out: PackedFloat32Array,  divergence: PackedFloat32Array, w: int, h: int, dt_pressure: float):

	for y in range(h):
		for x in range(w):
			var s := 0.0
			var nbrs := 0 
			if x > 0: 
				s += pressure[GridIndexingCalc.idx(x - 1, y, w)]
				nbrs +=1
			if x < w - 1:
				s += pressure[GridIndexingCalc.idx(x + 1, y, w)]
				nbrs +=1					
				
			if y > 0: 
				s += pressure[GridIndexingCalc.idx(x, y-1, w)]
				nbrs +=1	
			if y < h - 1: 
				s += pressure[GridIndexingCalc.idx(x, y + 1, w)]
				nbrs +=1 
			var i := GridIndexingCalc.idx(x, y, w)
			if nbrs > 0:				
				pressure_out[i] = (s - divergence[i]*dt_pressure) / nbrs
			else:
				pressure_out[i] =  0.0

			
	


			
static func apply_pressure_to_speeds(pressure: PackedFloat32Array, speeds_x: PackedFloat32Array, speeds_y: PackedFloat32Array, w:int, h:int, dt_pressure: float) -> void:
	for y in range(h):
		for x in range(w - 1):
			var sx := GridIndexingCalc.idx(x, y, w - 1)
			var a := GridIndexingCalc.idx(x, y, w)
			var b := GridIndexingCalc.idx(x + 1, y, w)
			speeds_x[sx] -= (pressure[b] - pressure[a]) * dt_pressure

	for y in range(h - 1):
		for x in range(w):
			var sy := GridIndexingCalc.idx(x, y, w)
			var a := GridIndexingCalc.idx(x, y, w)
			var b := GridIndexingCalc.idx(x, y + 1, w)
			speeds_y[sy] -= (pressure[b] - pressure[a]) * dt_pressure


			
	

	

static func move_mass_on_surface(mass: PackedFloat32Array,								
								temp_mass : PackedFloat32Array, 
								speeds_x: PackedFloat32Array, 
								speeds_y: PackedFloat32Array, 
								width: int, 
								height: int, 
								dt_mass: float) -> void:		

	var clamp_factor := 0.5

	var width_m_1 = width - 1
	var row:=0
	
	for i in range(mass.size()):
		temp_mass[i] = mass[i]
	for y in range(height):		
		for i in range(row, row + width_m_1):
			var j := i+1
			var i_speed := i-y
			move_mass_between_cells(mass,temp_mass,speeds_x,i,j,i_speed, dt_mass,clamp_factor)	
		row+=width
	row=0
	for y in range(height - 1):
		for i in range(row, row + width):
			var j := i+width
			move_mass_between_cells(mass,temp_mass,speeds_y,i,j,i,dt_mass,clamp_factor)
		row+=width

			

	
	
static func move_mass(mass: PackedFloat32Array,temp_mass : PackedFloat32Array, speeds_x: PackedFloat32Array, speeds_y: PackedFloat32Array, width: int, height: int, dt_mass: float) -> void:
	var size := width * height
	var clamp_factor := 0.5
	for i in range(size):
		temp_mass[i] = mass[i]


	# X-direction transfers
	# x- speeds have width of width - 1 :
	var width_m_1 = width -1
	
	for y in range(height):
		for x in range(width - 1):
			var i := GridIndexingCalc.idx(x, y, width)
			var j := GridIndexingCalc.idx(x + 1, y, width)
			var i_speed := GridIndexingCalc.idx(x,y,width-1)
			
			#move_mass_between_cells(mass,temp_mass,speeds_x,i,j,dt_mass,clamp_factor)
			move_mass_between_cells_clamped(mass,temp_mass,speeds_x,i,j,i_speed, dt_mass,clamp_factor)
			#_move_mass_momentum_between_cells(mass,temp_mass,speeds_x,i,j,dt_mass,clamp_factor)
			

	# Y-direction transfers
	for y in range(height - 1):
		for x in range(width):
			var i := GridIndexingCalc.idx(x, y, width)
			var j := GridIndexingCalc.idx(x, y + 1, width)
			#move_mass_between_cells(mass,temp_mass,speeds_y,i,j,dt_mass,clamp_factor)
			move_mass_between_cells_clamped(mass,temp_mass,speeds_y,i,j,i,dt_mass,clamp_factor)
			#_move_mass_momentum_between_cells(mass,temp_mass,speeds_y,i,j,dt_mass,clamp_factor)
			
			
	# Apply accumulated changes
	for i in range(size):
		mass[i] = temp_mass[i]
		
static func move_mass_momentum(mass: PackedFloat32Array,temp_mass : PackedFloat32Array,temp_speeds_x : PackedFloat32Array,temp_speeds_y : PackedFloat32Array, speeds_x: PackedFloat32Array, speeds_y: PackedFloat32Array, width: int, height: int, dt_mass: float) -> void:
	var size := width * height
	var clamp_factor := 0.75
	for i in range(size):
		temp_mass[i] = mass[i]
		
	for i in range(speeds_x.size()):
		temp_speeds_x[i] = speeds_x[i]
		
	for i in range(speeds_y.size()):
		temp_speeds_y[i] = speeds_y[i]


	# X-direction transfers
	# x- speeds have width of width - 1 :
	var width_m_1 = width -1
	for y in range(height):
		for x in range(width - 1):
			var i := GridIndexingCalc.idx(x, y, width)
			var j := GridIndexingCalc.idx(x + 1, y, width)
			var i_speed := GridIndexingCalc.idx(x,y,width-1)
			#move_mass_between_cells(mass,temp_mass,speeds_x,i,j,dt_mass,clamp_factor)
			_move_mass_momentum_between_cells(mass,temp_mass,speeds_x,temp_speeds_x,i,j,i_speed,dt_mass,clamp_factor)
			

	# Y-direction transfers
	# y- speeds have width - 1 :
	
	for y in range(height - 1):
		for x in range(width):
			var i:= GridIndexingCalc.idx(x, y, width)
			var j := GridIndexingCalc.idx(x, y + 1, width)
			#move_mass_between_cells(mass,temp_mass,speeds_y,i,j,dt_mass,clamp_factor)

			_move_mass_momentum_between_cells(mass,temp_mass,speeds_y,temp_speeds_y,i,j,i, dt_mass,clamp_factor)
			
			
	# Apply accumulated changes
	for i in range(size):
		mass[i] = temp_mass[i]
		
	for i in range(speeds_x.size()):
		speeds_x[i] = temp_speeds_x[i]
		
	for i in range(speeds_y.size()):
		speeds_y[i] = temp_speeds_y[i]		
		
		
static func move_mass_between_cells(mass: PackedFloat32Array,temp_mass : PackedFloat32Array,speeds: PackedFloat32Array, i:int, j:int,i_speed: int, dt_mass: float, clamp_factor : float):
	var s := speeds[i_speed]			
	var m := mass[i]  if s>= 0.0 else mass[j]
	var koef :=s * dt_mass 
	var amount := m * koef
	temp_mass[i] -= amount
	temp_mass[j] += amount
	
	
static func move_mass_between_cells_clamped(mass: PackedFloat32Array,temp_mass : PackedFloat32Array,speeds: PackedFloat32Array, i:int, j:int, i_speed : int, dt_mass: float, clamp_factor : float):
	var s := speeds[i_speed]	
	var clamp_speed:= 2.0
	s = clampf(s , -clamp_speed , clamp_speed)
	speeds[i_speed] = s 
	if s < 0:
		var temp := i 
		i = j 
		j = temp 
		s = -s
	var eps :float= 1e-6
	var mass_i = mass[i]
	var mass_j = mass[j]
	if mass_i <eps and mass_j < eps:
		speeds[i_speed]	= 0.0 
		return
	var m_available :float = max(0.0, mass_i)
	var m_free : float= max(0.0, 1-mass_j)
	
	var m_possible :float= min(m_available,m_free)	
	#ar m_possible :float= m_available	 
	
	var koef := s * dt_mass 

	var amount_possible :float = m_possible*koef 
	
		

	temp_mass[i] -= amount_possible
	temp_mass[j] += amount_possible	
	
	
static func _move_mass_momentum_between_cells(mass: PackedFloat32Array, temp_mass: PackedFloat32Array, speeds: PackedFloat32Array,temp_speeds: PackedFloat32Array, i: int, j: int, i_speed:int, dt_mass: float, clamp_factor: float) -> void:
	var s := speeds[i_speed]
	var donor_m := mass[i]  if(s >= 0.0)  else mass[j]
	var koef := clampf(s * dt_mass, -clamp_factor, clamp_factor)
	var amount := donor_m * koef


	# Mass transfer (upwind donor)
	temp_mass[i] -= amount
	temp_mass[j] += amount


	# Momentum update on this face (edge-based): p' = p + amount * u_donor
	var m_face := 0.5 * (mass[i] + mass[j])
	m_face = max(m_face, 1e-3)
	
	var p :=s * m_face + amount * s
	#var p := amount * s

	var inv_m := 1.0 / m_face
	var delta_speed = p * inv_m
	temp_speeds[i] = delta_speed


		
		
static func update_speed(mass: PackedFloat32Array, speeds_x: PackedFloat32Array, speeds_y: PackedFloat32Array, width: int, height: int, dt_speed: float) -> void:
	var width_m_1 = width -1
	
	for y in range(height):
		for x in range(width - 1):
			var i := GridIndexingCalc.idx(x, y, width)
			var j := GridIndexingCalc.idx(x + 1, y, width)
			var i_speed := GridIndexingCalc.idx(x,y,width_m_1)
			var diff := mass[i] - mass[j]
			speeds_x[i_speed] += diff * dt_speed


	for y in range(height - 1):
		for x in range(width):
			var i := GridIndexingCalc.idx(x, y, width)
			var j := GridIndexingCalc.idx(x, y + 1, width)
			var diff := mass[i] - mass[j]
			speeds_y[i] += diff * dt_speed
			

static func update_speed_for_surface(mass: PackedFloat32Array, 
									surface: PackedFloat32Array,
									speeds_x: PackedFloat32Array, 
									speeds_y: PackedFloat32Array, 
									width: int, 
									height: int, 
									dt_speed: float) -> void:
	var width_m_1 = width -1
	
	var row:=0
	for y in range(height):
		for i in range(row, row +width - 1):
			var j := i+1
			var i_speed := i-y
			update_speed_for_surface_between_cells(mass,surface,speeds_x,i,j,i_speed,dt_speed)
		row +=width
	row=0
	for y in range(height - 1):
		for i in range(row, row + width):
			var j := i+width
			update_speed_for_surface_between_cells(mass,surface,speeds_y,i,j,i,dt_speed)
		row +=width

static func update_speed_for_surface_between_cells(mass: PackedFloat32Array, 
									surface: PackedFloat32Array,
									speeds_x: PackedFloat32Array, 
									i:int,
									j:int,
									i_speed:int,
									dt_speed: float
									):
	var eps  := 1e-6
	var mass_i := mass[i] 
	var surface_i := surface[i]
	var ele_i := mass_i+surface_i
	var mass_j := mass[j] 
	var surface_j := surface[j]
	var ele_j := mass_j + surface_j
	
	if (mass_i < eps  and  mass_j < eps) or ((surface_i > ele_j and mass_i < eps) or (surface_j > ele_i and mass_j < eps)):
		speeds_x[i_speed] =0
		return

	var diff := ele_i - ele_j			
	speeds_x[i_speed] += diff * dt_speed
	
	

static func grid_cell_from_mouse_click(
	width: int,
	height: int,
	event: InputEvent,

) -> Vector2i:
	
		var cell_size_invert = calc_cell_size_invert(width, height)
		var cx :int= clamp(int(event.position.x * cell_size_invert.x), 0, width - 1)
		var cy :int= clamp(int(event.position.y * cell_size_invert.y), 0, height - 1)
		#var k := idx(cx, cy, width)
		return Vector2i(cx,cy)
		
		
static func grid_velocity_from_mouse_click(
		width: int,
		height: int,
		event: InputEvent,
		max_speed: float,
		)-> Vector2:

		# Convert mouse velocity (pixels/sec) to grid units (cells/sec)
		var cell_size_invert = calc_cell_size_invert(width, height)
		var gv :Vector2 = event.velocity *cell_size_invert
		var sx :float= clamp(gv.x, -max_speed, max_speed)
		var sy :float= clamp(gv.y, -max_speed, max_speed)
		return Vector2(sx,sy)

		#speeds_x[k] = sx
		#speeds_y[k] = sy



	
		
		

		
static func calc_cell_size_invert(grid_width: int, grid_height: int) -> Vector2:
	var win_size: Vector2i = DisplayServer.window_get_size()
	return Vector2(float(grid_width) / win_size.x, float(grid_height) / win_size.y )
