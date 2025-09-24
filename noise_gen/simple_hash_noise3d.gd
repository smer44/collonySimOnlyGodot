extends Noise3D
class_name SimpleHashNoise3D


var _seed: int


func _init(seed: int = 1234) -> void:
	_seed = seed
	
	
# Produces a 32-bit unsigned-like integer.
#it seems it does not distribute the values uniformally
func _hash3i_old(x: int, y: int, z: int) -> int:
	var h: int = int(_seed) ^ (x * 374761393) ^ (y * 668265263) ^ (z * 1442695040888963407 % 0x100000000)
	# Mix bits (xorshift & multiply). Constants are large odd numbers.
	h = h ^ (h >> 13)
	h = h * 1274126177
	h = h ^ (h >> 16)
	return h & 0xFFFFFFFF

#MurmurHash-style
func _hash3i(x: int, y: int, z: int) -> int:
	var h: int = _seed
	h ^= x * 0x27d4eb2d
	h ^= y * 0x165667b1
	h ^= z * 0xd3a2646c
	h ^= (h >> 15)
	h *= 0x2c1b3c6d
	h ^= (h >> 12)
	h *= 0x297a2d39
	h ^= (h >> 15)
	return h & 0xFFFFFFFF
	
# Convert a 32-bit int to [0,1]
func _u32_to_float_unsigned(u: int) -> float:
	return float(u) / 4294967295.0


# Convert a 32-bit int to [-1,1] (kept for parity; not used by default here)
func _u32_to_float_signed(u: int) -> float:
	return (float(u) / 4294967295.0) * 2.0 - 1.0
	
# get function is reserved in Godot; using get_at like your 2D version
func get_at(p: Vector3, scale: Vector3) -> float:
# Domain scaling to map grid domain into noise domain
	p = p * scale


	var x0 := int(floor(p.x))
	var y0 := int(floor(p.y))
	var z0 := int(floor(p.z))
	var x1 := x0 + 1
	var y1 := y0 + 1
	var z1 := z0 + 1


	var sx := p.x - float(x0)
	var sy := p.y - float(y0)
	var sz := p.z - float(z0)


	# Corner samples mapped to [0,1]
	var n000 := _u32_to_float_unsigned(_hash3i(x0, y0, z0))
	var n100 := _u32_to_float_unsigned(_hash3i(x1, y0, z0))
	var n010 := _u32_to_float_unsigned(_hash3i(x0, y1, z0))
	var n110 := _u32_to_float_unsigned(_hash3i(x1, y1, z0))
	var n001 := _u32_to_float_unsigned(_hash3i(x0, y0, z1))
	var n101 := _u32_to_float_unsigned(_hash3i(x1, y0, z1))
	var n011 := _u32_to_float_unsigned(_hash3i(x0, y1, z1))
	var n111 := _u32_to_float_unsigned(_hash3i(x1, y1, z1))


	#No — the order of axes in trilinear interpolation does not affect the result.
	#trilinear interpolation is just a weighted average of the eight corner values
	var ix00 : float = lerp(n000, n100, sx)
	var ix10 : float = lerp(n010, n110, sx)
	var ix01 : float = lerp(n001, n101, sx)
	var ix11 : float = lerp(n011, n111, sx)


	var iy0 : float = lerp(ix00, ix10, sy)
	var iy1 : float = lerp(ix01, ix11, sy)


	return lerp(iy0, iy1, sz)
	



	
