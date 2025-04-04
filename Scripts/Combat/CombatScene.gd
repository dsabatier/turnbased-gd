# CombatScene.gd
extends Node

# References
@onready var combat_ui = $CombatUI
@onready var end_combat_dialog = $CombatUI/EndCombatDialog

# Combat system
var combat_system = CombatSystem.new()

# Saved player party for continuing battles
var player_party: Array[CombatantResource] = []

func _ready() -> void:
	# Get the saved team selection from the party selection scene
	var team_selection = get_node("/root/TeamSelection")
	
	# Check if we have valid teams
	if team_selection and !team_selection.player_team.is_empty() and !team_selection.enemy_team.is_empty():
		player_party = team_selection.player_team
		var enemy_team = team_selection.enemy_team
		
		# Initialize combat with selected teams
		_start_combat(player_party, enemy_team)
	else:
		# Create demo teams for testing
		_create_demo_combat()
	
	# Connect signals
	combat_ui.connect("continue_combat", _on_continue_combat)
	$CombatUI/EndCombatDialog/ContinueButton.pressed.connect(_on_continue_button_pressed)
	$CombatUI/EndCombatDialog/QuitButton.pressed.connect(_on_quit_button_pressed)

func _start_combat(player_team: Array[CombatantResource], enemy_team: Array[CombatantResource]) -> void:
	# Add the combat system as a child of this scene
	add_child(combat_system)
	
	# Initialize the combat system
	combat_system.initialize_combat(player_team, enemy_team)
	
	# Initialize the UI
	combat_ui.initialize(combat_system)

func _create_demo_combat() -> void:
	# Get some demo combatants
	var database = get_node("/root/CombatantDatabase")
	database._ensure_demo_combatants()
	
	var player_team = database.get_playable_combatants()
	var enemy_team = database.get_enemy_combatants()
	
	# Limit teams to 2 combatants each for the demo
	if player_team.size() > 2:
		player_team = player_team.slice(0, 2)
	
	if enemy_team.size() > 2:
		enemy_team = enemy_team.slice(0, 2)
	
	# Save player team for continue functionality
	player_party = player_team
	
	# Start combat
	_start_combat(player_team, enemy_team)

func _on_continue_combat() -> void:
	# Generate a new random enemy team
	var enemy_team = combat_system.generate_random_enemy_team()
	
	# Remove old combat system
	remove_child(combat_system)
	combat_system.queue_free()
	
	# Create a new combat system
	combat_system = CombatSystem.new()
	
	# Start a new combat with the same player team
	_start_combat(player_party, enemy_team)

func _on_continue_button_pressed() -> void:
	# Close dialog and signal for new combat
	end_combat_dialog.visible = false
	_on_continue_combat()

func _on_quit_button_pressed() -> void:
	# Return to main menu
	get_tree().change_scene_to_file("res://Scenes/start_menu.tscn")
