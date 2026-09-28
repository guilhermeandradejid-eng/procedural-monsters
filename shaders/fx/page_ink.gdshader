// A faded ink illustration printed on the page (non-glowing, multiplied).
shader_type spatial;
render_mode unshaded, blend_mul, depth_draw_never, cull_disabled, shadows_disabled;

uniform sampler2D sigil : source_color, filter_linear_mipmap;
uniform vec4 ink : source_color = vec4(0.42, 0.3, 0.22, 1.0);
uniform float strength = 0.35;

void fragment() {
	float s = texture(sigil, UV).a * strength;
	ALBEDO = mix(vec3(1.0), ink.rgb, s);
}
