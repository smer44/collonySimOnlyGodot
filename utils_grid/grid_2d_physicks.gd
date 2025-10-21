extends RefCounted
class_name GridPhysicks2D

static func divergence_2d(divs: PackedFloat32Array, speeds_x: PackedFloat32Array, speeds_y: PackedFloat32Array, width: int, height: int):
	divs.fill(0.0)
	for y in range(height):
		for x in range(width-2):
			var i := GridIndexingCalc.idx(x+1 , y, width-1)
			var spd_x:= speeds_x[i]
			var i_x_prev := GridIndexingCalc.idx(x, y, width)
			divs[i]+=spd_x
			divs[i_x_prev]-=spd_x
			
	for y in range(height-2):
		for x in range(width):	
			var i := GridIndexingCalc.idx(x, y+1, width)
			var spd_y:= speeds_y[i]
			var i_y_prev := GridIndexingCalc.idx(x, y, width)
			divs[i]+=spd_y
			divs[i_y_prev]-=spd_y
			
			
static func diffuse_scalar(arr: PackedFloat32Array, temp : PackedFloat32Array, width: int, height: int, rate: float) -> void:
	## calculates difusion (laplasian) ? 
	var size := width * height

	for y in range(1, height - 1):
		for x in range(1, width - 1):
			var i := GridIndexingCalc.idx(x, y, width)
			var lap := arr[GridIndexingCalc.idx(x - 1, y, width)]
			lap += arr[GridIndexingCalc.idx(x + 1, y, width)]
			lap += arr[GridIndexingCalc.idx(x, y - 1, width)]
			lap += arr[GridIndexingCalc.idx(x, y + 1, width)]
			lap -= 4.0 * arr[i]
			temp[i] = arr[i] + rate * lap
			
	diffuse_scalar_at_borders(arr,temp,width,height,rate)
			

static func diffuse_scalar_at_borders(arr: PackedFloat32Array, temp : PackedFloat32Array, width: int, height: int,rate: float):	

	for x in range(0, width):		
		diffuse_scalar_at_border(arr,temp,width,height,x,0,rate)
	var hm1 := height -1
	if hm1 > 0:
		for x in range(0, width):
			diffuse_scalar_at_border(arr,temp,width,height,x,hm1,rate)
		
	
	for y in range(1, height - 1):
			diffuse_scalar_at_border(arr,temp,width,height,0,y,rate)
	var wm1 := width -1 
	if wm1 > 0:
		for y in range(1, height - 1):
				diffuse_scalar_at_border(arr,temp,width,height,wm1,y,rate)		
			
			
			
static func diffuse_scalar_at_border(arr: PackedFloat32Array, temp : PackedFloat32Array, width: int, height: int, x:int,y:int,rate: float):
			var i := GridIndexingCalc.idx(x, y, width)
			var s := 0.0
			var n := 0

			if x > 0:
				s += arr[GridIndexingCalc.idx(x - 1, y, width)]
				n += 1
			if x < width - 1:
				s += arr[GridIndexingCalc.idx(x + 1, y, width)]
				n += 1
			if y > 0:
				s += arr[GridIndexingCalc.idx(x, y - 1, width)]
				n += 1
			if y < height - 1:
				s += arr[GridIndexingCalc.idx(x, y + 1, width)]
				n += 1

			var lap := s - float(n) * arr[i]
			temp[i] = arr[i] + rate * lap	
		
		
