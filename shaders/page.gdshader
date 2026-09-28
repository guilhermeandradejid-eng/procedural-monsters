// The floor of every room is a page of the Grimoire: aged parchment with
// fibres, foxing, stains, faded lines of script, marginal rules and a
// deckled edge. Lit with the same toon ramp as the characters.
shader_type spatial;
render_mode cull_back, depth_draw_opaque;

#include "res://shaders/fx/noise.gdshaderinc"

uniform vec4 paper : source_color = vec4(0.937, 0.886, 0.769, 1.0);
uniform vec4 paper_dark : source_color = vec4(0.851, 0.769, 0.604, 1.0);
uniform vec4 ink : source_color = vec4(0.11, 0.08, 0.07, 1.0);
uniform vec4 rubric : source_color = vec4(0.62, 0.17, 0.15, 1.0);
uniform vec4 shade_color : source_color = vec4(0.45, 0.32, 0.4, 1.0);
uniform vec2 page_size = vec2(30.0, 22.0);
uniform float writing = 0.55;
uniform float seed = 0.0;
uniform float edge_burn = 0.35;
uniform float deckle = 0.35;

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float text_mask(vec2 p, vec2 uv) {
	float line_h = 0.62;
	float row = floor(p.y / line_h);
	float fy = fract(p.y / line_h);
	float band = smoothstep(0.3, 0.4, fy) * (1.0 - smoothstep(0.58, 0.7, fy));
	float words = step(0.38, vnoise2(vec2(p.x * 0.9, row * 7.31 + seed)));
	float letters = smoothstep(0.45, 0.6, vnoise2(vec2(p.x * 7.0, row * 3.17 + fy * 3.0 + seed)));
	float ascenders = step(0.93, h21(vec2(floor(p.x * 3.5), row + seed))) * smoothstep(0.1, 0.35, fy) * (1.0 - smoothstep(0.35, 0.4, fy));
	float para = step(0.18, fract(row / 9.0 + seed * 0.1));
	return clamp((band * words * letters + ascenders * words * 0.8) * para, 0.0, 1.0);
}

void fragment() {
	vec2 uv = UV;
	vec2 p = uv * page_size;
	vec2 e = min(uv, 1.0 - uv) * page_size;
	float edge_dist = min(e.x, e.y);
	float deck = fbm2(p * 1.7 + seed * 4.0) * deckle;
	if (edge_dist < deck * 0.5) {
		discard;
	}
	float stains = fbm2(p * 0.09 + seed);
	float blotch = fbm2(p * 0.35 + seed * 2.0);
	float fibers = vnoise2(p * vec2(11.0, 1.4) + seed * 3.0) * 0.55 + vnoise2(p * vec2(1.2, 13.0)) * 0.45;
	vec3 col = mix(paper.rgb, paper_dark.rgb, smoothstep(0.35, 0.85, stains) * 0.75);
	col = mix(col, paper_dark.rgb * 0.92, smoothstep(0.62, 0.8, blotch) * 0.35);
	col *= 0.965 + fibers * 0.06;
	vec2 fc = p * 2.2;
	float fox = step(0.975, h21(floor(fc) + seed)) * (1.0 - smoothstep(0.05, 0.35, length(fract(fc) - 0.5)));
	col = mix(col, vec3(0.55, 0.36, 0.2), fox * 0.35);
	// Script lines inside the text block, a rubric (red) initial and ruled margins.
	float inside = step(2.2, e.x) * step(1.6, e.y);
	float text = text_mask(p, uv) * inside * writing;
	col = mix(col, ink.rgb, text * 0.28);
	float margin_l = 1.0 - smoothstep(0.0, 0.035, abs(p.x - 1.7));
	float margin_r = 1.0 - smoothstep(0.0, 0.035, abs(p.x - (page_size.x - 1.7)));
	col = mix(col, rubric.rgb, (margin_l + margin_r) * 0.22 * step(1.2, e.y));
	vec2 ic = vec2(3.2, page_size.y - 3.2);
	float initial = (1.0 - smoothstep(0.9, 0.95, length(p - ic))) * smoothstep(0.7, 0.75, length(p - ic));
	col = mix(col, rubric.rgb, initial * 0.35 * writing);
	float burn = 1.0 - smoothstep(0.0, 1.8, edge_dist - deck * 0.5);
	col = mix(col, paper_dark.rgb * 0.55, burn * edge_burn);
	col = mix(col, vec3(0.3, 0.2, 0.14), (1.0 - smoothstep(0.0, 0.25, edge_dist - deck * 0.5)) * 0.6);
	ALBEDO = col;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float lit = smoothstep(0.0, 0.08, ndl) * ATTENUATION;
	vec3 shadow_tint = mix(vec3(1.0), shade_color.rgb, 0.7);
	vec3 band = mix(shadow_tint * 0.42, vec3(1.0), lit);
	DIFFUSE_LIGHT += band * LIGHT_COLOR / PI;
}
