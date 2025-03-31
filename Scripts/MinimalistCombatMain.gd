# MinimalistCombatMain.gd - Updated for data-driven damage types
extends Node

@onready var combat_ui = $MinimalistCombat
@onready var combat_system = $MinimalistCombat/CombatSystem

func _ready() -> void:
    # Wait for one frame to ensure all nodes are initialized
    await get_tree().process_frame
    
    # Safety check for node references
    if not combat_system:
        push_error("Failed to find CombatSystem node")
        return
    
    if not combat_ui:
        push_error("Failed to find MinimalistCombat node")
        return
    
    # Set up combat system reference on UI
    if combat_ui:
        print("Setting combat_system on combat_ui")
        combat_ui.combat_system = combat_system
    else:
        push_error("combat_ui reference is null")
    
    # Check if we're coming from character selection
    if CombatantDatabase.get_selected_party().size() > 0 and CombatantDatabase.get_selected_enemies().size() > 0:
        # Use the selected combatants
        setup_selected_combatants()
    else:
        # Create example combatants for testing
        var combatants = create_example_combatants()
        
        # Add all combatants as children
        for combatant in combatants:
            add_child(combatant)
            
        # Make sure combatants are properly initialized
        for combatant in combatants:
            combatant._ready()
        
        # Register first 3 combatants as players, rest as enemies
        combat_system.player_combatants = combatants.slice(0, 3)
        combat_system.cpu_combatants = combatants.slice(3)
    
    # Start the combat
    combat_system.start()

func setup_selected_combatants() -> void:
    var player_combatants: Array[Combatant] = CombatantDatabase.get_selected_party()
    var enemy_combatants: Array[Combatant] = CombatantDatabase.get_selected_enemies()
    
    # Debug: Output combatant information
    print("Player combatants: ", player_combatants.size())
    print("Enemy combatants: ", enemy_combatants.size())
    
    # Ensure all combatants have the correct is_player value
    for combatant in player_combatants:
        combatant.is_player = true
    
    for combatant in enemy_combatants:
        combatant.is_player = false
    
    # Add all combatants as children (required for signals to work)
    for combatant in player_combatants + enemy_combatants:
        # Initialize signals when adding as child
        combatant._ready()
        add_child(combatant)
    
    # Register combatants with the combat system
    combat_system.player_combatants = player_combatants
    combat_system.cpu_combatants = enemy_combatants

# Helper function to safely load ability from a resource
func load_ability_from_resource(path: String) -> Ability:
    var resource = load(path)

    if resource is AbilityResource:
        return resource.create_ability_instance()
    return null

