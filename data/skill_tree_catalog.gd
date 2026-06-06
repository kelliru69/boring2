## Catálogo del árbol de habilidades por clase base (max nivel 5).
class_name SkillTreeCatalog
extends RefCounted

const MAX_SKILL_LEVEL: int = 5
const DEFAULT_ICON: String = "res://art/skills/default_icon.png"

const SLOT_LMB: String = "lmb"
const SLOT_RMB: String = "rmb"
const SLOT_SPACE: String = "space"
const SLOT_Q: String = "slot_q"
const SLOT_E: String = "slot_e"

const ALL_SLOT_IDS: Array[String] = [SLOT_LMB, SLOT_RMB, SLOT_SPACE, SLOT_Q, SLOT_E]
const MAX_COMBAT_ACTIVE_SKILLS: int = 5

## Filas extra bajo el árbol base donde se dibujan las fusiones de Job Change.
const FUSION_GRID_ROW_OFFSET: int = 4


static func get_skill(skill_id: String) -> Dictionary:
	var resolved_id: String = resolve_skill_id(skill_id)
	var def: Dictionary = _ALL_SKILLS.get(resolved_id, {}).duplicate()
	if not def.is_empty():
		def["id"] = resolved_id
		# Flag lógico (estado real vive en Global); aquí existe como propiedad estándar del catálogo.
		if not def.has("is_disabled_for_combat"):
			def["is_disabled_for_combat"] = false
	return def


## IDs legacy / typo → ID canónico del árbol (run_skill_levels).
static func resolve_skill_id(skill_id: String) -> String:
	match skill_id:
		"frost_diver":
			return "frost_dive"
		_:
			return skill_id


static func get_skills_for_class(class_id: String) -> Array[String]:
	var ids: Array[String] = []
	for skill_id: String in _ALL_SKILLS:
		var def: Dictionary = _ALL_SKILLS[skill_id]
		var tree_class: String = String(def.get("base_class", ""))
		if bool(def.get("is_fusion", false)):
			if tree_class == class_id:
				ids.append(skill_id)
			continue
		if tree_class == class_id:
			ids.append(skill_id)
			continue
		if _is_evolved_job(class_id) and tree_class == _base_class_for_job(class_id):
			ids.append(skill_id)
	ids.sort_custom(func(a: String, b: String) -> bool:
		var pa: Vector2i = Vector2i(_ALL_SKILLS[a].get("grid_col", 0), _ALL_SKILLS[a].get("grid_row", 0))
		var pb: Vector2i = Vector2i(_ALL_SKILLS[b].get("grid_col", 0), _ALL_SKILLS[b].get("grid_row", 0))
		if pa.y == pb.y:
			return pa.x < pb.x
		return pa.y < pb.y
	)
	return ids


static func get_skill_tree_grid_pos(skill_id: String) -> Vector2i:
	var def: Dictionary = _ALL_SKILLS.get(skill_id, {})
	var col: int = int(def.get("grid_col", 0))
	var row: int = int(def.get("grid_row", 0))
	if bool(def.get("is_fusion", false)):
		row += FUSION_GRID_ROW_OFFSET
	return Vector2i(col, row)


static func resolve_tree_view_class_id() -> String:
	var current: String = Global.current_class
	if _is_evolved_job(current):
		return current
	if not Global.base_class_id.is_empty():
		return Global.base_class_id
	return Game.selected_class_id


