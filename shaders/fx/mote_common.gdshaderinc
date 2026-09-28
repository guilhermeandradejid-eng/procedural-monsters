// Particle sprite shapes, all procedural (no textures).
// 0 soft glow · 1 shard · 2 spark · 3 bubble · 4 twinkle · 5 flame lick · 6 ink blot · 7 leaf/petal

#include "res://shaders/fx/noise.gdshaderinc"

void billboard_particle(inout mat4 modelview, mat4 inv_view, mat4 view, mat4 model, vec4 custom) {
	mat4 mat_world = mat4(normalize(inv_view[0]), normalize(inv_view[1]), normalize(inv_view[2]), model[3]);
	mat_world = mat_world * mat4(vec4(cos(custom.x), -sin(custom.x), 0.0, 0.0), vec4(sin(custom.x), cos(custom.x), 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	modelview = view * mat_world;
	modelview = modelview * mat4(vec4(length(model[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(model[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(model[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
}

float mote_alpha(int shape, vec2 uv, float seed) {
	float d = length(uv);
	if (shape == 0) {
		return pow(1.0 - smoothstep(0.0, 1.0, d), 1.6);
	} else if (shape == 1) {
		float k = abs(uv.x) * 1.6 + abs(uv.y) * 0.75;
		return 1.0 - smoothstep(0.75, 1.0, k);
	} else if (shape == 2) {
		return (1.0 - smoothstep(0.0, 0.22, abs(uv.x))) * (1.0 - smoothstep(0.2, 1.0, abs(uv.y)));
	} else if (shape == 3) {
		return smoothstep(0.55, 0.72, d) * (1.0 - smoothstep(0.78, 0.95, d)) + 0.12 * (1.0 - d) + (1.0 - smoothstep(0.0, 0.2, length(uv - vec2(-0.3, -0.3)))) * 0.8;
	} else if (shape == 4) {
		float s = max((1.0 - smoothstep(0.0, 0.1, abs(uv.x))) * (1.0 - abs(uv.y)), (1.0 - smoothstep(0.0, 0.1, abs(uv.y))) * (1.0 - abs(uv.x)));
		return clamp(s + (1.0 - smoothstep(0.0, 0.3, d)), 0.0, 1.0);
	} else if (shape == 5) {
		vec2 p = uv;
		p.y += 0.25;
		float w = 1.3 + p.y * 1.1;
		float f = length(vec2(p.x * w, p.y * 0.8));
		return 1.0 - smoothstep(0.45, 0.85, f);
	} else if (shape == 6) {
		float n = vnoise2(uv * 3.0 + seed * 17.0);
		return 1.0 - smoothstep(0.55, 0.75, d + (n - 0.5) * 0.5);
	} else {
		vec2 p = uv;
		float f = abs(p.x) * 1.9 + p.y * p.y * 0.9;
		return (1.0 - smoothstep(0.7, 0.95, f)) * (1.0 - smoothstep(0.0, 0.06, abs(p.x)) * 0.35);
	}
}
