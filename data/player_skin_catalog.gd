## Catálogo de skins del jugador (misma plantilla 4×5 direcciones que Eris 16×16).
class_name PlayerSkinCatalog
extends RefCounted

const SKIN_BLUE_CAT: String = "blue_cat"
const SKIN_MAGE_GIRL: String = "mage_girl"

const _ERIS_BASE: String = "res://assets/sprites/player/Eris Esra's Character Template 4.1/16x16/"


static func get_all_skins() -> Array[Dictionary]:
	return [get_skin(SKIN_BLUE_CAT), get_skin(SKIN_MAGE_GIRL)]


static func get_skin(skin_id: String) -> Dictionary:
	match skin_id:
		SKIN_MAGE_GIRL:
			return {
				"id": SKIN_MAGE_GIRL,
				"display_name": "Maga",
				"description": "Personaje humano (hoja 96×120, celdas 24×24).",
				"idle_sheet": _ERIS_BASE + "16x16 Idle-Sheetmage.png",
				"walk_sheet": _ERIS_BASE + "16x16 Walk-Sheetmage.png",
				"frame_px": 0,
				"hframes": 4,
				"vframes": 5,
				"use_scene_default": false,
				"preview_frame": Vector2i(1, 0),
			}
		_:
			return {
				"id": SKIN_BLUE_CAT,
				"display_name": "Gato azul",
				"description": "Personaje actual del juego (hoja Eris / escena Player).",
				"idle_sheet": _ERIS_BASE + "16x16 Idle-Sheet.png",
				"walk_sheet": _ERIS_BASE + "16x16 Walk-Sheet.png",
				"frame_px": 24,
				"hframes": 4,
				"vframes": 5,
				"use_scene_default": true,
				"preview_frame": Vector2i(1, 0),
			}


static func is_valid(skin_id: String) -> bool:
	return skin_id == SKIN_BLUE_CAT or skin_id == SKIN_MAGE_GIRL


static func get_default_skin_id() -> String:
	return SKIN_BLUE_CAT
