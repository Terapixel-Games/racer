extends Node

const GAME_ID := "circuit-collapse-racer"
const GAME_VERSION := "1.0.0"

const MAX_RACERS := 8
const LAPS := 2
const LOBBY_COUNTDOWN_SECONDS := 20
const LOBBY_RESET_TO_TEN_THRESHOLD := 10
const BEHIND_SECONDS_TO_WASTED := 6
const INPUT_TICK_HZ := 20
const SNAPSHOT_HZ := 15
const TRACK_SCENE := "res://scenes/tracks/TrackSerpentine.tscn"

const NAKAMA_HOST := "nakama-qxqz.onrender.com"
const NAKAMA_PORT := 443
const NAKAMA_SCHEME := "https"
const NAKAMA_SERVER_KEY := "the_man_who_sold_the_world"
const NAKAMA_SOCKET_URL := "wss://nakama-qxqz.onrender.com/ws"

var override_host : String = ""

func get_host() -> String:
	return override_host if override_host != "" else NAKAMA_HOST

func get_scheme() -> String:
	return "http" if override_host != "" else NAKAMA_SCHEME

func get_port() -> int:
	return 7350 if override_host != "" else NAKAMA_PORT
