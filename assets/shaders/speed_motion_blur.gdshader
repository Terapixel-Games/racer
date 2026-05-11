shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float radial_strength : hint_range(0.0, 0.035) = 0.018;
uniform float streak_strength : hint_range(0.0, 0.04) = 0.024;
uniform float edge_bias : hint_range(0.0, 1.0) = 0.72;
uniform vec4 speed_tint : source_color = vec4(0.42, 0.86, 1.0, 0.055);
uniform float center_clear_radius : hint_range(0.0, 0.6) = 0.18;
uniform float center_clear_softness : hint_range(0.01, 0.6) = 0.28;
uniform float sample_guard : hint_range(0.0, 4.0) = 1.0;
uniform float edge_vignette : hint_range(0.0, 1.0) = 0.16;

vec4 sample_screen(vec2 uv_screen) {
	vec2 guard = (1.0 / max(vec2(textureSize(screen_texture, 0)), vec2(1.0))) * sample_guard;
	return texture(screen_texture, clamp(uv_screen, guard, vec2(1.0) - guard));
}

void fragment() {
	vec2 center = vec2(0.5);
	vec2 from_center = SCREEN_UV - center;
	float dist = length(from_center);
	float edge_mask = smoothstep(0.12, 0.78, dist);
	float clear_mask = smoothstep(center_clear_radius, center_clear_radius + center_clear_softness, dist);
	float active = clamp(intensity, 0.0, 1.0);
	vec2 radial = normalize(from_center + vec2(0.0001)) * radial_strength * active;

	vec4 radial_color = sample_screen(SCREEN_UV) * 0.46;
	radial_color += sample_screen(SCREEN_UV - radial * 0.55) * 0.24;
	radial_color += sample_screen(SCREEN_UV - radial * 1.2) * 0.18;
	radial_color += sample_screen(SCREEN_UV - radial * 2.0) * 0.12;

	vec2 side_dir = normalize(vec2(from_center.x, from_center.y * 0.32) + vec2(0.0001));
	vec2 streak = side_dir * streak_strength * active * edge_mask;
	vec4 streak_color = sample_screen(SCREEN_UV - streak) * 0.34;
	streak_color += sample_screen(SCREEN_UV - streak * 2.0) * 0.23;
	streak_color += sample_screen(SCREEN_UV + streak * 0.85) * 0.18;
	streak_color += sample_screen(SCREEN_UV) * 0.25;

	vec4 blended = mix(radial_color, streak_color, edge_mask * edge_bias);
	vec4 base = sample_screen(SCREEN_UV);
	float blend_amount = clamp(active * (0.52 + edge_mask * 0.38) * clear_mask, 0.0, 1.0);
	vec4 tinted = blended + speed_tint * speed_tint.a * active * edge_mask;
	tinted.rgb *= 1.0 - edge_mask * edge_vignette * active;
	COLOR = mix(base, tinted, blend_amount);
}
