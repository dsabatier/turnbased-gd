# Boot.gd
extends Node

func _ready() -> void:
	# Use call_deferred to change the scene after the current frame is complete
	call_deferred("_change_scene")

func _change_scene() -> void:
	# Change to the character selection scene
	get_tree().change_scene_to_file("res://Scenes/start_menu.tscn")
