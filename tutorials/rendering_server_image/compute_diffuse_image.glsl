#[compute]
#version 450

// Workgroup size (same as before)
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

// Input image (read-only)
layout(set = 0, binding = 0, r32f) uniform readonly image2D in_image;

// Output image (write-only)
layout(set = 0, binding = 1, r32f) uniform writeonly image2D out_image;


// Params: width, height, diffusion coefficient (same as before)
layout(set = 0, binding = 2, std140) uniform Params {
	float width;
	float height;
	float diffusion; // e.g. 0.25
	float _pad;      // padding so block is 16 bytes total
} params;

void main() {
	uvec2 gid = gl_GlobalInvocationID.xy;
	int x = int(gid.x);
	int y = int(gid.y);
	
	int w = int(params.width);
	int h = int(params.height);
	
	// Outside the simulation area? Do nothing.
	if (x >= w || y >= h) {
		return;
	}
	
	int x_left  = (x > 0)      ? x - 1 : x;
	int x_right = (x + 1 < w)  ? x + 1 : x;
	int y_up    = (y > 0)      ? y - 1 : y;
	int y_down  = (y + 1 < h)  ? y + 1 : y;

   // Current pixel coordinate
	ivec2 coord_center = ivec2(x, y);
	ivec2 c_up     = ivec2(x,       y_up);
	ivec2 c_down   = ivec2(x,       y_down);
	ivec2 c_left   = ivec2(x_left,  y);
	ivec2 c_right  = ivec2(x_right, y);
	
	float center = imageLoad(in_image, coord_center).r;
	float up     = imageLoad(in_image, c_up).r;
	float down   = imageLoad(in_image, c_down).r;
	float left   = imageLoad(in_image, c_left).r;
	float right  = imageLoad(in_image, c_right).r;
	
	float lap  = (up + down + left + right - 4.0 * center);
	float next = center + params.diffusion * lap;
	
	imageStore(out_image, coord_center, vec4(next, 0.0, 0.0, 1.0));
	
}


	
	
