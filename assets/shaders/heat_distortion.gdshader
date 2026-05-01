shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float strength : hint_range(0.0, 0.04) = 0.012;
uniform float speed : hint_range(0.0, 12.0) = 4.5;
uniform float ripple_scale : hint_range(1.0, 80.0) = 26.0;
uniform float vertical_stretch : hint_range(0.1, 6.0) = 2.8;
uniform vec4 heat_tint : source_color = vec4(1.0, 0.72, 0.34, 0.05);

float heat_noise(vec2 p) {
	return sin(p.x * 1.7 + TIME * speed) * 0.5
		+ sin((p.y * 2.1 - p.x * 0.35) + TIME * speed * 1.37) * 0.35
		+ sin((p.x + p.y) * 0.8 + TIME * speed * 0.72) * 0.15;
}

void fragment() {
	vec2 centered = UV - vec2(0.5);
	centered.y *= vertical_stretch;
	float soft_mask = smoothstep(0.92, 0.12, length(centered));
	float active = intensity * soft_mask;
	vec2 noise_uv = UV * vec2(ripple_scale * 0.55, ripple_scale);
	float n1 = heat_noise(noise_uv);
	float n2 = heat_noise(noise_uv + vec2(11.3, -4.7));
	vec2 offset = vec2(n1 * 0.65, n2) * strength * active;
	vec4 screen_color = texture(screen_texture, SCREEN_UV + offset);
	COLOR = mix(screen_color, screen_color + heat_tint, heat_tint.a * active);
}
