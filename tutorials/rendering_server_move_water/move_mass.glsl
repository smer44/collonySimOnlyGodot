#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

// Mass images: input and output (ping-pong on host side)
layout(set = 0, binding = 0, r32f) uniform readonly  image2D mass_in_image;
layout(set = 0, binding = 1, r32f) uniform writeonly image2D mass_out_image;

// Speed image (rg32f):
//  r = horizontal speed between (x,y) and (x+1,y)
//  g = vertical   speed between (x,y) and (x,y+1)
layout(set = 0, binding = 2, rg32f) uniform readonly image2D speed_image;


// Params: width, height, dt_mass
layout(set = 0, binding = 3, std140) uniform Params {
	float width;
	float height;
	float dt_mass;
	float _pad;   // alignment padding
} params;

// ------------------------------------------------------------
// Helper: equivalent to the CPU move_mass_between_cells core
// It returns the "amount" term (m * s * dt_mass).
// In CPU:
//   var s := speeds[i_speed]
//   var m := mass[i] if s >= 0.0 else mass[j]
//   var koef := s * dt_mass
//   var amount := m * koef
// ------------------------------------------------------------

float compute_amount(float mass_i, float mass_j, float s, float dt_mass) {
	float m = (s >= 0.0) ? mass_i : mass_j;
	float koef = s * dt_mass;
	return m * koef;  // "amount" in the original code
}

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
	
	ivec2 coord = ivec2(int(x), int(y));
	float first_mass = imageLoad(mass_in_image, coord).r;
	float dt = params.dt_mass;
	
	//Horizontal flow
	// This will accumulate the net change (sum of all amounts from edges)
	float delta = 0.0;
	
	if (x > 0u) {
		ivec2 left_coord = ivec2(int(x) - 1, int(y));
		float left_mass = imageLoad(mass_in_image, left_coord).r;
		float speed = imageLoad(speed_image, left_coord).r; // speed_x from (x-1,y) to (x,y)
		float amount = compute_amount(left_mass, first_mass, speed, dt);
		delta += amount;
		
	}
	
	
	if (x + 1u < w) {
		
		ivec2 right_coord = ivec2(int(x+1u), int(y));	
		float right_mass = imageLoad(mass_in_image, right_coord).r;
		float speed = imageLoad(speed_image, coord).r; // speed_x from (x,y) to (x+1,y)
		
		float amount = compute_amount(first_mass, right_mass, speed, dt);
		delta -= amount;
	}
	
	if (y > 0u) {
		ivec2 up_coord = ivec2(int(x), int(y) - 1);
		float up_mass = imageLoad(mass_in_image, up_coord).r;
		float speed = imageLoad(speed_image, up_coord).g; // speed_y from (x,y-1) to (x,y)
		float amount = compute_amount(up_mass, first_mass, speed, dt);
		delta += amount;
	}
	
	if (y + 1u < h) {
		ivec2 down_coord = ivec2(int(x), int(y) + 1);
		float down_mass = imageLoad(mass_in_image, down_coord).r;
		float speed = imageLoad(speed_image, coord).g; // speed_y from (x,y) to (x,y+1)
		float amount = compute_amount(first_mass, down_mass, speed, dt);
		delta -= amount;
	}
	// Final mass: original + net change from all 4 edges
	float m_new = first_mass + delta;
	imageStore(mass_out_image, coord, vec4(m_new, 0.0, 0.0, 0.0));

}
