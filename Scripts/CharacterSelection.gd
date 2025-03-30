# CharacterSelection.gd
extends Control

@onready var available_list: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/AvailableContainer/AvailableList/VBoxContainer
@onready var party_list: VBoxContainer = %PartyList
@onready var enemy_list: VBoxContainer = %EnemyList
@onready var start_battle_button: Button = %StartBattleButton
@onready var party_label: Label = %PartyLabel
@onready var enemy_label: Label = %EnemyLabel

var available_combatants: Array[Combatant] = []
var selected_party: Array[Combatant] = []
var selected_enemies: Array[Combatant] = []

const MAX_PARTY_SIZE: int = 4
const MAX_ENEMY_SIZE: int = 10
const CombatantOption = preload("res://Scripts/CombatantOption.gd")

func _ready() -> void:
	# Load all available combatants
	load_available_combatants()
	
	# Populate the available list
	populate_available_list()
	
	# Update UI labels
	update_labels()

func load_available_combatants() -> void:
	# Load from our CombatantDatabase
	available_combatants = CombatantDatabase.get_all_combatants()

func populate_available_list() -> void:
	# Clear existing items
	for child in available_list.get_children():
		child.queue_free()
	
	# Create option buttons for each available combatant
	for combatant_data in available_combatants:
		var option: Button = create_combatant_option(combatant_data)
		available_list.add_child(option)

func create_combatant_option(combatant_data: Combatant) -> Button:
	var option: Button = Button.new()
	
	# Create a more detailed description of the combatant
	var text = combatant_data.name + "\n"
	text += "HP: " + str(combatant_data.max_hp) + " | "
	text += "MP: " + str(combatant_data.max_mp) + " | "
	text += "SPD: " + str(combatant_data.speed) + "\n"
	text += "ATK: " + str(combatant_data.physical_attack) + " | "
	text += "MAG: " + str(combatant_data.magic_attack) + " | "
	text += "DEF: " + str(combatant_data.physical_defense) + " | "
	text += "RES: " + str(combatant_data.magic_defense)
	
	option.text = text
	option.set_script(CombatantOption)
	option.combatant_data = combatant_data
	option.pressed.connect(_on_combatant_option_pressed.bind(option))
	return option

func _on_combatant_option_pressed(option: Button) -> void:
	# Show selection popup
	var popup: ConfirmationDialog = ConfirmationDialog.new()
	popup.title = "Select Destination"
	
	# Create VBox for buttons
	var vbox: VBoxContainer = VBoxContainer.new()
	popup.add_child(vbox)
	
	# Add to party button
	var party_button: Button = Button.new()
	party_button.text = "Add to Party" + (" (Full)" if selected_party.size() >= MAX_PARTY_SIZE else "")
	party_button.disabled = selected_party.size() >= MAX_PARTY_SIZE
	party_button.pressed.connect(func(): 
		add_to_party(option.combatant_data)
		popup.queue_free()
	)
	vbox.add_child(party_button)
	
	# Add to enemies button
	var enemy_button: Button = Button.new()
	enemy_button.text = "Add to Enemies" + (" (Full)" if selected_enemies.size() >= MAX_ENEMY_SIZE else "")
	enemy_button.disabled = selected_enemies.size() >= MAX_ENEMY_SIZE
	enemy_button.pressed.connect(func(): 
		add_to_enemies(option.combatant_data)
		popup.queue_free()
	)
	vbox.add_child(enemy_button)
	
	# Cancel button
	var cancel_button: Button = Button.new()
	cancel_button.text = "Cancel"
	cancel_button.pressed.connect(func(): popup.queue_free())
	vbox.add_child(cancel_button)
	
	# Set popup size and position
	popup.position = get_global_mouse_position()
	popup.size = Vector2(200, 150)
	
	# Add popup to scene
	add_child(popup)
	popup.popup_centered()

