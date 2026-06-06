## Global.gd — Persistencia, sesión, tienda de Zeny y cartas equipadas.
extends Node

signal level_up(new_level: int)
signal zeny_gained(amount: int, total: int)
signal campaign_zeny_gained(amount: int, total: int)
signal card_collected(card_id: String, card_data: Dictionary)
signal run_zeny_changed(run_total: int)
signal profile_loaded
signal shop_updated
signal equipped_cards_changed
signal run_cards_changed
signal skill_tree_changed
signal active_slots_changed
signal combat_kit_changed
signal consumables_changed
signal job_change_ready(job_id: String)
signal fusion_unlocked(fusion_id: String, display_name: String)
signal dps_updated(dps_value: float)

const SAVE_PATH: String = "user://profile.save"

const _MetaShop = preload("res://data/meta_shop.gd")
const _CardStats = preload("res://data/card_stats.gd")
const _SkillTree = preload("res://data/skill_tree_catalog.gd")
const _RunStats = preload("res://data/run_stat_catalog.gd")
const _MapConfig = preload("res://data/map_config.gd")
const _SkinCatalog = preload("res://data/player_skin_catalog.gd")
const _JobFusion = preload("res://data/job_fusion_catalog.gd")
const _CombatKit = preload("res://scripts/combat/combat_kit_service.gd")
const _Consumables = preload("res://scripts/inventory/consumable_inventory.gd")

const CARD_EVOLVE_COST: int = 5

## Progreso de campaña (persistente entre runs).
var map_1_cleared: bool = false
var boss_1_discovered: bool = false
## Jefe de Payon (misma lógica de "?" en el selector de mapas).
var boss_2_discovered: bool = false
var map_2_cleared: bool = false
var boss_3_discovered: bool = false
var player_skin_id: String = _SkinCatalog.SKIN_BLUE_CAT

var total_zeny: int = 0
## Zeny ganado solo en mapas de campaña (Orc Village / tier 3+); moneda de la tienda avanzada.
var campaign_zeny: int = 0
var unlocked_cards: Dictionary = {}
var shop_purchases: Dictionary = MetaShop.build_default_purchases()
var equipped_cards: Array[String] = ["", "", "", "", ""]

var session_level: int = 1
var session_xp: int = 0
var session_xp_required: int = 0
var session_elapsed_time: float = 0.0
var run_zeny: int = 0
var run_campaign_zeny: int = 0
## -1 = probabilidad normal; 0.0–1.0 = override de debug (p. ej. 0.10 = 10%).
var debug_card_drop_chance: float = -1.0
## Primera tómbola de la run en Payon: garantiza un stat exclusivo del mapa 2.
var payon_map2_stat_boost_used: bool = false
## Primera tómbola en Orc Village: garantiza pasiva de Job Change del mapa 3.
var orc_map3_stat_boost_used: bool = false
## Carta MVP Orc Hero: máximo 1 drop por run.
var run_orc_hero_card_dropped: bool = false
## Cartas obtenidas en la run actual (id -> cantidad); no duplica iconos en HUD.
var run_card_drops: Dictionary = {}

## --- Árbol de habilidades (sesión / run) ---
var base_class_id: String = ""
var current_class: String = ""
var run_skill_levels: Dictionary = {}
## Skills deshabilitadas por fusión (se conservan niveles para sinergias futuras).
## skill_id -> true
var run_skill_disabled_for_combat: Dictionary = {}
## Stats globales de tómbola (velocidad, suerte, etc.), máx. 5 por stat.
var run_stat_levels: Dictionary = {}
## Mejoras de habilidad obtenidas vía tómbola en esta run (Job Change).
var tombola_skill_upgrades_this_run: int = 0
var active_skill_slots: Dictionary = {
	SkillTreeCatalog.SLOT_LMB: "",
	SkillTreeCatalog.SLOT_RMB: "",
	SkillTreeCatalog.SLOT_SPACE: "",
	SkillTreeCatalog.SLOT_Q: "",
	SkillTreeCatalog.SLOT_E: "",
}
## Habilidades activas equipadas en combate (máx. 5).
var combat_kit_skill_ids: Array[String] = []
## Consumibles de la run: item_id → cantidad.
var run_consumables: Dictionary = {}
## Tecla 1–9 (string) → item_id.
var consumable_hotkeys: Dictionary = {}
var job_change_event_pending: bool = false
## Selección de menú arcade (Resources).
var selected_character: CharacterData = null
var selected_class_data: ClassData = null

