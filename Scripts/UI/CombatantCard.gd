# CombatantCard.gd
extends PanelContainer

# References to UI elements
var name_label: Label
var hp_bar: ProgressBar
var hp_label: Label
var mp_bar: ProgressBar
var mp_label: Label
var status_container: Container
var portrait: TextureRect

# Reference to the combatant
var combatant: Combatant

# Status effect icon scene
var status_icon_scene = preload("res://Scenes/status_icon.tscn")

func _ready() -> void:
	# Get node references
	name_label = get_node_or_null("VBoxContainer/NameLabel")
	hp_bar = get_node_or_null("VBoxContainer/HpBar")
	hp_label = get_node_or_null("VBoxContainer/HpBar/HpLabel") if hp_bar else null
	mp_bar = get_node_or_null("VBoxContainer/MpBar")
	mp_label = get_node_or_null("VBoxContainer/MpBar/MpLabel") if mp_bar else null
	status_container = get_node_or_null("VBoxContainer/StatusContainer")
	portrait = get_node_or_null("VBoxContainer/Portrait")

func initialize(combatant_ref: Combatant) -> void:
	# Wait until ready if needed
	if not is_inside_tree():
		await ready
	
	# Refresh node references if needed
	if name_label == null:
		name_label = get_node_or_null("VBoxContainer/NameLabel")
	if hp_bar == null:
		hp_bar = get_node_or_null("VBoxContainer/HpBar")
	if hp_label == null and hp_bar != null:
		hp_label = get_node_or_null("VBoxContainer/HpBar/HpLabel")
	if mp_bar == null:
		mp_bar = get_node_or_null("VBoxContainer/MpBar")
	if mp_label == null and mp_bar != null:
		mp_label = get_node_or_null("VBoxContainer/MpBar/MpLabel")
	if status_container == null:
		status_container = get_node_or_null("VBoxContainer/StatusContainer")
	if portrait == null:
		portrait = get_node_or_null("VBoxContainer/Portrait")
	
	combatant = combatant_ref
	
	# Set basic info
	if name_label:
		name_label.text = combatant.display_name
	
	# Set portrait if available
	if portrait:
		if combatant.icon:
			portrait.texture = combatant.icon
	
	# Update HP and MP bars
	_update_hp_display()
	_update_mp_display()
	
	# Show/hide MP bar based on combatant type (only show for player)
	if mp_bar:
		mp_bar.visible = combatant.is_player
	
	# Connect signals
	combatant.hp_changed.connect(_on_hp_changed)
	combatant.mp_changed.connect(_on_mp_changed)
	combatant.status_effect_added.connect(_on_status_effect_added)
	combatant.status_effect_removed.connect(_on_status_effect_removed)
	combatant.defeated.connect(_on_combatant_defeated)

func _update_hp_display() -> void:
	if hp_bar == null or combatant == null:
		return
		
	var max_hp = combatant.get_modified_stat("max_hp")
	
	# Update HP bar
	hp_bar.max_value = max_hp
	hp_bar.value = combatant.current_hp
	
	# Update HP text
	if hp_label:
		hp_label.text = str(combatant.current_hp) + "/" + str(max_hp)

func _update_mp_display() -> void:
	if mp_bar == null or combatant == null or !combatant.is_player:
		return
		
	var max_mp = combatant.get_modified_stat("max_mp")
	
	# Update MP bar
	mp_bar.max_value = max_mp
	mp_bar.value = combatant.current_mp
	
	# Update MP text
	if mp_label:
		mp_label.text = str(combatant.current_mp) + "/" + str(max_mp)

func _on_hp_changed(new_hp: int, max_hp: int) -> void:
	_update_hp_display()

func _on_mp_changed(new_mp: int, max_mp: int) -> void:
	_update_mp_display()

func _on_combatant_defeated() -> void:
	# Visual indication of defeat (could be replaced with animation)
	modulate = Color(0.5, 0.5, 0.5, 0.5)
	
	# Could also play a defeat animation here

func _on_status_effect_added(effect: StatusEffect) -> void:
	if status_container == null:
		return
		
	# Create status icon
	var status_icon = status_icon_scene.instantiate()
	status_icon.setup(effect)
	status_container.add_child(status_icon)

func _on_status_effect_removed(effect: StatusEffect) -> void:
	if status_container == null:
		return
		
	# Find and remove the icon for this effect
	for icon in status_container.get_children():
		if icon.effect_name == effect.display_name:
			icon.queue_free()
			break
