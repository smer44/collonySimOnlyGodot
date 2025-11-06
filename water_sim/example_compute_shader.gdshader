shader_type compute;
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;


// Binding 0: sampled input texture (R32F)
uniform sampler2D mass_in; // binding = 0


// Binding 1: storage image output (R32F)
layout(r32f, binding = 1) uniform writeonly image2D mass_out;


void main() {
ivec2 gid = ivec2(gl_GlobalInvocationID.xy);
ivec2 sz = imageSize(mass_out);
if (gid.x >= sz.x || gid.y >= sz.y) return;


// integer fetch (no filtering, no sampler state dependence)
float m = texelFetch(mass_in, gid, 0).r;


// Simple operation so we can see change over time
float out_m = m * 0.95 + 0.01;


imageStore(mass_out, gid, vec4(out_m, 0.0, 0.0, 1.0));
}