## Tómbola por mapa (1 reroll y 1 eliminar por run de mapa; bans persisten hasta cambiar mapa).
var run_reroll_used: bool = false
var run_eliminate_used: bool = false
var run_tombola_banned: Array[String] = []

var _run_clock_timer: Timer = null
## Registro de daño infligido: { "t": float, "dmg": int }
var _damage_dealt_log: Array[Dictionary] = []
const DPS_WINDOW_SEC: float = 3.0

@export var base_xp: int = 100
@export var xp_level_multiplier: float = 1.2


func _ready() -> void:
	_recalculate_xp_required()
	_setup_run_clock_timer()
	load_profile()
	SkillInputRemap.load_bindings()


func _setup_run_clock_timer() -> void:
	_run_clock_timer = Timer.new()
	_run_clock_timer.name = "RunClockTimer"
	_run_clock_timer.wait_time = 1.0
	_run_clock_timer.one_shot = false
	_run_clock_timer.autostart = true
	_run_clock_timer.ignore_time_scale = true
	_run_clock_timer.timeout.connect(_on_run_clock_tick)
	add_child(_run_clock_timer)


func _on_run_clock_tick() -> void:
	if get_tree().paused:
		return
	session_elapsed_time += 1.0


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
	if _MapConfig.is_campaign_tier_map(Game.selected_map_id):
		_add_campaign_zeny(grant)
	else:
		_add_standard_zeny(grant)


func _add_standard_zeny(grant: int) -> void:
	if grant <= 0:
		return
	total_zeny += grant
	run_zeny += grant
	zeny_gained.emit(grant, total_zeny)
	run_zeny_changed.emit(run_zeny)
	save_profile()


func _add_campaign_zeny(grant: int) -> void:
	if grant <= 0:
		return
	campaign_zeny += grant
	run_campaign_zeny += grant
	run_zeny += grant
	campaign_zeny_gained.emit(grant, campaign_zeny)
	run_zeny_changed.emit(run_zeny)
	save_profile()


func spend_zeny(amount: int) -> bool:
	if amount <= 0 or total_zeny < amount:
		return false
	total_zeny -= amount
	zeny_gained.emit(-amount, total_zeny)
	save_profile()
	return true


func spend_campaign_zeny(amount: int) -> bool:
	if amount <= 0 or campaign_zeny < amount:
		return false
	campaign_zeny -= amount
	campaign_zeny_gained.emit(-amount, campaign_zeny)
	save_profile()
	return true


func get_shop_wallet_balance(upgrade_id: String) -> int:
	if _MetaShop.uses_campaign_currency(upgrade_id):
		return campaign_zeny
	return total_zeny


## Legacy: ya no se usa en fusiones (ingredientes conservan nivel). Mantener por compatibilidad.
func remove_fused_ingredient(ingredient_id: String) -> void:
	if ingredient_id.is_empty():
		return
	if ingredient_id.begins_with("stat_"):
		run_stat_levels.erase(ingredient_id)
	else:
		run_skill_levels.erase(ingredient_id)
		for slot_id: String in _SkillTree.ALL_SLOT_IDS:
			if String(active_skill_slots.get(slot_id, "")) == ingredient_id:
				active_skill_slots[slot_id] = ""


## Marca una habilidad como "deshabilitada para combate" (ingrediente de una fusión).
## Conserva su nivel para futuras fusiones/sinergias, pero ya no debe ejecutarse ni ocupar ranura.
func disable_skill_for_combat(skill_id: String) -> void:
	if skill_id.is_empty():
		return
	if get_skill_level(skill_id) <= 0:
		return
	run_skill_disabled_for_combat[skill_id] = true
	for slot_id: String in _SkillTree.ALL_SLOT_IDS:
		if String(active_skill_slots.get(slot_id, "")) == skill_id:
			active_skill_slots[slot_id] = ""
	_CombatKit.sync_from_active_slots()
	active_slots_changed.emit()
	combat_kit_changed.emit()


