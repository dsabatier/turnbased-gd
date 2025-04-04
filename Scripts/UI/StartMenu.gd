# StartMenu.gd
extends Control

func _ready() -> void:
	# Connect button signals
	$PanelContainer/MarginContainer/VBoxContainer/StartButton.pressed.connect(_on_start_button_pressed)
	$PanelContainer/MarginContainer/VBoxContainer/QuitButton.pressed.connect(_on_quit_button_pressed)

func _on_start_button_pressed() -> void:
	# Start the game by going to party selection
	get_tree().change_scene_to_file("res://Scenes/party_selection.tscn")

func _on_quit_button_pressed() -> void:
	# Quit the game
	get_tree().quit()
