# CombatantView.gd
extends PanelContainer

signal clicked(combatant_view)

# Node references
@onready var highlight = $Highlight
@onready var portrait = $MarginContainer/HBoxContainer/Portrait
@onready var name_label = $MarginContainer/HBoxContainer/VBoxContainer/NameLabel
@onready var hp_bar = $MarginContainer/HBoxContainer/VBoxContainer/HPContainer/HPBar
@onready var hp_label = $MarginContainer/HBoxContainer/VBoxContainer/HPContainer/HPBar/HPLabel
@onready var mp_container = $MarginContainer/HBoxContainer/VBoxContainer/MPContainer
@onready var mp_bar = $MarginContainer/HBoxContainer/VBoxContainer/MPContainer/MPBar
@onready var mp_label = $MarginContainer/HBoxContainer/VBoxContainer/MPContainer/MPBar/MPLabel
@onready var status_effects = $MarginContainer/HBoxContainer/VBoxContainer/StatusEffectsContainer/StatusEffects
@onready var status_container = $MarginContainer/HBoxContainer/VBoxContainer/StatusEffectsContainer

# Combatant reference
var combatant: Combatant = null
var is_player: bool = true

func _ready():
	# Make this panel clickable
	gui_input.connect(_on_gui_input)
	# Hide status container initially (will show when there are effects)
	status_container.visible = false

func setup(new_combatant: Combatant, is_player_combatant: bool = true):
	# Store combatant reference
	combatant = new_combatant
	is_player = is_player_combatant
	
	# Connect signals
	if combatant:
		combatant.hp_changed.connect(_on_combatant_hp_changed)
		combatant.mp_changed.connect(_on_combatant_mp_changed)
		combatant.status_effect_added.connect(_on_status_effect_added)
		combatant.status_effect_removed.connect(_on_status_effect_removed)
		combatant.defeated.connect(_on_combatant_defeated)
		
		# Set display values
		name_label.text = combatant.display_name
		
		# Set portrait color based on combatant type
		if is_player:
			# Player colors can be based on class/type
			if "Warrior" in combatant.name:
				portrait.color = Color(0.8, 0.2, 0.2) # Red for warriors
			elif "Wizard" in combatant.name or "Mage" in combatant.name:
				portrait.color = Color(0.2, 0.2, 0.8) # Blue for magic users
			elif "Cleric" in combatant.name or "Healer" in combatant.name:
				portrait.color = Color(0.2, 0.8, 0.2) # Green for healers
			elif "Rogue" in combatant.name or "Thief" in combatant.name:
				portrait.color = Color(0.8, 0.8, 0.2) # Yellow for rogues
			else:
				portrait.color = Color(0.5, 0.5, 0.8) # Default player color
		else:
			# Enemy color can be based on enemy type
			if "Dragon" in combatant.name:
				portrait.color = Color(0.8, 0.2, 0.2) # Red for dragons
			elif "Mage" in combatant.name or "Wizard" in combatant.name:
				portrait.color = Color(0.5, 0.2, 0.5) # Purple for magic enemies
			elif "Undead" in combatant.name or "Skeleton" in combatant.name:
				portrait.color = Color(0.5, 0.5, 0.5) # Gray for undead
			elif "Spider" in combatant.name or "Insect" in combatant.name:
				portrait.color = Color(0.2, 0.5, 0.2) # Green for creatures
			else:
				portrait.color = Color(0.6, 0.3, 0.3) # Default enemy color
		
		# Update HP and MP display
		update_hp_display()
		update_mp_display()
		
		# Handle MP display for combatants with no MP
		if combatant.max_mp <= 0:
			mp_container.visible = false
	else:
		# Hide if no combatant
		visible = false

func update_hp_display():
	if combatant:
		var hp_ratio = float(combatant.current_hp) / float(combatant.max_hp)
		hp_bar.value = hp_ratio * 100
		hp_label.text = str(combatant.current_hp) + "/" + str(combatant.max_hp)
		
		# Change HP bar color based on health percentage
		if hp_ratio < 0.25:
			hp_bar.self_modulate = Color(0.9, 0.1, 0.1) # Red for low health
		elif hp_ratio < 0.5:
			hp_bar.self_modulate = Color(0.9, 0.6, 0.1) # Orange for medium health
		else:
			hp_bar.self_modulate = Color(0.1, 0.9, 0.1) # Green for high health

func update_mp_display():
	if combatant and combatant.max_mp > 0:
		var mp_ratio = float(combatant.current_mp) / float(combatant.max_mp)
		mp_bar.value = mp_ratio * 100
		mp_label.text = str(combatant.current_mp) + "/" + str(combatant.max_mp)

func update_status_effects():
	# Clear existing status icons
	for child in status_effects.get_children():
		child.queue_free()
	
	if not combatant or combatant.status_effects.size() == 0:
		status_container.visible = false
		return
	
	status_container.visible = true
	
	# Add icon for each status effect
	for effect in combatant.status_effects:
		# Determine color based on effect type
		var color = Color.WHITE
		
		match effect.trigger_type:
			StatusEffect.TriggerType.TURN_START:
				color = Color.GREEN
			StatusEffect.TriggerType.TURN_END:
				color = Color.RED
			StatusEffect.TriggerType.ON_DAMAGE_TAKEN:
				color = Color.BLUE
			StatusEffect.TriggerType.ON_HEALING_RECEIVED:
				color = Color.YELLOW
		
		# Create status effect icon
		var panel = Panel.new()
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = color
		style_box.corner_radius_top_left = 4
		style_box.corner_radius_top_right = 4
		style_box.corner_radius_bottom_left = 4
		style_box.corner_radius_bottom_right = 4
		
		panel.add_theme_stylebox_override("panel", style_box)
		panel.custom_minimum_size = Vector2(12, 12)
		
		# Make sure we use the correct turns property (remaining_turns not duration)
		panel.tooltip_text = effect.name + " (" + str(effect.remaining_turns) + " turns)" + \
							"\n" + effect.description
		
		status_effects.add_child(panel)
        
func set_highlighted(is_highlighted: bool):
	highlight.visible = is_highlighted

func _on_combatant_hp_changed(current_hp, max_hp):
	update_hp_display()

func _on_combatant_mp_changed(current_mp, max_mp):
	update_mp_display()

func _on_status_effect_added(effect):
	update_status_effects()

func _on_status_effect_removed(effect):
	update_status_effects()

func _on_combatant_defeated():
	# Gray out the entire panel
	modulate = Color(0.5, 0.5, 0.5, 0.7)

func _on_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		emit_signal("clicked", self)