func is_skill_disabled_for_combat(skill_id: String) -> bool:
	return bool(run_skill_disabled_for_combat.get(skill_id, false))


func get_card_owned_count(card_id: String) -> int:
	if card_id.is_empty() or not unlocked_cards.has(card_id):
		return 0
	var data: Dictionary = unlocked_cards[card_id]
	return maxi(int(data.get("count", 1)), 0)


func count_equipped_card(card_id: String) -> int:
	if card_id.is_empty():
		return 0
	_ensure_equipped_slots()
	var total: int = 0
	for i: int in _CardStats.MAX_EQUIPPED:
		if String(equipped_cards[i]) == card_id:
			total += 1
	return total


func can_equip_card_to_slot(card_id: String, slot_index: int) -> bool:
	if card_id.is_empty():
		return true
	if not unlocked_cards.has(card_id):
		return false
	var owned: int = get_card_owned_count(card_id)
	var equipped: int = count_equipped_card(card_id)
	var current_in_slot: String = ""
	if slot_index >= 0 and slot_index < equipped_cards.size():
		current_in_slot = String(equipped_cards[slot_index])
	if current_in_slot == card_id:
		return true
	return equipped < owned


func add_run_card_drop(card_id: String) -> void:
	if card_id.is_empty():
		return
	run_card_drops[card_id] = int(run_card_drops.get(card_id, 0)) + 1
	run_cards_changed.emit()


func get_run_card_drops() -> Dictionary:
	return run_card_drops.duplicate()


func get_total_owned_card_copies() -> int:
	var total: int = 0
	for key: String in unlocked_cards:
		total += get_card_owned_count(key)
	return total


func unlock_card(card_id: String, card_data: Dictionary = {}, track_run_drop: bool = true) -> void:
	var data: Dictionary = card_data.duplicate()
	if not data.has("id"):
		data["id"] = card_id
	if not data.has("name"):
		data["name"] = card_id
	var prev_count: int = get_card_owned_count(card_id)
	if unlocked_cards.has(card_id):
		data["count"] = prev_count + 1
	else:
		data["count"] = 1
	unlocked_cards[card_id] = data
	if track_run_drop:
		add_run_card_drop(card_id)
	card_collected.emit(card_id, data)
	save_profile()


func get_plus_card_id(card_id: String) -> String:
	if card_id.ends_with("_plus"):
		return card_id
	return "%s_plus" % card_id


func is_plus_card(card_id: String) -> bool:
	return card_id.ends_with("_plus")


func can_evolve_card(card_id: String) -> bool:
	if card_id.is_empty() or is_plus_card(card_id):
		return false
	return get_card_owned_count(card_id) >= CARD_EVOLVE_COST


func evolve_card_to_plus(card_id: String) -> bool:
	if not can_evolve_card(card_id):
		return false
	var data: Dictionary = unlocked_cards.get(card_id, {}).duplicate()
	var base_name: String = String(data.get("name", card_id))
	var new_count: int = maxi(int(data.get("count", 0)) - CARD_EVOLVE_COST, 0)
	if new_count <= 0:
		unlocked_cards.erase(card_id)
	else:
		data["count"] = new_count
		unlocked_cards[card_id] = data
	var plus_id: String = get_plus_card_id(card_id)
	var display_name: String = base_name
	if not display_name.ends_with("+"):
		display_name = "%s+" % display_name
	var plus_entry: Dictionary = {
		"id": plus_id,
		"tier": "plus",
		"evolved_from": card_id,
		"name": display_name,
		"count": get_card_owned_count(plus_id) + 1,
	}
	unlocked_cards[plus_id] = plus_entry
	card_collected.emit(plus_id, plus_entry)
	equipped_cards_changed.emit()
	save_profile()
	return true


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
	return get_shop_wallet_balance(upgrade_id) >= cost


func can_decrease_shop(_upgrade_id: String) -> bool:
	return false


