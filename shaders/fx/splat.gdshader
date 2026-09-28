// Ink splat that stays on the page after hits and deaths.
// Each instance gets its own shape from `seed`: blob, satellite droplets, runs.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

#include "res://shaders/fx/noise.gdshaderinc"

uniform vec4 ink : source_color = vec4(0.11, 0.08, 0.07, 1.0);
instance uniform vec4 tint : source_color = vec4(0.11, 0.08, 0.07, 1.0);
instance uniform float seed = 0.0;
instance uniform float fade = 1.0;
instance uniform float grow = 1.0;

void fragment() {
	vec2 uv = (UV * 2.0 - 1.0) / max(grow, 0.05);
	float d = length(uv);
	float ang = atan(uv.y, uv.x);
	float lobes = vnoise2(vec2(ang * 2.2 + seed * 7.0, seed)) * 0.35 + vnoise2(vec2(ang * 6.0, seed * 3.1)) * 0.12;
	float blob = 1.0 - smoothstep(0.42 + lobes, 0.47 + lobes, d);
	float drops = 0.0;
	for (int i = 0; i < 6; i++) {
		float fi = float(i);
		float a = h21(vec2(seed, fi)) * 6.2831;
		float r = 0.62 + h21(vec2(fi, seed + 3.0)) * 0.3;
		vec2 c = vec2(cos(a), sin(a)) * r;
		float s = 0.03 + h21(vec2(seed + fi, 9.0)) * 0.06;
		drops = max(drops, 1.0 - smoothstep(s, s + 0.02, length(uv - c)));
	}
	float a = max(blob, drops);
	float rim = smoothstep(0.3, 0.47 + lobes, d) * blob;
	vec3 col = mix(tint.rgb, tint.rgb * 0.55, rim);
	ALBEDO = col;
	ALPHA = a * fade * 0.92;
}
