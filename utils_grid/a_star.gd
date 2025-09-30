extends RefCounted
class_name AStarMy

var eps := 0.001
var ele_need :=10
var grid: AbstractTerrainElevationGenerator

func _init(grid: AbstractTerrainElevationGenerator):
	self.grid = grid


func walkable(cell:Vector2i):
	var ele:= grid.get_elevation_at(cell.x,cell.y)
	return  abs(ele - ele_need) <= eps
	
	
func _heuristic_euclid(a: Vector2i, b: Vector2i) -> float:
	var dx := float(a.x - b.x)
	var dy := float(a.y - b.y)
	return sqrt(dx * dx + dy * dy)

# Manhattan (recommended for strictly 4-dir movement)
func _heuristic_manhattan(a: Vector2i, b: Vector2i) -> float:
	return abs(a.x - b.x) + abs(a.y - b.y)
	
func _heuristic_euclid_nbr(d: Vector2i) -> float:
	return sqrt(d.x * d.x + d.y * d.y)
	
func heuristic_nbr(d: Vector2i) -> float:
	return _heuristic_euclid_nbr(d)


func heuristic(a: Vector2i,b: Vector2i) -> float:
	return _heuristic_euclid(a,b)
	
func _reconstruct_path(came_from: Dictionary, current: Vector2i) -> Array:
	var path := [current]
	while came_from.has(current):
		current = came_from[current]
		path.append(current)
	path.reverse()
	return path

func find(start: Vector2i, goal: Vector2i,  bound_a: Vector2i, bound_b: Vector2i ) -> Array:
	var p := start
	ele_need = grid.get_elevation_at(p.x,p.y)
	
	var ret := []
	assert (GridCheck.is_inside_boundary(start,bound_a,bound_b), "AStarMy: start %s is outside of boundary %s : %s" % [start, bound_a, bound_b])
	assert (GridCheck.is_inside_boundary(goal,bound_a,bound_b), "AStarMy: goal %s is outside of boundary %s : %s" % [goal, bound_a, bound_b])
	
	if not  (walkable(p)  or walkable(goal)):
		print("AStarMy: short fail")
		return ret
	
	var heap := MinHeap.new()
	#g- score is actuall cheapest cost to go from the start nore to current node_
	var g := {} # g-score { Vector2i: float }
	#f-score is estimated total cost pf a path going through node n
	#calculating actual cost + heuristic estimation:
	#f(n)=g(n)+h(n)
	var f := {}# f-score{ Vector2i: float }
	#value is a previous point you come to the key (given point) in the 
	#last version on the path
	var came_from := {} # { Vector2i: Vector2i }
	# set of visited points
	var closed := {} # set-like { Vector2i: true }
	
	
	g[p] = 0.0
	
	var f_p := heuristic(p,goal)
	f[p] = f_p
	heap.push(f_p,p)
	while heap.heap.size()>0:
		var key_value = heap.pop()
		var popped_f :float= key_value[0]
		p = key_value[1]
		# Skip stale entries (we found a better f for given point after this was queued)
		if popped_f > f.get(p, INF):
			continue
		if p == goal:
			print("AStarMy: path found")
			return _reconstruct_path(came_from, p)
			
		if closed.has(p):
			continue		
		closed[p] = true
		
		for dn in GridCheck.get_nbrs_delta(p,bound_a,bound_b,GridCheck.nbrs8):
			var n := p + dn
			#var cell = grid[n.x][n.y]
			if not walkable(n) or closed.has(n):
				continue 
			var tentative_g :float= g.get(p,INF) + heuristic_nbr(dn)
			if tentative_g < g.get(n, INF):
				#we found better way to point n or point n is new:
				came_from[n] = p
				g[n] = tentative_g
				var fn := tentative_g + heuristic(n, goal) # swap heuristic if desired
				f[n] = fn
				heap.push(fn, n)
	print("AStarMy: long fail")
	return []
	
