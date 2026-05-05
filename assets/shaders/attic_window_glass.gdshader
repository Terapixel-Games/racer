shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_back, specular_schlick_ggx;

uniform vec4 glass_tint : source_color = vec4(0.45, 0.72, 1.0, 0.28);
uniform vec4 edge_tint : source_color = vec4(0.82, 0.96, 1.0, 0.46);
uniform float grime_strength : hint_range(0.0, 1.0) = 0.32;
uniform float fresnel_power : hint_range(0.5, 8.0) = 3.2;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
	vec2 grid_uv = UV * vec2(18.0, 10.0);
	float grime = hash(floor(grid_uv)) * grime_strength;
	float scratches = smoothstep(0.965, 1.0, hash(floor(UV * vec2(64.0, 24.0))));
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), fresnel_power);
	vec3 color = mix(glass_tint.rgb, edge_tint.rgb, fresnel * 0.65);
	color = mix(color, vec3(0.12, 0.16, 0.2), grime * 0.22);
	color += scratches * vec3(0.12, 0.17, 0.2);
	ALBEDO = color;
	ALPHA = clamp(glass_tint.a + fresnel * 0.24 + scratches * 0.08, 0.08, 0.62);
	ROUGHNESS = 0.18 + grime * 0.36;
	METALLIC = 0.0;
	SPECULAR = 0.82;
}
