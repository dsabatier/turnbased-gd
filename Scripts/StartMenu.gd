# StartMenu.gd
extends Control

func _ready() -> void:
	# Center the window on startup
	if OS.has_feature("pc"):
		var screen_size = DisplayServer.screen_get_size()
		var window_size = DisplayServer.window_get_size()
		DisplayServer.window_set_position(screen_size / 2 - window_size / 2)

func _on_play_button_pressed() -> void:
	# Change to an empty gameplay scene (we'll create this next)
	get_tree().change_scene_to_file("res://Scenes/gameplay.tscn")

func _on_combat_test_button_pressed() -> void:
	# Change to the character selection scene
	get_tree().change_scene_to_file("res://Scenes/character_selection.tscn")

func _on_quit_button_pressed() -> void:
	# Quit the game
	get_tree().quit()