@tool
extends EditorProperty

# The dropdown control
var dropdown = OptionButton.new()

# Flag to avoid infinite loops when setting the property
var updating = false

func _init():
    # Create the dropdown with minimal sizing
    dropdown.custom_minimum_size.x = 200
    add_child(dropdown)
    
    # Load damage types from the config
    load_damage_types()
    
    # Connect to the option change signal
    dropdown.item_selected.connect(_on_dropdown_selected)

# Load damage types from the config file    
func load_damage_types():
    var config_path = "res://config/damage_types.json"
    var file = FileAccess.open(config_path, FileAccess.READ)
    
    if not file:
        push_error("Failed to open damage_types.json - Error code: " + str(FileAccess.get_open_error()))
        # Add a default option at least
        dropdown.add_item("physical")
        dropdown.set_item_metadata(0, "physical")
        return
        
    var json_text = file.get_as_text()
    file.close()
    
    var json_result = JSON.parse_string(json_text)
    
    if json_result == null:
        push_error("Failed to parse damage_types.json")
        # Add a default option at least
        dropdown.add_item("physical")
        dropdown.set_item_metadata(0, "physical")
        return
        
    var damage_types = json_result.get("damage_types", {})
    
    # Add each damage type to the dropdown
    var index = 0
    for damage_id in damage_types.keys():
        var type_data = damage_types[damage_id]
        var display_name = type_data.get("name", damage_id.capitalize())
        
        # Add the item with basic info
        dropdown.add_item(display_name)
        dropdown.set_item_metadata(index, damage_id)
        
        index += 1

func _on_dropdown_selected(index):
    if updating:
        return
        
    if index >= 0 and index < dropdown.item_count:
        var selected_id = dropdown.get_item_metadata(index)
        emit_changed(get_edited_property(), selected_id)

func update_property():
    var new_value = get_edited_object()[get_edited_property()]
    
    updating = true
    
    # Find the index for this value
    var found = false
    for i in range(dropdown.item_count):
        if dropdown.get_item_metadata(i) == new_value:
            dropdown.select(i)
            found = true
            break
    
    if not found:
        # If not found, add this value
        if not new_value.is_empty():
            # Add the unknown value as an item
            dropdown.add_item(new_value.capitalize() + " (Unknown)")
            dropdown.set_item_metadata(dropdown.item_count - 1, new_value)
            dropdown.select(dropdown.item_count - 1)
        elif dropdown.item_count > 0:
            dropdown.select(0)
    
    updating = false