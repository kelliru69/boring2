## Kit de combate: máximo 5 habilidades activas manuales en ranuras de input.
class_name CombatKitService
extends RefCounted

const MAX_EQUIPPED: int = SkillTreeCatalog.MAX_COMBAT_ACTIVE_SKILLS


static func get_equipped_skill_ids() -> Array[String]:
	_rebuild_kit_id_list()
	var ids: Array[String] = []
	for raw: Variant in Global.combat_kit_skill_ids:
		ids.append(String(raw))
	return ids


static func count_equipped_in_slots() -> int:
	var total: int = 0
	for slot_id: String in SkillTreeCatalog.ALL_SLOT_IDS:
		if not Global.get_kit_slot_assignment(slot_id).is_empty():
			total += 1
	return total


static func count_equipped() -> int:
	return count_equipped_in_slots()


static func is_equipped(skill_id: String) -> bool:
	if skill_id.is_empty():
		return false
	for slot_id: String in SkillTreeCatalog.ALL_SLOT_IDS:
		if Global.get_kit_slot_assignment(slot_id) == skill_id:
			return true
	return false


static func can_equip_more() -> bool:
	return count_equipped_in_slots() < MAX_EQUIPPED


static func get_unlocked_manual_skills() -> Array[String]:
	var result: Array[String] = []
	for skill_id: String in SkillTreeCatalog.get_skills_for_class(SkillTreeCatalog.resolve_tree_view_class_id()):
		if Global.get_skill_level(skill_id) <= 0:
			continue
		if not SkillTreeCatalog.is_manual_slot_skill(skill_id):
			continue
		if Global.is_skill_disabled_for_combat(skill_id):
			continue
		result.append(skill_id)
	return result


static func assign_skill_to_slot(slot_id: String, skill_id: String) -> bool:
	return Global.assign_kit_slot(slot_id, skill_id)


static func clear_slot(slot_id: String) -> bool:
	return Global.clear_kit_slot(slot_id)


static func auto_add_if_room(skill_id: String) -> void:
	if not SkillTreeCatalog.is_manual_slot_skill(skill_id):
		return
	if is_equipped(skill_id):
		return
	for slot_id: String in SkillTreeCatalog.ALL_SLOT_IDS:
		if Global.get_kit_slot_assignment(slot_id).is_empty():
			Global.assign_kit_slot(slot_id, skill_id)
			return


static func sync_from_active_slots() -> void:
	_rebuild_kit_id_list()


static func _rebuild_kit_id_list() -> void:
	var ids: Array[String] = []
	for slot_id: String in SkillTreeCatalog.ALL_SLOT_IDS:
		var skill_id: String = Global.get_kit_slot_assignment(slot_id)
		if skill_id.is_empty():
			continue
		if not ids.has(skill_id):
			ids.append(skill_id)
	Global.combat_kit_skill_ids = ids


static func reset_for_new_run() -> void:
	Global.combat_kit_skill_ids.clear()
	for slot_id: String in SkillTreeCatalog.ALL_SLOT_IDS:
		Global.active_skill_slots[slot_id] = ""
