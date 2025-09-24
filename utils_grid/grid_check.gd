class_name GridCheck
extends RefCounted


static func is_on_boundary(p: Vector2i, a: Vector2i, b: Vector2i) -> bool:

	# On any of the four edges (including corners)
	return p.x == a.x or p.x == b.x or p.y == a.y or p.y == b.y
	

static func top_boundary(grid: Array) -> Vector2i:
	var w := grid.size()
	assert ( w > 0)
	var h :int= grid[0].size()
	assert ( h > 0)
	return Vector2i(w,h)
	


static func is_inside_boundary(p: Vector2i, a: Vector2i, b: Vector2i) -> bool:
	var min_x :int= min(a.x, b.x)
	var max_x :int= max(a.x, b.x)
	var min_y :int= min(a.y, b.y)
	var max_y :int= max(a.y, b.y)
	return p.x >= min_x and p.x <= max_x and p.y >= min_y and p.y <= max_y
	
const  nbrs4: Array[Vector2i] = [Vector2i.UP,	Vector2i.DOWN,	 Vector2i.LEFT,	 Vector2i.RIGHT,]

const UP_LEFT :=Vector2i.UP + Vector2i.LEFT
const UP_RIGHT :=Vector2i.UP + Vector2i.RIGHT
const DOWN_LEFT :=Vector2i.DOWN + Vector2i.LEFT
const DOWN_RIGHT :=Vector2i.DOWN + Vector2i.RIGHT

const nbrs8: Array[Vector2i] = [Vector2i.UP,	Vector2i.DOWN,	 Vector2i.LEFT,	 Vector2i.RIGHT,UP_LEFT, UP_RIGHT, DOWN_LEFT, DOWN_RIGHT]

	
static func get_nbrs(p: Vector2i, bound_a: Vector2i, bound_b: Vector2i, nbrs : Array[Vector2i] ) -> Array[Vector2i]:
	# Returns 4-connected neighbors (Up, Down, Left, Right) of point `p`
	# clamped to the inclusive rectangular bounds defined by `bound_a` and `bound_b`.

	var result: Array[Vector2i] = []
	result.resize(0)
	for c in nbrs:
		var nbr := p+c
		if is_inside_boundary(nbr, bound_a, bound_b):
			result.append(nbr)
	return result
	
static func get_nbrs_delta(p: Vector2i, bound_a: Vector2i, bound_b: Vector2i, nbrs : Array[Vector2i] ) -> Array[Vector2i]:
	
	var result: Array[Vector2i] = []
	result.resize(0)
	for c in nbrs:
		var nbr := p+c
		if is_inside_boundary(nbr, bound_a, bound_b):
			result.append(c)
	return result	
	

static func is_on_elevation_boundary(grid2d: Array[Array],elevation: int, p: Vector2i,  bound_a: Vector2i, bound_b: Vector2i) -> bool:
	var elevation_at_p :int= grid2d[p.x][p.y]
	if elevation_at_p != elevation:
		return false
	
	var inside_nbrs := get_nbrs(p, bound_a, bound_b, nbrs8)

	if is_on_boundary(p, bound_a, bound_b):
		return true
	
	assert ( inside_nbrs.size()  ==  8)
	for nbr in inside_nbrs:
		var nbr_elevation :int =grid2d[nbr.x][nbr.y]
		if nbr_elevation != elevation:
			return true 
	return false
	

	
	
