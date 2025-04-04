# CombatantCard.gd
extends PanelContainer

# References to UI elements
@onready var name_label = $VBoxContainer/NameLabel
@onready var hp_bar = $VBoxContainer/HpBar
@onready var hp_label = $VBoxContainer/HpBar/HpLabel
@onready var mp_bar = $VBoxContainer/MpBar
@onready var mp_label = $VBoxContainer/MpBar/MpLabel
@onready var status_container = $VBoxContainer/StatusContainer
@onready var portrait = $VBoxContainer/Portrait

# Reference to the combatant
var combatant: Combatant

# Status effect icon scene
var status_icon_scene = preload("res://Scenes/status_icon.tscn")

func initialize(combatant_ref: Combatant) -> void:
	combatant = combatant_ref
	
	# Set basic info
	name_label.text = combatant.display_name
	
	# Set portrait if available
	if combatant.icon:
		portrait.texture = combatant.icon
	
	# Update HP and MP bars
	_update_hp_display()
	_update_mp_display()
	
	# Show/hide MP bar based on combatant type (only show for player)
	mp_bar.visible = combatant.is_player
	
	# Connect signals
	combatant.hp_changed.connect(_on_hp_changed)
	combatant.mp_changed.connect(_on_mp_changed)
	combatant.status_effect_added.connect(_on_status_effect_added)
	combatant.status_effect_removed.connect(_on_status_effect_removed)
	combatant.defeated.connect(_on_combatant_defeated)

func _update_hp_display() -> void:
	var max_hp = combatant.get_modified_stat("max_hp")
	
	# Update HP bar
	hp_bar.max_value = max_hp
	hp_bar.value = combatant.current_hp
	
	# Update HP text
	hp_label.text = str(combatant.current_hp) + "/" + str(max_hp)

func _update_mp_display() -> void:
	if !combatant.is_player:
		return
		
	var max_mp = combatant.get_modified_stat("max_mp")
	
	# Update MP bar
	mp_bar.max_value = max_mp
	mp_bar.value = combatant.current_mp
	
	# Update MP text
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
	# Create status icon
	var status_icon = status_icon_scene.instantiate()
	status_icon.setup(effect)
	status_container.add_child(status_icon)

func _on_status_effect_removed(effect: StatusEffect) -> void:
	# Find and remove the icon for this effect
	for icon in status_container.get_children():
		if icon.effect_name == effect.display_name:
			icon.queue_free()
			break
