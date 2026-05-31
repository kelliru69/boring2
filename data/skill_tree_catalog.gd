## Catálogo del árbol de habilidades por clase base (max nivel 5).
class_name SkillTreeCatalog
extends RefCounted

const MAX_SKILL_LEVEL: int = 5
const DEFAULT_ICON: String = "res://art/skills/default_icon.png"

const SLOT_LMB: String = "lmb"
const SLOT_RMB: String = "rmb"
const SLOT_SPACE: String = "space"

const ALL_SLOT_IDS: Array[String] = [SLOT_LMB, SLOT_RMB, SLOT_SPACE]


static func get_skill(skill_id: String) -> Dictionary:
	var def: Dictionary = _ALL_SKILLS.get(skill_id, {}).duplicate()
	if not def.is_empty():
		def["id"] = skill_id
	return def


static func get_skills_for_class(class_id: String) -> Array[String]:
	var ids: Array[String] = []
	for skill_id: String in _ALL_SKILLS:
		var def: Dictionary = _ALL_SKILLS[skill_id]
		if String(def.get("base_class", "")) == class_id:
			ids.append(skill_id)
	ids.sort_custom(func(a: String, b: String) -> bool:
		var pa: Vector2i = Vector2i(_ALL_SKILLS[a].get("grid_col", 0), _ALL_SKILLS[a].get("grid_row", 0))
		var pb: Vector2i = Vector2i(_ALL_SKILLS[b].get("grid_col", 0), _ALL_SKILLS[b].get("grid_row", 0))
		if pa.y == pb.y:
			return pa.x < pb.x
		return pa.y < pb.y
	)
	return ids


static func get_grid_size(class_id: String) -> Vector2i:
	var max_col: int = 0
	var max_row: int = 0
	for skill_id: String in get_skills_for_class(class_id):
		var def: Dictionary = _ALL_SKILLS[skill_id]
		max_col = maxi(max_col, int(def.get("grid_col", 0)))
		max_row = maxi(max_row, int(def.get("grid_row", 0)))
	return Vector2i(max_col + 1, max_row + 1)


static func get_starter_levels(class_id: String) -> Dictionary:
	match class_id:
		Game.CLASS_MAGE:
			return {"soul_strike": 1}
		Game.CLASS_SWORDMAN:
			return {"bash": 1}
		_:
			return {}


## Habilidad pasiva (sin botón ni temporizador de combate directo).
static func is_passive_skill(skill_id: String) -> bool:
	return bool(get_skill(skill_id).get("is_passive", false))


## Habilidad asignable a ranura manual (LMB / RMB / Space).
static func is_manual_slot_skill(skill_id: String) -> bool:
	var def: Dictionary = get_skill(skill_id)
	if def.is_empty():
		return false
	return bool(def.get("is_active", false)) \
		and not bool(def.get("is_basic_auto", false)) \
		and not bool(def.get("is_autonomous", false))


## Ataque básico automático (Soul Strike / Bash).
static func is_basic_auto_skill(skill_id: String) -> bool:
	return bool(get_skill(skill_id).get("is_basic_auto", false))


## Se activa sola por cooldown (Sight, Firewall, etc.).
static func is_autonomous_skill(skill_id: String) -> bool:
	return bool(get_skill(skill_id).get("is_autonomous", false))


## Íconos del HUD secundario (básico auto, autónomas y pasivas).
static func is_background_hud_skill(skill_id: String) -> bool:
	var def: Dictionary = get_skill(skill_id)
	if def.is_empty():
		return false
	return bool(def.get("is_passive", false)) \
		or bool(def.get("is_autonomous", false)) \
		or bool(def.get("is_basic_auto", false))


static func get_background_skills_for_class(class_id: String) -> Array[String]:
	var ids: Array[String] = []
	for skill_id: String in get_skills_for_class(class_id):
		if is_background_hud_skill(skill_id):
			ids.append(skill_id)
	return ids


static func get_tombola_lock_hint(skill_id: String) -> String:
	var def: Dictionary = get_skill(skill_id)
	if def.is_empty():
		return ""
	var prereq_id: String = String(def.get("prerequisite_id", ""))
	if prereq_id.is_empty():
		return ""
	var req_level: int = int(def.get("prerequisite_level", 2))
	var prereq_name: String = String(get_skill(prereq_id).get("display_name", prereq_id))
	var skill_name: String = String(def.get("display_name", skill_id))
	return "Sube %s a Nv.%d para habilitar %s en la tómbola." % [prereq_name, req_level, skill_name]


