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
uniform bool multiply_by_intensity = true;              // noise *= intensity
uniform float noise_strength : hint_range(0.0, 1.0) = 1.0; // overall noise amplitude
uniform float blend_with_source : hint_range(0.0, 1.0) = 0.0; // 0=noise, 1=original


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

float fbm(vec2 p, float seed) {
	float sum = 0.0;
	float amp = 0.5;
	float freq = 1.0;

	for (int o = 0; o < 8; o++) {
		if (o >= octaves) break;
		sum += amp * perlin2(p * freq, seed);
		freq *= lacunarity;
		amp *= gain;
	}
	return sum; // roughly [-1,1] depending on settings
}

void fragment() {
	vec4 src = use_texture ? texture(TEXTURE, UV) : solid_color;

	// Intensity (luminance). If your input is already grayscale, this is effectively src.r.
	float intensity = dot(src.rgb, vec3(0.2126, 0.7152, 0.0722));

	// Base noise coordinates in UV space
	vec2 p = UV * noise_scale;

	// Make noise depend on brightness by warping coordinates using intensity
	p += vec2(intensity, intensity * 1.37) * intensity_warp;

	// Possible linear animation
	//p += vec2(TIME * time_speed);
	
	float t = TIME * time_speed;
	
	float s0 = floor(t);
	float s1 = s0 + 1.0;
	
	// Smooth blend factor between seeds
	float f = fract(t);
	float w = f; // * f * f * (f * (f * 6.0 - 15.0) + 10.0); // quintic fade

	// fBm Perlin noise, remapped to [0,1]
	float n0 = fbm(p, s0);
	float n1 = fbm(p, s1);
	
	float n = mix(n0, n1, w);
	n = n * 0.5 + 0.5;

	// Apply output shaping
	//n *= noise_strength;
	n*=n;
	if (multiply_by_intensity) {
		//n *= intensity;
	}
	

	vec3 noise_rgb = vec3(n);

	// Blend: 0 -> pure noise, 1 -> original color
	//vec3 out_rgb = mix(noise_rgb, src.rgb, blend_with_source);

	COLOR = vec4(src.rgb*n, src.a);
}
