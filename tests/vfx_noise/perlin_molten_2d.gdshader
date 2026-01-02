shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;

// Base shape source
uniform bool use_texture = true;
uniform vec4 solid_color : source_color = vec4(1.0); // used if use_texture = false

// Glass appearance
uniform vec4 glass_tint : source_color = vec4(0.70, 0.90, 1.00, 0.85);
uniform float refraction : hint_range(0.0, 0.08) = 0.025;
uniform float blur_mix : hint_range(0.0, 1.0) = 0.15; // small fake blur by mixing a second sample
uniform float highlight_strength : hint_range(0.0, 2.0) = 0.8;

// Edge controls (clean, soft, random)
uniform float edge_threshold : hint_range(0.0, 1.0) = 0.5; // where alpha becomes "inside"
uniform float edge_softness  : hint_range(0.0005, 0.2) = 0.02;
uniform float edge_noise_scale : hint_range(0.1, 200.0) = 18.0;
uniform float edge_noise_amp   : hint_range(0.0, 0.5) = 0.10;
uniform float edge_noise_sharpness : hint_range(0.5, 8.0) = 3.0; // higher = cleaner “random cuts”

// One-sided “vanish” of irregularity (not the whole glass unless you want it)
uniform vec2 vanish_dir = vec2(1.0, 0.0); // direction in UV space
uniform float vanish_start : hint_range(0.0, 1.0) = 0.65;
uniform float vanish_end   : hint_range(0.0, 1.0) = 0.95;

// Animation (pattern morph, not scrolling)
uniform float time_speed : hint_range(0.0, 5.0) = 0.6;

// Refraction noise controls (separate from edge noise)
uniform float warp_scale : hint_range(0.1, 200.0) = 6.0;
uniform float warp_strength : hint_range(0.0, 0.2) = 0.4;
uniform int octaves : hint_range(1, 8) = 4;
uniform float lacunarity : hint_range(1.0, 4.0) = 2.0;
uniform float gain : hint_range(0.0, 1.0) = 0.5;


// ---------- Seed-morph hash / Perlin (smooth pattern change over time) ----------
float hash12_seed(vec2 p, float seed) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031 + vec3(seed, seed * 1.33, seed * 2.17));
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

vec2 grad2_seed(vec2 cell, float seed) {
	float a = TAU * hash12_seed(cell, seed);
	return vec2(cos(a), sin(a));
}

float perlin2_seed(vec2 p, float seed) {
	vec2 i = floor(p);
	vec2 f = fract(p);

	// quintic fade
	vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);

	float a = dot(grad2_seed(i + vec2(0.0, 0.0), seed), f - vec2(0.0, 0.0));
	float b = dot(grad2_seed(i + vec2(1.0, 0.0), seed), f - vec2(1.0, 0.0));
	float c = dot(grad2_seed(i + vec2(0.0, 1.0), seed), f - vec2(0.0, 1.0));
	float d = dot(grad2_seed(i + vec2(1.0, 1.0), seed), f - vec2(1.0, 1.0));

	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y); // ~[-1,1]
}

float fbm_seed(vec2 p, float seed) {
	float sum = 0.0;
	float amp = 0.5;
	float freq = 1.0;

	for (int o = 0; o < 8; o++) {
		if (o >= octaves) break;
		sum += amp * perlin2_seed(p * freq, seed);
		freq *= lacunarity;
		amp *= gain;
	}
	return sum; // roughly [-1,1]
}

// Smoothly morph seeded noise over time: seed = floor(t) -> floor(t)+1 cross-fade
float fbm_morph(vec2 p, float t, float seed_offset) {
	float s0 = floor(t) + seed_offset;
	float s1 = s0 + 1.0;

	float f = fract(t);
	// quintic fade for the blend
	float w = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);

	float n0 = fbm_seed(p, s0);
	float n1 = fbm_seed(p, s1);
	return mix(n0, n1, w);
}