func purchase_shop_upgrade(upgrade_id: String) -> bool:
	if not can_purchase_shop(upgrade_id):
		return false
	var cost: int = get_shop_cost(upgrade_id)
	var paid: bool = false
	if _MetaShop.uses_campaign_currency(upgrade_id):
		paid = spend_campaign_zeny(cost)
	else:
		paid = spend_zeny(cost)
	if not paid:
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
	if card_id != "" and not can_equip_card_to_slot(card_id, slot_index):
		return
	_ensure_equipped_slots()
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
	return count_equipped_card(card_id) > 0


func get_equipped_cards_clean() -> Array[String]:
	return get_equipped_cards_all_slots()


func get_equipped_cards_all_slots() -> Array[String]:
	var result: Array[String] = []
	_ensure_equipped_slots()
	for i: int in _CardStats.MAX_EQUIPPED:
		var id: String = String(equipped_cards[i])
		if id == "" or not unlocked_cards.has(id):
			continue
		if count_equipped_card(id) > get_card_owned_count(id):
			continue
		result.append(id)
	return result


func _ensure_equipped_slots() -> void:
	while equipped_cards.size() < _CardStats.MAX_EQUIPPED:
		equipped_cards.append("")
	while equipped_cards.size() > _CardStats.MAX_EQUIPPED:
		equipped_cards.pop_back()


func _sanitize_equipped_cards() -> void:
	_ensure_equipped_slots()
	var equipped_totals: Dictionary = {}
	for i: int in _CardStats.MAX_EQUIPPED:
		var id: String = String(equipped_cards[i])
		if id == "":
			continue
		if not unlocked_cards.has(id):
			equipped_cards[i] = ""
			continue
		equipped_totals[id] = int(equipped_totals.get(id, 0)) + 1
	for i: int in _CardStats.MAX_EQUIPPED:
		var id: String = String(equipped_cards[i])
		if id == "":
			continue
		if int(equipped_totals.get(id, 0)) > get_card_owned_count(id):
			equipped_cards[i] = ""
			equipped_totals[id] = int(equipped_totals.get(id, 0)) - 1


## Aplica tienda + cartas al jugador al iniciar la run.
func apply_run_bonuses_to_player(player: Node) -> void:
	if player == null:
		return
	var shop: Dictionary = _MetaShop.collect_run_bonuses(shop_purchases)
	var card_agg: Dictionary = _CardStats.aggregate_equipped(get_equipped_cards_all_slots())
	shop["card_stats"] = card_agg
	if player.has_method("apply_meta_bonuses"):
		player.apply_meta_bonuses(shop)


func reset_session() -> void:
	session_level = 1
	session_xp = 0
	session_elapsed_time = 0.0
	run_zeny = 0
	run_campaign_zeny = 0
	run_card_drops.clear()
	payon_map2_stat_boost_used = false
	orc_map3_stat_boost_used = false
	run_orc_hero_card_dropped = false
	_damage_dealt_log.clear()
	reset_map_tombola_tools()
	run_cards_changed.emit()
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
		"cards_count": get_total_owned_card_copies(),
		"run_card_drops": run_card_drops.duplicate(),
		"run_consumables": run_consumables.duplicate(),
		"class_id": current_class,
		"map_id": Game.selected_map_id,
	}


