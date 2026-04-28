local M = {}

local kitchen = {
	id = "kitchen",
	display_name = "Kitchen / Sir Clink",
	laps = 2,
	road_width = 12.0,
	closed_loop = true,
	out_of_bounds_y = 1.5,
	reset_mode = "instant_pop",
	route_length = 512.5324527602634,
	checkpoint_radius = 7.8,
	route_points = {
		{-50.0, 3.0, -70.0},
		{-24.0, 3.0, -72.0},
		{8.0, 3.0, -72.0},
		{38.0, 3.0, -68.0},
		{64.0, 3.0, -56.0},
		{82.0, 3.0, -36.0},
		{88.0, 3.0, -10.0},
		{82.0, 3.0, 18.0},
		{66.0, 3.0, 44.0},
		{40.0, 3.0, 64.0},
		{8.0, 3.0, 72.0},
		{-24.0, 3.0, 70.0},
		{-54.0, 3.0, 58.0},
		{-78.0, 3.0, 38.0},
		{-86.0, 3.0, 10.0},
		{-84.0, 3.0, -20.0},
		{-72.0, 3.0, -48.0},
		{-58.0, 3.0, -66.0},
	},
	checkpoints = {
		{index = 0, route_index = 0, position = {-50.0, 3.0, -70.0}, is_lap_gate = true},
		{index = 1, route_index = 6, position = {88.0, 3.0, -10.0}, is_lap_gate = false},
		{index = 2, route_index = 11, position = {-24.0, 3.0, 70.0}, is_lap_gate = false},
		{index = 3, route_index = 15, position = {-84.0, 3.0, -20.0}, is_lap_gate = false},
	},
	lap_gate_checkpoint_index = 0,
	spawn_points = {
		{-48.0, 3.8, -72.2, 90.0},
		{-48.0, 3.8, -67.8, 90.0},
		{-44.0, 3.8, -72.2, 90.0},
		{-44.0, 3.8, -67.8, 90.0},
		{-40.0, 3.8, -72.2, 90.0},
		{-40.0, 3.8, -67.8, 90.0},
		{-36.0, 3.8, -72.2, 90.0},
		{-36.0, 3.8, -67.8, 90.0},
	},
	item_sockets = {
		{position = {-10.0, 3.8, -72.0}, yaw_degrees = 90.0},
		{position = {26.0, 3.8, -70.0}, yaw_degrees = 90.0},
		{position = {74.0, 3.8, -48.0}, yaw_degrees = 40.0},
		{position = {86.0, 3.8, -8.0}, yaw_degrees = 176.0},
		{position = {58.0, 3.8, 52.0}, yaw_degrees = 130.0},
		{position = {6.0, 3.8, 71.0}, yaw_degrees = -88.0},
		{position = {-76.0, 3.8, 32.0}, yaw_degrees = 190.0},
		{position = {-72.0, 3.8, -46.0}, yaw_degrees = -38.0},
	},
	hazard_sockets = {
		{position = {18.0, 3.8, -72.0}, yaw_degrees = 90.0},
		{position = {84.0, 3.8, -22.0}, yaw_degrees = 176.0},
		{position = {66.0, 3.8, 40.0}, yaw_degrees = 150.0},
		{position = {-50.0, 3.8, 60.0}, yaw_degrees = -120.0},
		{position = {-84.0, 3.8, 4.0}, yaw_degrees = 184.0},
		{position = {-66.0, 3.8, -58.0}, yaw_degrees = -34.0},
	},
	shortcut_gates = {
		{id = "table_jump", kind = "jump", entry = {62.0, 3.0, 46.0}, exit = {-24.0, 3.0, 68.0}, width = 8.0},
	},
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
