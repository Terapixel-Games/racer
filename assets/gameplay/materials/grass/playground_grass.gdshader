shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.24, 0.34, 0.14, 1.0);
uniform vec4 bright_color : source_color = vec4(0.38, 0.50, 0.20, 1.0);
uniform vec4 dry_color : source_color = vec4(0.50, 0.43, 0.25, 1.0);
uniform vec4 soil_color : source_color = vec4(0.16, 0.12, 0.07, 1.0);
uniform float patch_scale = 24.0;
uniform float blade_scale = 120.0;
uniform float blade_strength = 0.18;
uniform float wind_speed = 0.16;
uniform float wind_strength = 0.025;

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
	float dry = smoothstep(0.54, 0.94, noise(uv * patch_scale * 0.32 + vec2(9.0, 3.0)));
	float soil = smoothstep(0.72, 0.95, noise(uv * patch_scale * 0.55 + vec2(17.0, 11.0)));
	float wind = sin((uv.x + uv.y) * 10.0 + TIME * wind_speed) * wind_strength;
	float blades = sin((uv.x + wind) * blade_scale) * sin((uv.y - wind) * blade_scale * 0.43);
	blades = smoothstep(0.34, 1.0, blades) * blade_strength;
	vec3 color = mix(base_color.rgb, bright_color.rgb, patches * 0.45);
	color = mix(color, dry_color.rgb, dry * 0.42);
	color = mix(color, soil_color.rgb, soil * 0.18);
	color += blades * vec3(0.035, 0.055, 0.018);
	ALBEDO = color;
	ROUGHNESS = 0.98;
	SPECULAR = 0.03;
}
