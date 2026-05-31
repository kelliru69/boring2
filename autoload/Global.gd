## Global.gd — Persistencia, sesión, tienda de Zeny y cartas equipadas.
extends Node

signal level_up(new_level: int)
signal zeny_gained(amount: int, total: int)
signal card_collected(card_id: String, card_data: Dictionary)
signal run_zeny_changed(run_total: int)
signal profile_loaded
signal shop_updated
signal equipped_cards_changed
signal skill_tree_changed
signal active_slots_changed
signal job_change_ready(job_id: String)

const SAVE_PATH: String = "user://profile.save"

const _MetaShop = preload("res://data/meta_shop.gd")
const _CardStats = preload("res://data/card_stats.gd")
const _SkillTree = preload("res://data/skill_tree_catalog.gd")
const _RunStats = preload("res://data/run_stat_catalog.gd")

var total_zeny: int = 0
var unlocked_cards: Dictionary = {}
var shop_purchases: Dictionary = MetaShop.build_default_purchases()
var equipped_cards: Array[String] = ["", "", "", "", ""]

var session_level: int = 1
var session_xp: int = 0
var session_xp_required: int = 0
var session_elapsed_time: float = 0.0
var run_zeny: int = 0
## -1 = probabilidad normal; 0.0–1.0 = override de debug (p. ej. 0.10 = 10%).
var debug_card_drop_chance: float = -1.0

## --- Árbol de habilidades (sesión / run) ---
var base_class_id: String = ""
var current_class: String = ""
var run_skill_levels: Dictionary = {}
## Stats globales de tómbola (velocidad, suerte, etc.), máx. 5 por stat.
var run_stat_levels: Dictionary = {}
## Mejoras de habilidad obtenidas vía tómbola en esta run (Job Change).
var tombola_skill_upgrades_this_run: int = 0
var active_skill_slots: Dictionary = {
	SkillTreeCatalog.SLOT_LMB: "",
	SkillTreeCatalog.SLOT_RMB: "",
	SkillTreeCatalog.SLOT_SPACE: "",
}
var job_change_event_pending: bool = false

## Tómbola por mapa (1 reroll y 1 eliminar por run de mapa; bans persisten hasta cambiar mapa).
var run_reroll_used: bool = false
var run_eliminate_used: bool = false
var run_tombola_banned: Array[String] = []

@export var base_xp: int = 100
@export var xp_level_multiplier: float = 1.2


func _ready() -> void:
	_recalculate_xp_required()
	load_profile()


func _process(delta: float) -> void:
	if get_tree().paused:
		return
	session_elapsed_time += delta


func get_xp_required_for_level(level: int) -> int:
	if level < 1:
		level = 1
	return int(round(float(base_xp) * float(level) * xp_level_multiplier))


func _recalculate_xp_required() -> void:
	session_xp_required = get_xp_required_for_level(session_level)


func add_experience(amount: int) -> void:
	if amount <= 0:
		return
	var grant: int = int(round(float(amount) * get_xp_multiplier()))
	session_xp += grant
	while session_xp >= session_xp_required and session_xp_required > 0:
		session_xp -= session_xp_required
		session_level += 1
		_recalculate_xp_required()
		_check_job_change_ready()
		level_up.emit(session_level)


func add_zeny(amount: int) -> void:
	if amount <= 0:
		return
	var grant: int = int(round(float(amount) * get_zeny_multiplier()))
	total_zeny += grant
	run_zeny += grant
	zeny_gained.emit(grant, total_zeny)
	run_zeny_changed.emit(run_zeny)
	save_profile()


func spend_zeny(amount: int) -> bool:
	if amount <= 0 or total_zeny < amount:
		return false
	total_zeny -= amount
	zeny_gained.emit(-amount, total_zeny)
	save_profile()
	return true


func unlock_card(card_id: String, card_data: Dictionary = {}) -> void:
	var data: Dictionary = card_data.duplicate()
	if not data.has("id"):
		data["id"] = card_id
	if not data.has("name"):
		data["name"] = card_id
	if unlocked_cards.has(card_id):
		unlocked_cards[card_id] = data
		save_profile()
		return
	unlocked_cards[card_id] = data
	card_collected.emit(card_id, data)
	save_profile()


