// World-only screen treatment (sits below the HUD): printed-paper grain,
// vignette, hurt pulse with chromatic fringing, perfect-dodge tint and
// the low-health heartbeat.
shader_type canvas_item;

#include "res://shaders/fx/noise.gdshaderinc"

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float hurt = 0.0;
uniform float perfect = 0.0;
uniform float low_hp = 0.0;
uniform float grain = 0.045;
uniform float vignette = 0.55;
uniform float time_s = 0.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 c = uv - 0.5;
	float d = length(c * vec2(1.4, 1.0));
	float ab = hurt * 0.006 + perfect * 0.002;
	vec3 col;
	col.r = texture(screen_tex, uv + c * ab).r;
	col.g = texture(screen_tex, uv).g;
	col.b = texture(screen_tex, uv - c * ab).b;
	if (perfect > 0.0) {
		float l = dot(col, vec3(0.299, 0.587, 0.114));
		col = mix(col, vec3(l) * vec3(0.85, 0.95, 1.12), perfect * 0.55);
	}
	float n = h21(uv * 900.0 + fract(time_s * 13.0) * 50.0) - 0.5;
	float paper = fbm2(uv * vec2(6.0, 3.4)) - 0.5;
	col *= 1.0 + n * grain + paper * grain * 0.8;
	float v = smoothstep(0.35, 1.05, d) * vignette;
	col *= 1.0 - v * 0.6;
	col = mix(col, col * vec3(0.52, 0.34, 0.26), v * 0.35);
	float beat = 0.5 + 0.5 * sin(time_s * 7.5);
	float red = hurt * smoothstep(0.25, 0.95, d) + low_hp * smoothstep(0.45, 1.0, d) * (0.35 + 0.3 * beat);
	col = mix(col, vec3(0.55, 0.06, 0.04), clamp(red, 0.0, 0.75));
	COLOR = vec4(col, 1.0);
}
