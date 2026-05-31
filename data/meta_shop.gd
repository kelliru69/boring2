## Tienda persistente de Zeny — desbloqueos y aumentos con precios escalonados.
## Balance orientado a ~14–15k Z por run completa de Prontera (mobs + Creamy).
class_name MetaShop
extends RefCounted

const KIND_UNLOCK: String = "unlock"
const KIND_STAT: String = "stat"

# --- Desbloqueos (1 nivel máximo) ---
const UNLOCK_REROLL: String = "unlock_reroll"
const UNLOCK_ELIMINATE: String = "unlock_eliminate"

# --- Aumentos ---
const UPGRADE_MAX_HP: String = "max_hp"
const UPGRADE_ATTACK: String = "attack"
const UPGRADE_MOVE_SPEED: String = "move_speed"
const UPGRADE_CRIT: String = "crit"
const UPGRADE_PICKUP_RANGE: String = "pickup_range"
const UPGRADE_ATTACK_SPEED: String = "attack_speed"
const UPGRADE_REGEN: String = "regen"
const UPGRADE_DEFENSE: String = "defense"
const UPGRADE_XP_GAIN: String = "xp_gain"
const UPGRADE_FOOD_DROP: String = "food_drop"
const UPGRADE_ZENY_GAIN: String = "zeny_gain"

const UNLOCK_IDS: Array[String] = [UNLOCK_REROLL, UNLOCK_ELIMINATE]

const STAT_IDS: Array[String] = [
	UPGRADE_MAX_HP,
	UPGRADE_ATTACK,
	UPGRADE_MOVE_SPEED,
	UPGRADE_CRIT,
	UPGRADE_PICKUP_RANGE,
	UPGRADE_ATTACK_SPEED,
	UPGRADE_REGEN,
	UPGRADE_DEFENSE,
	UPGRADE_XP_GAIN,
	UPGRADE_FOOD_DROP,
	UPGRADE_ZENY_GAIN,
]

const ALL_IDS: Array[String] = UNLOCK_IDS + STAT_IDS

const REGEN_INTERVAL_SEC: float = 5.0
const CRIT_DAMAGE_MULT: float = 1.5

## Referencia de economía Prontera (~15–20 min, victoria).
const ESTIMATED_PRONTERA_RUN_ZENY: int = 14500

static var _DEFINITIONS: Dictionary = {
	UNLOCK_REROLL: {
		"kind": KIND_UNLOCK,
		"title": "Volver a tirar",
		"description": "Un reroll de las 3 opciones al subir de nivel (1 vez por mapa).",
		"max_level": 1,
		"base_cost": 4800,
		"cost_growth": 0,
	},
	UNLOCK_ELIMINATE: {
		"kind": KIND_UNLOCK,
		"title": "Eliminar",
		"description": "Quita 1 mejora/habilidad del pool de la tómbola por el resto del mapa (1 vez por mapa).",
		"max_level": 1,
		"base_cost": 4200,
		"cost_growth": 0,
	},
	UPGRADE_MAX_HP: {
		"kind": KIND_STAT,
		"title": "Aumento de vida",
		"description": "+4% PV máximos por nivel.",
		"max_level": 10,
		"base_cost": 1100,
		"cost_growth": 680,
		"bonus_per_level": 0.04,
	},
	UPGRADE_ATTACK: {
		"kind": KIND_STAT,
		"title": "Aumento de ATK",
		"description": "+6% daño por nivel.",
		"max_level": 10,
		"base_cost": 1350,
		"cost_growth": 800,
		"bonus_per_level": 0.06,
	},
	UPGRADE_MOVE_SPEED: {
		"kind": KIND_STAT,
		"title": "Velocidad aumentada",
		"description": "+6% velocidad de movimiento por nivel.",
		"max_level": 10,
		"base_cost": 1050,
		"cost_growth": 620,
		"bonus_per_level": 0.06,
	},
	UPGRADE_CRIT: {
		"kind": KIND_STAT,
		"title": "Crítico ascendente",
		"description": "+2% probabilidad de crítico por nivel (×1.5 daño).",
		"max_level": 5,
		"base_cost": 1600,
		"cost_growth": 920,
		"bonus_per_level": 0.02,
	},
	UPGRADE_PICKUP_RANGE: {
		"kind": KIND_STAT,
		"title": "Gama de recogida",
		"description": "+10% rango de recogida por nivel.",
		"max_level": 10,
		"base_cost": 850,
		"cost_growth": 550,
		"bonus_per_level": 0.10,
	},
	UPGRADE_ATTACK_SPEED: {
		"kind": KIND_STAT,
		"title": "Date prisa",
		"description": "+4% velocidad de ataque por nivel.",
		"max_level": 5,
		"base_cost": 1250,
		"cost_growth": 740,
		"bonus_per_level": 0.04,
	},
	UPGRADE_REGEN: {
		"kind": KIND_STAT,
		"title": "Regeneración",
		"description": "+1 HP cada 5 s por nivel (base 1 HP).",
		"max_level": 5,
		"base_cost": 1200,
		"cost_growth": 680,
		"bonus_per_level": 1.0,
	},
	UPGRADE_DEFENSE: {
		"kind": KIND_STAT,
		"title": "Defensa aumentada",
		"description": "+3% reducción de daño recibido por nivel.",
		"max_level": 5,
		"base_cost": 1300,
		"cost_growth": 710,
		"bonus_per_level": 0.03,
	},
	UPGRADE_XP_GAIN: {
		"kind": KIND_STAT,
		"title": "Ganancia de EXP",
		"description": "+4% EXP por nivel.",
		"max_level": 5,
		"base_cost": 1400,
		"cost_growth": 760,
		"bonus_per_level": 0.04,
	},
	UPGRADE_FOOD_DROP: {
		"kind": KIND_STAT,
		"title": "Caídas de alimentos",
		"description": "+4% probabilidad de comida por nivel.",
		"max_level": 5,
		"base_cost": 1000,
		"cost_growth": 590,
		"bonus_per_level": 0.04,
	},
	UPGRADE_ZENY_GAIN: {
		"kind": KIND_STAT,
		"title": "Ganancia de dinero",
		"description": "+20% Zeny por nivel.",
		"max_level": 10,
		"base_cost": 1550,
		"cost_growth": 860,
		"bonus_per_level": 0.20,
	},
}


