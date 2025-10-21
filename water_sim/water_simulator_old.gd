extends Node
class_name WaterSimulatorOld

@export var dt: float = 1.0 / 60.0 *0.01
@export var amount_to_speed_gain: float = 1.0 / 60.0 *0.01 # tweak as needed
@export var speed_propagate_factor :float = 0.01
@export var size: Vector2i = Vector2i(800,600)
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
@export var grid_view:CanvasItem 
var show_speed := true

#var cell_size: float = 1.0# not need

var old_grid: Array = [] # Array[Array[WaterCell]]
var new_grid: Array = []
var frames :=0
var period :=2
var img :Image
var tex: ImageTexture
var mat: ShaderMaterial

func _ready():
	init_shader()
	mat.set_shader_parameter("speed_tex", tex)
	old_grid = _alloc_grid(size)
	new_grid = _alloc_grid(size)	
	#seed_center_patch_x(new_grid, 1, Vector2i(3,3),size)
	seed_center_patch_x(new_grid, Vector2(0.0,1.0), Vector2i(20,5),size)
	
func init_shader():
	mat = grid_view.material as ShaderMaterial
	var pal_tex := make_palette_texture(palette_colors)
	mat.set_shader_parameter("palette_tex", pal_tex)
	mat.set_shader_parameter("palette_count", palette_colors.size())	
	img = Image.create(size.x, size.y, false, Image.FORMAT_RGB8)
	tex = ImageTexture.create_from_image(img)	




static func in_bounds(xy :Vector2i  , size: Vector2i) -> bool:
	return xy.x >= 0 and xy.y >= 0 and xy.x < size.x and xy.y < size.y	
	
static func in_bounds_xy(x: int, y:int  , size: Vector2i) -> bool:
	return x >= 0 and y >= 0 and x < size.x and y < size.y		
	
static func in_bounds_x(x:int, size: Vector2i) -> bool:
	return x >= 0  and x < size.x 	
	
static func in_bounds_y( y:int, size: Vector2i) -> bool:
	return y >= 0 and  y < size.y		
	
static func cell(g: Array, xy :Vector2i ) -> WaterCell:
	return g[xy.y][xy.x]
	
static func cell_xy(g: Array, x: int, y: int ) -> WaterCell:
	return g[y][x]

static func _alloc_grid(size: Vector2i) -> Array:
	var g: Array = []
	g.resize(size.y)
	for j in size.y:
		var row: Array = []
		row.resize(size.x)
		for i in size.x:
			row[i] = WaterCell.new()
		g[j] = row
	return g
	
static func seed_center_patch_x(g: Array,  speed: Vector2 ,patch: Vector2i,size: Vector2i) -> void:
	var cx := size.x >> 1
	var cy := size.y >> 1
	var hx := patch.x >> 1
	var hy := patch.y >> 1
	var y0 :int= max(0, cy - hy)
	var y1 :int= min(size.y, cy + hy)
	var x0 :int= max(0, cx - hx)
	var x1 :int= min(size.x, cx + hx)
	for j in range(y0, y1):
		for i in range(x0, x1):
			var c: WaterCell = cell_xy(g, i, j)
			c.vel = speed
	
	
static func clear_grid(g: Array, size: Vector2i) -> void:
	for j in size.y:
		for i in size.x:
			(cell_xy(g, i, j) as WaterCell).reset()
			
static func apply_friction(g: Array, size: Vector2i) -> void:
	for j in size.y:
		for i in size.x:
			var cell := cell_xy(g, i, j)
			cell.vel *=0.9995
			
func swap_buffers() -> void:
	var t = old_grid
	old_grid = new_grid
	new_grid = t




func _physics_process(delta: float) -> void:
	frames+=1
	if frames == period:
		frames =0
		print("updating")
		_grid_update()
	

func _grid_update():
	move_amount_and_dye(new_grid, old_grid,size, dt)
	#move_amount_and_dye(new_grid, old_grid,size, dt)
	#recalc_speed_from_amount_diff(new_grid,old_grid,amount_to_speed_gain,size)
	recalc_speed_from_amount_diff_faces(new_grid,size,amount_to_speed_gain)
	if show_speed:
		update_speed_texture_v2(tex,new_grid,size)
	else:
		update_amount_texture(tex,new_grid,size)
	#apply_friction(new_grid,size)
	mat.set_shader_parameter("speed_tex", tex)
	#swap_buffers()
	



