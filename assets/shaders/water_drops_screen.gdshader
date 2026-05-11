shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float drop_density : hint_range(2.0, 24.0) = 10.0;
uniform float drop_size : hint_range(0.01, 0.12) = 0.04;
uniform float refraction_strength : hint_range(0.0, 0.08) = 0.026;

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

vec2 hash22(vec2 p) {
	float n = hash12(p);
	return vec2(n, hash12(p + n + 19.19));
}

void fragment() {
	vec2 aspect_uv = UV;
	vec2 screen_size = max(vec2(textureSize(screen_texture, 0)), vec2(1.0));
	aspect_uv.x *= screen_size.x / screen_size.y;
	vec2 grid_uv = aspect_uv * drop_density;
	vec2 cell = floor(grid_uv);
	vec2 local = fract(grid_uv);
	vec4 result = texture(screen_texture, SCREEN_UV);
	float mask = 0.0;
	vec2 offset = vec2(0.0);
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 neighbor = cell + vec2(float(x), float(y));
			vec2 rnd = hash22(neighbor);
			float life = fract(TIME * (0.22 + rnd.y * 0.42) + rnd.x);
			vec2 center = vec2(float(x), float(y)) + rnd - vec2(0.0, life * 0.55);
			vec2 to_drop = local - center;
			to_drop.y *= 1.55;
			float radius = drop_size * drop_density * mix(0.7, 1.35, rnd.x);
			float drop = smoothstep(radius, radius * 0.35, length(to_drop));
			drop *= smoothstep(1.0, 0.55, life);
			mask = max(mask, drop);
			offset += normalize(to_drop + vec2(0.001)) * drop;
		}
	}
	offset *= refraction_strength * intensity;
	result = texture(screen_texture, SCREEN_UV - offset);
	result.rgb = mix(result.rgb, vec3(0.82, 0.94, 1.0), mask * intensity * 0.18);
	COLOR = result;
}