func save_profile() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.set_value("profile", "total_zeny", total_zeny)
	cfg.set_value("profile", "campaign_zeny", campaign_zeny)
	cfg.set_value("profile", "shop_purchases", shop_purchases.duplicate())
	cfg.set_value("profile", "equipped_cards", equipped_cards.duplicate())
	cfg.set_value("progress", "map_1_cleared", map_1_cleared)
	cfg.set_value("progress", "boss_1_discovered", boss_1_discovered)
	cfg.set_value("progress", "boss_2_discovered", boss_2_discovered)
	cfg.set_value("progress", "map_2_cleared", map_2_cleared)
	cfg.set_value("progress", "boss_3_discovered", boss_3_discovered)
	cfg.set_value("profile", "player_skin_id", player_skin_id)
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
	campaign_zeny = int(cfg.get_value("profile", "campaign_zeny", 0))
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
	unlocked_cards.clear()
	var keys: Variant = cfg.get_value("profile", "unlocked_card_keys", PackedStringArray())
	if keys is PackedStringArray:
		for key: String in keys:
			var data: Variant = cfg.get_value("cards", key, {})
			if data is Dictionary:
				var card_data: Dictionary = data
				if not card_data.has("count"):
					card_data["count"] = 1
				unlocked_cards[key] = card_data
	_sanitize_equipped_cards()
	map_1_cleared = bool(cfg.get_value("progress", "map_1_cleared", false))
	boss_1_discovered = bool(cfg.get_value("progress", "boss_1_discovered", false))
	boss_2_discovered = bool(cfg.get_value("progress", "boss_2_discovered", false))
	map_2_cleared = bool(cfg.get_value("progress", "map_2_cleared", false))
	boss_3_discovered = bool(cfg.get_value("progress", "boss_3_discovered", false))
	var loaded_skin: String = String(cfg.get_value("profile", "player_skin_id", _SkinCatalog.SKIN_BLUE_CAT))
	player_skin_id = loaded_skin if _SkinCatalog.is_valid(loaded_skin) else _SkinCatalog.SKIN_BLUE_CAT
	Game.selected_player_skin_id = player_skin_id
	profile_loaded.emit()


func is_map_unlocked(map_id: String) -> bool:
	if map_id == _MapConfig.MAP_PRONTERA:
		return true
	if map_id == _MapConfig.MAP_PAYON:
		return map_1_cleared
	if map_id == _MapConfig.MAP_ORC_VILLAGE:
		return map_2_cleared
	return false


func is_boss_discovered_for_map(map_id: String) -> bool:
	if map_id == _MapConfig.MAP_PRONTERA:
		return boss_1_discovered
	if map_id == _MapConfig.MAP_PAYON:
		return boss_2_discovered
	if map_id == _MapConfig.MAP_ORC_VILLAGE:
		return boss_3_discovered
	return false


func on_boss_spawned_in_run(map_id: String) -> void:
	var changed: bool = false
	if map_id == _MapConfig.MAP_PRONTERA and not boss_1_discovered:
		boss_1_discovered = true
		changed = true
	elif map_id == _MapConfig.MAP_PAYON and not boss_2_discovered:
		boss_2_discovered = true
		changed = true
	elif map_id == _MapConfig.MAP_ORC_VILLAGE and not boss_3_discovered:
		boss_3_discovered = true
		changed = true
	if changed:
		save_profile()


func on_map_cleared(map_id: String) -> void:
	var changed: bool = false
	if map_id == _MapConfig.MAP_PRONTERA and not map_1_cleared:
		map_1_cleared = true
		changed = true
	elif map_id == _MapConfig.MAP_PAYON and not map_2_cleared:
		map_2_cleared = true
		changed = true
	if changed:
		save_profile()


## Borra progreso persistente y reinicia variables de campaña (nuevo juego).
func wipe_all_progress() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	total_zeny = 0
	campaign_zeny = 0
	unlocked_cards.clear()
	shop_purchases = _MetaShop.build_default_purchases()
	equipped_cards = ["", "", "", "", ""]
	map_1_cleared = false
	boss_1_discovered = false
	boss_2_discovered = false
	map_2_cleared = false
	boss_3_discovered = false
	player_skin_id = _SkinCatalog.SKIN_BLUE_CAT
	Game.selected_player_skin_id = player_skin_id
	run_card_drops.clear()
	reset_session()
	shop_updated.emit()
	equipped_cards_changed.emit()
	run_cards_changed.emit()
	save_profile()
	profile_loaded.emit()


func select_character(character: CharacterData) -> void:
	selected_character = character


func select_character_and_class(
	character: CharacterData,
	class_data: ClassData,
	skin_id: String = ""
) -> void:
	selected_character = character
	selected_class_data = class_data
	var gameplay_class_id: String = class_data.class_id
	if gameplay_class_id.is_empty():
		return
	select_class_for_run(gameplay_class_id, skin_id)


