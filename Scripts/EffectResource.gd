class_name EffectResource
extends Resource

enum EffectType { Healing, Damage, None }

@export var display_name : String = "Null Effect"
@export var Power : int = 1
@export var status_effect : StatusEffectResource
