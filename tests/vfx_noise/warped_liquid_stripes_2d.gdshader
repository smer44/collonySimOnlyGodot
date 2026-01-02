shader_type canvas_item;


vec2 rot(vec2 p, float a) {
    float s = sin(a);
    float c = cos(a);

    // Columns: (c, -s) and (s, c)
    mat2 R = mat2(vec2(c, -s),
                  vec2(s,  c));

    return R * p;
}


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



void fragment() {
	//Work in centered screen space
	vec2 uv = UV - 0.5;
	float scale = 10.0;
	float stripe_thickness = 1.0;


	uv *= scale;
	//Rotate the coordinate system (so stripes “orbit” the center)
	//uv = rot(uv, -0.2 + sin(TIME) * 1.05);

	//3) Build an x-dependent warp amplitude (“osc”)
	//float osc = sin(uv.x * (uv.x + 0.5) * 15.0) * 0.2;

	//4) Domain-warp the y coordinate (this bends the stripes)
	uv.y +=  sin(TIME + uv.x * 2.0);
	uv.x +=  sin(0.11 + TIME - uv.y * 2.1);

	//uv.x += smoothstep(-1.15 + stripe_thickness, 0.55 + stripe_thickness, uv.x)*10.0;

	//Tile the pattern into repeated stripe cells
	float stripes = 0.1;
	uv.y = fract(uv.y * stripes);

	//float uv_x = perlin2(uv, 124.5);
	//float uv_y = perlin2(uv, 561.2);
	//uv = vec2(uv_x, uv_y);
	//uv = rot(uv, -0.2 + TIME * 1.05);

	float mask = smoothstep(0.5, 0.55, uv.y);
	mask -= smoothstep(-1.15 + stripe_thickness, 0.55 + stripe_thickness, uv.y);



	vec4 background_color =texture(TEXTURE, UV);
	vec4 stripe_color = vec4(0.1,0.2,0.7,1.0);
	vec3 final_color = mix(background_color.rgb, stripe_color.rgb, mask);
	COLOR = vec4(final_color, 1.0);


	}