func get_shop_purchase_count(upgrade_id: String) -> int:
	return int(shop_purchases.get(upgrade_id, 0))


func get_shop_cost(upgrade_id: String) -> int:
	return _MetaShop.get_cost(upgrade_id, get_shop_purchase_count(upgrade_id))


func can_purchase_shop(upgrade_id: String) -> bool:
	if not _MetaShop.ALL_IDS.has(upgrade_id):
		return false
	var cost: int = get_shop_cost(upgrade_id)
	if cost < 0:
		return false
	return total_zeny >= cost


func can_decrease_shop(upgrade_id: String) -> bool:
	return get_shop_purchase_count(upgrade_id) > 0


func purchase_shop_upgrade(upgrade_id: String) -> bool:
	if not can_purchase_shop(upgrade_id):
		return false
	var cost: int = get_shop_cost(upgrade_id)
	if not spend_zeny(cost):
		return false
	shop_purchases[upgrade_id] = get_shop_purchase_count(upgrade_id) + 1
	shop_updated.emit()
	save_profile()
	return true


func decrease_shop_upgrade(upgrade_id: String) -> bool:
	if not can_decrease_shop(upgrade_id):
		return false
	shop_purchases[upgrade_id] = get_shop_purchase_count(upgrade_id) - 1
	shop_updated.emit()
	save_profile()
	return true


func has_meta_shop_reroll() -> bool:
	return _MetaShop.has_unlock(shop_purchases, _MetaShop.UNLOCK_REROLL)


func has_meta_shop_eliminate() -> bool:
	return _MetaShop.has_unlock(shop_purchases, _MetaShop.UNLOCK_ELIMINATE)


func reset_map_tombola_tools() -> void:
	run_reroll_used = false
	run_eliminate_used = false
	run_tombola_banned.clear()


func can_use_run_reroll() -> bool:
	return has_meta_shop_reroll() and not run_reroll_used


func can_use_run_eliminate() -> bool:
	return has_meta_shop_eliminate() and not run_eliminate_used


func mark_run_reroll_used() -> void:
	run_reroll_used = true


func ban_tombola_choice(choice_id: String) -> void:
	if choice_id.is_empty():
		return
	if not run_tombola_banned.has(choice_id):
		run_tombola_banned.append(choice_id)
	run_eliminate_used = true


func is_tombola_choice_banned(choice_id: String) -> bool:
	return run_tombola_banned.has(choice_id)


func set_equipped_card(slot_index: int, card_id: String) -> void:
	if slot_index < 0 or slot_index >= _CardStats.MAX_EQUIPPED:
		return
	if card_id != "" and not unlocked_cards.has(card_id):
		return
	_ensure_equipped_slots()
	if card_id != "":
		for i: int in _CardStats.MAX_EQUIPPED:
			if i != slot_index and String(equipped_cards[i]) == card_id:
				equipped_cards[i] = ""
	equipped_cards[slot_index] = card_id
	equipped_cards_changed.emit()
	save_profile()


func clear_equipped_slot(slot_index: int) -> void:
	set_equipped_card(slot_index, "")


func get_equipped_slot_for(card_id: String) -> int:
	if card_id.is_empty():
		return -1
	_ensure_equipped_slots()
	for i: int in _CardStats.MAX_EQUIPPED:
		if String(equipped_cards[i]) == card_id:
			return i
	return -1


func is_card_equipped(card_id: String) -> bool:
	return get_equipped_slot_for(card_id) >= 0


func get_equipped_cards_clean() -> Array[String]:
	var result: Array[String] = []
	var seen: Dictionary = {}
	_ensure_equipped_slots()
	for i: int in _CardStats.MAX_EQUIPPED:
		var id: String = String(equipped_cards[i])
		if id == "" or not unlocked_cards.has(id) or seen.has(id):
			continue
		seen[id] = true
		result.append(id)
	return result


func _ensure_equipped_slots() -> void:
	while equipped_cards.size() < _CardStats.MAX_EQUIPPED:
		equipped_cards.append("")
	while equipped_cards.size() > _CardStats.MAX_EQUIPPED:
		equipped_cards.pop_back()


