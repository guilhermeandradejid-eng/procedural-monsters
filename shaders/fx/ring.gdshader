// Expanding shock ring on the ground (novas, impacts, ricochets).
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

#include "res://shaders/fx/noise.gdshaderinc"

uniform vec4 color : source_color = vec4(1.0, 0.6, 0.2, 1.0);
uniform vec4 core : source_color = vec4(1.0);
uniform float glow = 3.0;
instance uniform float progress = 0.0;
instance uniform float thickness = 0.14;
instance uniform float seed = 0.0;

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float d = length(uv);
	float r = progress * 0.92;
	float w = thickness * (1.0 - progress * 0.55);
	float ang = atan(uv.y, uv.x);
	float n = vnoise2(vec2(ang * 3.0 + seed * 10.0, progress * 4.0 + seed));
	float ring = 1.0 - smoothstep(0.0, w * (0.7 + n * 0.8), abs(d - r));
	float inner = (1.0 - smoothstep(0.0, r + 0.001, d)) * 0.18 * (1.0 - progress);
	float fade = 1.0 - smoothstep(0.55, 1.0, progress);
	vec3 col = mix(color.rgb, core.rgb, ring * ring * 0.8);
	ALBEDO = col * glow;
	ALPHA = clamp((ring + inner) * fade, 0.0, 1.0);
}
