## Pool de la tómbola: stats globales (6) + habilidades de clase con prerrequisitos.
class_name UpgradePool
extends RefCounted

const SKILL_PREFIX: String = "skill:"
const STAT_PREFIX: String = "stat:"
const ZENY_BAG_PREFIX: String = "zeny:"
const ZENY_BAG_CHOICE_ID: String = "zeny:bolsa"
const ZENY_BAG_GRANT: int = 500
const DEFAULT_ROLL_COUNT: int = 3

const _RunStats = preload("res://data/run_stat_catalog.gd")
const _MapConfig = preload("res://data/map_config.gd")


static func roll_choices(count: int = DEFAULT_ROLL_COUNT, player: Node = null) -> Array[String]:
	var pool: Array[String] = _build_eligible_pool(player)
	pool.shuffle()
	var result: Array[String] = []
	var pick_count: int = mini(count, pool.size())
	for i: int in pick_count:
		result.append(pool[i])
	while result.size() < count:
		result.append(ZENY_BAG_CHOICE_ID)
	_inject_payon_first_map2_stat(result, pool)
	_inject_orc_first_map3_stat(result, pool)
	return result


static func _inject_payon_first_map2_stat(result: Array[String], eligible_pool: Array[String]) -> void:
	if Game.selected_map_id != _MapConfig.MAP_PAYON or Global.payon_map2_stat_boost_used:
		return
	var guaranteed: String = _pick_random_payon_map2_stat(eligible_pool)
	if guaranteed.is_empty():
		return
	Global.payon_map2_stat_boost_used = true
	var slot: int = result.find(guaranteed)
	if slot >= 0:
		result.remove_at(slot)
	result.insert(0, guaranteed)
	while result.size() > DEFAULT_ROLL_COUNT:
		result.pop_back()


static func _pick_random_payon_map2_stat(eligible_pool: Array[String]) -> String:
	var class_id: String = Global.base_class_id if not Global.base_class_id.is_empty() else Game.selected_class_id
	var candidates: Array[String] = []
	for choice_id: String in eligible_pool:
		if not is_stat_choice(choice_id):
			continue
		var stat_id: String = parse_stat_id(choice_id)
		if not _is_map2_stat_for_class(stat_id, class_id):
			continue
		if Global.can_grant_run_stat(stat_id):
			candidates.append(choice_id)
	if candidates.is_empty():
		return ""
	return candidates[randi() % candidates.size()]


static func _can_offer_map2_stat(stat_id: String, class_id: String) -> bool:
	if Game.selected_map_id != _MapConfig.MAP_PAYON:
		return false
	return _is_map2_stat_for_class(stat_id, class_id)


static func _is_map2_stat_for_class(stat_id: String, class_id: String) -> bool:
	if _RunStats.is_map2_mage_stat(stat_id):
		return class_id == Game.CLASS_MAGE
	if _RunStats.is_map2_swordman_stat(stat_id):
		return class_id == Game.CLASS_SWORDMAN
	return false


static func _is_map2_exclusive_stat(stat_id: String) -> bool:
	return _RunStats.is_map2_exclusive_stat(stat_id)


static func _inject_orc_first_map3_stat(result: Array[String], eligible_pool: Array[String]) -> void:
	if Game.selected_map_id != _MapConfig.MAP_ORC_VILLAGE or Global.orc_map3_stat_boost_used:
		return
	var guaranteed: String = _pick_random_orc_map3_stat(eligible_pool)
	if guaranteed.is_empty():
		return
	Global.orc_map3_stat_boost_used = true
	var slot: int = result.find(guaranteed)
	if slot >= 0:
		result.remove_at(slot)
	result.insert(0, guaranteed)
	while result.size() > DEFAULT_ROLL_COUNT:
		result.pop_back()


static func _pick_random_orc_map3_stat(eligible_pool: Array[String]) -> String:
	var job_id: String = _resolve_job_id()
	var candidates: Array[String] = []
	for choice_id: String in eligible_pool:
		if not is_stat_choice(choice_id):
			continue
		var stat_id: String = parse_stat_id(choice_id)
		if not _RunStats.is_map3_stat_for_job(stat_id, job_id):
			continue
		if Global.can_grant_run_stat(stat_id):
			candidates.append(choice_id)
	if candidates.is_empty():
		return ""
	return candidates[randi() % candidates.size()]


static func _can_offer_map3_stat(stat_id: String) -> bool:
	if Game.selected_map_id != _MapConfig.MAP_ORC_VILLAGE:
		return false
	return _RunStats.is_map3_stat_for_job(stat_id, _resolve_job_id())


static func _resolve_job_id() -> String:
	if not Global.current_class.is_empty():
		return Global.current_class
	return Game.selected_class_id