static var _ALL_SKILLS: Dictionary = {
	# --- Mage ---
	"soul_strike": {
		"base_class": Game.CLASS_MAGE,
		"display_name": "Soul Strike",
		"description": "Espíritus automáticos hacia el cursor (cadencia según nivel).",
		"max_level": MAX_SKILL_LEVEL,
		"prerequisite_id": "",
		"prerequisite_level": 2,
		"is_active": false,
		"is_passive": false,
		"is_basic_auto": true,
		"is_autonomous": false,
		"cooldown": 0.85,
		"grid_col": 0,
		"grid_row": 0,
		"icon_path": DEFAULT_ICON,
	},
	"sight": {
		"base_class": Game.CLASS_MAGE,
		"display_name": "Sight",
		"description": "Orbes orbitales que dañan en contacto (automático).",
		"max_level": MAX_SKILL_LEVEL,
		"prerequisite_id": "soul_strike",
		"prerequisite_level": 2,
		"is_active": false,
		"is_passive": false,
		"is_basic_auto": false,
		"is_autonomous": true,
		"cooldown": 0.0,
		"grid_col": 1,
		"grid_row": 0,
		"icon_path": DEFAULT_ICON,
	},
	"fire_bolt": {
		"base_class": Game.CLASS_MAGE,
		"display_name": "Fire Bolt",
		"description": "Proyectiles de fuego automáticos al enemigo más cercano (cada 2s).",
		"max_level": MAX_SKILL_LEVEL,
		"prerequisite_id": "",
		"prerequisite_level": 2,
		"is_active": false,
		"is_passive": false,
		"is_basic_auto": false,
		"is_autonomous": true,
		"cooldown": 2.0,
		"grid_col": 0,
		"grid_row": 1,
		"icon_path": DEFAULT_ICON,
	},
	"firewall": {
		"base_class": Game.CLASS_MAGE,
		"display_name": "Fire Wall",
		"description": "Barreras ígneas a la izquierda del mapa (−X); nv.5 también a la derecha (+X).",
		"max_level": MAX_SKILL_LEVEL,
		"prerequisite_id": "fire_bolt",
		"prerequisite_level": 2,
		"is_active": false,
		"is_passive": false,
		"is_basic_auto": false,
		"is_autonomous": true,
		"cooldown": 4.0,
		"grid_col": 1,
		"grid_row": 1,
		"icon_path": DEFAULT_ICON,
	},
	"cold_bolt": {
		"base_class": Game.CLASS_MAGE,
		"display_name": "Cold Bolt",
		"description": "Rayos de hielo automáticos a enemigos al azar; ralentiza (cada 2s).",
		"max_level": MAX_SKILL_LEVEL,
		"prerequisite_id": "",
		"prerequisite_level": 2,
		"is_active": false,
		"is_passive": false,
		"is_basic_auto": false,
		"is_autonomous": true,
		"cooldown": 2.0,
		"grid_col": 0,
		"grid_row": 2,
		"icon_path": DEFAULT_ICON,
	},
	"frost_dive": {
		"base_class": Game.CLASS_MAGE,
		"display_name": "Frost Diver",
		"description": "Congela en área bajo el cursor (activa, CD). Línea recta desde nv.3.",
		"max_level": MAX_SKILL_LEVEL,
		"prerequisite_id": "cold_bolt",
		"prerequisite_level": 2,
		"is_active": true,
		"is_passive": false,
		"is_basic_auto": false,
		"is_autonomous": false,
		"cooldown": 5.0,
		"grid_col": 1,
		"grid_row": 2,
		"icon_path": DEFAULT_ICON,
	},
	"lightning_bolt": {
		"base_class": Game.CLASS_MAGE,
		"display_name": "Lightning Bolt",
		"description": "Proyectiles boomerang eléctricos en dirección aleatoria.",
		"max_level": MAX_SKILL_LEVEL,
		"prerequisite_id": "",
		"prerequisite_level": 2,
		"is_active": false,
		"is_passive": false,
		"is_basic_auto": false,
		"is_autonomous": true,
		"cooldown": 2.2,
		"grid_col": 0,
		"grid_row": 3,
		"icon_path": DEFAULT_ICON,
	},
	"thunderstorm": {
		"base_class": Game.CLASS_MAGE,
		"display_name": "Thunder Storm",
		"description": "Tormenta eléctrica en el cursor tras 1s de casteo (activa).",
		"max_level": MAX_SKILL_LEVEL,
		"prerequisite_id": "lightning_bolt",
		"prerequisite_level": 2,
		"is_active": true,
		"is_passive": false,
		"is_basic_auto": false,
		"is_autonomous": false,
		"cooldown": 6.0,
		"grid_col": 1,
		"grid_row": 3,
		"icon_path": DEFAULT_ICON,
	},
	# --- Swordman ---
	"bash": {
		"base_class": Game.CLASS_SWORDMAN,
		"display_name": "Bash",
		"description": "Golpes en arco automáticos hacia adelante.",
		"max_level": MAX_SKILL_LEVEL,
		"prerequisite_id": "",
		"prerequisite_level": 2,
		"is_active": false,
		"is_passive": false,
		"is_basic_auto": true,
		"is_autonomous": false,
		"cooldown": 0.85,
		"grid_col": 0,
		"grid_row": 0,
		"icon_path": DEFAULT_ICON,
	},
	"magnum_break": {
		"base_class": Game.CLASS_SWORDMAN,
		"display_name": "Magnum Break",
		"description": "Explosión de fuego AoE manual alrededor del jugador.",
		"max_level": MAX_SKILL_LEVEL,
		"prerequisite_id": "bash",
		"prerequisite_level": 2,
		"is_active": true,
		"is_passive": false,
		"is_basic_auto": false,
		"is_autonomous": false,
		"cooldown": 5.0,
		"grid_col": 1,
		"grid_row": 0,
		"icon_path": DEFAULT_ICON,
	},
	"hp_recovery": {
		"base_class": Game.CLASS_SWORDMAN,
		"display_name": "Increase HP Recovery",
		"description": "Regeneración automática de HP (más rápida por nivel).",
		"max_level": MAX_SKILL_LEVEL,
		"prerequisite_id": "bash",
		"prerequisite_level": 2,
		"is_active": false,
		"is_passive": false,
		"is_basic_auto": false,
		"is_autonomous": true,
		"cooldown": 0.0,
		"grid_col": 0,
		"grid_row": 1,
		"icon_path": DEFAULT_ICON,
	},
	"endure": {
		"base_class": Game.CLASS_SWORDMAN,
		"display_name": "Endure",
		"description": "Mitiga el daño recibido según nivel (pasiva).",
		"max_level": MAX_SKILL_LEVEL,
		"prerequisite_id": "hp_recovery",
		"prerequisite_level": 2,
		"is_active": false,
		"is_passive": true,
		"is_basic_auto": false,
		"is_autonomous": false,
		"cooldown": 0.0,
		"grid_col": 1,
		"grid_row": 1,
		"icon_path": DEFAULT_ICON,
	},
	"sword_mastery": {
		"base_class": Game.CLASS_SWORDMAN,
		"display_name": "Sword Mastery",
		"description": "Aumenta el daño de todas las habilidades (+5% por nivel).",
		"max_level": MAX_SKILL_LEVEL,
		"prerequisite_id": "",
		"prerequisite_level": 2,
		"is_active": false,
		"is_passive": true,
		"cooldown": 0.0,
		"grid_col": 0,
		"grid_row": 2,
		"icon_path": DEFAULT_ICON,
	},
	"provoke": {
		"base_class": Game.CLASS_SWORDMAN,
		"display_name": "Provoke",
		"description": "Ralentiza y reduce defensa en área (activa, CD).",
		"max_level": MAX_SKILL_LEVEL,
		"prerequisite_id": "sword_mastery",
		"prerequisite_level": 2,
		"is_active": true,
		"is_passive": false,
		"is_basic_auto": false,
		"is_autonomous": false,
		"cooldown": 6.0,
		"grid_col": 1,
		"grid_row": 2,
		"icon_path": DEFAULT_ICON,
	},
}
