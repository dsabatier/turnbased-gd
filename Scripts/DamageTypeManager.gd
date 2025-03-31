# DamageTypeManager.gd (Updated for effective stats)
class_name DamageTypeManager
extends Node

# Damage types loaded from config
var damage_types = {}

# Default damage type for fallback
var default_damage_type = "physical"

func _ready() -> void:
    load_damage_types()
    
func load_damage_types() -> void:
    var file_path = "res://config/damage_types.json"
    var file = FileAccess.open(file_path, FileAccess.READ)
    
    if not file:
        push_error("Failed to open damage_types.json - Error code: " + str(FileAccess.get_open_error()))
        return
        
    var json_text = file.get_as_text()
    file.close()
    
    var json_result = JSON.parse_string(json_text)
    
    if json_result == null:
        push_error("Failed to parse damage_types.json")
        return
        
    damage_types = json_result.get("damage_types", {})
    
    print("Loaded " + str(damage_types.size()) + " damage types")

func get_damage_type(type_id: String) -> Dictionary:
    if damage_types.has(type_id):
        return damage_types[type_id]
    
    push_warning("Damage type not found: " + type_id + ", using default")
    if damage_types.has(default_damage_type):
        return damage_types[default_damage_type]
    
    # Last resort fallback
    return {
        "name": "Unknown",
        "defense_stat": "physical_defense"
    }

func get_damage_type_color(type_id: String) -> Color:
    var damage_type = get_damage_type(type_id)
    if damage_type.has("color"):
        return Color(damage_type.color)
    return Color.WHITE

func calculate_damage(base_damage: int, damage_type_id: String, 
                     attacker: Combatant, defender: Combatant) -> Dictionary:
    var damage_type = get_damage_type(damage_type_id)
    var modified_damage = base_damage
    var flags = {
        "resisted": false,
        "weak": false,
        "immune": false
    }
    
    # 1. Apply basic stat scaling based on attacker's EFFECTIVE stats
    # Physical attacks scale with physical_attack, magical with magic_attack
    if damage_type_id == "physical" or damage_type_id == "pure":
        modified_damage += int(base_damage * (attacker.get_effective_physical_attack() / 100.0))
    else:
        modified_damage += int(base_damage * (attacker.get_effective_magic_attack() / 100.0))
    
    # 2. Check for resistances/weaknesses directly on the defender
    if defender.has_method("get_damage_resistance"):
        var resistance = defender.get_damage_resistance(damage_type_id)
        
        # Record effectiveness flags
        if resistance < 0.75:  # More than 25% resistant
            flags.resisted = true
        elif resistance > 1.5:  # More than 50% weak
            flags.weak = true
        elif resistance == 0:   # Completely immune
            flags.immune = true
            
        # Apply resistance multiplier
        modified_damage = int(modified_damage * resistance)
    
    # 3. Apply defense stat reduction if applicable (using EFFECTIVE defense)
    if damage_type.has("defense_stat") and damage_type.defense_stat != null:
        var defense = 0
        if damage_type.defense_stat == "physical_defense":
            defense = defender.get_effective_physical_defense()
        elif damage_type.defense_stat == "magic_defense":
            defense = defender.get_effective_magic_defense()
            
        var defense_reduction = int(modified_damage * (defense / 100.0))
        modified_damage = max(1, modified_damage - defense_reduction)
    
    # Return both the calculated damage and effect flags
    return {
        "damage": max(1, modified_damage), # Minimum 1 damage
        "type": damage_type_id,
        "flags": flags
    }

func apply_damage_result(result: Dictionary, attacker: Combatant, defender: Combatant) -> Dictionary:
    var response = {
        "damage_dealt": 0
    }
    
    # Apply the damage to the defender
    if defender and defender.has_method("take_damage"):
        response.damage_dealt = defender.take_damage(result.damage)
    
    return response