static func move_amount_and_dye(grid: Array, tmp_grid:Array, size:Vector2i,  dt : float) -> void:

	for j in size.y:
		for i in size.x:
			var grid_cell: WaterCell = cell_xy(grid, i, j)
			var tmp_cell: WaterCell = cell_xy(tmp_grid, i, j)
			tmp_cell.amount = 0.0
			tmp_cell.vel = Vector2.ZERO
			
			

	for j in size.y:
		for i in size.x:
			var src: WaterCell = cell_xy(grid, i, j)
			var src_vel := src.vel
			var amt := src.amount
			if amt <= 0.0:
				continue
			var ux := src.vel.x
			var uy := src.vel.y			
			var keep :float= amt
			var keep_vel : Vector2 = src_vel

			
			if ux > 0.0:
				var ixp := i + 1
				if in_bounds_x(ixp,size):
					var moved_amount:= amt*ux*dt
					var moved_momentum := src_vel * moved_amount
					keep -= moved_amount
					keep_vel-=moved_momentum
					#amount gets substracted from move_amount:
					var c2: WaterCell = cell_xy(tmp_grid, ixp, j)
					c2.amount += moved_amount
					c2.vel += moved_momentum
			elif  ux < 0.0:
				var ixp := i - 1
				if in_bounds_x(ixp,size):
					var moved_amount:= amt*(-ux)*dt
					var moved_momentum:= src_vel * moved_amount
					keep -= moved_amount
					keep_vel-=moved_momentum
					var c2: WaterCell = cell_xy(tmp_grid, ixp, j)
					c2.amount += moved_amount
					c2.vel += moved_momentum					

			if uy > 0.0:
				var jyp := j + 1
				if in_bounds_y(jyp,size):
					var moved_amount:= amt*uy*dt
					var moved_momentum := src_vel * moved_amount
					keep -= moved_amount
					keep_vel-= moved_momentum
					var c2: WaterCell = cell_xy(tmp_grid,i,jyp)
					c2.amount += moved_amount
					c2.vel += moved_momentum								

			elif uy < 0.0:
				var jyp := j - 1
				if in_bounds_y(jyp,size):
					var moved_amount:= amt*(-uy)*dt
					var moved_momentum := src_vel * moved_amount
					keep -= moved_amount
					keep_vel-=moved_momentum
					var c2: WaterCell = cell_xy(tmp_grid,i,jyp)
					c2.amount += moved_amount
					c2.vel += moved_momentum							

			var c2: WaterCell = cell_xy(tmp_grid,i,j)
			c2.amount += keep
			c2.vel += keep_vel					
					
	for j in size.y:
		for i in size.x:
			var grid_cell: WaterCell = cell_xy(grid, i, j)
			var tmp_cell: WaterCell = cell_xy(tmp_grid, i, j)
			var t_amount = tmp_cell.amount	
			grid_cell.amount = t_amount
			if true:
				pass
				#grid_cell.vel = tmp_cell.vel / t_amount if t_amount > 0.001 else Vector2.ZERO
			else:
				
				#approdimation of the division, using a Newton–Raphson approx:				
				if t_amount > 0.1:
					var a:float= t_amount
					var inv := 2.0 - a                 # initial approx of 1/a near a=1
					inv = inv * (2.0 - a * inv)   #
					inv = inv * (2.0 - a * inv)   
					grid_cell.vel =  tmp_cell.vel * inv 
				else:
					grid_cell.vel = Vector2.ZERO
			
			
			



# Add to WaterSimulator (works on new_grid after move step)

# Kills checkerboard: compute corrections on faces, then average back to centers.
static func recalc_speed_from_amount_diff_faces(grid: Array, size: Vector2i, gain: float) -> void:
	# --- face arrays: u_x on vertical faces between (i,j) and (i+1,j) ---
	var uxf: Array = []
	uxf.resize(size.y)
	for j in size.y:
		var row := PackedFloat32Array()
		row.resize(max(0, size.x - 1))
		uxf[j] = row

	# --- face arrays: u_y on horizontal faces between (i,j) and (i,j+1) ---
	var uyf: Array = []
	uyf.resize(size.y - 1 if size.y > 0 else 0)
	for j in max(0, size.y - 1):
		var row := PackedFloat32Array()
		row.resize(size.x)
		uyf[j] = row

	# 1) initialize faces from current cell-centered velocities (simple average)
	for j in size.y:
		for i in range(0, size.x - 1):
			var L: WaterCell = grid[j][i]
			var R: WaterCell = grid[j][i + 1]
			uxf[j][i] = 0.5 * (L.vel.x + R.vel.x)

	for j in range(0, size.y - 1):
		for i in size.x:
			var D: WaterCell = grid[j][i]
			var U: WaterCell = grid[j + 1][i]
			uyf[j][i] = 0.5 * (D.vel.y + U.vel.y)

	# 2) apply pressure-like corrections ON FACES using amount differences
	for j in size.y:
		for i in range(0, size.x - 1):
			var L: WaterCell = grid[j][i]
			var R: WaterCell = grid[j][i + 1]
			var amount :=gain * (R.amount - L.amount)  
			uxf[j][i] += amount   # + if right is fuller


	for j in range(0, size.y - 1):
		for i in size.x:
			var D: WaterCell = grid[j][i]
			var U: WaterCell = grid[j + 1][i]
			var amount :=gain * (U.amount - D.amount)  
			uyf[j][i] += amount  # + if up is fuller


	# 3) reconstruct cell-centered velocities by averaging adjacent faces
	for j in size.y:
		for i in size.x:
			var vx_l :=  float(uxf[j][i - 1]) if(i > 0)  else 0.0
			var vx_r :=  float(uxf[j][i]) if (i < size.x - 1) else 0.0
			var vy_d :=  float(uyf[j - 1][i]) if (j > 0)  else 0.0
			var vy_u :=  float(uyf[j][i]) if (j < size.y - 1)  else 0.0

			var c: WaterCell = grid[j][i]
			c.vel.x += 0.5 * (vx_l + vx_r)
			c.vel.y += 0.5 * (vy_d + vy_u)