func select_class_for_run(class_id: String, skin_id: String = "") -> void:
	base_class_id = class_id
	current_class = class_id
	Game.selected_class_id = class_id
	if not skin_id.is_empty() and _SkinCatalog.is_valid(skin_id):
		set_player_skin(skin_id)


func set_player_skin(skin_id: String) -> void:
	if not _SkinCatalog.is_valid(skin_id):
		return
	player_skin_id = skin_id
	Game.selected_player_skin_id = skin_id
	save_profile()


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


func debug_set_card_drop_test_percent(percent: float) -> void:
	if percent < 0.0:
		debug_card_drop_chance = -1.0
		return
	debug_card_drop_chance = clampf(percent, 0.0, 1.0)


func debug_is_card_drop_test_mode() -> bool:
	return debug_card_drop_chance >= 0.0


## Desbloquea Orc Village en el selector (marca Payon como completado).
func debug_unlock_orc_village() -> void:
	map_1_cleared = true
	map_2_cleared = true
	boss_1_discovered = true
	boss_2_discovered = true
	boss_3_discovered = true
	save_profile()


# --- Árbol de habilidades ---

func init_run_skill_tree(class_id: String) -> void:
	base_class_id = class_id
	current_class = class_id
	run_skill_levels.clear()
	run_stat_levels.clear()
	run_skill_disabled_for_combat.clear()
	selected_character = null
	selected_class_data = null
	tombola_skill_upgrades_this_run = 0
	job_change_event_pending = false
	active_skill_slots = {
		_SkillTree.SLOT_LMB: "",
		_SkillTree.SLOT_RMB: "",
		_SkillTree.SLOT_SPACE: "",
		_SkillTree.SLOT_Q: "",
		_SkillTree.SLOT_E: "",
	}
	_CombatKit.reset_for_new_run()
	run_consumables.clear()
	consumable_hotkeys.clear()
	var starters: Dictionary = _SkillTree.get_starter_levels(class_id)
	for skill_id: String in starters:
		run_skill_levels[skill_id] = int(starters[skill_id])
	skill_tree_changed.emit()
	active_slots_changed.emit()


func get_skill_level(skill_id: String) -> int:
	return int(run_skill_levels.get(skill_id, 0))


## Configuración de spritesheet VFX de combate (32×32 → escala 16×16 en runtime).
func get_skill_vfx_config(skill_id: String, role_key: String = "projectile") -> SkillVfxSheetConfig:
	return SkillDefinitions.get_vfx_config(skill_id, role_key)


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
		_CombatKit.auto_add_if_room(skill_id)
	skill_tree_changed.emit()
	_check_job_change_ready()
	_check_pending_fusions()
	return true


func can_grant_skill_level(skill_id: String) -> bool:
	var def: Dictionary = _SkillTree.get_skill(skill_id)
	if def.is_empty():
		return false
	if bool(def.get("is_fusion", false)):
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
	if skill_id.is_empty():
		clear_kit_slot(slot_id)
	else:
		assign_kit_slot(slot_id, skill_id)


func get_kit_slot_assignment(slot_id: String) -> String:
	if not _SkillTree.ALL_SLOT_IDS.has(slot_id):
		return ""
	return String(active_skill_slots.get(slot_id, ""))


## Asigna una habilidad manual a una ranura de input (LMB/RMB/Space/Q/E) y persiste en el kit.
func assign_kit_slot(slot_id: String, skill_id: String) -> bool:
	if not _SkillTree.ALL_SLOT_IDS.has(slot_id):
		return false
	if skill_id.is_empty():
		return clear_kit_slot(slot_id)
	if get_skill_level(skill_id) <= 0:
		return false
	if not _SkillTree.is_manual_slot_skill(skill_id):
		return false
	if is_skill_disabled_for_combat(skill_id):
		return false
	for other_slot: String in _SkillTree.ALL_SLOT_IDS:
		if String(active_skill_slots.get(other_slot, "")) == skill_id:
			active_skill_slots[other_slot] = ""
	active_skill_slots[slot_id] = skill_id
	_CombatKit.sync_from_active_slots()
	active_slots_changed.emit()
	combat_kit_changed.emit()
	return true


