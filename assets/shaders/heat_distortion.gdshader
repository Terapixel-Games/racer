shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float strength : hint_range(0.0, 0.04) = 0.012;
uniform float speed : hint_range(0.0, 12.0) = 4.5;
uniform float ripple_scale : hint_range(1.0, 80.0) = 26.0;
uniform float vertical_stretch : hint_range(0.1, 6.0) = 2.8;
uniform vec4 heat_tint : source_color = vec4(1.0, 0.72, 0.34, 0.05);
uniform float center_clear_radius : hint_range(0.0, 0.7) = 0.14;
uniform float edge_fade : hint_range(0.0, 1.0) = 0.24;
uniform float sample_guard : hint_range(0.0, 4.0) = 1.0;

float heat_noise(vec2 p) {
	return sin(p.x * 1.7 + TIME * speed) * 0.5
		+ sin((p.y * 2.1 - p.x * 0.35) + TIME * speed * 1.37) * 0.35
		+ sin((p.x + p.y) * 0.8 + TIME * speed * 0.72) * 0.15;
}

vec4 sample_screen(vec2 uv_screen) {
	vec2 guard = (1.0 / max(vec2(textureSize(screen_texture, 0)), vec2(1.0))) * sample_guard;
	return texture(screen_texture, clamp(uv_screen, guard, vec2(1.0) - guard));
}

void fragment() {
	vec2 centered = UV - vec2(0.5);
	centered.y *= vertical_stretch;
	float soft_mask = smoothstep(0.92, 0.12, length(centered));
	float center_mask = smoothstep(center_clear_radius, center_clear_radius + 0.22, length(UV - vec2(0.5)));
	float edge_mask = 1.0 - smoothstep(1.0 - edge_fade, 1.0, max(abs(UV.x - 0.5), abs(UV.y - 0.5)) * 2.0);
	float active = intensity * soft_mask * center_mask * edge_mask;
	vec2 noise_uv = UV * vec2(ripple_scale * 0.55, ripple_scale);
	float n1 = heat_noise(noise_uv);
	float n2 = heat_noise(noise_uv + vec2(11.3, -4.7));
	vec2 offset = vec2(n1 * 0.65, n2) * strength * active;
	vec4 screen_color = sample_screen(SCREEN_UV + offset);
	COLOR = mix(screen_color, screen_color + heat_tint, heat_tint.a * active);
}
