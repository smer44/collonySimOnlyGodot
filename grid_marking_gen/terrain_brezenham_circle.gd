extends TerrainFunction
class_name TerrainBresenhamCircle

# Parameters
@export var radius: int = 8
var grid: Array[Array] = [] # grid[z][x] = bool

func _init():
	pass

# Bresenham arc (first octant, x from 0..y)
func bresenham_8_arc( r: int) -> Array[Vector2i]:
	var pts: Array[Vector2i] = []
	if r <= 0:
		return pts
	var x := 0
	var y := r
	var d := 1 - r
	while x <= y:
		pts.append(Vector2i( x, y))  # first-octant arc
		if d < 0:
			d += 2 * x + 3
		else:
			d += 2 * (x - y) + 5
			y -= 1
		x += 1
	return pts
	
func next():
	var ele :float= get_elevation_at(0,0)
	var elei :int= -1.0 if ele > 0.0 else ele
	return [Vector3i(0,elei,0)]

func precalc():
	var width := radius * 2 + 2
	var height := radius * 2 + 2
	grid.resize(height)
	for z in height:
		var row:Array[bool]=[] 
		row.resize(width)
		for x in width:
			row[x] = false
		grid[z] = row
	# Fill grid using Bresenham arc
	var pts := bresenham_8_arc(radius)
	#print(" pts : " , pts)
	for p in pts:
		grid[radius+p.x][radius+p.y] = true
		grid[radius+p.x][radius-p.y] = true
		grid[radius-p.x][radius-p.y] = true
		grid[radius-p.x][radius+p.y] = true		
		grid[radius+p.y][radius+p.x] = true
		grid[radius+p.y][radius-p.x] = true
		grid[radius-p.y][radius-p.x] = true
		grid[radius-p.y][radius+p.x] = true
	#print(grid)
		
func get_elevation_at(x: int, z: int) -> float:
	var width := radius * 2 + 2
	var height := radius * 2 + 2	
	if z < 0 or z >= height or x < 0 or x >= width:
		return -1.0
	#return 1.0 if grid[z][x] else 0.5  if x > 0 and grid[z][x-1]  else  0.0
	return 1.0 if grid[z][x] else 0.5  if z>0 and x > 0 and  grid[z-1][x-1]  else  0.0

# need to iterate over lefrmost points 

# Returns color at coordinate (y included if needed).
func get_color_at(x: int, y: int, z: int) -> Color:
	var width := radius * 2 + 2
	var height := radius * 2 + 2
	if z < 0 or z >= height or x < 0 or x >= width:
		return Color.YELLOW
	#return Color.RED if grid[z][x] else Color.BLUE  if x > 0 and grid[z][x-1]  else  Color.GRAY
	return Color.RED if grid[z][x] else Color.BLUE  if z>0 and x > 0 and  grid[z-1][x-1] else  Color.GRAY
		
	