# Updated create_example_combatants function
func create_example_combatants() -> Array:
    # Try to load abilities from resources first
    var slash_ability = load_ability_from_resource("res://Resources/Abilities/slash.tres")
    if slash_ability == null:
        # If resource doesn't exist, create programmatically as fallback
        slash_ability = AbilityFactory.create_damage_ability(
            "Slash", 
            15, 
            Ability.TargetType.ENEMY, 
            "A strong sword slash"
        )
    
    var fireball_ability = load_ability_from_resource("res://Resources/Abilities/fireball.tres")
    if fireball_ability == null:
        fireball_ability = AbilityFactory.create_damage_ability(
            "Fireball", 
            20, 
            Ability.TargetType.ENEMY, 
            "A ball of fire", 
            "", 
            10, 
            "fire"  # Use string ID instead of enum
        )
    
    # Create a warrior
    var warrior: Combatant = Combatant.new()
    warrior.name = "Warrior"
    warrior.display_name = "Warrior"
    warrior.max_hp = 120
    warrior.current_hp = 120
    warrior.max_mp = 40
    warrior.current_mp = 40
    warrior.physical_attack = 20
    warrior.magic_attack = 5
    warrior.physical_defense = 18
    warrior.magic_defense = 8
    warrior.speed = 8
    warrior.is_player = true
    
    # Add resistances
    warrior.damage_resistances = {
        "physical": 0.9  # Slight resistance to physical
    }
    
    warrior.abilities = [
        slash_ability,
        AbilityFactory.create_damage_ability(
            "Heavy Strike", 
            25, 
            Ability.TargetType.ENEMY, 
            "A powerful but slower attack", 
            "", 
            10
        ),
        AbilityFactory.create_damage_reduction_ability(
            "Defend", 
            30, 
            2, 
            Ability.TargetType.SELF, 
            "Prepare to block incoming attacks", 
            "", 
            5
        ),
        AbilityFactory.create_skip_turn_ability("Skip Turn", "Skip this turn")
    ]
    
    # Create a wizard
    var wizard: Combatant = Combatant.new()
    wizard.name = "Wizard"
    wizard.display_name = "Wizard"
    wizard.max_hp = 70
    wizard.current_hp = 70
    wizard.max_mp = 100
    wizard.current_mp = 100
    wizard.physical_attack = 5
    wizard.magic_attack = 22
    wizard.physical_defense = 6
    wizard.magic_defense = 15
    wizard.speed = 10
    wizard.is_player = true
    
    # Add resistances
    wizard.damage_resistances = {
        "magical": 0.9,  # Slight resistance to magical
        "fire": 0.8      # Moderate resistance to fire
    }
    
    wizard.abilities = [
        fireball_ability,
        AbilityFactory.create_dot_ability(
            "Poison", 
            8, 
            3, 
            Ability.TargetType.ENEMY, 
            "Poisons enemy for 3 turns", 
            "", 
            15, 
            "poison"  # Use string ID instead of enum
        ),
        AbilityFactory.create_mp_restore_ability(
			"Meditate", 
			15,  # Restore 15 MP
			Ability.TargetType.SELF, 
			"Restore 15 MP", 
			"{user} meditates and restores {power} MP!"
    )
    ]
    
    # Create a cleric
    var cleric: Combatant = Combatant.new()
    cleric.name = "Cleric"
    cleric.display_name = "Cleric"
    cleric.max_hp = 90
    cleric.current_hp = 90
    cleric.max_mp = 85
    cleric.current_mp = 85
    cleric.physical_attack = 8
    cleric.magic_attack = 15
    cleric.physical_defense = 12
    cleric.magic_defense = 18
    cleric.speed = 7
    cleric.is_player = true
    
    # Add resistances
    wizard.damage_resistances = {
        "holy": 0.7  # Good resistance to holy damage
    }
    
    cleric.abilities = [
        AbilityFactory.create_damage_ability(
            "Smite", 
            15, 
            Ability.TargetType.ENEMY, 
            "A holy attack", 
            "", 
            5, 
            "holy"  # Use string ID instead of enum
        ),
        AbilityFactory.create_healing_ability(
            "Heal", 
            20, 
            Ability.TargetType.FRIENDLY, 
            "Heals an ally", 
            "", 
            10
        ),
        AbilityFactory.create_hot_ability(
            "Regeneration", 
            8, 
            3, 
            Ability.TargetType.FRIENDLY, 
            "Healing over time", 
            "", 
            15
        ),
        AbilityFactory.create_skip_turn_ability("Skip Turn", "Skip this turn")
    ]
    
    # Create an orc
    var orc: Combatant = Combatant.new()
    orc.name = "Orc Bruiser"
    orc.display_name = "Orc Bruiser"
    orc.max_hp = 95
    orc.current_hp = 95
    orc.max_mp = 30
    orc.current_mp = 30
    orc.physical_attack = 18
    orc.magic_attack = 2
    orc.physical_defense = 12
    orc.magic_defense = 5
    orc.speed = 6
    orc.is_player = false
    
    # Add resistances
    orc.damage_resistances = {
        "physical": 0.8,  # Good resistance to physical
        "magical": 1.2    # Slight weakness to magical
    }
    
    orc.abilities = [
        AbilityFactory.create_damage_ability(
            "Club Smash", 
            18, 
            Ability.TargetType.ENEMY, 
            "A heavy club attack"
        ),
        AbilityFactory.create_healing_ability(
            "Crude Potion", 
            12, 
            Ability.TargetType.SELF, 
            "Drinks a healing potion", 
            "", 
            8
        )
    ]
    
    # Create a dark mage
    var dark_mage: Combatant = Combatant.new()
    dark_mage.name = "Dark Mage"
    dark_mage.display_name = "Dark Mage"
    dark_mage.max_hp = 65
    dark_mage.current_hp = 65
    dark_mage.max_mp = 80
    dark_mage.current_mp = 80
    dark_mage.physical_attack = 3
    dark_mage.magic_attack = 18
    dark_mage.physical_defense = 5
    dark_mage.magic_defense = 15
    dark_mage.speed = 8
    dark_mage.is_player = false
    
    # Add resistances
    dark_mage.damage_resistances = {
        "holy": 1.5,      # Weakness to holy
        "necrotic": 0.5   # Strong resistance to necrotic
    }
    
    dark_mage.abilities = [
        AbilityFactory.create_damage_ability(
            "Shadow Bolt", 
            14, 
            Ability.TargetType.ENEMY, 
            "A bolt of dark energy",
            "",
            5,
            "necrotic"  # Use string ID instead of enum
        ),
        AbilityFactory.create_dot_ability(
            "Curse", 
            6, 
            3, 
            Ability.TargetType.ENEMY, 
            "A curse that deals damage over time",
            "",
            10,
            "necrotic"  # Use string ID instead of enum
        )
    ]
    
    # Create a giant spider
    var spider: Combatant = Combatant.new()
    spider.name = "Giant Spider"
    spider.display_name = "Giant Spider"
    spider.max_hp = 75
    spider.current_hp = 75
    spider.max_mp = 40
    spider.current_mp = 40
    spider.physical_attack = 12
    spider.magic_attack = 8
    spider.physical_defense = 10
    spider.magic_defense = 10
    spider.speed = 14
    spider.is_player = false
    
    # Add resistances
    spider.damage_resistances = {
        "poison": 0.0  # Immune to poison
    }
    
    spider.abilities = [
        AbilityFactory.create_damage_ability(
            "Bite", 
            10, 
            Ability.TargetType.ENEMY, 
            "A venomous bite"
        ),
        AbilityFactory.create_dot_ability(
            "Web", 
            5, 
            4, 
            Ability.TargetType.ENEMY, 
            "Ensnares target in sticky web",
            "",
            8,
            "physical"  # Use string ID instead of enum
        )
    ]
    
    return [warrior, wizard, cleric, orc, dark_mage, spider]