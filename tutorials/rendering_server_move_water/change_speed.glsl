#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

// Mass (water) image
layout(set = 0, binding = 0, r32f) uniform readonly image2D mass_image;

// Surface (terrain) image
layout(set = 0, binding = 1, r32f) uniform readonly image2D surface_image;

// Speed image (rg32f):
//  .r = horizontal speed between (x,y) and (x+1,y)
//  .g = vertical   speed between (x,y) and (x,y+1)
layout(set = 0, binding = 2, rg32f) uniform image2D speed_image;


// Params: width, height, dt_speed
layout(set = 0, binding = 3, std140) uniform Params {
	float width;
	float height;
	float dt_speed;
	float _pad;   // alignment padding
} params;

// ------------------------------------------------------------
// Equivalent of update_speed_for_surface_between_cells()
// Returns updated speed value for the edge between cell i and j.
// ------------------------------------------------------------

float update_speed_between_cells(
	float mass_i,
	float surface_i,
	float mass_j,
	float surface_j,
	float speed,
	float dt_speed
){
	const float eps = 1e-6;
	float ele_i = mass_i + surface_i;
	float ele_j = mass_j + surface_j;
	
	// Same condition as in CPU code:
	if ((mass_i < eps && mass_j < eps) ||
		((surface_i > ele_j && mass_i < eps) ||
		 (surface_j > ele_i && mass_j < eps))) {
		return 0.0;
	}
	float diff = ele_i - ele_j;
	return speed + diff * dt_speed;	
}

void main() {
	uvec2 gid = gl_GlobalInvocationID.xy;
	uint x = gid.x;
	uint y = gid.y;
	
	uint w = uint(params.width);
	uint h = uint(params.height);
	
	// Outside simulation area? Do nothing
	if (x >= w || y >= h) {
		return;
	}
	
	ivec2 coord = ivec2(int(x), int(y));
	// Load current speeds at this speed-texel
	vec4 s4 = imageLoad(speed_image, coord);
	float sx = s4.r; // horizontal speed from (x,y) to (x+1,y) 
	float sy = s4.g; // vertical   speed from (x,y) to (x,y+1)
	
	float dt = params.dt_speed;
	
	// Preload center mass/surface once
	float mass_c    = imageLoad(mass_image,    coord).r;
	float surface_c = imageLoad(surface_image, coord).r;
	
	if (x + 1u < w) {
		ivec2 right_coord = ivec2(int(x) + 1, int(y));
		float mass_r    = imageLoad(mass_image,    right_coord).r;
		float surface_r = imageLoad(surface_image, right_coord).r;
		sx = update_speed_between_cells(
			mass_c, surface_c,
			mass_r, surface_r,
			sx, dt
		);
	}
	
	if (y + 1u < h) {
		ivec2 down_coord = ivec2(int(x), int(y) + 1);
		float mass_d    = imageLoad(mass_image,    down_coord).r;
		float surface_d = imageLoad(surface_image, down_coord).r;
		sy = update_speed_between_cells(
			mass_c, surface_c,
			mass_d, surface_d,
			sy, dt
		);
		
	}
	
// Write updated speeds back
imageStore(speed_image, coord, vec4(sx, sy, 0.0, 0.0));
	
	
}
