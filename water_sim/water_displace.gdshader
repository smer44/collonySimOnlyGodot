// water_displace.gdshader
shader_type spatial;
render_mode cull_back, depth_prepass_alpha;

uniform sampler2D surface_tex;  // R (ground)
uniform sampler2D mass_tex;     // R (current water mass)
uniform float height_scale = 1.0;

void vertex() {
	float ground = texture(surface_tex, UV).r;
	float mass   = texture(mass_tex,    UV).r;
	float elev   = ground + mass;
	VERTEX.y = elev * height_scale;
}
