extends RefCounted
class_name GridVectorMath


static func fill_all(arr, size: int, value) -> void:
	arr.resize(size)
	arr.fill(value)
	
	
static func fill_x_add_y(arr, width: int, height: int, rate:float) -> void:
	var size:=width*height
	arr.resize(size)
	var row:=0
	for y in range(height):
		for x in range(width):
			arr[row + x] = float(x + y) * rate
		row+=width
		
static func add_x_add_y(arr, width: int, height: int, rate:float) -> void:
	var size:=width*height
	arr.resize(size)
	var row:=0
	for y in range(height):
		for x in range(width):
			arr[row + x] += float(x + y) * rate
		row+=width
	
	
static func fill_rect(arr, width: int, height: int, cx: int, cy: int, rx: int, ry: int, value) -> void:
	arr.resize(width * height)
	var x0 : int = max(0, cx-rx)
	var x1 : int = min(width, cx + rx)
	var y0 : int = max(0, cy-ry)
	var y1 : int = min(height, cy + ry)
	for y in range(y0, y1):
		for x in range(x0, x1):
			arr[GridIndexingCalc.idx(x, y, width)] = value	

static func max_of_all(mass: PackedFloat32Array) -> float:
	var m := mass[0]
	for i in range(1, mass.size()):
		if mass[i] > m:
			m = mass[i]
	return m


static func sum_of_all(arr: PackedFloat32Array) -> float :
	var s:float=0
	for i in range(arr.size()):
		s+=arr[i]
	return s

static func add_to_all(arr: PackedFloat32Array, value: float):
	for i in range(arr.size()):
		arr[i] +=value
		
static func mult_with_scalar(arr: PackedFloat32Array, value: float):\
	for i in range(arr.size()):
		arr[i] *=value

static func decay_to_all(mass: PackedFloat32Array, width: int, height: int, dt_mass: float):
	var size := width * height
	for i in range(size):
		var value :float= mass[i]
		var delta_value = -value * dt_mass
		mass[i] = delta_value
		
		