static func get_grid_size(class_id: String) -> Vector2i:
	var max_col: int = 0
	var max_row: int = 0
	for skill_id: String in get_skills_for_class(class_id):
		var grid_pos: Vector2i = get_skill_tree_grid_pos(skill_id)
		max_col = maxi(max_col, grid_pos.x)
		max_row = maxi(max_row, grid_pos.y)
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
		"icon_path": "res://assets/skills/mage/soul_strike.png",
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
		"icon_path": "res://assets/skills/mage/sight.png",
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
		"icon_path": "res://assets/skills/mage/fire_bolt.png",
	},
	"firewall": {
		"base_class": Game.CLASS_MAGE,
		"display_name": "Fire Wall",
		"description": "Línea vertical de fuego a la izquierda (−X): 1 tile en nv.1, +1 por nivel (máx. 5). Nv.5 también a la derecha (+X). +20% daño.",
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
		"icon_path": "res://assets/skills/mage/firewall.png",
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
		"icon_path": "res://assets/skills/mage/cold_bolt.png",
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
		"icon_path": "res://assets/skills/mage/frost_diver.png",
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
		"icon_path": "res://assets/skills/mage/lightning_bolt.png",
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
		"icon_path": "res://assets/skills/mage/thunderstorm.png",
	},
	# --- Swordman ---
	"bash": {
		"base_class": Game.CLASS_SWORDMAN,
		"display_name": "Bash",
		"description": "Arco de corte físico hacia el cursor. Nv.5: 15% de stun 1 s.",
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
		"description": "Explosión ígnea radial (CD 3.5 s): knockback 360° y +15% daño de fuego 2 s.",
		"max_level": MAX_SKILL_LEVEL,
		"prerequisite_id": "bash",
		"prerequisite_level": 2,
		"is_active": false,
		"is_passive": false,
		"is_basic_auto": false,
		"is_autonomous": true,
		"cooldown": 3.5,
		"grid_col": 1,
		"grid_row": 0,
		"icon_path": DEFAULT_ICON,
	},
	"moving_recovery": {
		"base_class": Game.CLASS_SWORDMAN,
		"display_name": "Moving Recovery",
		"description": "Cada 4 s regenera un 2% del HP faltante automáticamente.",
		"max_level": MAX_SKILL_LEVEL,
		"prerequisite_id": "",
		"prerequisite_level": 2,
		"is_active": false,
		"is_passive": false,
		"is_basic_auto": false,
		"is_autonomous": true,
		"cooldown": 4.0,
		"grid_col": 0,
		"grid_row": 1,
		"icon_path": DEFAULT_ICON,
	},
	"increase_hp_recovery": {
		"base_class": Game.CLASS_SWORDMAN,
		"display_name": "Increase HP Recovery",
		"description": "+5% HP máximo por nivel y comida cura un 25% más por nivel.",
		"max_level": MAX_SKILL_LEVEL,
		"prerequisite_id": "moving_recovery",
		"prerequisite_level": 2,
		"is_active": false,
		"is_passive": false,
		"is_basic_auto": false,
		"is_autonomous": true,
		"cooldown": 0.0,
		"grid_col": 1,
		"grid_row": 1,
		"icon_path": DEFAULT_ICON,
	},
	"auto_berserk": {
		"base_class": Game.CLASS_SWORDMAN,
		"display_name": "Auto Berserk",
		"description": "Pasiva: +0.5%–2.5% daño por cada 1% de HP faltante (según nivel).",
		"max_level": MAX_SKILL_LEVEL,
		"prerequisite_id": "",
		"prerequisite_level": 2,
		"is_active": false,
		"is_passive": true,
		"is_basic_auto": false,
		"is_autonomous": false,
		"cooldown": 0.0,
		"grid_col": 0,
		"grid_row": 2,
		"icon_path": DEFAULT_ICON,
	},
	"endure": {
		"base_class": Game.CLASS_SWORDMAN,
		"display_name": "Endure",
		"description": "Activa (CD 8 s): +30% defensa e inmunidad a interrupciones 4 s.",
		"max_level": MAX_SKILL_LEVEL,
		"prerequisite_id": "auto_berserk",
		"prerequisite_level": 2,
		"is_active": true,
		"is_passive": false,
		"is_basic_auto": false,
		"is_autonomous": false,
		"cooldown": 8.0,
		"grid_col": 1,
		"grid_row": 2,
		"icon_path": DEFAULT_ICON,
	},
	"spear_stab": {
		"base_class": Game.CLASS_SWORDMAN,
		"display_name": "Spear Stab",
		"description": "Tajo horizontal (CD 2.5 s): daño ×1.5 y knockback frontal masivo.",
		"max_level": MAX_SKILL_LEVEL,
		"prerequisite_id": "",
		"prerequisite_level": 2,
		"is_active": false,
		"is_passive": false,
		"is_basic_auto": false,
		"is_autonomous": true,
		"cooldown": 2.5,
		"grid_col": 0,
		"grid_row": 3,
		"icon_path": DEFAULT_ICON,
	},
	"bowling_bash": {
		"base_class": Game.CLASS_SWORDMAN,
		"display_name": "Bowling Bash",
		"description": "Golpe rectangular frontal (CD 5 s): daño en cadena al chocar enemigos.",
		"max_level": MAX_SKILL_LEVEL,
		"prerequisite_id": "spear_stab",
		"prerequisite_level": 2,
		"is_active": true,
		"is_passive": false,
		"is_basic_auto": false,
		"is_autonomous": false,
		"cooldown": 5.0,
		"grid_col": 1,
		"grid_row": 3,
		"icon_path": DEFAULT_ICON,
	},
	"lord_of_vermilion": {
		"base_class": Game.JOB_WIZARD,
		"display_name": "Lord of Vermilion",
		"description": "Fusión: tormenta eléctrica masiva en el cursor (Thunder Storm + Sight Nv.5).",
		"max_level": 1,
		"prerequisite_id": "",
		"prerequisite_level": 1,
		"is_active": true,
		"is_passive": false,
		"is_fusion": true,
		"is_basic_auto": false,
		"is_autonomous": false,
		"cooldown": 14.0,
		"grid_col": 0,
		"grid_row": 0,
		"icon_path": "res://assets/skills/mage/thunderstorm.png",
	},
	"storm_gust": {
		"base_class": Game.JOB_WIZARD,
		"display_name": "Storm Gust",
		"description": "Fusión: ventisca masiva; 50% de congelar 2 s (Frost Diver + Cold Bolt Nv.5).",
		"max_level": 1,
		"prerequisite_id": "",
		"prerequisite_level": 1,
		"is_active": true,
		"is_passive": false,
		"is_fusion": true,
		"is_basic_auto": false,
		"is_autonomous": false,
		"cooldown": 12.0,
		"grid_col": 1,
		"grid_row": 0,
		"icon_path": "res://assets/skills/mage/frost_diver.png",
	},
	"vanguard_force": {
		"base_class": Game.JOB_KNIGHT,
		"display_name": "Vanguard Force",
		"description": "Fusión: tajo frontal masivo con escudo por impacto (Bowling Bash + Bash Nv.5).",
		"max_level": 1,
		"prerequisite_id": "",
		"prerequisite_level": 1,
		"is_active": true,
		"is_passive": false,
		"is_fusion": true,
		"is_basic_auto": false,
		"is_autonomous": false,
		"cooldown": 9.0,
		"grid_col": 0,
		"grid_row": 0,
		"icon_path": DEFAULT_ICON,
	},
	"meteor_storm": {
		"base_class": Game.JOB_WIZARD,
		"display_name": "Meteor Storm",
		"description": "Fusión: lluvia constante de meteoros con daño por tic (Fire Bolt + Fire Wall Nv.5).",
		"max_level": 1,
		"prerequisite_id": "",
		"prerequisite_level": 1,
		"is_active": true,
		"is_passive": false,
		"is_fusion": true,
		"is_basic_auto": false,
		"is_autonomous": false,
		"cooldown": 11.0,
		"grid_col": 0,
		"grid_row": 1,
		"icon_path": "res://assets/skills/mage/firewall.png",
	},
	"jupitel_thunder": {
		"base_class": Game.JOB_WIZARD,
		"display_name": "Jupitel Thunder",
		"description": "Fusión: rayos con knockback extremo (Soul Strike + Lightning Bolt Nv.5).",
		"max_level": 1,
		"prerequisite_id": "",
		"prerequisite_level": 1,
		"is_active": true,
		"is_passive": false,
		"is_fusion": true,
		"is_basic_auto": false,
		"is_autonomous": false,
		"cooldown": 10.0,
		"grid_col": 1,
		"grid_row": 1,
		"icon_path": "res://assets/skills/mage/lightning_bolt.png",
	},
	"land_protector": {
		"base_class": Game.JOB_SAGE,
		"display_name": "Land Protector",
		"description": "Fusión: zona sagrada; inmunidad al daño entrante (Sight + Fire Wall Nv.5). CD largo.",
		"max_level": 1,
		"prerequisite_id": "",
		"prerequisite_level": 1,
		"is_active": true,
		"is_passive": false,
		"is_fusion": true,
		"is_basic_auto": false,
		"is_autonomous": false,
		"cooldown": 28.0,
		"grid_col": 0,
		"grid_row": 0,
		"icon_path": "res://assets/skills/mage/firewall.png",
	},
	"heavens_drive": {
		"base_class": Game.JOB_SAGE,
		"display_name": "Heaven's Drive",
		"description": "Fusión: línea recta enorme que ralentiza mucho (Frost Diver + Thunder Storm Nv.5).",
		"max_level": 1,
		"prerequisite_id": "",
		"prerequisite_level": 1,
		"is_active": true,
		"is_passive": false,
		"is_fusion": true,
		"is_basic_auto": false,
		"is_autonomous": false,
		"cooldown": 13.0,
		"grid_col": 1,
		"grid_row": 0,
		"icon_path": "res://assets/skills/mage/thunderstorm.png",
	},
	"autocast": {
		"base_class": Game.JOB_SAGE,
		"display_name": "Autocast",
		"description": "Fusión pasiva: 50% de duplicar bolts en dirección aleatoria (Soul Strike + Cold Bolt Nv.5).",
		"max_level": 1,
		"prerequisite_id": "",
		"prerequisite_level": 1,
		"is_active": false,
		"is_passive": true,
		"is_fusion": true,
		"is_basic_auto": false,
		"is_autonomous": false,
		"cooldown": 0.0,
		"grid_col": 0,
		"grid_row": 1,
		"icon_path": "res://assets/skills/mage/soul_strike.png",
	},
	"diamond_dust": {
		"base_class": Game.JOB_SAGE,
		"display_name": "Diamond Dust",
		"description": "Fusión: explosión helada-eléctrica en el cursor (Fire Bolt + Lightning Bolt Nv.5).",
		"max_level": 1,
		"prerequisite_id": "",
		"prerequisite_level": 1,
		"is_active": true,
		"is_passive": false,
		"is_fusion": true,
		"is_basic_auto": false,
		"is_autonomous": false,
		"cooldown": 11.0,
		"grid_col": 1,
		"grid_row": 1,
		"icon_path": "res://assets/skills/mage/cold_bolt.png",
	},
	"spiral_pierce": {
		"base_class": Game.JOB_KNIGHT,
		"display_name": "Spiral Pierce",
		"description": "Fusión: lanza devastadora (Spear Stab + Magnum Break Nv.5).",
		"max_level": 1,
		"prerequisite_id": "",
		"prerequisite_level": 1,
		"is_active": true,
		"is_passive": false,
		"is_fusion": true,
		"is_basic_auto": false,
		"is_autonomous": false,
		"cooldown": 8.0,
		"grid_col": 1,
		"grid_row": 0,
		"icon_path": DEFAULT_ICON,
	},
	"knights_rush": {
		"base_class": Game.JOB_KNIGHT,
		"display_name": "Knight's Rush",
		"description": "Fusión: embestida con curación y explosión (Endure + Moving Recovery Nv.5).",
		"max_level": 1,
		"prerequisite_id": "",
		"prerequisite_level": 1,
		"is_active": true,
		"is_passive": false,
		"is_fusion": true,
		"is_basic_auto": false,
		"is_autonomous": false,
		"cooldown": 10.0,
		"grid_col": 0,
		"grid_row": 1,
		"icon_path": DEFAULT_ICON,
	},
	"two_hand_quicken": {
		"base_class": Game.JOB_KNIGHT,
		"display_name": "Two-Hand Quicken",
		"description": "Fusión: duplica la velocidad de ataque 8 s (Auto Berserk + Spear Stab Nv.5).",
		"max_level": 1,
		"prerequisite_id": "",
		"prerequisite_level": 1,
		"is_active": true,
		"is_passive": false,
		"is_fusion": true,
		"is_basic_auto": false,
		"is_autonomous": false,
		"cooldown": 16.0,
		"grid_col": 1,
		"grid_row": 1,
		"icon_path": DEFAULT_ICON,
	},
	"grand_cross": {
		"base_class": Game.JOB_CRUSADER,
		"display_name": "Grand Cross",
		"description": "Fusión: cruz sagrada de daño por tic centrada en ti (Magnum Break + Endure Nv.5).",
		"max_level": 1,
		"prerequisite_id": "",
		"prerequisite_level": 1,
		"is_active": true,
		"is_passive": false,
		"is_fusion": true,
		"is_basic_auto": false,
		"is_autonomous": false,
		"cooldown": 14.0,
		"grid_col": 0,
		"grid_row": 0,
		"icon_path": DEFAULT_ICON,
	},
	"shield_boomerang": {
		"base_class": Game.JOB_CRUSADER,
		"display_name": "Shield Boomerang",
		"description": "Fusión: escudo ida/vuelta; −50% defensa mientras está en CD (Bowling Bash + Bash Nv.5).",
		"max_level": 1,
		"prerequisite_id": "",
		"prerequisite_level": 1,
		"is_active": true,
		"is_passive": false,
		"is_fusion": true,
		"is_basic_auto": false,
		"is_autonomous": false,
		"cooldown": 11.0,
		"grid_col": 1,
		"grid_row": 0,
		"icon_path": DEFAULT_ICON,
	},
	"reflect_shield": {
		"base_class": Game.JOB_CRUSADER,
		"display_name": "Reflect Shield",
		"description": "Fusión: refleja hasta 500% del daño recibido 6 s (HP Recovery + Auto Berserk Nv.5).",
		"max_level": 1,
		"prerequisite_id": "",
		"prerequisite_level": 1,
		"is_active": true,
		"is_passive": false,
		"is_fusion": true,
		"is_basic_auto": false,
		"is_autonomous": false,
		"cooldown": 18.0,
		"grid_col": 0,
		"grid_row": 1,
		"icon_path": DEFAULT_ICON,
	},
	"sacred_hammer": {
		"base_class": Game.JOB_CRUSADER,
		"display_name": "Sacred Hammer",
		"description": "Fusión: martillo sagrado radial que cura (Moving Recovery + Spear Stab Nv.5).",
		"max_level": 1,
		"prerequisite_id": "",
		"prerequisite_level": 1,
		"is_active": true,
		"is_passive": false,
		"is_fusion": true,
		"is_basic_auto": false,
		"is_autonomous": false,
		"cooldown": 9.5,
		"grid_col": 1,
		"grid_row": 1,
		"icon_path": DEFAULT_ICON,
	},
}


static func _is_evolved_job(class_id: String) -> bool:
	return class_id in [Game.JOB_WIZARD, Game.JOB_SAGE, Game.JOB_KNIGHT, Game.JOB_CRUSADER]


static func _base_class_for_job(job_id: String) -> String:
	if job_id in [Game.JOB_WIZARD, Game.JOB_SAGE]:
		return Game.CLASS_MAGE
	if job_id in [Game.JOB_KNIGHT, Game.JOB_CRUSADER]:
		return Game.CLASS_SWORDMAN
	return job_id
