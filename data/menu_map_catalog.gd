## Datos de presentación para la pantalla de selección de mapa.
class_name MenuMapCatalog
extends RefCounted

const _MapConfig = preload("res://data/map_config.gd")
const _EnemyCatalog = preload("res://data/enemy_catalog.gd")

const PRONTERA_PREVIEW: String = "res://art/maps/prontera.jpg"
const PAYON_PREVIEW: String = "res://art/maps/payon.jpg"


static func get_all_entries() -> Array[Dictionary]:
	return [
		_build_prontera(),
		_build_payon(),
		_build_orc_village(),
	]


static func get_entry(map_id: String) -> Dictionary:
	for entry: Dictionary in get_all_entries():
		if String(entry.get("id", "")) == map_id:
			return entry
	return {}


static func _build_prontera() -> Dictionary:
	return {
		"id": _MapConfig.MAP_PRONTERA,
		"title": "Prontera Outskirts",
		"difficulty_label": "Fácil",
		"description": "Praderas abiertas al sur de Prontera. Ideal para farmear Zeny y aprender el combate.",
		"preview_tint": Color(0.04, 0.06, 0.1, 0.28),
		"preview_texture": PRONTERA_PREVIEW,
		"mob_type_ids": [
			_EnemyCatalog.TYPE_PORING,
			_EnemyCatalog.TYPE_LUNATIC,
			_EnemyCatalog.TYPE_FABRE,
		],
		"boss_type_id": _EnemyCatalog.TYPE_CREAMY,
		"boss_discovered_flag": "boss_1_discovered",
		"unlock_requires_map_cleared": "",
	}


static func _build_payon() -> Dictionary:
	return {
		"id": _MapConfig.MAP_PAYON,
		"title": "Payon Dungeon",
		"difficulty_label": "Media–Alta",
		"description": "Bosque y cuevas de Payon. Enemigos más resistentes y mayor recompensa.",
		"preview_tint": Color(0.03, 0.05, 0.08, 0.32),
		"preview_texture": PAYON_PREVIEW,
		"mob_type_ids": [
			_EnemyCatalog.TYPE_ZOMBIE,
			_EnemyCatalog.TYPE_SKELETON,
			_EnemyCatalog.TYPE_FAMILIAR,
		],
		"boss_type_id": _EnemyCatalog.TYPE_MOONLIGHT_FLOWER,
		"boss_discovered_flag": "boss_2_discovered",
		"unlock_requires_map_cleared": _MapConfig.MAP_PRONTERA,
	}


static func _build_orc_village() -> Dictionary:
	return {
		"id": _MapConfig.MAP_ORC_VILLAGE,
		"title": "Orc Village",
		"difficulty_label": "Endgame",
		"description": "Aldea orca al norte. Hordas rápidas, arqueros y el temible Orc Hero.",
		"preview_tint": Color(0.08, 0.12, 0.06, 0.34),
		"preview_texture": PAYON_PREVIEW,
		"mob_type_ids": [
			_EnemyCatalog.TYPE_ORC_BABY,
			_EnemyCatalog.TYPE_ORC_WARRIOR,
			_EnemyCatalog.TYPE_ORC_LADY,
			_EnemyCatalog.TYPE_ORC_ARCHER,
			_EnemyCatalog.TYPE_HIGH_ORC,
		],
		"boss_type_id": _EnemyCatalog.TYPE_ORC_HERO,
		"boss_discovered_flag": "boss_3_discovered",
		"unlock_requires_map_cleared": _MapConfig.MAP_PAYON,
	}
