# MinimalistCombatUI.gd - Updated for data-driven damage types
extends Control

@export var combat_system: CombatSystem

# Node references
@onready var combat_log_window = $CombatLogWindow
@onready var ability_popup = $AbilityPopup
@onready var ability_container = $AbilityPopup/AbilityContainer
@onready var ability_title = $AbilityPopup/TitleBar/TitleLabel
@onready var target_popup = $TargetPopup
@onready var target_container = $TargetPopup/TargetContainer
@onready var target_title = $TargetPopup/TitleBar/TitleLabel
@onready var log_text = $CombatLogWindow/LogText
@onready var player_container = $BattleArea/PlayerContainer
@onready var enemy_container = $BattleArea/EnemyContainer

# Scene references
const CombatantViewScene = preload("res://Scenes/combatant_view.tscn")

# References to combatant views
var player_views = []
var enemy_views = []

# Track current combat state
var selected_ability = -1
var current_combatant = null

# Reference to the damage type manager
var damage_manager = null

func _ready():
    # Try to get the DamageTypeManager singleton
    if Engine.has_singleton("DamageTypeManager"):
        damage_manager = Engine.get_singleton("DamageTypeManager")
    
    # Set up log toggle button
    $LogToggleButton.pressed.connect(_toggle_combat_log)
    $CombatLogWindow/CloseButton.pressed.connect(_close_combat_log)
    
    # Initialize with all popups hidden
    combat_log_window.visible = false
    ability_popup.visible = false
    target_popup.visible = false
    
    # Connect navigation buttons
    $ButtonContainer/BackToMenuButton.pressed.connect(return_to_menu)
    $ButtonContainer/BackToSelectionButton.pressed.connect(return_to_selection)
    
    log_text.text = "Waiting for combat to start...\n"
    
    # We'll connect the signals once the combat_system is properly set
    call_deferred("_connect_combat_signals")

func _connect_combat_signals():
    # Safety check - make sure combat_system exists before connecting signals
    if combat_system:
        # Connect signals from combat system
        if not combat_system.is_connected("combat_log_updated", _on_combat_log_updated):
            combat_system.combat_log_updated.connect(_on_combat_log_updated)
        
        if not combat_system.is_connected("turn_started", _on_turn_started):
            combat_system.turn_started.connect(_on_turn_started)
        
        if not combat_system.is_connected("combat_ended", _on_combat_ended):
            combat_system.combat_ended.connect(_on_combat_ended)
        
        if not combat_system.is_connected("combat_started", _on_combat_started):
            combat_system.combat_started.connect(_on_combat_started)
        
        print("Combat signals connected successfully")
    else:
        print("WARNING: combat_system is null, signals not connected")
        # Try again after a short delay
        await get_tree().create_timer(0.5).timeout
        _connect_combat_signals()

func _on_combat_started():
    # Safety check
    if not combat_system:
        push_error("Combat system is null in _on_combat_started")
        return
    
    # Clear existing views
    for child in player_container.get_children():
        child.queue_free()
    for child in enemy_container.get_children():
        child.queue_free()
    
    player_views.clear()
    enemy_views.clear()
    
    # Create views for player combatants
    for combatant in combat_system.player_combatants:
        var view = CombatantViewScene.instantiate()
        player_container.add_child(view)
        view.setup(combatant, true)
        view.clicked.connect(_on_player_combatant_clicked)
        player_views.append(view)
        print("Added player view for: " + combatant.display_name)
    
    # Create views for CPU combatants
    for combatant in combat_system.cpu_combatants:
        var view = CombatantViewScene.instantiate()
        enemy_container.add_child(view)
        view.setup(combatant, false)
        view.clicked.connect(_on_enemy_combatant_clicked)
        enemy_views.append(view)
        print("Added enemy view for: " + combatant.display_name)
    
    log_text.text = "Combat started!\n"
    
    # Setup for first turn
    if combat_system.current_turn_index < combat_system.turn_order.size():
        var first_combatant = combat_system.turn_order[combat_system.current_turn_index]
        _highlight_active_combatant(first_combatant)
        
        if first_combatant.is_player:
            _show_abilities_for_combatant(first_combatant)

func _on_player_combatant_clicked(combatant_view):
    # Debug output
    print("Player combatant clicked: " + combatant_view.combatant.display_name)
    
    # Only process click if we're selecting a target for an ability
    if selected_ability >= 0 and current_combatant and current_combatant.is_player:
        var ability = current_combatant.abilities[selected_ability]
        
        # Check if this is a valid target
        var target_combatant = combatant_view.combatant
        
        if target_combatant and not target_combatant.is_defeated:
            # Check target type compatibility
            var is_valid_target = false
            
            match ability.target_type:
                Ability.TargetType.FRIENDLY:
                    is_valid_target = target_combatant.is_player
                Ability.TargetType.OTHER_FRIENDLY:
                    is_valid_target = target_combatant.is_player and target_combatant != current_combatant
                Ability.TargetType.ANY:
                    is_valid_target = true
            
            if is_valid_target:
                print("Executing ability: " + ability.name + " on target: " + target_combatant.display_name)
                
                # Apply the ability to the target
                combat_system.process_turn(selected_ability, target_combatant)
                
                # Hide popups
                target_popup.visible = false
                ability_popup.visible = false
                selected_ability = -1
                
                # Reset dimming
                _reset_combatant_dimming()

