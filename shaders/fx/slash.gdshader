// Quill slash: a dry-brush ink stroke swept along an arc, rimmed with the
// knight's colour. UV.x runs along the arc, UV.y from inner to outer edge.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

#include "res://shaders/fx/noise.gdshaderinc"

uniform vec4 ink : source_color = vec4(0.11, 0.08, 0.07, 1.0);
uniform vec4 rim : source_color = vec4(1.0, 0.55, 0.2, 1.0);
instance uniform float progress = 0.0;
instance uniform float fade = 1.0;
instance uniform float reverse = 0.0;
instance uniform float seed = 0.0;

void fragment() {
	float x = mix(UV.x, 1.0 - UV.x, reverse);
	float y = UV.y;
	float head = progress * 1.25;
	float body = step(x, head) * smoothstep(head - 1.0, head - 0.2, x);
	float width = sin(clamp(x, 0.0, 1.0) * 3.14159);
	float n = vnoise2(vec2(x * 22.0 + seed, y * 6.0));
	float bristles = step(0.25, vnoise2(vec2(y * 40.0 + seed * 3.0, x * 2.0)));
	float edge = abs(y - 0.5) * 2.0;
	float stroke = (1.0 - smoothstep(width * 0.75, width * 0.95 + n * 0.1, edge));
	stroke *= mix(1.0, bristles, smoothstep(0.35, 0.9, edge) * 0.8);
	float rim_mask = smoothstep(0.55, 0.85, y) * stroke;
	vec3 col = mix(ink.rgb, rim.rgb * 1.8, rim_mask * 0.9);
	ALBEDO = col;
	ALPHA = clamp(stroke * body * fade, 0.0, 1.0);
}
