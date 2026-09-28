// Opaque-ish particle sprite (alpha blended): ink droplets, smoke, paper bits, leaves.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

#include "res://shaders/fx/mote_common.gdshaderinc"

uniform int shape = 6;
uniform float brightness = 1.0;

void vertex() {
	billboard_particle(MODELVIEW_MATRIX, INV_VIEW_MATRIX, VIEW_MATRIX, MODEL_MATRIX, INSTANCE_CUSTOM);
}

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float a = mote_alpha(shape, uv, INSTANCE_CUSTOM.w);
	ALBEDO = COLOR.rgb * brightness;
	ALPHA = clamp(a * COLOR.a, 0.0, 1.0);
}
