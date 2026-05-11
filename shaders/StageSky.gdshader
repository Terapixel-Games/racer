shader_type sky;

uniform vec4 sky_top_color : source_color = vec4(0.58, 0.72, 0.90, 1.0);
uniform vec4 sky_horizon_color : source_color = vec4(0.64, 0.72, 0.82, 1.0);
uniform vec4 ground_haze_color : source_color = vec4(0.55, 0.57, 0.60, 1.0);
uniform vec4 sun_color : source_color = vec4(1.0, 0.92, 0.76, 1.0);
uniform float time_of_day = 0.5;
uniform float cloud_amount = 0.25;
uniform float cloud_speed = 0.02;
uniform float haze_amount = 0.18;
uniform float storm_darkness = 0.0;
uniform float sun_halo_strength : hint_range(0.0, 2.0) = 0.42;
uniform float horizon_contrast : hint_range(0.0, 1.0) = 0.24;
uniform float cloud_softness : hint_range(0.01, 0.5) = 0.18;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
		u.y
	);
}

void sky() {
	float horizon = clamp(EYEDIR.y * 0.5 + 0.5, 0.0, 1.0);
	float gradient = smoothstep(0.0, 1.0, horizon);
	vec3 color = mix(sky_horizon_color.rgb, sky_top_color.rgb, gradient);

	vec2 cloud_uv = EYEDIR.xz * 2.4 + vec2(TIME * cloud_speed, TIME * cloud_speed * 0.37);
	float cloud_noise = noise(cloud_uv) * 0.65 + noise(cloud_uv * 2.03 + 7.0) * 0.35;
	float cloud_floor = clamp(1.0 - cloud_amount, 0.0, 0.999);
	float cloud_mask = smoothstep(cloud_floor, min(cloud_floor + cloud_softness, 1.0), cloud_noise) * smoothstep(0.04, 0.28, EYEDIR.y);
	vec3 cloud_color = mix(vec3(0.72, 0.75, 0.78), vec3(1.0), 1.0 - storm_darkness);
	color = mix(color, cloud_color, cloud_mask * (0.45 + cloud_amount * 0.35));

	float sun_angle = time_of_day * 6.2831853;
	vec3 sun_dir = normalize(vec3(cos(sun_angle), sin(sun_angle), -0.34));
	float sun_dot = max(dot(EYEDIR, sun_dir), 0.0);
	float sun_disc = smoothstep(0.9992, 1.0, dot(EYEDIR, sun_dir));
	float moon_disc = smoothstep(0.9994, 1.0, dot(EYEDIR, -sun_dir));
	float sun_halo = pow(sun_dot, 48.0) * sun_halo_strength * (1.0 - storm_darkness);
	color += sun_color.rgb * sun_disc * (1.5 * (1.0 - storm_darkness));
	color += sun_color.rgb * sun_halo * 0.35;
	color += vec3(0.48, 0.58, 0.82) * moon_disc * (0.8 + storm_darkness);

	float haze = (1.0 - smoothstep(0.02, 0.42, abs(EYEDIR.y))) * haze_amount;
	color = mix(color, ground_haze_color.rgb, haze);
	color = mix(color, color * smoothstep(0.0, 0.42, horizon), horizon_contrast * (1.0 - horizon));
	color *= 1.0 - storm_darkness * 0.45;

	COLOR = color;
}