func _sanitize_equipped_cards() -> void:
	_ensure_equipped_slots()
	var seen: Dictionary = {}
	for i: int in _CardStats.MAX_EQUIPPED:
		var id: String = String(equipped_cards[i])
		if id == "":
			continue
		if not unlocked_cards.has(id) or seen.has(id):
			equipped_cards[i] = ""
		else:
			seen[id] = true


## Aplica tienda + cartas al jugador al iniciar la run.
func apply_run_bonuses_to_player(player: Node) -> void:
	if player == null:
		return
	var shop: Dictionary = _MetaShop.collect_run_bonuses(shop_purchases)
	var card_agg: Dictionary = _CardStats.aggregate_equipped(get_equipped_cards_clean())
	shop["card_stats"] = card_agg
	if player.has_method("apply_meta_bonuses"):
		player.apply_meta_bonuses(shop)


func reset_session() -> void:
	session_level = 1
	session_xp = 0
	session_elapsed_time = 0.0
	run_zeny = 0
	reset_map_tombola_tools()
	_recalculate_xp_required()
	run_zeny_changed.emit(run_zeny)
	init_run_skill_tree(Game.selected_class_id)


func get_session_snapshot() -> Dictionary:
	return {
		"level": session_level,
		"xp": session_xp,
		"xp_required": session_xp_required,
		"elapsed_time": session_elapsed_time,
		"zeny": total_zeny,
		"run_zeny": run_zeny,
		"cards_count": unlocked_cards.size(),
	}


func save_profile() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.set_value("profile", "total_zeny", total_zeny)
	cfg.set_value("profile", "shop_purchases", shop_purchases.duplicate())
	cfg.set_value("profile", "equipped_cards", equipped_cards.duplicate())
	var card_keys: PackedStringArray = PackedStringArray()
	for key: String in unlocked_cards:
		card_keys.append(key)
	cfg.set_value("profile", "unlocked_card_keys", card_keys)
	for key: String in unlocked_cards:
		cfg.set_value("cards", key, unlocked_cards[key])
	cfg.save(SAVE_PATH)


func load_profile() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		profile_loaded.emit()
		return
	total_zeny = int(cfg.get_value("profile", "total_zeny", 0))
	var loaded_shop: Variant = cfg.get_value("profile", "shop_purchases", {})
	if loaded_shop is Dictionary:
		shop_purchases = _MetaShop.sanitize_purchases(loaded_shop)
	else:
		shop_purchases = _MetaShop.build_default_purchases()
	var loaded_equipped: Variant = cfg.get_value("profile", "equipped_cards", [])
	if loaded_equipped is Array:
		equipped_cards = []
		for entry: Variant in loaded_equipped:
			equipped_cards.append(String(entry))
		_sanitize_equipped_cards()
	unlocked_cards.clear()
	var keys: Variant = cfg.get_value("profile", "unlocked_card_keys", PackedStringArray())
	if keys is PackedStringArray:
		for key: String in keys:
			var data: Variant = cfg.get_value("cards", key, {})
			if data is Dictionary:
				unlocked_cards[key] = data
	_sanitize_equipped_cards()
	profile_loaded.emit()


## --- Atajos de prueba (HUD debug en partida) ---
func debug_add_time(seconds: float) -> void:
	session_elapsed_time = maxf(session_elapsed_time + seconds, 0.0)


func debug_force_level_up() -> void:
	var needed: int = maxi(session_xp_required - session_xp, 1)
	add_experience(needed)


func debug_add_xp(amount: int) -> void:
	add_experience(maxi(amount, 1))


func debug_toggle_card_drop_test() -> void:
	if debug_card_drop_chance >= 0.0:
		debug_card_drop_chance = -1.0
	else:
		debug_card_drop_chance = 0.10


func debug_is_card_drop_test_mode() -> bool:
	return debug_card_drop_chance >= 0.0


# --- Árbol de habilidades ---

func init_run_skill_tree(class_id: String) -> void:
	base_class_id = class_id
	current_class = class_id
	run_skill_levels.clear()
	run_stat_levels.clear()
	tombola_skill_upgrades_this_run = 0
	job_change_event_pending = false
	active_skill_slots = {
		_SkillTree.SLOT_LMB: "",
		_SkillTree.SLOT_RMB: "",
		_SkillTree.SLOT_SPACE: "",
	}
	var starters: Dictionary = _SkillTree.get_starter_levels(class_id)
	for skill_id: String in starters:
		run_skill_levels[skill_id] = int(starters[skill_id])
	skill_tree_changed.emit()
	active_slots_changed.emit()


