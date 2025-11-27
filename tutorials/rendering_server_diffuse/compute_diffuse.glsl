#[compute]
#version 450

// Workgroup size (tweak as you like)
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

// Read-only input buffer
layout(set = 0, binding = 0, std430) readonly buffer InputBuffer {
	float in_values[];
};

// Write-only output buffer
layout(set = 0, binding = 1, std430) writeonly buffer OutputBuffer {
	float out_values[];
};

// Params: width, height, diffusion coefficient
layout(set = 0, binding = 2, std140) uniform Params {
	float width;
	float height;
	float diffusion; // e.g. 0.25
	float _pad;      // padding so block is 16 bytes total
} params;

void main() {
	uvec2 gid = gl_GlobalInvocationID.xy;
	uint x = gid.x;
	uint y = gid.y;
	
	uint w = uint(params.width);
	uint h = uint(params.height);

	// Outside the simulation area? Do nothing
	if (x >= w || y >= h) {
		return;
	}


	uint idx = y * w + x;

	float center = in_values[idx];

	// Neumann-style borders (use self when neighbor is out of bounds)
	float up    = (y > 0)          ? in_values[(y - 1u) * w + x] : center;
	float down  = (y + 1u < h)     ? in_values[(y + 1u) * w + x] : center;
	float left  = (x > 0)          ? in_values[y * w + (x - 1u)] : center;
	float right = (x + 1u < w)     ? in_values[y * w + (x + 1u)] : center;

	float lap = (up + down + left + right - 4.0 * center);
	float next =  center + params.diffusion * lap;

	out_values[idx] = next;
}
