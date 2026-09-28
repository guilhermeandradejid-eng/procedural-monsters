// Elemental ground zone (Linger, Steam, Miasma, Sap, Vortex floor).
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

#include "res://shaders/fx/noise.gdshaderinc"

uniform vec4 color : source_color = vec4(1.0, 0.5, 0.1, 1.0);
uniform vec4 dark : source_color = vec4(0.3, 0.05, 0.0, 1.0);
uniform float glow = 1.6;
uniform float swirl = 0.0;
instance uniform float fade = 1.0;
instance uniform float seed = 0.0;

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float d = length(uv);
	float ang = atan(uv.y, uv.x);
	vec2 p = vec2(ang * 1.5 + swirl * (1.0 - d) * 4.0 + TIME * swirl, d * 3.0 - TIME * 0.6);
	float n = fbm2(p + seed * 13.0);
	float edge = smoothstep(0.78, 0.96, d) * (1.0 - smoothstep(0.96, 1.0, d));
	float body = (1.0 - smoothstep(0.5, 1.0, d)) * smoothstep(0.35, 0.75, n);
	vec3 col = mix(dark.rgb, color.rgb, n);
	ALBEDO = col * glow;
	ALPHA = clamp((body * 0.55 + edge * 0.9) * fade, 0.0, 1.0);
}
