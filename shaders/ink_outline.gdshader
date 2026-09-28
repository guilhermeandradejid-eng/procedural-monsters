// Screen-space ink outline: edges from depth and normal discontinuities.
// Lives on a full-screen quad parented to the camera. Only opaque geometry
// writes depth/normals, so spell effects stay clean while characters and the
// pop-up scenery get the hand-inked contour.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, depth_test_disabled, cull_disabled, fog_disabled, shadows_disabled;

uniform sampler2D depth_tex : hint_depth_texture, filter_nearest, repeat_disable;
uniform sampler2D normal_tex : hint_normal_roughness_texture, filter_nearest, repeat_disable;
uniform vec4 line_color : source_color = vec4(0.11, 0.08, 0.07, 1.0);
uniform float thickness = 1.6;
uniform float depth_threshold = 0.012;
uniform float normal_threshold = 0.45;
uniform float max_distance = 90.0;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

float lin_depth(vec2 uv, mat4 inv_proj) {
	float d = texture(depth_tex, uv).r;
	vec4 v = inv_proj * vec4(uv * 2.0 - 1.0, d, 1.0);
	return -v.z / v.w;
}

vec3 nrm(vec2 uv) {
	return texture(normal_tex, uv).xyz * 2.0 - 1.0;
}

void fragment() {
	vec2 px = thickness / VIEWPORT_SIZE;
	float d0 = lin_depth(SCREEN_UV, INV_PROJECTION_MATRIX);
	if (d0 > max_distance) {
		discard;
	}
	vec3 n0 = nrm(SCREEN_UV);
	float dd = 0.0;
	float nd = 0.0;
	vec2 offs[4] = vec2[](vec2(px.x, 0.0), vec2(-px.x, 0.0), vec2(0.0, px.y), vec2(0.0, -px.y));
	for (int i = 0; i < 4; i++) {
		vec2 uv = SCREEN_UV + offs[i];
		float d = lin_depth(uv, INV_PROJECTION_MATRIX);
		dd = max(dd, d0 - d);
		nd = max(nd, 1.0 - dot(n0, nrm(uv)));
	}
	float edge_d = smoothstep(depth_threshold * d0, depth_threshold * d0 * 1.8, dd);
	float edge_n = smoothstep(normal_threshold, normal_threshold + 0.2, nd);
	float edge = max(edge_d, edge_n * 0.85);
	if (edge < 0.02) {
		discard;
	}
	ALBEDO = line_color.rgb;
	ALPHA = edge * line_color.a;
}
