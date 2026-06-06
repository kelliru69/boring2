## Mejoras de tómbola globales (cualquier clase) + exclusivas Mapa 2 por clase.
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

## Mapa 2 — solo Mage
const STAT_MYSTICAL_AMPLIFICATION: String = "stat_mystical_amplification"
const STAT_ENERGY_COAT: String = "stat_energy_coat"
const STAT_SPELL_PIERCE: String = "stat_spell_pierce"

## Mapa 2 — solo Swordman
const STAT_FATAL_BLOW: String = "stat_fatal_blow"
const STAT_SHIELD_UP: String = "stat_shield_up"
const STAT_SWORD_MASTERY: String = "stat_sword_mastery"

const MAP2_MAGE_STAT_IDS: Array[String] = [
	STAT_MYSTICAL_AMPLIFICATION,
	STAT_ENERGY_COAT,
	STAT_SPELL_PIERCE,
]

const MAP2_SWORDMAN_STAT_IDS: Array[String] = [
	STAT_FATAL_BLOW,
	STAT_SHIELD_UP,
	STAT_SWORD_MASTERY,
]

## Mapa 3 — pasivas de Job Change (por evolución).
const STAT_AOE_MASTERY: String = "stat_aoe_mastery"
const STAT_FREE_CAST: String = "stat_free_cast"
const STAT_PROJECTILE_MULT: String = "stat_projectile_mult"
const STAT_MELEE_FURY: String = "stat_melee_fury"
const STAT_GRAND_CROSS: String = "stat_grand_cross"
const STAT_SACRED_REGEN: String = "stat_sacred_regen"

const MAP3_WIZARD_STAT_IDS: Array[String] = [STAT_AOE_MASTERY]
const MAP3_SAGE_STAT_IDS: Array[String] = [STAT_FREE_CAST, STAT_PROJECTILE_MULT]
const MAP3_KNIGHT_STAT_IDS: Array[String] = [STAT_MELEE_FURY]
const MAP3_CRUSADER_STAT_IDS: Array[String] = [STAT_GRAND_CROSS, STAT_SACRED_REGEN]

const ALL_STAT_IDS: Array[String] = [
	STAT_MOVE_SPEED,
	STAT_ATTACK_SPEED,
	STAT_COOLDOWN_REDUCTION,
	STAT_XP_GAIN,
	STAT_COMMERCIAL_LUCK,
	STAT_MAX_HP,
	STAT_MYSTICAL_AMPLIFICATION,
	STAT_ENERGY_COAT,
	STAT_SPELL_PIERCE,
	STAT_FATAL_BLOW,
	STAT_SHIELD_UP,
	STAT_SWORD_MASTERY,
	STAT_AOE_MASTERY,
	STAT_FREE_CAST,
	STAT_PROJECTILE_MULT,
	STAT_MELEE_FURY,
	STAT_GRAND_CROSS,
	STAT_SACRED_REGEN,
]


static func is_map2_mage_stat(stat_id: String) -> bool:
	return stat_id in MAP2_MAGE_STAT_IDS


static func is_map2_swordman_stat(stat_id: String) -> bool:
	return stat_id in MAP2_SWORDMAN_STAT_IDS


static func is_map2_exclusive_stat(stat_id: String) -> bool:
	return is_map2_mage_stat(stat_id) or is_map2_swordman_stat(stat_id)


static func is_map3_exclusive_stat(stat_id: String) -> bool:
	return stat_id in MAP3_WIZARD_STAT_IDS \
		or stat_id in MAP3_SAGE_STAT_IDS \
		or stat_id in MAP3_KNIGHT_STAT_IDS \
		or stat_id in MAP3_CRUSADER_STAT_IDS


static func is_map3_stat_for_job(stat_id: String, job_id: String) -> bool:
	match job_id:
		Game.JOB_WIZARD:
			return stat_id in MAP3_WIZARD_STAT_IDS
		Game.JOB_SAGE:
			return stat_id in MAP3_SAGE_STAT_IDS
		Game.JOB_KNIGHT:
			return stat_id in MAP3_KNIGHT_STAT_IDS
		Game.JOB_CRUSADER:
			return stat_id in MAP3_CRUSADER_STAT_IDS
		_:
			return false


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
	STAT_MYSTICAL_AMPLIFICATION: {
		"title": "Mystical Amplification",
		"description": "+20% daño de hechizos por nivel (máx. +100%). Solo Mage en mapa 2.",
	},
	STAT_ENERGY_COAT: {
		"title": "Energy Coat",
		"description": "Escudo de 10% HP máx por nivel (máx. 50%). Regenera a full tras 8 s sin daño. Solo Mage en mapa 2.",
	},
	STAT_SPELL_PIERCE: {
		"title": "Spell Pierce",
		"description": "+10% probabilidad por nivel de que hechizos atraviesen enemigos (máx. 50%). Solo Mage en mapa 2.",
	},
	STAT_FATAL_BLOW: {
		"title": "Fatal Blow",
		"description": "+10% probabilidad por nivel de curar 1% del daño de Bash como HP (máx. 50%). Solo Swordman en mapa 2.",
	},
	STAT_SHIELD_UP: {
		"title": "Shield Up",
		"description": "Escudo de 10% HP máx por nivel (máx. 50%). Regenera a full tras 8 s sin daño. Solo Swordman en mapa 2.",
	},
	STAT_SWORD_MASTERY: {
		"title": "Sword Mastery",
		"description": "+20% daño con espada por nivel (máx. +100%). Solo Swordman en mapa 2.",
	},
	STAT_AOE_MASTERY: {
		"title": "AoE Mastery",
		"description": "+12% radio y daño AoE por nivel (máx. +60%). Wizard — Mapa 3.",
	},
	STAT_FREE_CAST: {
		"title": "Free Cast",
		"description": "+8% probabilidad por nivel de lanzar sin CD (máx. 40%). Sage — Mapa 3.",
	},
	STAT_PROJECTILE_MULT: {
		"title": "Multi-Proyectil",
		"description": "+1 proyectil extra cada 2 niveles (máx. +2). Sage — Mapa 3.",
	},
	STAT_MELEE_FURY: {
		"title": "Melee Fury",
		"description": "+15% daño melee por nivel (máx. +75%). Knight — Mapa 3.",
	},
	STAT_GRAND_CROSS: {
		"title": "Grand Cross",
		"description": "Aura sagrada: +10% daño AoE sagrado por nivel (máx. +50%). Crusader — Mapa 3.",
	},
	STAT_SACRED_REGEN: {
		"title": "Regeneración Sagrada",
		"description": "Regenera 0.4% HP máx/s por nivel (máx. 2%/s). Crusader — Mapa 3.",
	},
}


static func get_definition(stat_id: String) -> Dictionary:
	var def: Dictionary = _DEFINITIONS.get(stat_id, {}).duplicate()
	def["id"] = stat_id
	return def


static func get_bonus_fraction(level: int) -> float:
	return float(clampi(level, 0, MAX_STAT_LEVEL)) * BONUS_PER_LEVEL
