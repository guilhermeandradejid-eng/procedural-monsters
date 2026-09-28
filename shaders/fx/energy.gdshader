// Spell body: a boiling, fresnel-rimmed energy core. Colours and motion come
// from the spell's procedural visual profile (SpellVisual).
shader_type spatial;
render_mode unshaded, cull_back, depth_draw_opaque, shadows_disabled;

#include "res://shaders/fx/noise.gdshaderinc"

uniform vec4 core_color : source_color = vec4(1.0);
uniform vec4 main_color : source_color = vec4(1.0, 0.5, 0.1, 1.0);
uniform vec4 dark_color : source_color = vec4(0.4, 0.05, 0.0, 1.0);
uniform vec4 rim_color : source_color = vec4(1.0, 0.8, 0.4, 1.0);
uniform float glow = 3.0;
uniform float noise_scale = 3.0;
uniform float noise_speed = 1.0;
uniform float pulse_hz = 3.0;
uniform float wobble = 0.2;
uniform float dark_core = 0.0;
instance uniform float fade = 1.0;
instance uniform float charge = 0.0;

varying vec3 obj_pos;

void vertex() {
	obj_pos = VERTEX;
	float n = vnoise3(VERTEX * 4.0 + vec3(TIME * 3.0));
	VERTEX += NORMAL * (n - 0.5) * wobble * 0.3;
	VERTEX *= 1.0 + 0.07 * sin(TIME * pulse_hz * 6.2831) + charge * 0.25 * sin(TIME * 40.0);
}

void fragment() {
	float ndv = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float fres = pow(1.0 - ndv, 2.2);
	float n = fbm3(obj_pos * noise_scale + vec3(0.0, -TIME * noise_speed * 2.0, TIME * noise_speed));
	float heat = clamp(ndv + (n - 0.5) * 0.9, 0.0, 1.0);
	vec3 col = mix(dark_color.rgb, main_color.rgb, smoothstep(0.05, 0.5, heat));
	col = mix(col, core_color.rgb, smoothstep(0.62, 0.95, heat));
	col += rim_color.rgb * fres * 1.3;
	if (dark_core > 0.5) {
		float inner = smoothstep(0.25, 0.75, ndv + (n - 0.5) * 0.4);
		col = mix(rim_color.rgb * 1.4 + main_color.rgb * 0.6, dark_color.rgb * 0.15, inner);
	}
	ALBEDO = col * glow * (1.0 + charge * 1.5);
	ALPHA = clamp(fade, 0.0, 1.0);
	ALPHA_SCISSOR_THRESHOLD = 0.02;
}