static func recalc_speed_from_amount_diff(grid:Array, tmp_grid :Array,amount_to_speed_gain:float, size:Vector2i ) -> void:
	# X-axis pairs: (i,j) ↔ (i+1,j)
	for j in size.y:
		for i in range(0, size.x):
			var tmp_cell: WaterCell = cell_xy(tmp_grid, i, j)
			var grid_cell: WaterCell = cell_xy(grid, i, j)
			tmp_cell.vel = grid_cell.vel
			
	for j in size.y:
		for i in range(0, size.x - 1):
			var L: WaterCell = cell_xy(grid, i, j)
			var R: WaterCell = cell_xy(grid, i + 1, j)
			var diff := (R.amount - L.amount)  # positive if right is more filled
			#amount_to_speed_gain contain the factor of 0.5 used for averaging
			var du := amount_to_speed_gain * diff
			# update both neighbors; sign handles direction
			var left_new_cell: WaterCell = cell_xy(tmp_grid, i, j)
			var right_new_cell: WaterCell = cell_xy(tmp_grid, i + 1, j)			
			left_new_cell.vel.x += du
			right_new_cell.vel.x -= du

	for i in size.x:
		for j in range(0, size.y - 1):
			var U: WaterCell = cell_xy(grid, i, j)
			var D: WaterCell = cell_xy(grid, i , j+1)
			var diff := (D.amount - U.amount)  # positive if down is more filled
			var dv := amount_to_speed_gain * diff
			var up_new_cell:WaterCell = cell_xy(tmp_grid, i, j)
			var down_new_cell:WaterCell =  cell_xy(tmp_grid, i , j+1)
			up_new_cell.vel.y += dv
			down_new_cell.vel.y -= dv
		
	for j in size.y:
		for i in size.x:
			var tmp_cell: WaterCell = cell_xy(tmp_grid, i, j)
			var grid_cell: WaterCell = cell_xy(grid, i, j)
			grid_cell.vel = tmp_cell.vel
			

static func update_speed_texture(tex: ImageTexture,  g: Array, size:Vector2i) :
	var img := tex.get_image()
	#img.lock()
	for j in size.y:
		for i in size.x:
			var v := (cell_xy(g, i, j) as WaterCell).vel.length() 
			if v > 1.0:
				v = 1.0
			img.set_pixel(i, j, Color(v, 0, 0)) # red channel used for speed
	#img.unlock()
	tex.update(img)
	
static func update_speed_texture_v2(tex: ImageTexture,  g: Array, size:Vector2i) :
	var img := tex.get_image()
	#img.lock()
	for j in size.y:
		for i in size.x:
			var v := (cell_xy(g, i, j) as WaterCell).vel
			v.x = clampf(v.x, 0.0, 1.0)
			v.y = clampf(v.y, 0.0, 1.0)
			img.set_pixel(i, j, Color(v.x, v.y, 0)) 
	#img.unlock()
	tex.update(img)
	
static func update_amount_texture(tex: ImageTexture,  g: Array, size:Vector2i) :
	var img := tex.get_image()
	#img.lock()
	for j in size.y:
		for i in size.x:
			var v := (cell_xy(g, i, j) as WaterCell).amount
			v = (v-1.0)*0.4+ 0.5
			#v = (v-1.0) * 10.0 + 1.0
			v = clampf(v, 0.0, 1.0)
			img.set_pixel(i, j, Color(v, 0, 0)) 


	tex.update(img)
	
static func make_palette_texture(palette_colors: Array[Color] ) -> ImageTexture:
	var n :int= max(1, palette_colors.size())
	var img := Image.create(n, 1, false, Image.FORMAT_RGBA8)
	#img.lock()
	for i in n:
		img.set_pixel(i, 0, palette_colors[i])
	#img.unlock()
	return ImageTexture.create_from_image(img)
