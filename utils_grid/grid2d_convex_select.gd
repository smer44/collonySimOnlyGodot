extends Node
class_name GridConvexSelect

static func ray_inside(grid2d: Array[Array],p: Vector2i, dir: Vector2i,  bound_a: Vector2i, bound_b: Vector2i) -> Vector2i:
	var estimate :=p + dir
	while (GridCheck.is_inside_boundary(estimate, bound_a , bound_b) and grid2d[estimate.x][estimate.y]):
		estimate += dir
	return estimate - dir
	
	
static func ray_outside(grid2d: Array[Array],p: Vector2i, dir: Vector2i,  bound_a: Vector2i, bound_b: Vector2i) -> Vector2i:
	var estimate :=p - dir
	while (GridCheck.is_inside_boundary(estimate, bound_a , bound_b) and grid2d[estimate.x][estimate.y]):
		estimate -= dir
	return estimate


static func convex_octagon_from(grid2d: Array[Array],p: Vector2i, last_dir: int,   bound_a: Vector2i, bound_b: Vector2i) -> Array[Vector2i]:
	var ret :Array[Vector2i]= []
	
	var top_left_estimate := GridConvexSelect.ray_inside(grid2d, p, Vector2i.UP, bound_a, bound_b)
	var top_right_estimate := GridConvexSelect.ray_inside(grid2d, p, Vector2i.UP, bound_a, bound_b)
	
	#var next_left_estimate := 
	
	
	return ret 
	