func clear_kit_slot(slot_id: String) -> bool:
	if not _SkillTree.ALL_SLOT_IDS.has(slot_id):
		return false
	if String(active_skill_slots.get(slot_id, "")).is_empty():
		return false
	active_skill_slots[slot_id] = ""
	_CombatKit.sync_from_active_slots()
	active_slots_changed.emit()
	combat_kit_changed.emit()
	return true


func get_slot_skill(slot_id: String) -> String:
	var skill_id: String = String(active_skill_slots.get(slot_id, ""))
	if skill_id.is_empty():
		return ""
	if get_skill_level(skill_id) <= 0:
		return ""
	if is_skill_disabled_for_combat(skill_id):
		return ""
	return skill_id


## Otorga una habilidad de fusión (Nv.1) antes de consumir ingredientes — transacción segura.
func grant_fusion_skill(fusion_id: String) -> bool:
	if fusion_id.is_empty():
		return false
	var def: Dictionary = _SkillTree.get_skill(fusion_id)
	if def.is_empty() or not bool(def.get("is_fusion", false)):
		return false
	if get_skill_level(fusion_id) > 0:
		return true
	run_skill_levels[fusion_id] = 1
	if _SkillTree.is_manual_slot_skill(fusion_id):
		_CombatKit.auto_add_if_room(fusion_id)
	skill_tree_changed.emit()
	return true


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
	_check_pending_fusions()
	return true


func get_run_stat_bonus(stat_id: String) -> float:
	return _RunStats.get_bonus_fraction(get_run_stat_level(stat_id))


func get_xp_multiplier() -> float:
	return 1.0 + get_run_stat_bonus(_RunStats.STAT_XP_GAIN) \
		+ _MetaShop.get_total_bonus(_MetaShop.UPGRADE_XP_GAIN, get_shop_purchase_count(_MetaShop.UPGRADE_XP_GAIN))


func get_zeny_multiplier() -> float:
	var mult: float = 1.0 + get_run_stat_bonus(_RunStats.STAT_COMMERCIAL_LUCK) \
		+ _MetaShop.get_total_bonus(_MetaShop.UPGRADE_ZENY_GAIN, get_shop_purchase_count(_MetaShop.UPGRADE_ZENY_GAIN))
	if _MapConfig.is_campaign_tier_map(Game.selected_map_id):
		mult += _MetaShop.get_total_bonus(
			_MetaShop.UPGRADE_CAMPAIGN_FORTUNE,
			get_shop_purchase_count(_MetaShop.UPGRADE_CAMPAIGN_FORTUNE)
		)
	return mult


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


func get_mystical_amplification_multiplier() -> float:
	if base_class_id != Game.CLASS_MAGE:
		return 1.0
	var lv: int = get_run_stat_level(_RunStats.STAT_MYSTICAL_AMPLIFICATION)
	return 1.0 + float(lv) * 0.20


func get_energy_coat_ratio() -> float:
	if base_class_id != Game.CLASS_MAGE:
		return 0.0
	var lv: int = get_run_stat_level(_RunStats.STAT_ENERGY_COAT)
	return clampf(float(lv) * 0.10, 0.0, 0.50)


func get_shield_up_ratio() -> float:
	if base_class_id != Game.CLASS_SWORDMAN:
		return 0.0
	var lv: int = get_run_stat_level(_RunStats.STAT_SHIELD_UP)
	return clampf(float(lv) * 0.10, 0.0, 0.50)


func get_spell_pierce_chance() -> float:
	if base_class_id != Game.CLASS_MAGE:
		return 0.0
	var lv: int = get_run_stat_level(_RunStats.STAT_SPELL_PIERCE)
	return clampf(float(lv) * 0.10, 0.0, 0.50)


func get_fatal_blow_proc_chance() -> float:
	if base_class_id != Game.CLASS_SWORDMAN:
		return 0.0
	var lv: int = get_run_stat_level(_RunStats.STAT_FATAL_BLOW)
	return clampf(float(lv) * 0.10, 0.0, 0.50)


