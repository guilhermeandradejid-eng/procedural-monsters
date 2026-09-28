// Ribbon trail. UV.x runs head (0) to tail (1), UV.y across the ribbon.
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

#include "res://shaders/fx/noise.gdshaderinc"

uniform vec4 head_color : source_color = vec4(1.0);
uniform vec4 tail_color : source_color = vec4(1.0, 0.4, 0.1, 1.0);
uniform float glow = 2.5;
uniform float noise_scale = 3.0;
uniform float scroll = 2.0;
uniform float jagged = 0.0;
uniform float softness = 0.45;

void fragment() {
	float along = UV.x;
	float across = abs(UV.y - 0.5) * 2.0;
	float n = vnoise2(vec2(along * noise_scale * 5.0 - TIME * scroll * 4.0, UV.y * 2.5 + TIME));
	float jag = jagged * (vnoise2(vec2(along * 30.0, TIME * 20.0)) - 0.5) * 0.9;
	float edge = 1.0 - smoothstep(softness + n * 0.35, 1.0, abs(across + jag));
	float fade = 1.0 - along;
	fade = fade * fade;
	vec3 col = mix(head_color.rgb, tail_color.rgb, smoothstep(0.0, 0.8, along));
	float a = clamp(edge * fade * COLOR.a, 0.0, 1.0);
	ALBEDO = col * glow;
	ALPHA = a;
}
