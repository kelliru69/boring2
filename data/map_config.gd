## Configuración de mapas: balance, spawns y jefe final.
class_name MapConfig
extends RefCounted

const MAP_PRONTERA: String = "prontera_fields"
const MAP_PAYON: String = "payon_dungeon"
const MAP_ORC_VILLAGE: String = "orc_village"

const BOSS_SPAWN_SECONDS: float = 540.0

## Mapa 2 (Payon) — referencia de dificultad intermedia.
const MAP2_HP_MULTIPLIER: float = 2.2
const MAP2_DAMAGE_MULTIPLIER: float = 1.55

## Mapa 3 debe sentirse ~4× más exigente que Mapa 2 (misma run, tras Job Change).
const MAP3_VS_MAP2_FACTOR: float = 4.0
const MAP3_HP_MULTIPLIER: float = MAP2_HP_MULTIPLIER * MAP3_VS_MAP2_FACTOR
const MAP3_DAMAGE_MULTIPLIER: float = MAP2_DAMAGE_MULTIPLIER * MAP3_VS_MAP2_FACTOR

## Poder esperado del jugador evolucionado al entrar a Orc Village (fin Mapa 2).
const MAP3_EVOLVED_HP_MULT: float = 2.0
const MAP3_EVOLVED_ATTACK_MULT: float = 3.0


static func get_definition(map_id: String) -> Dictionary:
	match map_id:
		MAP_ORC_VILLAGE:
			return {
				"id": MAP_ORC_VILLAGE,
				"display_name": "Orc Village",
				"hp_multiplier": MAP3_HP_MULTIPLIER,
				"damage_multiplier": MAP3_DAMAGE_MULTIPLIER,
				"xp_multiplier": 7.0,
				"spawn_interval_multiplier": 0.82,
				"max_enemies_bonus": 22,
				"background_scene": "res://scenes/world/OrcVillageBackground.tscn",
				"boss_scene_key": "orc_hero",
				"bgm_path": "res://assets/audio/bgm_orc_village.mp3",
			}
		MAP_PAYON:
			return {
				"id": MAP_PAYON,
				"display_name": "Payon Dungeon",
				"hp_multiplier": MAP2_HP_MULTIPLIER,
				"damage_multiplier": MAP2_DAMAGE_MULTIPLIER,
				"xp_multiplier": 2.475, # +50% sobre el valor anterior (1.65)
				"spawn_interval_multiplier": 0.9,
				"max_enemies_bonus": 14,
				"background_scene": "res://scenes/world/PayonBackground.tscn",
				"boss_scene_key": "moonlight_flower",
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


static func get_map_tier(map_id: String) -> int:
	match map_id:
		MAP_ORC_VILLAGE:
			return 3
		MAP_PAYON:
			return 2
		_:
			return 1


## Mapas cuyo Zeny solo alimenta la tienda de campaña (Orc Village en adelante).
static func is_campaign_tier_map(map_id: String) -> bool:
	return get_map_tier(map_id) >= 3
