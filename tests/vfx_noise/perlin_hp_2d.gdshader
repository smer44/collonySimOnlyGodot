shader_type canvas_item;

// If true, uses the node's TEXTURE; if false, uses solid_color instead.
uniform bool use_texture = true;
uniform vec4 solid_color : source_color = vec4(1.0);

// Noise controls
uniform float noise_scale : hint_range(0.1, 200.0) = 8.0;
uniform int octaves : hint_range(1, 8) = 2;
uniform float lacunarity : hint_range(1.0, 4.0) = 2.0;
uniform float gain : hint_range(0.0, 1.0) = 0.5;

// How strongly the input intensity shifts the noise coordinates (makes noise depend on brightness)
uniform float intensity_warp : hint_range(0.0, 10.0) = 2.0;

// Optional animation
uniform float time_speed : hint_range(0.0, 5.0) = 0.0;

// Output controls

uniform float split_threshold : hint_range(0.0, 1.0) = 0.3;
uniform float split_softness  : hint_range(0.0, 0.5) = 0.3; // half-width of the smooth band
uniform float split_amount    : hint_range(0.0, 0.5) = 1.5; // how much brighter/darker




// ---- Hash/grad helpers (IQ-style hash; good quality, no texture needed) ----
float hash12_seed(vec2 p, float seed) {
    // Any deterministic injection is fine; the point is to decorrelate per seed.
    vec3 p3 = fract(vec3(p.xyx) * 0.1031 + vec3(seed, seed * 1.33, seed * 2.17));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}



vec2 grad2(vec2 cell, float seed) {
    float a = TAU * hash12_seed(cell, seed);
    return vec2(cos(a), sin(a));
}


float perlin2(vec2 p, float seed) {
	vec2 i = floor(p);
	vec2 f = fract(p);

	// Quintic fade (smoother than cubic)
	vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);

	float a = dot(grad2(i + vec2(0.0, 0.0),seed), f - vec2(0.0, 0.0));
	float b = dot(grad2(i + vec2(1.0, 0.0),seed), f - vec2(1.0, 0.0));
	float c = dot(grad2(i + vec2(0.0, 1.0),seed), f - vec2(0.0, 1.0));
	float d = dot(grad2(i + vec2(1.0, 1.0),seed), f - vec2(1.0, 1.0));

	float x1 = mix(a, b, u.x);
	float x2 = mix(c, d, u.x);
	return mix(x1, x2, u.y); // ~[-1,1]
}

float bipolar_softstep(float x, float threshold, float half_width) {
    float s = smoothstep(threshold - half_width, threshold + half_width, x);
    return s; // [-1..+1]
}

// Multiplier: below threshold => 1+amount (brighter), above => 1-amount (darker).
float bright_dark_around_threshold(float x, float threshold, float half_width, float amount) {
    return 1.0 - amount * bipolar_softstep(x, threshold, half_width);
}




float fbm(vec2 p, float seed) {
	float sum = 0.0;
	float amp = 0.5;
	float freq = 1.0;

	for (int o = 0; o < 4; o++) {
		if (o >= octaves) break;
		sum += amp * perlin2(p * freq, seed);
		freq *= lacunarity;
		amp *= gain;
	}
	return sum; // roughly [-1,1] depending on settings
}

// Returns 1.0 if uv is inside the rectangle [uv_min, uv_max], else 0.0.
// uv_min and uv_max are in UV space (typically 0..1). pad expands (>0) or shrinks (<0) the rect.
float uv_in_rect(vec2 uv, vec2 uv_min, vec2 uv_max, float pad) {
    vec2 mn = uv_min - vec2(pad);
    vec2 mx = uv_max + vec2(pad);

    // step(a,b) = 0 if b < a else 1
    float inside_x = step(mn.x, uv.x) * step(uv.x, mx.x);
    float inside_y = step(mn.y, uv.y) * step(uv.y, mx.y);
    return inside_x * inside_y;
}

// Soft (feathered) mask for a UV rectangle.
// Returns 1.0 well inside the rect, 0.0 well outside, and smoothly transitions across `feather`.
// pad expands (>0) or shrinks (<0) the rect prior to feathering.
float uv_in_rect_soft(vec2 uv, float pad, float feather) {
    vec2 mn = vec2(pad);
    vec2 mx = 1.0 - vec2(pad);

    // Feather per axis: ramp up after mn, ramp down before mx
    float x_in = smoothstep(mn.x, mn.x + feather, uv.x) * (1.0 - smoothstep(mx.x - feather, mx.x, uv.x));
    float y_in = smoothstep(mn.y, mn.y + feather, uv.y) * (1.0 - smoothstep(mx.y - feather, mx.y, uv.y));

    return x_in * y_in;
}




void fragment() {
	vec4 src = use_texture ? texture(TEXTURE, UV) : solid_color;

	// Intensity (luminance). If your input is already grayscale, this is effectively src.r.
	float intensity = dot(src.rgb, vec3(0.2126, 0.7152, 0.0722));

	// Base noise coordinates in UV space
	vec2 p = UV * noise_scale;

	// Make noise depend on brightness by warping coordinates using intensity
	//p += vec2(intensity, intensity * 1.37) * intensity_warp;

	// Possible linear animation
	//p += vec2(TIME * time_speed);
	
	float t = TIME * time_speed;
	
	p += vec2(t);
	
	float s0 = floor(t);
	float s1 = s0 + 1.0;
	
	// Smooth blend factor between seeds
	float f = fract(t);
	float w = f; // * f * f * (f * (f * 6.0 - 15.0) + 10.0); // quintic fade

	// fBm Perlin noise, remapped to [0,1]
	float n0 = fbm(p, s0);
	float n1 = fbm(p, s1);
	
	float n = mix(n0, n1, w);
	
	float border = 1.0- uv_in_rect_soft(UV, -0.15,0.3 );
	
	//n = n * 0.5 + 0.5;
	//n*=n;
	
	float point = smoothstep(0.1,1.0,1.0-n);
	
	
	float mult = bright_dark_around_threshold(n, split_threshold, split_softness, split_amount);
	vec3 out_rgb = clamp(src.rgb * mult + 0.2 * border, 0.0, 1.0);
	

	COLOR = vec4(out_rgb, src.a);
}
