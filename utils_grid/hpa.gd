extends RefCounted
class_name HPA

var ele_need :=10
var eps := 0.001

#const steps := [  Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT,	Vector2i.UP]
const steps_len := 4
const directions := [  Vector2i.RIGHT, Vector2i.DOWN, Vector2i.RIGHT,	Vector2i.DOWN]
const vdirections := [  Vector2i.UP, Vector2i.LEFT, Vector2i.DOWN,	Vector2i.RIGHT]

func walkable(grid: TerrainFunction, cell:Vector2i):
	var ele:= grid.get_elevation_at(cell.x,cell.y)
	return  abs(ele - ele_need) <= eps
	
func set_ele(ele):
	self.ele_need = ele
	
	
func find_all_windows(grid:TerrainFunction, bounds_block_a: Vector2i, block_bounds_b: Vector2i, bounds_a: Vector2i, bounds_b: Vector2i)-> Array:
	var all_windows := []
	var top_right:= bounds_block_a + Vector2i(block_bounds_b.x,0)
	var bottom_left :=  bounds_block_a + Vector2i(0,block_bounds_b.y) 
	var bottom_right := bounds_block_a+block_bounds_b
	var bounds_begins :=[bounds_block_a,bounds_block_a, bottom_left, top_right ]
	var bounds_end := [top_right, bottom_left, bottom_right,bottom_right]
	for i in range(steps_len):
		var p = bounds_begins[i]
		var row_end = bounds_end[i]
		
		
		var windows_for_border := []
		#var vstep_index :=  (i - 1 + steps_len) % steps_len
		var step :Vector2i= directions[i]
		var vstep :Vector2i= vdirections[i]
		
		
		var next_window = find_next_window(grid,p,row_end,bounds_a,bounds_b,step,vstep)
		#print("HPA: window found : %s" %[next_window])
		while (next_window != null):
			#print("HPA: i = %s along step %s window found : %s" %[ i, step,next_window])
			windows_for_border.append(next_window)
			p = next_window[1] 
			if p == row_end:
				next_window = null 
			else:
				next_window = find_next_window(grid,p,row_end,bounds_a,bounds_b,step,vstep)
		print("HPA:for: i = %s along step %s ,bounds : %s , %s : found windows: %s" %[ i, step, bounds_begins[i], row_end, windows_for_border])
		all_windows.append(windows_for_border)
		
	return all_windows
	
	
func all_windows_to_all_border_points(all_windows : Array) -> Array:
	var all_points = []
	for i in range(steps_len):
		var row = all_windows[i]
		var step = directions[i]
		for window in row:
			var fro :Vector2i = window[0]
			var to :Vector2i = window[1]
			while (fro != to):
				all_points.append(fro)
				fro+= step
			all_points.append(to) 
		
	return all_points
		
			
		
			
		
		
	
	

func find_next_window(grid: TerrainFunction,bounds_block_a: Vector2i, bounds_block_end: Vector2i,bounds_a: Vector2i, bounds_b: Vector2i, step: Vector2i, vstep: Vector2i) :
	
	#if -step leads outside of the bounds there is no next window for this side:
	var vnbr := bounds_block_a - vstep
	#var bounds_block_end := bounds_block_a+block_dim
	if not GridCheck.is_inside_boundary(vnbr,bounds_a,bounds_b):
		return null
	var nbr := bounds_block_a
	
	#find first walkable pair:
	while not  (walkable(grid,nbr) and walkable(grid,vnbr)):
		if nbr == bounds_block_end:			
			return null
		nbr += step
		vnbr+= step
	var window_begin := nbr
	#traverse untill it is walkable or end:
	while walkable(grid,nbr) and walkable(grid,vnbr):
		if nbr == bounds_block_end:
			break
		nbr += step
		vnbr+= step
					
	#nbr-=step
	return [window_begin, nbr]
