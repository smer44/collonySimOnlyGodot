#version 450
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set=0, binding=0) uniform sampler2D mass_in;
layout(r32f, set=0, binding=1) writeonly uniform image2D mass_out;

void main() {
	ivec2 gid = ivec2(gl_GlobalInvocationID.xy);
	ivec2 sz  = imageSize(mass_out);
	if (gid.x >= sz.x || gid.y >= sz.y) return;

	float m = texelFetch(mass_in, gid, 0).r;
	float out_m = m * 0.95 + 0.01;
	imageStore(mass_out, gid, vec4(out_m, 0.0, 0.0, 1.0));
}
