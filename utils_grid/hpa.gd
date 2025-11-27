extends RefCounted
class_name HPA

var ele_need :=10
var eps := 0.001
var grid: AbstractTerrainElevationGenerator
#const steps := [  Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT,	Vector2i.UP]
const steps_len := 4
const directions := [  Vector2i.RIGHT, Vector2i.DOWN, Vector2i.RIGHT,	Vector2i.DOWN]
const vdirections := [  Vector2i.UP, Vector2i.LEFT, Vector2i.DOWN,	Vector2i.RIGHT]

#TODO - sometimes it marks one cell more for border window.

func _init(grid: AbstractTerrainElevationGenerator):
	self.grid = grid
	

func walkable(cell:Vector2i)-> bool:
	var ele:= grid.get_elevation_at(cell.x,cell.y)
	return  abs(ele - ele_need) <= eps
	
func set_ele(ele):
	self.ele_need = ele
	

func _scan_boundary(start: Vector2i, step: Vector2i, neighbor_offset: Vector2i, length: int, gateways: Array) -> void:

	var in_window := false
	var window_start := 0
	var a:= start
	for i in range(length):
		var b := a + neighbor_offset
		var free_pair := walkable(a) and walkable(b)
		if free_pair:
			if not in_window:
				in_window = true
				window_start = i
		
		elif in_window:
			var mid :int= (window_start + i - 1) / 2
			gateways.append(start + step * mid)
			in_window = false
			
		a+= step
	# Handle window that goes to the end
	if in_window:
		var mid :int= (window_start + length - 1) / 2
		gateways.append(start + step * mid)

	
	
func find_bottom_right_gateways_for_cluster(cx: int, cy: int , cluster_width: int, cluster_height: int) -> Array:
	var gateways:= []
	var origin := Vector2i(cx * cluster_width, cy * cluster_height)
	
	# Horizontal boundary: scan along X
	var start := Vector2i(origin.x, origin.y + cluster_height - 1)  # cell in top cluster
	var step := Vector2i(1, 0)
	var neighbor_offset := Vector2i(0, 1)  # moves into bottom cluster
	var length := cluster_width
	_scan_boundary(start,step,neighbor_offset,length,gateways)	
	
	# Vertical boundary: scan along Y
	start = Vector2i(origin.x + cluster_width - 1, origin.y)  # cell in left cluster
	step = Vector2i(0, 1)
	neighbor_offset = Vector2i(1, 0)  # moves into right cluster
	length = cluster_height
	_scan_boundary(start,step,neighbor_offset,length,gateways)
	return gateways
	
func find_all_gateways(overall_width: int, overall_height: int, cluster_width: int, cluster_height: int) -> Array:
	var clusters_x :int= overall_width / cluster_width
	var clusters_y :int= overall_height / cluster_height

	var all_gateways: Array = []

	for cy in range(clusters_y-1):
		for cx in range(clusters_x-1):
			var gateways_for_cluster := find_bottom_right_gateways_for_cluster(cx, cy, cluster_width, cluster_height)
			all_gateways.append(gateways_for_cluster)

	return all_gateways


	
	
func find_all_windows(bounds_block_a: Vector2i, block_bounds_b: Vector2i, bounds_a: Vector2i, bounds_b: Vector2i)-> Array:
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
		
		
		var next_window = find_next_window(p,row_end,bounds_a,bounds_b,step,vstep)
		#print("HPA: window found : %s" %[next_window])
		while (next_window != null):
			#print("HPA: i = %s along step %s window found : %s" %[ i, step,next_window])
			windows_for_border.append(next_window)
			p = next_window[1] 
			if p == row_end:
				next_window = null 
			else:
				next_window = find_next_window(p,row_end,bounds_a,bounds_b,step,vstep)
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
	

func find_next_window(bounds_block_a: Vector2i, bounds_block_end: Vector2i,bounds_a: Vector2i, bounds_b: Vector2i, step: Vector2i, vstep: Vector2i) :
	
	#if -step leads outside of the bounds there is no next window for this side:
	var vnbr := bounds_block_a - vstep
	#var bounds_block_end := bounds_block_a+block_dim
	if not GridIndexingCalc.is_inside_boundary(vnbr,bounds_a,bounds_b):
		return null
	var nbr := bounds_block_a
	
	#find first walkable pair:
	while not  (walkable(nbr) and walkable(vnbr)):
		if nbr == bounds_block_end:			
			return null
		nbr += step
		vnbr+= step
	var window_begin := nbr
	#traverse untill it is walkable or end:
	while walkable(nbr) and walkable(vnbr):
		if nbr == bounds_block_end:
			break
		nbr += step
		vnbr+= step
					
	#nbr-=step
	return [window_begin, nbr]
