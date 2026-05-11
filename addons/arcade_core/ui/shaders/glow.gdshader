shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(0.42, 0.86, 1.0, 1.0);
uniform float intensity : hint_range(0.0, 2.0) = 1.0;
uniform float falloff : hint_range(0.5, 4.0) = 2.1;
uniform float edge_mix : hint_range(0.0, 1.0) = 0.75;
uniform float time_scale : hint_range(0.0, 4.0) = 0.35;
uniform float pulse_amount : hint_range(0.0, 0.6) = 0.14;
uniform float t = 0.0;
uniform float core_radius : hint_range(0.0, 1.0) = 0.28;
uniform float edge_softness : hint_range(0.01, 1.0) = 0.28;
uniform float aspect_compensation : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec2 uv_centered = UV * 2.0 - vec2(1.0);
	float pixel_ratio = max(abs(dFdx(UV.x)), 0.0001) / max(abs(dFdy(UV.y)), 0.0001);
	uv_centered.x *= mix(1.0, pixel_ratio, aspect_compensation);
	float dist = length(uv_centered);
	float core = 1.0 - smoothstep(core_radius, core_radius + edge_softness, dist);
	float ring = pow(max(0.0, 1.0 - dist), falloff);
	float edge_box = smoothstep(0.95, 0.1, max(abs(uv_centered.x), abs(uv_centered.y)));
	float pulse = 1.0 + sin(t * time_scale * 6.28318) * pulse_amount;
	float alpha = (max(ring, core * 0.42) * (1.0 - edge_mix) + edge_box * edge_mix) * intensity * pulse;
	COLOR = vec4(glow_color.rgb, glow_color.a * alpha);
}
