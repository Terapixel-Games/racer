shader_type canvas_item;

uniform vec4 color_a : source_color = vec4(0.02, 0.08, 0.21, 1.0);
uniform vec4 color_b : source_color = vec4(0.05, 0.18, 0.38, 1.0);
uniform vec4 accent_color : source_color = vec4(0.10, 0.46, 0.78, 1.0);
uniform float t = 0.0;
uniform float drift_speed : hint_range(0.0, 2.0) = 0.26;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.16;
uniform float accent_strength : hint_range(0.0, 1.0) = 0.23;
uniform float grain_strength : hint_range(0.0, 0.08) = 0.018;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
	vec2 uv = UV;
	float drift = sin((uv.y * 1.6 + uv.x * 0.5 + t * drift_speed) * 6.28318) * 0.055;
	float mixv = clamp(uv.y + drift, 0.0, 1.0);
	vec4 base = mix(color_a, color_b, mixv);
	float bloom = smoothstep(0.65, 0.05, distance(uv, vec2(0.5, 0.28)));
	float lower_bloom = smoothstep(0.84, 0.18, distance(uv, vec2(0.5, 0.92)));
	float edge_dist = distance(uv, vec2(0.5));
	float vignette = smoothstep(0.32, 0.84, edge_dist);
	float grain = hash(floor(uv * vec2(360.0, 640.0)) + vec2(t * 17.0, t * 9.0)) - 0.5;
	base.rgb += accent_color.rgb * (bloom + lower_bloom * 0.35) * accent_strength;
	base.rgb *= 1.0 - vignette * vignette_strength;
	base.rgb += grain * grain_strength;
	COLOR = vec4(base.rgb, 1.0);
}