func add_to_party(combatant_data: Combatant) -> void:
	if selected_party.size() >= MAX_PARTY_SIZE:
		return
	
	# Create a proper deep copy of the combatant for the party
	var combatant_copy: Combatant = Combatant.new()
	
	# Generate a unique name if there are duplicates
	var base_name: String = combatant_data.name
	var display_name: String = base_name
	
	# Check if we already have a combatant with this name
	var count: int = 1
	for existing in selected_party:
		if existing.display_name == display_name:
			count += 1
			display_name = base_name + " " + str(count)
	
	combatant_copy.name = combatant_data.name + "_" + str(selected_party.size() + 1)  # Unique node name
	combatant_copy.display_name = display_name  # Human-readable name
	
	# Copy all stats
	combatant_copy.max_hp = combatant_data.max_hp
	combatant_copy.current_hp = combatant_data.max_hp
	combatant_copy.max_mp = combatant_data.max_mp
	combatant_copy.current_mp = combatant_data.max_mp
	combatant_copy.physical_attack = combatant_data.physical_attack
	combatant_copy.magic_attack = combatant_data.magic_attack
	combatant_copy.physical_defense = combatant_data.physical_defense
	combatant_copy.magic_defense = combatant_data.magic_defense
	combatant_copy.speed = combatant_data.speed
	combatant_copy.is_player = true
	
	# Properly copy all abilities
	combatant_copy.abilities = []
	for ability in combatant_data.abilities:
		combatant_copy.abilities.append(ability)
	
	selected_party.append(combatant_copy)
	
	# Create UI element
	var option: HBoxContainer = create_selection_item(combatant_copy, true)
	party_list.add_child(option)
	
	update_labels()
	update_start_button()

func add_to_enemies(combatant_data: Combatant) -> void:
	if selected_enemies.size() >= MAX_ENEMY_SIZE:
		return
	
	# Create a proper deep copy of the combatant for the enemies
	var combatant_copy: Combatant = Combatant.new()
	
	# Generate a unique name if there are duplicates
	var base_name: String = combatant_data.name
	var display_name: String = base_name
	
	# Check if we already have a combatant with this name
	var count: int = 1
	for existing in selected_enemies:
		if existing.display_name == display_name:
			count += 1
			display_name = base_name + " " + str(count)
	
	combatant_copy.name = combatant_data.name + "_" + str(selected_enemies.size() + 1)  # Unique node name
	combatant_copy.display_name = display_name  # Human-readable name
	
	# Copy all stats
	combatant_copy.max_hp = combatant_data.max_hp
	combatant_copy.current_hp = combatant_data.max_hp
	combatant_copy.max_mp = combatant_data.max_mp
	combatant_copy.current_mp = combatant_data.max_mp
	combatant_copy.physical_attack = combatant_data.physical_attack
	combatant_copy.magic_attack = combatant_data.magic_attack
	combatant_copy.physical_defense = combatant_data.physical_defense
	combatant_copy.magic_defense = combatant_data.magic_defense
	combatant_copy.speed = combatant_data.speed
	combatant_copy.is_player = false
	
	# Properly copy all abilities
	combatant_copy.abilities = []
	for ability in combatant_data.abilities:
		combatant_copy.abilities.append(ability)
	
	selected_enemies.append(combatant_copy)
	
	# Create UI element
	var option: HBoxContainer = create_selection_item(combatant_copy, false)
	enemy_list.add_child(option)
	
	update_labels()
	update_start_button()

func create_selection_item(combatant_data: Combatant, is_party: bool) -> HBoxContainer:
	var container: HBoxContainer = HBoxContainer.new()
	
	# Label for combatant name and stats
	var label: Label = Label.new()
	label.text = combatant_data.display_name + " [HP: " + str(combatant_data.max_hp) + ", MP: " + str(combatant_data.max_mp) + "]"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(label)
	
	# Remove button
	var remove_button: Button = Button.new()
	remove_button.text = "X"
	remove_button.pressed.connect(func(): remove_selection(container, combatant_data, is_party))
	container.add_child(remove_button)
	
	return container

func remove_selection(container: HBoxContainer, combatant_data: Combatant, is_party: bool) -> void:
	if is_party:
		selected_party.erase(combatant_data)
	else:
		selected_enemies.erase(combatant_data)
	
	container.queue_free()
	update_labels()
	update_start_button()

func update_labels() -> void:
	party_label.text = "Your Party (%d/%d)" % [selected_party.size(), MAX_PARTY_SIZE]
	enemy_label.text = "Enemies (%d/%d)" % [selected_enemies.size(), MAX_ENEMY_SIZE]

func update_start_button() -> void:
	# Enable start button only if we have at least one party member and one enemy
	start_battle_button.disabled = selected_party.size() == 0 or selected_enemies.size() == 0

func _on_start_battle_button_pressed() -> void:
	# Store selected combatants for the battle
	CombatantDatabase.set_selected_party(selected_party)
	CombatantDatabase.set_selected_enemies(selected_enemies)
	
	# Change to the main scene
	get_tree().change_scene_to_file("res://Scenes/main.tscn")