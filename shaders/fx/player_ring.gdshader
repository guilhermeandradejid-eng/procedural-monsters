// Ground marker under each knight: a dashed ring in the player's colour with
// an ink arrowhead that shows where they are aiming. Readable in co-op chaos.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec4 color : source_color = vec4(1.0, 0.54, 0.17, 1.0);
uniform vec4 ink : source_color = vec4(0.11, 0.08, 0.07, 1.0);
instance uniform float aim_angle = 0.0;
instance uniform float strength = 1.0;
instance uniform float revive = 0.0;

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float d = length(uv);
	float a = atan(uv.y, uv.x);
	float ring = smoothstep(0.6, 0.64, d) * (1.0 - smoothstep(0.7, 0.74, d));
	float dash = step(0.35, fract(a / 6.2831 * 18.0 + TIME * 0.15));
	float da = abs(atan(sin(a - aim_angle), cos(a - aim_angle)));
	float tip = 1.0 - smoothstep(0.0, 0.03, da * 1.4 + (d - 0.95) * 1.1 - 0.02);
	float arrow = tip * step(0.74, d) * (1.0 - step(0.99, d));
	float rev = smoothstep(0.78, 0.8, d) * (1.0 - smoothstep(0.86, 0.88, d)) * step(fract((a + 3.14159) / 6.2831 + 0.25), revive);
	vec3 col = mix(color.rgb, ink.rgb, arrow * 0.35);
	ALBEDO = mix(col, vec3(1.0, 0.95, 0.8), rev);
	ALPHA = clamp((ring * dash * 0.55 + arrow * 0.95) * strength + rev, 0.0, 1.0);
}
