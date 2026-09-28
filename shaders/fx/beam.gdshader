// Lance / ray beam. Mesh is a flat strip: UV.x across, UV.y along the beam.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

#include "res://shaders/fx/noise.gdshaderinc"

uniform vec4 core : source_color = vec4(1.0);
uniform vec4 color : source_color = vec4(1.0, 0.5, 0.1, 1.0);
uniform float glow = 3.5;
uniform float jagged = 0.0;
instance uniform float fade = 1.0;

void fragment() {
	float across = abs(UV.x - 0.5) * 2.0;
	float n = vnoise2(vec2(UV.y * 18.0 - TIME * 30.0, TIME * 8.0));
	float jag = jagged * (vnoise2(vec2(UV.y * 40.0, TIME * 25.0)) - 0.5) * 0.8;
	float a_core = 1.0 - smoothstep(0.0, 0.18 + n * 0.1, abs(across + jag));
	float a_body = 1.0 - smoothstep(0.2, 1.0, abs(across + jag * 0.5));
	float tip = smoothstep(0.0, 0.04, UV.y) * (1.0 - smoothstep(0.93, 1.0, UV.y));
	vec3 col = mix(color.rgb, core.rgb, a_core);
	ALBEDO = col * glow;
	ALPHA = clamp((a_body * 0.7 + a_core) * tip * fade, 0.0, 1.0);
}
