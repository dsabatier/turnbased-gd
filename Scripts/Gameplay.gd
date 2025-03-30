# Gameplay.gd
extends Node2D

func _on_back_button_pressed() -> void:
	# Return to the start menu
	get_tree().change_scene_to_file("res://Scenes/start_menu.tscn")