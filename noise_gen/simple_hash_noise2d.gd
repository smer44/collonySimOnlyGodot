extends Noise2D
class_name SimpleHashNoise2D


var _seed: int


func _init(seed: int = 1234) -> void:
	_seed = seed

# Integer hash for 2D coordinates + seed.
# Produces a 32-bit unsigned-like integer, then maps to [-1, 1].
# This is intentionally simple and fast ("value noise" at lattice points).
func _hash2i(x: int, y: int) -> int:
	var h: int = int(_seed) ^ (x * 374761393) ^ (y * 668265263)
	# Mix bits (xorshift & multiply). Constants are large odd numbers.
	h = h ^ (h >> 13)
	h = h * 1274126177
	h = h ^ (h >> 16)
	# Constrain to 32-bit space (GDScript uses signed ints, so mask to emulate uint32)
	return h & 0xFFFFFFFF

func _u32_to_float_signed(u: int) -> float:
# Divide by 2^32-1 to get [0,1], then scale to [-1,1]
	return (float(u) / 4294967295.0) * 2.0 - 1.0
	
func _u32_to_float_unsigned(u: int) -> float:
# Divide by 2^32-1 to get [0,1], then scale to [-1,1]
	return float(u) / 4294967295.0
	
# get function is reserved for something in godot, this is why i use get_at
func get_at(p: Vector2, scale: Vector2) -> float:
	p = p * scale
	var x0 := int(floor(p.x))
	var y0 := int(floor(p.y))
	var x1 := x0 + 1
	var y1 := y0 + 1


	var sx := p.x - float(x0)
	var sy := p.y - float(y0)
	#var fn_to_float :=isSigned ? _u32_to_float_signed : _u32_to_float_unsigned


	var n00 := _u32_to_float_unsigned(_hash2i(x0, y0))
	var n10 := _u32_to_float_unsigned(_hash2i(x1, y0))
	var n01 := _u32_to_float_unsigned(_hash2i(x0, y1))
	var n11 := _u32_to_float_unsigned(_hash2i(x1, y1))


	# Simple (non-faded) bilinear interpolation.
	var ix0 :float= lerp(n00, n10, sx)
	var ix1 :float= lerp(n01, n11, sx)
	return lerp(ix0, ix1, sy)
	

func populate(grid: Array[Array], scale: Vector2):
	if grid.is_empty():
		return	
	var width := grid.size()
	var height := grid[0].size()
	var maxp := Vector2(width,height)
	for x in width:
		var row :Array= grid[x] 
		for y in height:
			var p:= Vector2(x,y)
			var value:=get_at(p,scale)
			row[y] = value 
	
			
	
	
