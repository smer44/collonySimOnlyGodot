shader_type canvas_item;
/* Inputs:
   - speed_tex: W×H texture where each texel’s R channel stores |velocity| (or a scaled version).
   - palette_tex: 1×N texture containing your N palette colors (set filtering to Nearest).
   - palette_count: number of colors in the palette texture (N).
   - speed_gain: multiplies the sampled speed before indexing into the palette.
   - wrap_palette: if true, use modulo N; if false, clamp to [0, N-1].
*/


uniform sampler2D speed_tex;
uniform sampler2D palette_tex;
uniform float palette_count = 8.0;
uniform float speed_gain = 8.0;
uniform bool copy_colors = false;




void fragment() {
    // read speed magnitude from red channel
	if (copy_colors){
		vec3 rgb = texture(speed_tex, UV).rgb;
		vec4 col = vec4(rgb, 1.0);
		COLOR = col;
		
	}
	else{
		
	    float s = texture(speed_tex, UV).r;

	    // convert to palette index

	    float idx_used = mod(speed_gain * s, palette_count-1.0);

	    // sample palette at the center of the chosen color texel
	    float u = (idx_used +0.5) / palette_count;
		
		vec4 palette_color = texture(palette_tex, vec2(u,0.5));
	    vec4 col = vec4(0.0, 0.0, s, 1.0);
		col = vec4(0.5,0.0, 0.5, 1.0);
			
	    COLOR = col;
		//COLOR = palette_color;
	}
}
