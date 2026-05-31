## Configuración de mapas: balance, spawns y jefe final.
class_name MapConfig
extends RefCounted

const MAP_PRONTERA: String = "prontera_fields"
const MAP_PAYON: String = "payon_dungeon"

const BOSS_SPAWN_SECONDS: float = 540.0


static func get_definition(map_id: String) -> Dictionary:
	match map_id:
		MAP_PAYON:
			return {
				"id": MAP_PAYON,
				"display_name": "Payon Dungeon",
				"hp_multiplier": 2.0,
				"damage_multiplier": 1.5,
				"background_scene": "res://scenes/world/PayonBackground.tscn",
				"boss_scene_key": "osiris",
				"bgm_path": "res://assets/audio/bgm_payon.ogg",
			}
		_:
			return {
				"id": MAP_PRONTERA,
				"display_name": "Prontera Fields",
				"hp_multiplier": 1.0,
				"damage_multiplier": 1.0,
				"background_scene": "res://scenes/world/FieldBackground.tscn",
				"boss_scene_key": "creamy",
				"bgm_path": "res://assets/audio/bgm_field.mp3",
			}


static func get_bgm_path(map_id: String) -> String:
	return String(get_definition(map_id).get("bgm_path", ""))
