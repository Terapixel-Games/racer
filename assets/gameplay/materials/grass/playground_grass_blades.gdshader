shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform vec4 bottom_color : source_color = vec4(0.18, 0.30, 0.08, 1.0);
uniform vec4 top_color : source_color = vec4(0.52, 0.78, 0.22, 1.0);
uniform vec4 dry_tip_color : source_color = vec4(0.68, 0.60, 0.28, 1.0);
uniform float sway_strength = 0.18;
uniform float sway_speed = 1.2;
uniform float sway_frequency = 0.55;
uniform float dry_tip_amount = 0.18;
uniform float underside_shadow : hint_range(0.0, 1.0) = 0.22;
uniform float highlight_amount : hint_range(0.0, 1.0) = 0.18;

varying float blade_height;
varying float blade_noise;
varying float bend_amount;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void vertex() {
	blade_height = UV.y;
	vec3 world_vertex = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	blade_noise = hash(floor(world_vertex.xz * 0.65));
	float wind = sin((world_vertex.x + world_vertex.z) * sway_frequency + TIME * sway_speed + blade_noise * 6.28318);
	float tip_weight = blade_height * blade_height;
	bend_amount = abs(wind) * tip_weight;
	VERTEX.x += wind * sway_strength * tip_weight;
	VERTEX.z += cos(TIME * sway_speed * 0.71 + blade_noise * 4.0) * sway_strength * 0.38 * tip_weight;
	NORMAL = normalize(vec3(-wind * 0.24, 0.72, 0.68));
}

void fragment() {
	float height_mix = smoothstep(0.0, 1.0, blade_height);
	vec3 color = mix(bottom_color.rgb, top_color.rgb, height_mix);
	float dry_tip = smoothstep(1.0 - dry_tip_amount, 1.0, blade_height) * smoothstep(0.48, 1.0, blade_noise);
	color = mix(color, dry_tip_color.rgb, dry_tip * 0.55);
	color *= 1.0 - underside_shadow * smoothstep(0.15, 1.0, bend_amount) * (1.0 - height_mix * 0.35);
	color += top_color.rgb * highlight_amount * smoothstep(0.45, 1.0, blade_height) * smoothstep(0.25, 0.95, blade_noise);
	ALBEDO = color;
	ROUGHNESS = 0.9;
	SPECULAR = 0.08;
}