// Ridged / clean-edged scalar from noise (helps avoid “muddy” edges)
float ridged_clean(float n, float sharpness) {
	// n in [-1,1] -> ridged in [0,1]
	float r = 1.0 - abs(n);
	// sharpen: cleaner “random cuts” while keeping soft transitions with smoothstep later
	return pow(clamp(r, 0.0, 1.0), sharpness);
}

void fragment() {
	vec4 src = use_texture ? texture(TEXTURE, UV) : solid_color;

	// Base mask: use alpha (recommended) or intensity if you prefer
	float base_mask = src.a;

	// One-sided factor along vanish_dir (0..1)
	vec2 dir = normalize(vanish_dir);
	float along = dot(UV, dir); // UV is [0,1], so along is approx [0,1] depending on dir
	float side = smoothstep(vanish_start, vanish_end, along); // 0 = noisy side, 1 = clean side

	// Time for morphing (pattern changes without scrolling)
	float t = TIME * time_speed;

	// --- Edge noise: single “clean” band, amplitude fades on one side ---
	vec2 pe = UV * edge_noise_scale;

	// Use morphing seeded noise for edge pattern
	float ne = fbm_morph(pe, t, 0.0);          // [-1,1]
	float ce = ridged_clean(ne, edge_noise_sharpness); // [0,1] cleaner structure
	float edge_offset = (ce - 0.5) * 2.0;      // [-1,1]

	float edge_amp_local = edge_noise_amp * (1.0 - side); // irregularity vanishes on one side
	float noisy_mask = base_mask + edge_offset * edge_amp_local;

	// Soft but controlled edge: threshold the (noisy) mask
	float w = max(edge_softness, fwidth(base_mask) * 2.0); // keep stable at different scales
	float shape_alpha = smoothstep(edge_threshold - w, edge_threshold + w, noisy_mask);

	// --- Refraction field: smoother fBm + domain warp (molten feel) ---
	vec2 pw = UV * warp_scale;

	// Two decorrelated morphing fields for a 2D warp vector
	float nx = fbm_morph(pw + vec2(17.3,  9.1), t, 10.0);
	float ny = fbm_morph(pw + vec2(-5.7, 21.4), t, 25.0);
	vec2 warp = vec2(nx, ny) * warp_strength;

	// Approx normal from the warp field for refraction (finite difference)
	float eps = 0.002;
	float nx1 = fbm_morph((pw + vec2(eps, 0.0)) + vec2(17.3, 9.1), t, 10.0);
	float nx2 = fbm_morph((pw - vec2(eps, 0.0)) + vec2(17.3, 9.1), t, 10.0);
	float ny1 = fbm_morph((pw + vec2(0.0, eps)) + vec2(-5.7, 21.4), t, 25.0);
	float ny2 = fbm_morph((pw - vec2(0.0, eps)) + vec2(-5.7, 21.4), t, 25.0);

	vec2 grad = vec2(nx1 - nx2, ny1 - ny2) / (2.0 * eps);

	// Refraction offset (combine warp + gradient)
	vec2 refr_uv = SCREEN_UV + (warp + grad * 0.02) * refraction * shape_alpha;

	vec3 scene0 = texture(screen_tex, refr_uv).rgb;
	vec3 scene1 = texture(screen_tex, refr_uv + warp * 0.25 * refraction).rgb;
	vec3 scene = mix(scene0, scene1, blur_mix);

	// Edge highlight (a thin ring near the boundary)
	float edge_ring = shape_alpha * (1.0 - shape_alpha); // peaks at the transition
	edge_ring = pow(edge_ring * 4.0, 0.8);               // widen slightly

	vec3 glass = scene * glass_tint.rgb ; //mix(scene, scene * glass_tint.rgb, glass_tint.a);
	glass += edge_ring * highlight_strength;

	COLOR = vec4(glass, shape_alpha * glass_tint.a);
}
