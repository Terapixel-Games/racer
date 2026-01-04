extends Control

@onready var play_button: Button = %PlayButton
@onready var quit_button: Button = %QuitButton
@onready var status_label: Label = %StatusLabel

func _ready() -> void:
	status_label.text = ""
	quit_button.visible = OS.has_feature("pc") or OS.has_feature("desktop")
	play_button.pressed.connect(_on_play)
	quit_button.pressed.connect(func(): get_tree().quit())

func _on_play() -> void:
	status_label.text = "Connecting..."
	await NakamaService.ensure_connected()
	status_label.text = ""
	get_tree().change_scene_to_file("res://scenes/Lobby.tscn")
