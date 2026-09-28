// Parchment for UI panels: fibres, foxing, stains, darkened margins and a
// deckled (torn) edge. `size` must be the control size in pixels.
shader_type canvas_item;

#include "res://shaders/fx/noise.gdshaderinc"

uniform vec4 paper : source_color = vec4(0.941, 0.874, 0.722, 1.0);
uniform vec4 paper_dark : source_color = vec4(0.847, 0.741, 0.541, 1.0);
uniform vec4 edge : source_color = vec4(0.42, 0.29, 0.18, 1.0);
uniform vec2 size = vec2(400.0, 300.0);
uniform float seed = 0.0;
uniform float deckle = 9.0;
uniform float burn = 0.45;
uniform float fold = 0.0;

void fragment() {
	vec2 px = UV * size;
	vec2 e = min(UV, vec2(1.0) - UV) * size;
	float ed = min(e.x, e.y);
	float tear = fbm2(px * 0.045 + seed * 7.0) * deckle + vnoise2(px * 0.3 + seed) * deckle * 0.25;
	float a = smoothstep(tear - 0.8, tear + 0.8, ed);
	if (a <= 0.001) {
		discard;
	}
	float stains = fbm2(px * 0.0045 + seed * 3.1);
	float blotch = fbm2(px * 0.012 + seed * 1.7);
	float fibers = vnoise2(px * vec2(0.9, 0.07) + seed) * 0.5 + vnoise2(px * vec2(0.06, 0.8)) * 0.5;
	vec3 col = mix(paper.rgb, paper_dark.rgb, smoothstep(0.38, 0.85, stains) * 0.7);
	col = mix(col, paper_dark.rgb * 0.94, smoothstep(0.64, 0.82, blotch) * 0.3);
	col *= 0.965 + fibers * 0.06;
	vec2 fc = px * 0.12;
	float fox = step(0.982, h21(floor(fc) + seed)) * (1.0 - smoothstep(0.05, 0.4, length(fract(fc) - 0.5)));
	col = mix(col, vec3(0.56, 0.37, 0.2), fox * 0.3);
	float margin = 1.0 - smoothstep(0.0, 36.0, ed - tear);
	col = mix(col, edge.rgb, margin * margin * burn);
	col = mix(col, edge.rgb * 0.7, (1.0 - smoothstep(0.0, 2.5, ed - tear)) * 0.7);
	if (fold > 0.0) {
		float f = abs(UV.x - 0.5);
		col *= 1.0 - fold * (1.0 - smoothstep(0.0, 0.06, f)) * 0.35;
		col *= 1.0 + fold * smoothstep(0.06, 0.2, f) * (1.0 - smoothstep(0.2, 0.5, f)) * 0.05;
	}
	COLOR = vec4(col, a) * COLOR;
}
