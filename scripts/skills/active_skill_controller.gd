## Ranuras activas LMB / RMB / Space: input, cooldowns y señales al HUD.
class_name ActiveSkillController
extends Node

signal slot_cooldown_updated(slot_id: String, ratio: float)
signal slot_skills_changed

const _SkillDefs = preload("res://data/skill_definitions.gd")
const _Consumables = preload("res://scripts/inventory/consumable_inventory.gd")

var _player: Player = null
var _slot_cooldowns: Dictionary = {}
var _slot_timers: Dictionary = {}


func bind_player(player: Player) -> void:
	_player = player
	_reset_slot_timers()
	if not Global.active_slots_changed.is_connected(_on_active_slots_changed):
		Global.active_slots_changed.connect(_on_active_slots_changed)
	if not Global.skill_tree_changed.is_connected(_on_skill_tree_changed):
		Global.skill_tree_changed.connect(_on_skill_tree_changed)
	slot_skills_changed.emit()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_INHERIT
	for slot_id: String in SkillTreeCatalog.ALL_SLOT_IDS:
		_slot_cooldowns[slot_id] = 0.0


func _reset_slot_timers() -> void:
	for slot_id: String in SkillTreeCatalog.ALL_SLOT_IDS:
		if _slot_timers.has(slot_id) and _slot_timers[slot_id] != null:
			(_slot_timers[slot_id] as Timer).queue_free()
		var timer: Timer = Timer.new()
		timer.one_shot = true
		timer.process_callback = Timer.TIMER_PROCESS_IDLE
		add_child(timer)
		timer.timeout.connect(_on_slot_cooldown_finished.bind(slot_id))
		_slot_timers[slot_id] = timer
		_slot_cooldowns[slot_id] = 0.0


func _process(delta: float) -> void:
	for slot_id: String in SkillTreeCatalog.ALL_SLOT_IDS:
		var remaining: float = float(_slot_cooldowns.get(slot_id, 0.0))
		if remaining <= 0.0:
			continue
		remaining = maxf(remaining - delta, 0.0)
		_slot_cooldowns[slot_id] = remaining
		_emit_cooldown_ratio(slot_id)


func try_handle_input(event: InputEvent) -> bool:
	if _player == null or not _player.is_alive():
		return false
	if get_tree().paused:
		return false
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if not mouse_event.pressed:
			return false
		var slot_id: String = ""
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			slot_id = SkillTreeCatalog.SLOT_LMB
		elif mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			slot_id = SkillTreeCatalog.SLOT_RMB
		if not slot_id.is_empty() and try_cast_slot(slot_id):
			return true
	for slot_id: String in SkillTreeCatalog.ALL_SLOT_IDS:
		var action: String = String(_SkillDefs.SLOT_TO_INPUT.get(slot_id, ""))
		if action.is_empty() or not event.is_action_pressed(action):
			continue
		if try_cast_slot(slot_id):
			return true
	for i: int in range(1, 10):
		var consumable_action: String = "consumable_%d" % i
		if event.is_action_pressed(consumable_action):
			if _Consumables.try_use_hotkey(i, _player):
				return true
	return false


func try_cast_slot(slot_id: String) -> bool:
	if _player == null or float(_slot_cooldowns.get(slot_id, 0.0)) > 0.0:
		return false
	var skill_id: String = Global.get_slot_skill(slot_id)
	if skill_id.is_empty():
		return false
	if Global.get_skill_level(skill_id) <= 0:
		return false
	if not SkillTreeCatalog.is_manual_slot_skill(skill_id):
		return false
	if not _player.cast_skill_by_id(skill_id):
		return false
	_start_slot_cooldown(slot_id, skill_id)
	return true


func get_slot_cooldown_ratio(slot_id: String) -> float:
	var skill_id: String = Global.get_slot_skill(slot_id)
	if skill_id.is_empty():
		return 0.0
	var total: float = Global.get_skill_cooldown(skill_id)
	if total <= 0.0:
		return 0.0
	return clampf(float(_slot_cooldowns.get(slot_id, 0.0)) / total, 0.0, 1.0)


func get_slot_display_level(slot_id: String) -> int:
	var skill_id: String = Global.get_slot_skill(slot_id)
	if skill_id.is_empty():
		return 0
	return Global.get_skill_level(skill_id)


func _start_slot_cooldown(slot_id: String, skill_id: String) -> void:
	var duration: float = _player.get_effective_skill_cooldown(skill_id)
	_slot_cooldowns[slot_id] = duration
	var timer: Timer = _slot_timers.get(slot_id) as Timer
	if timer:
		timer.start(duration)
	_emit_cooldown_ratio(slot_id)


func _emit_cooldown_ratio(slot_id: String) -> void:
	slot_cooldown_updated.emit(slot_id, get_slot_cooldown_ratio(slot_id))


func _on_slot_cooldown_finished(slot_id: String) -> void:
	_slot_cooldowns[slot_id] = 0.0
	_emit_cooldown_ratio(slot_id)


func _on_active_slots_changed() -> void:
	slot_skills_changed.emit()


func _on_skill_tree_changed() -> void:
	if _player:
		_player.sync_from_skill_tree()
	slot_skills_changed.emit()