static func _build_eligible_pool(player: Node) -> Array[String]:
	var pool: Array[String] = []
	var class_id: String = _resolve_class_id(player)
	for stat_id: String in _RunStats.ALL_STAT_IDS:
		if _RunStats.is_map3_exclusive_stat(stat_id):
			if not _can_offer_map3_stat(stat_id):
				continue
		elif _is_map2_exclusive_stat(stat_id):
			if not _can_offer_map2_stat(stat_id, class_id):
				continue
		var choice_id: String = STAT_PREFIX + stat_id
		if Global.is_tombola_choice_banned(choice_id):
			continue
		if Global.can_grant_run_stat(stat_id):
			pool.append(choice_id)
	for skill_id: String in SkillTreeCatalog.get_skills_for_class(class_id):
		var choice_id: String = SKILL_PREFIX + skill_id
		if Global.is_tombola_choice_banned(choice_id):
			continue
		if Global.can_grant_skill_level(skill_id):
			pool.append(choice_id)
	return pool



static func _resolve_class_id(player: Node) -> String:
	if not Global.base_class_id.is_empty():
		return Global.base_class_id
	if player != null and player.get("class_id") != null:
		return String(player.class_id)
	return Game.selected_class_id


static func parse_skill_id(choice_id: String) -> String:
	if choice_id.begins_with(SKILL_PREFIX):
		return choice_id.substr(SKILL_PREFIX.length())
	return ""


static func parse_stat_id(choice_id: String) -> String:
	if choice_id.begins_with(STAT_PREFIX):
		return choice_id.substr(STAT_PREFIX.length())
	return ""


static func is_skill_choice(choice_id: String) -> bool:
	return choice_id.begins_with(SKILL_PREFIX)


static func is_stat_choice(choice_id: String) -> bool:
	return choice_id.begins_with(STAT_PREFIX)


static func is_zeny_bag_choice(choice_id: String) -> bool:
	return choice_id == ZENY_BAG_CHOICE_ID


static func get_definition(choice_id: String) -> Dictionary:
	if is_zeny_bag_choice(choice_id):
		return _get_zeny_bag_definition(choice_id)
	if is_skill_choice(choice_id):
		return _get_skill_definition(parse_skill_id(choice_id), choice_id)
	if is_stat_choice(choice_id):
		return _get_stat_definition(parse_stat_id(choice_id), choice_id)
	return {"id": choice_id, "title": choice_id, "description": "", "kind": "unknown"}


static func _get_zeny_bag_definition(choice_id: String) -> Dictionary:
	return {
		"id": choice_id,
		"kind": "zeny_bag",
		"title": "Bolsa de Zeny",
		"description": "+%d Zeny inmediatos (sin límite de nivel)." % ZENY_BAG_GRANT,
	}


static func _get_stat_definition(stat_id: String, choice_id: String) -> Dictionary:
	var def: Dictionary = _RunStats.get_definition(stat_id)
	var level: int = Global.get_run_stat_level(stat_id)
	var next: int = level + 1
	return {
		"id": choice_id,
		"kind": "stat",
		"stat_id": stat_id,
		"title": "%s (Nv.%d/%d)" % [def.get("title", stat_id), next, _RunStats.MAX_STAT_LEVEL],
		"description": String(def.get("description", "")),
	}


static func _get_skill_definition(skill_id: String, choice_id: String) -> Dictionary:
	var def: Dictionary = SkillTreeCatalog.get_skill(skill_id)
	var level: int = Global.get_skill_level(skill_id)
	var max_level: int = int(def.get("max_level", SkillTreeCatalog.MAX_SKILL_LEVEL))
	var next_level: int = level + 1
	var tag: String = "Nuevo" if level == 0 else "Nv.%d" % next_level
	return {
		"id": choice_id,
		"kind": "skill",
		"skill_id": skill_id,
		"title": "%s (%s %d/%d)" % [def.get("display_name", skill_id), tag, next_level, max_level],
		"description": String(def.get("description", "")),
	}


static func apply(choice_id: String, player: Node) -> void:
	if is_zeny_bag_choice(choice_id):
		Global.add_zeny(ZENY_BAG_GRANT)
		return
	if is_skill_choice(choice_id):
		var skill_id: String = parse_skill_id(choice_id)
		if Global.grant_skill_level(skill_id) and player != null and player.has_method("sync_from_skill_tree"):
			player.sync_from_skill_tree()
		return
	if is_stat_choice(choice_id):
		Global.grant_run_stat_level(parse_stat_id(choice_id), player)
		if player != null and player.has_method("apply_run_stat_bonuses"):
			player.apply_run_stat_bonuses()
		return
