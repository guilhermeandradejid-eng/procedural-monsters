// Page-turn transition: the captured old frame is a page lifted from its
// right edge and folded over to the left, revealing the next page beneath.
shader_type canvas_item;

uniform sampler2D old_frame : filter_linear;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 paper_back : source_color = vec4(0.93, 0.87, 0.74, 1.0);
uniform vec4 ink : source_color = vec4(0.11, 0.08, 0.07, 1.0);

void fragment() {
	vec2 uv = UV;
	float slant = (uv.y - 0.5) * 0.22;
	float fold = 1.08 - progress * 1.5 + slant;
	float curl = 0.08 + 0.16 * sin(clamp(progress, 0.0, 1.0) * 3.14159);
	if (uv.x > fold) {
		// Revealed next page, darkened by the shadow of the lifted sheet.
		float sh = 1.0 - smoothstep(0.0, 0.18, uv.x - fold);
		COLOR = vec4(0.0, 0.0, 0.0, sh * 0.45 * (1.0 - progress * 0.5));
	} else if (uv.x > fold - curl) {
		// The back of the turning page, cylindrically shaded.
		float t = (fold - uv.x) / curl;
		float shade = mix(1.0, 0.72, t * t) * (0.92 + 0.08 * cos(t * 3.14159));
		vec3 c = paper_back.rgb * shade;
		// Faint mirrored show-through of the old frame's ink.
		vec2 mirror = vec2(fold + (fold - uv.x) * 0.9, uv.y);
		vec3 through = texture(old_frame, clamp(mirror, 0.0, 1.0)).rgb;
		c = mix(c, c * (0.75 + 0.25 * through), 0.35);
		float edge = smoothstep(0.0, 0.004, uv.x - (fold - curl));
		COLOR = vec4(mix(ink.rgb, c, edge), 1.0);
	} else {
		vec3 c = texture(old_frame, uv).rgb;
		float near = 1.0 - smoothstep(0.0, 0.12, (fold - curl) - uv.x);
		COLOR = vec4(c * (1.0 - near * 0.35), 1.0);
	}
}