static func get_definition(upgrade_id: String) -> Dictionary:
	var def: Dictionary = _DEFINITIONS.get(upgrade_id, {}).duplicate()
	def["id"] = upgrade_id
	return def


static func get_max_level(upgrade_id: String) -> int:
	return int(get_definition(upgrade_id).get("max_level", 1))


static func get_cost(upgrade_id: String, current_level: int) -> int:
	var max_lv: int = get_max_level(upgrade_id)
	if current_level >= max_lv:
		return -1
	var def: Dictionary = get_definition(upgrade_id)
	var base_cost: int = int(def.get("base_cost", 100))
	var growth: int = int(def.get("cost_growth", 50))
	return base_cost + current_level * growth


static func is_unlock(upgrade_id: String) -> bool:
	return String(get_definition(upgrade_id).get("kind", "")) == KIND_UNLOCK


static func get_total_bonus(upgrade_id: String, level: int) -> float:
	var def: Dictionary = get_definition(upgrade_id)
	var per: float = float(def.get("bonus_per_level", 0.0))
	return per * float(clampi(level, 0, get_max_level(upgrade_id)))


static func get_bonus_multiplier(upgrade_id: String, level: int) -> float:
	return 1.0 + get_total_bonus(upgrade_id, level)


static func build_default_purchases() -> Dictionary:
	var d: Dictionary = {}
	for id: String in ALL_IDS:
		d[id] = 0
	return d


static func sanitize_purchases(raw: Dictionary) -> Dictionary:
	var d: Dictionary = build_default_purchases()
	for id: String in ALL_IDS:
		if raw.has(id):
			d[id] = clampi(int(raw.get(id, 0)), 0, get_max_level(id))
	# Migración nombres antiguos de la tienda
	if raw.has("haste") and int(d.get(UPGRADE_ATTACK_SPEED, 0)) == 0:
		d[UPGRADE_ATTACK_SPEED] = clampi(int(raw.get("haste", 0)), 0, get_max_level(UPGRADE_ATTACK_SPEED))
	return d


static func collect_run_bonuses(purchases: Dictionary) -> Dictionary:
	var lv_hp: int = int(purchases.get(UPGRADE_MAX_HP, 0))
	var lv_atk: int = int(purchases.get(UPGRADE_ATTACK, 0))
	var lv_move: int = int(purchases.get(UPGRADE_MOVE_SPEED, 0))
	var lv_crit: int = int(purchases.get(UPGRADE_CRIT, 0))
	var lv_pickup: int = int(purchases.get(UPGRADE_PICKUP_RANGE, 0))
	var lv_as: int = int(purchases.get(UPGRADE_ATTACK_SPEED, 0))
	var lv_regen: int = int(purchases.get(UPGRADE_REGEN, 0))
	var lv_def: int = int(purchases.get(UPGRADE_DEFENSE, 0))
	var lv_xp: int = int(purchases.get(UPGRADE_XP_GAIN, 0))
	var lv_food: int = int(purchases.get(UPGRADE_FOOD_DROP, 0))
	var lv_zeny: int = int(purchases.get(UPGRADE_ZENY_GAIN, 0))
	return {
		"max_hp_mult": get_bonus_multiplier(UPGRADE_MAX_HP, lv_hp),
		"attack_mult": get_bonus_multiplier(UPGRADE_ATTACK, lv_atk),
		"move_speed_mult": get_bonus_multiplier(UPGRADE_MOVE_SPEED, lv_move),
		"crit_chance": get_total_bonus(UPGRADE_CRIT, lv_crit),
		"pickup_range_mult": get_bonus_multiplier(UPGRADE_PICKUP_RANGE, lv_pickup),
		"attack_speed_mult": get_bonus_multiplier(UPGRADE_ATTACK_SPEED, lv_as),
		"regen_hp_per_tick": 1 + lv_regen,
		"defense_pct": get_total_bonus(UPGRADE_DEFENSE, lv_def),
		"xp_bonus": get_total_bonus(UPGRADE_XP_GAIN, lv_xp),
		"food_drop_bonus": get_total_bonus(UPGRADE_FOOD_DROP, lv_food),
		"zeny_bonus": get_total_bonus(UPGRADE_ZENY_GAIN, lv_zeny),
		"unlock_reroll": int(purchases.get(UNLOCK_REROLL, 0)) > 0,
		"unlock_eliminate": int(purchases.get(UNLOCK_ELIMINATE, 0)) > 0,
	}


static func has_unlock(purchases: Dictionary, unlock_id: String) -> bool:
	return int(purchases.get(unlock_id, 0)) > 0
