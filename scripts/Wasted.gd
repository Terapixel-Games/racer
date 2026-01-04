extends Control

@onready var return_button: Button = %ReturnButton

func _ready() -> void:
	return_button.pressed.connect(_return)

func _return() -> void:
	get_tree().change_scene_to_file("res://scenes/Lobby.tscn")