func _on_enemy_combatant_clicked(combatant_view):
    # Debug output
    print("Enemy combatant clicked: " + combatant_view.combatant.display_name)
    
    # Only process click if we're selecting a target for an ability
    if selected_ability >= 0 and current_combatant and current_combatant.is_player:
        var ability = current_combatant.abilities[selected_ability]
        
        # Check if this is a valid target
        var target_combatant = combatant_view.combatant
        
        if target_combatant and not target_combatant.is_defeated:
            # Check target type compatibility
            var is_valid_target = false
            
            match ability.target_type:
                Ability.TargetType.ENEMY:
                    is_valid_target = !target_combatant.is_player
                Ability.TargetType.ANY:
                    is_valid_target = true
            
            if is_valid_target:
                print("Executing ability: " + ability.name + " on target: " + target_combatant.display_name)
                
                # Apply the ability to the target
                combat_system.process_turn(selected_ability, target_combatant)
                
                # Hide popups
                target_popup.visible = false
                ability_popup.visible = false
                selected_ability = -1
                
                # Reset dimming
                _reset_combatant_dimming()

func _reset_combatant_dimming():
    # Reset visual highlights
    for view in player_views + enemy_views:
        view.modulate = Color(1, 1, 1, 1)

func _on_combat_log_updated(message: String):
    log_text.text += message + "\n"
    # Make sure log scrolls to bottom
    log_text.scroll_to_paragraph(log_text.get_paragraph_count() - 1)

func _on_turn_started(combatant: Combatant):
    print("Turn started for: " + combatant.display_name + " (is_player: " + str(combatant.is_player) + ")")
    
    current_combatant = combatant
    
    # Hide any open popups
    ability_popup.visible = false
    target_popup.visible = false
    
    # Reset visual state
    _reset_combatant_dimming()
    
    # Highlight the active combatant
    _highlight_active_combatant(combatant)
    
    log_text.text += "It's " + combatant.display_name + "'s turn!\n"
    
    # If it's a player's turn, show abilities
    if combatant.is_player:
        call_deferred("_show_abilities_for_combatant", combatant)

func _highlight_active_combatant(combatant):
    # Clear all highlights first
    for view in player_views + enemy_views:
        view.set_highlighted(false)
    
    # Find and highlight the active combatant
    var found = false
    for view in player_views + enemy_views:
        if view.combatant == combatant:
            view.set_highlighted(true)
            found = true
            break
    
    if not found:
        print("WARNING: Could not find view for combatant: " + combatant.display_name)

func _show_abilities_for_combatant(combatant):
    print("Showing abilities for: " + combatant.display_name + " with " + str(combatant.abilities.size()) + " abilities")
    
    # Clear existing abilities
    for child in ability_container.get_children():
        child.queue_free()
    
    # Set title
    ability_title.text = combatant.display_name + "'s Abilities"
    
    # Create button for each ability
    for i in range(combatant.abilities.size()):
        var ability = combatant.abilities[i]
        
        # Skip if ability is null
        if ability == null:
            print("WARNING: Null ability found at index " + str(i) + " for " + combatant.display_name)
            continue
            
        var button = Button.new()
        button.custom_minimum_size = Vector2(0, 40)
        
        # Create ability name text with MP cost if applicable
        var ability_text = ability.name if ability.name else "Unknown Ability"
        
        # Add damage type info if available using the DamageTypeManager
        if ability.has_method("get") and ability.get("effect_type") == Ability.EffectType.DAMAGE and ability.get("damage_type_id") != null:
            var damage_type_name = "Physical" # Default
            var damage_type_color = Color.WHITE
            
            if damage_manager:
                # Get type info from the manager
                var damage_type = damage_manager.get_damage_type(ability.damage_type_id)
                
                if damage_type:
                    # Use the proper name from the config
                    damage_type_name = damage_type.get("name", ability.damage_type_id.capitalize())
                    
                    # Use the color from the config if available
                    if damage_type.has("color"):
                        damage_type_color = Color(damage_type.color)
            else:
                # Fallback if no manager - just capitalize the ID
                damage_type_name = ability.damage_type_id.capitalize()
            
            ability_text += " (" + damage_type_name + ")"
            
            # Apply color to button text if possible
            button.add_theme_color_override("font_color", damage_type_color)
        
        # Add MP cost if applicable
        if ability.has_method("get") and ability.get("mp_cost") != null and ability.mp_cost > 0:
            ability_text += " [MP: " + str(ability.mp_cost) + "]"
            
            # Disable button if not enough MP
            if combatant.current_mp < ability.mp_cost:
                button.disabled = true

        button.text = ability_text
        
        # Add description as tooltip
        if ability.has_method("get") and ability.get("description") != null:
            button.tooltip_text = ability.description

        # Connect button signal
        button.pressed.connect(_on_ability_selected.bind(i))
        ability_container.add_child(button)

    # Show popup
    ability_popup.visible = true

