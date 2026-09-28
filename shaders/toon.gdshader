// Painted-toy toon shading for characters and props.
// Two soft bands, warm-violet shadow tint instead of grey, a gentle rim and
// metallic "gold leaf" sheen. Per-instance flash/tint/dissolve drive the juice.
shader_type spatial;
render_mode cull_back, depth_draw_opaque;

#include "res://shaders/fx/noise.gdshaderinc"

uniform vec4 albedo : source_color = vec4(1.0);
uniform vec4 shade_color : source_color = vec4(0.42, 0.3, 0.42, 1.0);
uniform float shade_strength : hint_range(0.0, 1.0) = 0.62;
uniform float band_softness = 0.06;
uniform float band_bias = 0.0;
uniform float rim_strength = 0.28;
uniform vec4 rim_color : source_color = vec4(1.0, 0.86, 0.62, 1.0);
uniform float sheen = 0.0;
uniform vec4 emission_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_strength = 0.0;
uniform float wobble_paper = 0.0;

instance uniform float flash = 0.0;
instance uniform vec4 flash_color : source_color = vec4(1.0);
instance uniform vec4 tint : source_color = vec4(0.0);
instance uniform float dissolve = 0.0;
instance uniform vec4 dissolve_color : source_color = vec4(1.0, 0.55, 0.15, 1.0);

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 base = albedo.rgb;
	base = mix(base, tint.rgb, clamp(tint.a, 0.0, 1.0));
	if (wobble_paper > 0.0) {
		float n = vnoise2(world_pos.xz * 6.0 + world_pos.y * 3.0);
		base *= 1.0 - wobble_paper * (n - 0.5);
	}
	ALBEDO = base;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	METALLIC = 0.0;
	float ndv = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float rim = pow(1.0 - ndv, 3.0) * rim_strength;
	vec3 emis = emission_color.rgb * emission_strength;
	emis += rim_color.rgb * rim * base;
	emis += flash_color.rgb * flash * 1.6;
	if (dissolve > 0.0) {
		float n = fbm2(world_pos.xz * 3.0 + world_pos.y * 2.0);
		float cut = dissolve * 1.15 - 0.05;
		if (n < cut) {
			discard;
		}
		float edge = 1.0 - smoothstep(0.0, 0.08, n - cut);
		emis += dissolve_color.rgb * edge * 4.0;
	}
	EMISSION = emis;
}

void light() {
	float ndl = dot(NORMAL, LIGHT) + band_bias;
	float lit = smoothstep(0.0, band_softness, ndl);
	float high = smoothstep(0.55, 0.55 + band_softness, ndl) * 0.18;
	float amount = lit * ATTENUATION;
	vec3 shadow_tint = mix(vec3(1.0), shade_color.rgb, shade_strength);
	vec3 band = mix(shadow_tint * 0.35, vec3(1.0 + high), amount);
	DIFFUSE_LIGHT += band * LIGHT_COLOR / PI;
	if (sheen > 0.0) {
		vec3 h = normalize(LIGHT + VIEW);
		float spec = smoothstep(0.9, 0.93, dot(NORMAL, h)) * sheen;
		SPECULAR_LIGHT += spec * LIGHT_COLOR * ATTENUATION * 0.5;
	}
}
