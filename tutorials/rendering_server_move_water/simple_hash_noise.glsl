#[compute]
#version 450
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

// Output image: one float per cell, like populate_packed()
layout(set = 0, binding = 0, r32f) uniform writeonly image2D noise_image;

// Params: width, height, scale, seed
// You can pack these as floats in a UBO from Godot.
// seed is passed as float and cast to int in shader.
layout(set = 0, binding = 1, std140) uniform Params {
	float width;
	float height;
	vec2  scale;   // corresponds to your Vector2 scale
	float seed;    // will be cast to int
	float amplitude;    // 
	float _pad1;    // padding for alignment / future use
	float _pad2;    // padding for alignment / future use
} params;

uint hash2u(int x, int y, int seed) {
	uint h = uint(seed);
	h ^= uint(x) * 374761393u;
	h ^= uint(y) * 668265263u;

	h ^= (h >> 13);
	h *= 1274126177u;
	h ^= (h >> 16);

	return h; // already in 0..2^32-1
}


// Map uint32 to [0, 1], like _u32_to_float_unsigned
float u32_to_float_unsigned(uint u) {
	return float(u) / 4294967295.0;
}
// ------------------------------------------------------------
// get_at(p, scale) equivalent: p is (x,y) in cell coords.
// ------------------------------------------------------------

float noise_get_at(ivec2 p, vec2 scale, int seed) {
	// p * scale
	vec2 pf = vec2(p) * scale;

	int x0 = int(floor(pf.x));
	int y0 = int(floor(pf.y));
	int x1 = x0 + 1;
	int y1 = y0 + 1;

	float sx = pf.x - float(x0);
	float sy = pf.y - float(y0);

	// Lattice noise values at integer corners
	float n00 = u32_to_float_unsigned(hash2u(x0, y0, seed));
	float n10 = u32_to_float_unsigned(hash2u(x1, y0, seed));
	float n01 = u32_to_float_unsigned(hash2u(x0, y1, seed));
	float n11 = u32_to_float_unsigned(hash2u(x1, y1, seed));

	// Simple bilinear interpolation (no fade)
	float ix0 = mix(n00, n10, sx);
	float ix1 = mix(n01, n11, sx);
	return mix(ix0, ix1, sy);
}

void main() {
	uvec2 gid = gl_GlobalInvocationID.xy;
	uint x = gid.x;
	uint y = gid.y;
	uint w = uint(params.width);
	uint h = uint(params.height);
	// Outside bounds? Do nothing.
	if (x >= w || y >= h) {
		return;
	}
	
	ivec2 coord = ivec2(int(x), int(y));
	int seed_i = int(params.seed); // match GDScript _seed
	float value = noise_get_at(coord, params.scale, seed_i);
	imageStore(noise_image, coord, vec4(value * params.amplitude, 0.0, 0.0, 1.0));
}
	
	
	
