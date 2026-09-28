// Magic circle drawn from a spell's procedural sigil texture.
// The same sigil appears in the grimoire, so casting "signs" the page on the floor.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

uniform sampler2D sigil : source_color, filter_linear_mipmap;
uniform vec4 color : source_color = vec4(1.0, 0.6, 0.2, 1.0);
uniform vec4 core : source_color = vec4(1.0);
uniform float glow = 2.6;
uniform float spin = 0.6;
instance uniform float reveal = 1.0;
instance uniform float fade = 1.0;
instance uniform float spin_offset = 0.0;

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float ang0 = atan(uv.y, uv.x);
	float t = TIME * spin + spin_offset;
	mat2 rot = mat2(vec2(cos(t), -sin(t)), vec2(sin(t), cos(t)));
	vec2 ruv = rot * uv * 0.5 + 0.5;
	float s = texture(sigil, ruv).a;
	// Angular reveal: the circle is "drawn" clockwise.
	float a01 = fract((ang0 + 3.14159) / 6.28318 + 0.25);
	float drawn = step(a01, reveal) + step(0.999, reveal);
	float glowline = s * clamp(drawn, 0.0, 1.0);
	vec3 col = mix(color.rgb, core.rgb, smoothstep(0.6, 1.0, s));
	ALBEDO = col * glow;
	ALPHA = clamp(glowline * fade, 0.0, 1.0);
}