func get_sword_mastery_run_multiplier() -> float:
	if base_class_id != Game.CLASS_SWORDMAN:
		return 1.0
	var lv: int = get_run_stat_level(_RunStats.STAT_SWORD_MASTERY)
	return 1.0 + float(lv) * 0.20


func get_attack_speed_multiplier() -> float:
	return (1.0 + get_run_stat_bonus(_RunStats.STAT_ATTACK_SPEED)) \
		* _MetaShop.get_bonus_multiplier(
			_MetaShop.UPGRADE_ATTACK_SPEED, get_shop_purchase_count(_MetaShop.UPGRADE_ATTACK_SPEED)
		) \
		* _MetaShop.get_bonus_multiplier(
			_MetaShop.UPGRADE_CAMPAIGN_SWIFTNESS,
			get_shop_purchase_count(_MetaShop.UPGRADE_CAMPAIGN_SWIFTNESS)
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
	_grant_available_fusions(new_job)
	job_change_ready.emit(new_job)
	return true


func _auto_assign_active_slot(skill_id: String) -> void:
	if not _SkillTree.is_manual_slot_skill(skill_id):
		return
	for slot_id: String in _SkillTree.ALL_SLOT_IDS:
		if String(active_skill_slots.get(slot_id, "")).is_empty():
			active_skill_slots[slot_id] = skill_id
			_CombatKit.sync_from_active_slots()
			active_slots_changed.emit()
			combat_kit_changed.emit()
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


func needs_campaign_job_change() -> bool:
	return current_class == base_class_id and not base_class_id.is_empty()


func get_campaign_job_options() -> Array[String]:
	if base_class_id == Game.CLASS_MAGE:
		return [Game.JOB_WIZARD, Game.JOB_SAGE]
	if base_class_id == Game.CLASS_SWORDMAN:
		return [Game.JOB_KNIGHT, Game.JOB_CRUSADER]
	return []


func apply_campaign_job_change(new_job: String) -> bool:
	var options: Array[String] = get_campaign_job_options()
	if not options.has(new_job):
		return false
	current_class = new_job
	job_change_event_pending = true
	_grant_available_fusions(new_job)
	job_change_ready.emit(new_job)
	return true


func _check_pending_fusions() -> void:
	if not _JobFusion.is_advanced_job(current_class):
		return
	_grant_available_fusions(current_class)


## Reintenta fusiones pendientes (p. ej. al abrir el árbol de habilidades).
func retry_pending_fusions() -> Array[String]:
	if not _JobFusion.is_advanced_job(current_class):
		return []
	return _grant_available_fusions(current_class)


func _grant_available_fusions(job_id: String) -> Array[String]:
	if not _JobFusion.is_advanced_job(job_id):
		return []
	var granted: Array[String] = _JobFusion.try_apply_fusions(job_id)
	for fusion_id: String in granted:
		var display_name: String = String(_SkillTree.get_skill(fusion_id).get("display_name", fusion_id))
		fusion_unlocked.emit(fusion_id, display_name)
	if not granted.is_empty():
		skill_tree_changed.emit()
		active_slots_changed.emit()
		combat_kit_changed.emit()
	return granted


func record_damage_dealt(amount: int) -> void:
	if amount <= 0:
		return
	_damage_dealt_log.append({"t": session_elapsed_time, "dmg": amount})
	_trim_damage_log()
	dps_updated.emit(get_dps_last_seconds(DPS_WINDOW_SEC))


func get_dps_last_seconds(window_sec: float = DPS_WINDOW_SEC) -> float:
	_trim_damage_log()
	var cutoff: float = session_elapsed_time - window_sec
	var total: int = 0
	for entry: Dictionary in _damage_dealt_log:
		if float(entry.get("t", 0.0)) >= cutoff:
			total += int(entry.get("dmg", 0))
	var span: float = maxf(window_sec, 0.001)
	return float(total) / span


func _trim_damage_log() -> void:
	var cutoff: float = session_elapsed_time - (DPS_WINDOW_SEC + 2.0)
	while not _damage_dealt_log.is_empty():
		var first: Dictionary = _damage_dealt_log[0]
		if float(first.get("t", 0.0)) >= cutoff:
			break
		_damage_dealt_log.remove_at(0)
