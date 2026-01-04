extends Control

@onready var results_list: VBoxContainer = %ResultsList
@onready var lobby_button: Button = %LobbyButton
@onready var menu_button: Button = %MenuButton

func _ready() -> void:
	_populate_results()
	lobby_button.pressed.connect(_return_lobby)
	menu_button.pressed.connect(_return_menu)

func _populate_results() -> void:
	for child in results_list.get_children():
		child.queue_free()
	var results = NakamaService.get_meta_value("race_results", [])
	if results.is_empty():
		var label := Label.new()
		label.text = "Results unavailable."
		results_list.add_child(label)
		return
	for r in results:
		var label := Label.new()
		label.text = "%s" % str(r)
		results_list.add_child(label)

func _return_lobby() -> void:
	get_tree().change_scene_to_file("res://scenes/Lobby.tscn")

func _return_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