func get_skill_level(skill_id: String) -> int:
	return int(run_skill_levels.get(skill_id, 0))


func is_skill_unlocked(class_id: String, skill_id: String) -> bool:
	var def: Dictionary = _SkillTree.get_skill(skill_id)
	if def.is_empty():
		return false
	var tree_class: String = String(def.get("base_class", ""))
	if class_id != tree_class and not _job_uses_base_tree(class_id, tree_class):
		return false
	var prerequisite_id: String = String(def.get("prerequisite_id", ""))
	if prerequisite_id.is_empty():
		return true
	var required_level: int = int(def.get("prerequisite_level", 2))
	return get_skill_level(prerequisite_id) >= required_level


func can_learn_skill(skill_id: String) -> bool:
	return can_grant_skill_level(skill_id)


## Otorga +1 nivel desde la tómbola (sin gastar puntos del árbol).
func grant_skill_level(skill_id: String) -> bool:
	if not can_grant_skill_level(skill_id):
		return false
	var current_level: int = get_skill_level(skill_id)
	run_skill_levels[skill_id] = current_level + 1
	tombola_skill_upgrades_this_run += 1
	if _SkillTree.is_manual_slot_skill(skill_id) and current_level == 0:
		_auto_assign_active_slot(skill_id)
	skill_tree_changed.emit()
	_check_job_change_ready()
	return true


func can_grant_skill_level(skill_id: String) -> bool:
	var def: Dictionary = _SkillTree.get_skill(skill_id)
	if def.is_empty():
		return false
	var current_level: int = get_skill_level(skill_id)
	if current_level >= int(def.get("max_level", _SkillTree.MAX_SKILL_LEVEL)):
		return false
	if current_level == 0 and not is_skill_unlocked(base_class_id, skill_id):
		return false
	return true


func try_learn_skill(skill_id: String) -> bool:
	## Compatibilidad: el árbol ya no gasta puntos; delega a la tómbola.
	return grant_skill_level(skill_id)


func assign_skill_to_slot(slot_id: String, skill_id: String) -> void:
	if not _SkillTree.ALL_SLOT_IDS.has(slot_id):
		return
	if skill_id != "" and get_skill_level(skill_id) <= 0:
		return
	if skill_id != "" and not _SkillTree.is_manual_slot_skill(skill_id):
		return
	for other_slot: String in _SkillTree.ALL_SLOT_IDS:
		if active_skill_slots.get(other_slot, "") == skill_id:
			active_skill_slots[other_slot] = ""
	active_skill_slots[slot_id] = skill_id
	active_slots_changed.emit()


func get_slot_skill(slot_id: String) -> String:
	return String(active_skill_slots.get(slot_id, ""))


func get_skill_cooldown(skill_id: String) -> float:
	var def: Dictionary = _SkillTree.get_skill(skill_id)
	return float(def.get("cooldown", 1.0))


# --- Stats globales de run (tómbola) ---

func get_run_stat_level(stat_id: String) -> int:
	return int(run_stat_levels.get(stat_id, 0))


func can_grant_run_stat(stat_id: String) -> bool:
	if not _RunStats.ALL_STAT_IDS.has(stat_id):
		return false
	return get_run_stat_level(stat_id) < _RunStats.MAX_STAT_LEVEL


func grant_run_stat_level(stat_id: String, player: Node = null) -> bool:
	if not can_grant_run_stat(stat_id):
		return false
	run_stat_levels[stat_id] = get_run_stat_level(stat_id) + 1
	if stat_id == _RunStats.STAT_MAX_HP and player != null and player.has_method("apply_max_hp_percent_bonus"):
		player.apply_max_hp_percent_bonus(_RunStats.BONUS_PER_LEVEL)
	return true


func get_run_stat_bonus(stat_id: String) -> float:
	return _RunStats.get_bonus_fraction(get_run_stat_level(stat_id))


func get_xp_multiplier() -> float:
	return 1.0 + get_run_stat_bonus(_RunStats.STAT_XP_GAIN) \
		+ _MetaShop.get_total_bonus(_MetaShop.UPGRADE_XP_GAIN, get_shop_purchase_count(_MetaShop.UPGRADE_XP_GAIN))


