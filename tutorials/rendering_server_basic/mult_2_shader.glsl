#[compute]
#version 450

// How many threads per workgroup
layout(local_size_x = 4, local_size_y = 1, local_size_z = 1) in;

// Storage buffer from CPU (binding must match GDScript)
layout(set = 0, binding = 0, std430)  buffer DataBuffer {
	float values[];
} data_buffer;

void main() {
	uint i = gl_GlobalInvocationID.x;
	data_buffer.values[i] *= 2.0; // simple: value = value * 2
}
