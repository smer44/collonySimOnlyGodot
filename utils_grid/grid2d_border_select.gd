extends RefCounted
class_name GridBorderSelect

#static func is_on_elevation_boundary(grid2d: Array[Array],elevation: int, p: Vector2i,  bound_a: Vector2i, bound_b: Vector2i) -> bool:

const  out_check_order: Array[Vector2i] = [  Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT,	Vector2i.UP,	]
const no_dir = 5
#TODO: check if it is an island

static func first_valid_dir(grid2d: Array[Array],p: Vector2i, last_dir: int,   bound_a: Vector2i, bound_b: Vector2i) -> int:
	var ele :int= grid2d[p.x][p.y]
	for dir_offset in range(4):
		var dir_index := posmod(last_dir + dir_offset, 4)	
		var dir := out_check_order[dir_index]
		var nbr := p + dir 
		if GridCheck.is_inside_boundary(nbr,bound_a,bound_b):
			var nbr_ele :int = grid2d[nbr.x][nbr.y]
			if nbr_ele == ele:
				return dir_index 
	return no_dir
				
			
			
		

static func border_along(grid2d: Array[Array],p: Vector2i, last_dir: int,   bound_a: Vector2i, bound_b: Vector2i) -> Array[Vector2i]:
	var ret :Array[Vector2i] = []
	var ele :int= grid2d[p.x][p.y]
	ret.append(p)
	last_dir = first_valid_dir(grid2d,p,last_dir,bound_a,bound_b)
	if last_dir == no_dir:
		#this is only one point
		return ret 		
	
	print("ele :" , ele, "first dir : ", last_dir)
	
	var starting_p := p
	var starting_dir := last_dir
	var seen_start_once := false
	
	
	while true:
		#this can be encountered only twice: at the very begin or after we moved ofer full loop
			
		for dir_offset in range(4):		
			

			var dir_index := posmod(last_dir-1 + dir_offset, 4)
			var dir := out_check_order[dir_index]
			var nbr := p + dir 
			
				
			
			#print("p : ", p , "testing_dir : " , dir)		
			if GridCheck.is_inside_boundary(nbr,bound_a,bound_b):
				var nbr_ele :int = grid2d[nbr.x][nbr.y]
				if nbr_ele == ele:
					last_dir = dir_index 	
					#print("p : ", p , "last_dir : " , last_dir)				
					print(" - checking for end : p : ", p , "dir : " , last_dir)
					if p == starting_p and last_dir == starting_dir:
						if seen_start_once:
							return ret 
						seen_start_once = true								

					p = nbr 
					ret.append(p)
					
					break
	print("border_along returns : ", ret)
	return ret 

static func is_near_diagonally(a: Vector2i, b: Vector2i) -> bool:
	var d := (a - b).abs()
	return d != Vector2i.ZERO and d.x <= 1 and d.y <= 1
