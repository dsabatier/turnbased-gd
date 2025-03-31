@tool
extends EditorPlugin

const DamageTypeEditorProperty = preload("res://addons/damage_types/damage_type_editor_property.gd")

func _enter_tree():
    # Register the custom property editor
    add_custom_property_editor("damage_type_id", DamageTypeEditorProperty)

func _exit_tree():
    # Remove the custom property editor when the plugin is disabled
    # No explicit cleanup needed for property editors added this way
    pass

func add_custom_property_editor(property_name: String, property_editor_class):
    # Create a custom inspector plugin
    var inspector_plugin = create_custom_inspector_plugin()
    inspector_plugin.property_name = property_name
    inspector_plugin.property_editor_class = property_editor_class
    add_inspector_plugin(inspector_plugin)
    return inspector_plugin

# Custom inspector plugin implementation
class DamageTypeInspectorPlugin extends EditorInspectorPlugin:
    var property_name: String
    var property_editor_class
    
    func _can_handle(object):
        # Return true to handle all objects - we'll filter by property name
        return true
    
    func _parse_property(object, type, name, hint_type, hint_string, usage_flags, wide):
        # Only handle the specific property we want
        if name == property_name:
            # Create our custom property editor
            var editor = property_editor_class.new()
            add_property_editor(name, editor)
            return true
        return false
    
func create_custom_inspector_plugin():
    return DamageTypeInspectorPlugin.new()