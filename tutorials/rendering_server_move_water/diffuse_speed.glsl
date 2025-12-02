#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

// Input speed image (read-only)
layout(set = 0, binding = 0, rg32f) uniform readonly image2D speed_in_image;

// Output speed image (write-only)
layout(set = 0, binding = 1, rg32f) uniform writeonly image2D speed_out_image;

// Params: width, height, diffusion coefficient
layout(set = 0, binding = 2, std140) uniform Params {
	float width;
	float height;
	float diffusion; // e.g. 0.25
	float _pad;      // padding so block is 16 bytes
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
	// Component-specific right/down indices
	// Common clamping for left/up
	int x_left  = (x > 0)     ? x - 1 : x;
	int y_up    = (y > 0)      ? y - 1 : y;
	
	// .r (horizontal speeds): valid x range [0, w-2]
	int x_right_r = (x + 2 < w) ? x + 1 : x;  // clamp to <= w-2
	int y_down_r  = (y + 1 < h) ? y + 1 : y;  // full vertical range
	
	// .g (vertical speeds): valid y range [0, h-2]
	int x_right_g = (x + 1 < w) ? x + 1 : x;  // full horizontal range
	int y_down_g  = (y + 2 < h) ? y + 1 : y;  // clamp to <= h-2
	
	ivec2 c_center   = ivec2(x, y);
	ivec2 c_left     = ivec2(x_left, y);
	ivec2 c_right_r  = ivec2(x_right_r, y);
	ivec2 c_right_g  = ivec2(x_right_g, y);
	ivec2 c_up       = ivec2(x, y_up);
	ivec2 c_down_r   = ivec2(x, y_down_r);
	ivec2 c_down_g   = ivec2(x, y_down_g);
	
	// Load center
	vec2 center = imageLoad(speed_in_image, c_center).rg;
	float center_r = center.x;
	float center_g = center.y;
	
	// Load left:
	vec2 left = imageLoad(speed_in_image, c_left).rg;
	float left_r  = left.x;
	float left_g  = left.y;
	
	// Load up:
	vec2 up = imageLoad(speed_in_image, c_up).rg;
	float up_r   = up.x;
	float up_g   = up.y;
	
	// Neighbors for .r
	float right_r = imageLoad(speed_in_image, c_right_r).r;
	float down_r  = imageLoad(speed_in_image, c_down_r).r;
	
	// Neighbors for .g
	float right_g = imageLoad(speed_in_image, c_right_g).g;
	float down_g  = imageLoad(speed_in_image, c_down_g).g;
	
	float d = params.diffusion;
	
	// Laplacian for each component
	float lap_r = (up_r + down_r + left_r + right_r - 4.0 * center_r);
	float lap_g = (up_g + down_g + left_g + right_g - 4.0 * center_g);	

	float next_r = center_r + d * lap_r;
	float next_g = center_g + d * lap_g;

	vec2 next = vec2(next_r, next_g);
	imageStore(speed_out_image, c_center, vec4(next, 0.0, 1.0));
	
	
}
