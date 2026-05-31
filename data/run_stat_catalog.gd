## Mejoras de tómbola globales (cualquier clase, máx. nivel 5, +5% por nivel).
class_name RunStatCatalog
extends RefCounted

const MAX_STAT_LEVEL: int = 5
const BONUS_PER_LEVEL: float = 0.05

const STAT_MOVE_SPEED: String = "stat_move_speed"
const STAT_ATTACK_SPEED: String = "stat_attack_speed"
const STAT_COOLDOWN_REDUCTION: String = "stat_cooldown_reduction"
const STAT_XP_GAIN: String = "stat_xp_gain"
const STAT_COMMERCIAL_LUCK: String = "stat_commercial_luck"
const STAT_MAX_HP: String = "stat_max_hp"

const ALL_STAT_IDS: Array[String] = [
	STAT_MOVE_SPEED,
	STAT_ATTACK_SPEED,
	STAT_COOLDOWN_REDUCTION,
	STAT_XP_GAIN,
	STAT_COMMERCIAL_LUCK,
	STAT_MAX_HP,
]

static var _DEFINITIONS: Dictionary = {
	STAT_MOVE_SPEED: {
		"title": "Velocidad de movimiento",
		"description": "+5% velocidad por nivel (máx. +25%).",
	},
	STAT_ATTACK_SPEED: {
		"title": "Velocidad de ataque",
		"description": "+5% cadencia de habilidades automáticas por nivel (máx. +25%).",
	},
	STAT_COOLDOWN_REDUCTION: {
		"title": "Reducción de cooldown",
		"description": "-5% recarga de habilidades activas por nivel (máx. -25%).",
	},
	STAT_XP_GAIN: {
		"title": "Experiencia",
		"description": "+5% EXP ganada por nivel (máx. +25%).",
	},
	STAT_COMMERCIAL_LUCK: {
		"title": "Suerte comercial",
		"description": "+5% Zeny y probabilidad de drops por nivel (máx. +25%).",
	},
	STAT_MAX_HP: {
		"title": "Salud máxima",
		"description": "+5% HP máximo por nivel; cura la vida plana añadida al subir.",
	},
}


static func get_definition(stat_id: String) -> Dictionary:
	var def: Dictionary = _DEFINITIONS.get(stat_id, {}).duplicate()
	def["id"] = stat_id
	return def


static func get_bonus_fraction(level: int) -> float:
	return float(clampi(level, 0, MAX_STAT_LEVEL)) * BONUS_PER_LEVEL
