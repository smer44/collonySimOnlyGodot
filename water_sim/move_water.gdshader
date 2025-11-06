// move_mass.gdshader
shader_type canvas_item;

uniform sampler2D mass_tex;     // R channel (water mass), previous step
uniform sampler2D speed_tex;    // RG (R=speed_x, G=speed_y), previous step
//uniform vec2 texel;// = vec2(1.0/256.0, 1.0/256.0); // 1.0 / (width, height)
uniform vec2 texel = vec2(0.00390625, 0.00390625); // 1/256 as literals
uniform float dt_mass = 0.2;

float flow(float s, float m_from, float m_to) {
	// If s >= 0 flow goes "forward" using upstream mass m_from.
	// If s  < 0 flow goes "backward" using upstream mass m_to   (the neighbor is upstream).
	float use_from = step(0.0, s);              // 1 when s>=0, 0 when s<0
	float m_upstream = mix(m_to, m_from, use_from);
	return s * dt_mass * m_upstream;
}

void fragment() {
	vec2 uv = UV;
	vec2 dx = vec2(texel.x, 0.0);
	vec2 dy = vec2(0.0, texel.y);

	// Mass of current + 4-neighbors
	float mC = texture(mass_tex, uv).r;
	float mR = texture(mass_tex, clamp(uv + dx, vec2(0.0), vec2(1.0))).r;
	float mL = texture(mass_tex, clamp(uv - dx, vec2(0.0), vec2(1.0))).r;
	float mD = texture(mass_tex, clamp(uv + dy, vec2(0.0), vec2(1.0))).r;
	float mU = texture(mass_tex, clamp(uv - dy, vec2(0.0), vec2(1.0))).r;

	// Speeds at current and neighbor edges (packed RG)
	vec2 sC = texture(speed_tex, uv).rg;                       // (sx to right, sy to down)
	vec2 sL = texture(speed_tex, clamp(uv - dx, vec2(0.0), vec2(1.0))).rg; // left cell's sx to right
	vec2 sU = texture(speed_tex, clamp(uv - dy, vec2(0.0), vec2(1.0))).rg; // up cell's sy to down

	float sxR = sC.r;                   // edge (C -> R)
	float syD = sC.g;                   // edge (C -> D)
	float sxL = sL.r;                   // edge (L -> C)
	float syU = sU.g;                   // edge (U -> C)

	// Kill non-existent edges at domain borders
	bool right_border  = uv.x >= (1.0 - 0.5 * texel.x);
	bool bottom_border = uv.y >= (1.0 - 0.5 * texel.y);
	bool left_border   = uv.x <= (0.5 * texel.x);
	bool top_border    = uv.y <= (0.5 * texel.y);

	if (right_border)  sxR = 0.0;
	if (bottom_border) syD = 0.0;
	if (left_border)   sxL = 0.0;
	if (top_border)    syU = 0.0;

	// Outflows (to right & down) and inflows (from left & up)
	float outR = flow(sxR, mC, mR);
	float inL  = flow(sxL, mL, mC);
	float outD = flow(syD, mC, mD);
	float inU  = flow(syU, mU, mC);

	float mNew = mC - outR - outD + inL + inU;
	mNew = max(mNew, 0.0); // no negative mass

	COLOR = vec4(mNew, 0.0, 0.0, 1.0);
}