func _on_ability_selected(index):
    selected_ability = index
    
    if current_combatant == null:
        print("ERROR: No current combatant")
        return
        
    if selected_ability < 0 or selected_ability >= current_combatant.abilities.size():
        print("ERROR: Invalid ability index: " + str(selected_ability))
        return
        
    var ability = current_combatant.abilities[selected_ability]
    
    if ability == null:
        print("ERROR: Null ability at index " + str(selected_ability))
        return
    
    print("Selected ability: " + ability.name + " with target type: " + str(ability.target_type))
    
    # If it's a self-targeting ability, use it immediately
    if ability.target_type == Ability.TargetType.SELF:
        print("Executing self-targeted ability: " + ability.name)
        combat_system.process_turn(selected_ability, current_combatant)
        ability_popup.visible = false
        selected_ability = -1
        return
    
    # Visually indicate valid targets
    _highlight_valid_targets(ability)
    
    # For complex target selection, show the target popup
    if ability.target_type != Ability.TargetType.ENEMY and ability.target_type != Ability.TargetType.FRIENDLY:
        _show_target_selection(ability)
        
func _highlight_valid_targets(ability):
    # Reset all highlights and modulate
    for view in player_views + enemy_views:
        view.modulate = Color(1, 1, 1, 1)
    
    # Dim invalid targets
    match ability.target_type:
        Ability.TargetType.ENEMY:
            for view in player_views:
                view.modulate = Color(0.7, 0.7, 0.7, 0.5)
        Ability.TargetType.FRIENDLY:
            for view in enemy_views:
                view.modulate = Color(0.7, 0.7, 0.7, 0.5)
        Ability.TargetType.OTHER_FRIENDLY:
            for view in enemy_views:
                view.modulate = Color(0.7, 0.7, 0.7, 0.5)
            
            # Current combatant can't be targeted with OTHER_FRIENDLY
            for view in player_views:
                if view.combatant == current_combatant:
                    view.modulate = Color(0.7, 0.7, 0.7, 0.5)

func _show_target_selection(ability):
    # Clear existing targets
    for child in target_container.get_children():
        child.queue_free()
    
    # Build target list based on ability target type
    var targets = []
    
    match ability.target_type:
        Ability.TargetType.ENEMY:
            targets = combat_system.cpu_combatants
        Ability.TargetType.FRIENDLY:
            targets = combat_system.player_combatants
        Ability.TargetType.OTHER_FRIENDLY:
            targets = combat_system.player_combatants.filter(func(c): return c != current_combatant)
        Ability.TargetType.ANY:
            targets = combat_system.player_combatants + combat_system.cpu_combatants
    
    # Create button for each valid target
    for i in range(targets.size()):
        var target = targets[i]
        
        # Skip defeated targets
        if target.is_defeated:
            continue
        
        var button = Button.new()
        button.custom_minimum_size = Vector2(0, 40)
        button.text = target.display_name + " (" + str(target.current_hp) + "/" + str(target.max_hp) + ")"
        
        # Connect button signal
        button.pressed.connect(_on_target_selected.bind(target))
        
        target_container.add_child(button)
    
    # Show target popup only if there are valid targets
    if target_container.get_child_count() > 0:
        target_popup.visible = true
        ability_popup.visible = false
    else:
        # If no valid targets, show message
        var label = Label.new()
        label.text = "No valid targets available!"
        target_container.add_child(label)
        target_popup.visible = true
        ability_popup.visible = false

func _on_target_selected(target):
    if current_combatant and selected_ability >= 0:
        print("Target selected: " + target.display_name)
        
        # Apply the ability to the target
        combat_system.process_turn(selected_ability, target)
        
        # Hide popups
        target_popup.visible = false
        ability_popup.visible = false
        selected_ability = -1
        
        # Reset visual highlights
        _reset_combatant_dimming()

func _on_combat_ended(winner: String):
    # Hide all popups
    ability_popup.visible = false
    target_popup.visible = false
    
    # Show combat log if not visible
    combat_log_window.visible = true
    
    log_text.text += "Combat has ended! " + winner + " wins!\n"

func _toggle_combat_log():
    combat_log_window.visible = !combat_log_window.visible

func _close_combat_log():
    combat_log_window.visible = false

# Navigation functions
func return_to_menu():
    get_tree().change_scene_to_file("res://Scenes/start_menu.tscn")

func return_to_selection():
    get_tree().change_scene_to_file("res://Scenes/character_selection.tscn")