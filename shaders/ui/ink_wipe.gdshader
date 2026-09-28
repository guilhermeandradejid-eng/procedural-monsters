// Ink wipe: a blot of ink spreads over the screen with bleeding edges.
shader_type canvas_item;

#include "res://shaders/fx/noise.gdshaderinc"

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 ink : source_color = vec4(0.07, 0.05, 0.05, 1.0);
uniform vec2 aspect = vec2(1.78, 1.0);

void fragment() {
	vec2 p = (UV - 0.5) * aspect;
	float d = length(p);
	float n = fbm2(p * 3.0 + vec2(progress * 0.7)) * 0.35;
	float r = progress * 1.35;
	float a = 1.0 - smoothstep(r - 0.02, r + 0.02, d + n - 0.1);
	COLOR = vec4(ink.rgb, a);
}
