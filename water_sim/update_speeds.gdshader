// update_speeds.gdshader
shader_type canvas_item;

uniform sampler2D mass_tex;     // R (the *new* mass from Pass 1)
uniform sampler2D surface_tex;  // R (static ground elevation)
uniform sampler2D speed_tex;    // RG (previous speeds)
//uniform vec2 texel = vec2(1.0/256.0, 1.0/256.0);// you may not write 1/126 
uniform vec2 texel = vec2(0.00390625, 0.00390625); // 1/256 as literals
uniform float dt_speed = 0.1;

void fragment() {
	vec2 uv = UV;
	vec2 dx = vec2(texel.x, 0.0);
	vec2 dy = vec2(0.0, texel.y);
	float eps = 1e-6;

	// current & neighbors mass/surface/elevation
	float mC = texture(mass_tex, uv).r;
	float mR = texture(mass_tex, clamp(uv + dx, vec2(0.0), vec2(1.0))).r;
	float mD = texture(mass_tex, clamp(uv + dy, vec2(0.0), vec2(1.0))).r;

	float sC = texture(surface_tex, uv).r;
	float sR = texture(surface_tex, clamp(uv + dx, vec2(0.0), vec2(1.0))).r;
	float sD = texture(surface_tex, clamp(uv + dy, vec2(0.0), vec2(1.0))).r;

	float eC = mC + sC;
	float eR = mR + sR;
	float eD = mD + sD;

	vec2 v = texture(speed_tex, uv).rg; // (sx, sy)

	// Horizontal edge (C <-> R) lives at (uv)
	if (uv.x >= (1.0 - 0.5 * texel.x)) {
		v.r = 0.0; // last column: no edge to the right
	} else {
		bool empty_or_blocked =
			(mC < eps && mR < eps) ||
			((sC > eR && mC < eps) || (sR > eC && mR < eps));
		if (empty_or_blocked) {
			v.r = 0.0;
		} else {
			float diff = eC - eR;
			v.r += diff * dt_speed;
		}
	}

	// Vertical edge (C <-> D) lives at (uv)
	if (uv.y >= (1.0 - 0.5 * texel.y)) {
		v.g = 0.0; // last row: no edge downward
	} else {
		bool empty_or_blocked =
			(mC < eps && mD < eps) ||
			((sC > eD && mC < eps) || (sD > eC && mD < eps));
		if (empty_or_blocked) {
			v.g = 0.0;
		} else {
			float diffy = eC - eD;
			v.g += diffy * dt_speed;
		}
	}

	COLOR = vec4(v, 0.0, 1.0);
}
