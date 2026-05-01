shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.18, 0.42, 0.15, 1.0);
uniform vec4 bright_color : source_color = vec4(0.42, 0.72, 0.22, 1.0);
uniform vec4 dry_color : source_color = vec4(0.56, 0.48, 0.24, 1.0);
uniform float patch_scale = 18.0;
uniform float blade_scale = 82.0;
uniform float blade_strength = 0.34;
uniform float wind_speed = 0.35;
uniform float wind_strength = 0.08;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
		u.y
	);
}

void fragment() {
	vec2 uv = UV;
	float patches = noise(uv * patch_scale);
	float dry = smoothstep(0.64, 0.95, noise(uv * patch_scale * 0.42 + vec2(9.0, 3.0)));
	float wind = sin((uv.x + uv.y) * 10.0 + TIME * wind_speed) * wind_strength;
	float blades = sin((uv.x + wind) * blade_scale) * sin((uv.y - wind) * blade_scale * 0.43);
	blades = smoothstep(0.28, 1.0, blades) * blade_strength;
	vec3 color = mix(base_color.rgb, bright_color.rgb, patches);
	color = mix(color, dry_color.rgb, dry * 0.32);
	color += blades * vec3(0.08, 0.16, 0.04);
	ALBEDO = color;
	ROUGHNESS = 0.92;
	SPECULAR = 0.12;
}