func get_zeny_multiplier() -> float:
	return 1.0 + get_run_stat_bonus(_RunStats.STAT_COMMERCIAL_LUCK) \
		+ _MetaShop.get_total_bonus(_MetaShop.UPGRADE_ZENY_GAIN, get_shop_purchase_count(_MetaShop.UPGRADE_ZENY_GAIN))


func get_food_drop_multiplier() -> float:
	return 1.0 + _MetaShop.get_total_bonus(
		_MetaShop.UPGRADE_FOOD_DROP, get_shop_purchase_count(_MetaShop.UPGRADE_FOOD_DROP)
	)


func compute_food_drop_chance(base_chance: float) -> float:
	return clampf(base_chance * get_food_drop_multiplier() * get_commercial_luck_multiplier(), 0.0, 1.0)


## Multiplicador de suerte para drops (cartas y consumibles).
## chance_final = chance_base * (1 + bonus), p. ej. 0.0005 * 1.25 = 0.000625 (0.0625%).
func get_commercial_luck_multiplier() -> float:
	return 1.0 + get_run_stat_bonus(_RunStats.STAT_COMMERCIAL_LUCK)


func compute_card_drop_chance(base_chance: float = 0.0005) -> float:
	return base_chance * get_commercial_luck_multiplier()


func compute_loot_drop_chance(base_chance: float) -> float:
	return clampf(base_chance * get_commercial_luck_multiplier(), 0.0, 1.0)


func get_move_speed_multiplier() -> float:
	return 1.0 + get_run_stat_bonus(_RunStats.STAT_MOVE_SPEED)


func get_attack_speed_multiplier() -> float:
	return (1.0 + get_run_stat_bonus(_RunStats.STAT_ATTACK_SPEED)) \
		* _MetaShop.get_bonus_multiplier(
			_MetaShop.UPGRADE_ATTACK_SPEED, get_shop_purchase_count(_MetaShop.UPGRADE_ATTACK_SPEED)
		)


func get_active_cooldown_multiplier() -> float:
	return maxf(1.0 - get_run_stat_bonus(_RunStats.STAT_COOLDOWN_REDUCTION), 0.55)


func can_trigger_job_change() -> bool:
	return session_level >= Game.JOB_CHANGE_MIN_LEVEL \
		and tombola_skill_upgrades_this_run >= Game.JOB_CHANGE_MIN_SKILL_POINTS \
		and current_class == base_class_id


func get_available_job_evolutions() -> Array[String]:
	if not can_trigger_job_change():
		return []
	if base_class_id == Game.CLASS_MAGE:
		return [Game.JOB_WIZARD, Game.JOB_SAGE]
	if base_class_id == Game.CLASS_SWORDMAN:
		return [Game.JOB_KNIGHT, Game.JOB_CRUSADER]
	return []


func apply_job_change(new_job: String) -> bool:
	if not can_trigger_job_change():
		return false
	var options: Array[String] = get_available_job_evolutions()
	if not options.has(new_job):
		return false
	current_class = new_job
	job_change_event_pending = true
	job_change_ready.emit(new_job)
	skill_tree_changed.emit()
	return true


func _auto_assign_active_slot(skill_id: String) -> void:
	if not _SkillTree.is_manual_slot_skill(skill_id):
		return
	for slot_id: String in _SkillTree.ALL_SLOT_IDS:
		if String(active_skill_slots.get(slot_id, "")).is_empty():
			active_skill_slots[slot_id] = skill_id
			active_slots_changed.emit()
			return


func _job_uses_base_tree(job_id: String, tree_class: String) -> bool:
	if job_id == tree_class:
		return true
	if tree_class == Game.CLASS_MAGE and job_id in [Game.JOB_WIZARD, Game.JOB_SAGE]:
		return true
	if tree_class == Game.CLASS_SWORDMAN and job_id in [Game.JOB_KNIGHT, Game.JOB_CRUSADER]:
		return true
	return false


func _check_job_change_ready() -> void:
	if can_trigger_job_change() and not job_change_event_pending:
		job_change_event_pending = true
		for job_id: String in get_available_job_evolutions():
			job_change_ready.emit(job_id)
