# DebugOverlay.gd
class_name DebugOverlay
extends CanvasLayer

@onready var debug_label: Label = $DebugLabel

var enabled: bool = false
var combat_system: CombatSystem = null
var update_timer: float = 0.0
var update_interval: float = 0.5  # Update every half second

func _ready() -> void:
	# Initially hidden
	debug_label.visible = false
	
	# Enable with F3 key
	set_process_input(true)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F3:
			enabled = !enabled
			debug_label.visible = enabled

func _process(delta: float) -> void:
	if !enabled or !combat_system:
		return
	
	update_timer += delta
	if update_timer >= update_interval:
		update_timer = 0.0
		update_debug_info()

func initialize(combat_sys: CombatSystem) -> void:
	combat_system = combat_sys
	
	# Connect to signals
	combat_system.turn_started.connect(_on_turn_started)
	combat_system.round_started.connect(_on_round_started)
	
	update_debug_info()

func update_debug_info() -> void:
	if !combat_system:
		debug_label.text = "No combat system reference!"
		return
	
	var info = "Combat State: " + _get_state_name(combat_system.current_state) + "\n"
	info += "Round: " + str(combat_system.round_count) + "\n"
	info += "Current Index: " + str(combat_system.current_combatant_index) + "/" + str(combat_system.turn_order.size()) + "\n\n"
	
	info += "Turn Order:\n"
	for i in range(combat_system.turn_order.size()):
		var combatant = combat_system.turn_order[i]
		var prefix = "→ " if i == combat_system.current_combatant_index else "   "
		info += prefix + combatant.display_name + " (HP: " + str(combatant.current_hp) + ")\n"
	
	info += "\nPlayer Team:\n"
	for combatant in combat_system.player_combatants:
		info += "- " + combatant.display_name + " (HP: " + str(combatant.current_hp) + "/" + str(combatant.max_hp) + ")\n"
	
	info += "\nEnemy Team:\n"
	for combatant in combat_system.enemy_combatants:
		info += "- " + combatant.display_name + " (HP: " + str(combatant.current_hp) + "/" + str(combatant.max_hp) + ")\n"
	
	debug_label.text = info

func _on_round_started() -> void:
	update_debug_info()

func _on_turn_started(_combatant: Combatant) -> void:
	update_debug_info()

func _get_state_name(state: int) -> String:
	match state:
		CombatSystem.CombatState.SETUP:
			return "Setup"
		CombatSystem.CombatState.COMBAT_STARTING:
			return "Combat Starting"
		CombatSystem.CombatState.TURN_ACTIVE:
			return "Turn Active"
		CombatSystem.CombatState.COMBAT_ENDED:
			return "Combat Ended"
		_:
			return "Unknown"