local M = {}

local kitchen = {
	id = "kitchen",
	display_name = "Kitchen / Sir Clink",
	laps = 2,
	road_width = 12.0,
	closed_loop = true,
	route_length = 374.749514471995,
	checkpoint_radius = 7.8,
	route_points = {
		{0.0, 0.55, -54.0},
		{-42.0, 0.55, -42.0},
		{-64.0, 0.55, -8.0},
		{-46.0, 0.55, 36.0},
		{0.0, 0.55, 58.0},
		{50.0, 0.55, 38.0},
		{66.0, 0.55, -12.0},
		{42.0, 0.55, -48.0},
	},
	checkpoints = {
		{index = 0, route_index = 0, position = {0.0, 0.55, -54.0}, is_lap_gate = true},
		{index = 1, route_index = 2, position = {-64.0, 0.55, -8.0}, is_lap_gate = false},
		{index = 2, route_index = 4, position = {0.0, 0.55, 58.0}, is_lap_gate = false},
		{index = 3, route_index = 6, position = {66.0, 0.55, -12.0}, is_lap_gate = false},
	},
	lap_gate_checkpoint_index = 0,
	spawn_points = {
		{-4.0, 0.8, -61.0, -74.0},
		{1.0, 0.8, -63.0, -74.0},
		{-8.0, 0.8, -66.0, -74.0},
		{-3.0, 0.8, -68.0, -74.0},
		{-12.0, 0.8, -71.0, -74.0},
		{-7.0, 0.8, -73.0, -74.0},
		{-16.0, 0.8, -76.0, -74.0},
		{-11.0, 0.8, -78.0, -74.0},
	},
	item_sockets = {
		{position = {-28.0, 0.8, -46.0}, yaw_degrees = -60.0},
		{position = {-62.0, 0.8, -20.0}, yaw_degrees = -8.0},
		{position = {-34.0, 0.8, 44.0}, yaw_degrees = 48.0},
		{position = {18.0, 0.8, 56.0}, yaw_degrees = 110.0},
		{position = {60.0, 0.8, 18.0}, yaw_degrees = 170.0},
		{position = {34.0, 0.8, -50.0}, yaw_degrees = -110.0},
	},
	hazard_sockets = {
		{position = {-52.0, 0.8, 8.0}, yaw_degrees = 20.0},
		{position = {44.0, 0.8, 36.0}, yaw_degrees = -20.0},
		{position = {54.0, 0.8, -30.0}, yaw_degrees = 30.0},
		{position = {-10.0, 0.8, 54.0}, yaw_degrees = 90.0},
	},
	shortcut_gates = {},
	audio_ids = {
		music = "res://assets/source/audio/suno/tracks/kitchen/kitchen_loop_suno_01.mp3",
		clatter = "res://assets/source/audio/canva/tracks/kitchen/kitchen_clatter_canva_01.mp3",
		sink_splash = "res://assets/source/audio/canva/tracks/kitchen/kitchen_sink_splash_canva_01.mp3",
		utensil_clink = "res://assets/source/audio/canva/tracks/kitchen/kitchen_utensil_clink_canva_01.wav",
	},
	runtime_scene_path = "res://assets/gameplay/tracks/kitchen/kitchen_track.tscn",
}

M.tracks = {
	kitchen = kitchen,
	oval = kitchen,
	serpentine = kitchen,
}

function M.get(id)
	return M.tracks[id or "kitchen"] or kitchen
end

return M
