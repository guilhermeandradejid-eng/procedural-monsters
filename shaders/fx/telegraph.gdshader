// Attack warning on the floor. shape: 0 circle, 1 cone (sector), 2 line.
// `charge` fills from the centre (circle/cone) or from the start (line).
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec4 color : source_color = vec4(1.0, 0.33, 0.2, 1.0);
uniform int shape = 0;
instance uniform float charge = 0.0;
instance uniform float half_angle = 0.6;
instance uniform float fade = 1.0;

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float inside = 0.0;
	float edge = 0.0;
	float fill = 0.0;
	float stripes = 0.5 + 0.5 * sin((uv.x + uv.y) * 22.0 - TIME * 6.0);
	if (shape == 0) {
		float d = length(uv);
		inside = 1.0 - step(1.0, d);
		edge = smoothstep(0.86, 0.94, d) * inside;
		fill = (1.0 - step(charge, d)) * inside;
	} else if (shape == 1) {
		float d = length(uv);
		float ang = abs(atan(uv.x, -uv.y));
		inside = (1.0 - step(1.0, d)) * (1.0 - step(half_angle, ang));
		edge = max(smoothstep(0.88, 0.95, d), smoothstep(half_angle - 0.06, half_angle, ang)) * inside;
		fill = (1.0 - step(charge, d)) * inside;
	} else {
		float along = 1.0 - (uv.y * 0.5 + 0.5);
		inside = 1.0;
		edge = smoothstep(0.8, 0.95, abs(uv.x));
		fill = 1.0 - step(charge, along);
	}
	float a = inside * (0.16 + stripes * 0.07) + edge * 0.85 + fill * 0.32;
	ALBEDO = color.rgb * (1.0 + fill * 0.6);
	ALPHA = clamp(a * fade, 0.0, 1.0);
}
