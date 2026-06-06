## Registro compartido de habilidades, slots e iconos.
class_name SkillDefinitions
extends RefCounted

const GROUP_ENEMIES: String = "Enemigos"
const DEFAULT_ICON: String = "res://art/skills/default_icon.png"

const INPUT_SPACE: String = "skill_space"
const INPUT_Q: String = "skill_q"
const INPUT_E: String = "skill_e"

## LMB/RMB se leen como InputEventMouseButton en ActiveSkillController.
const SLOT_TO_INPUT: Dictionary = {
	SkillTreeCatalog.SLOT_LMB: "",
	SkillTreeCatalog.SLOT_RMB: "",
	SkillTreeCatalog.SLOT_SPACE: INPUT_SPACE,
	SkillTreeCatalog.SLOT_Q: INPUT_Q,
	SkillTreeCatalog.SLOT_E: INPUT_E,
}

const SLOT_LABELS: Dictionary = {
	SkillTreeCatalog.SLOT_LMB: "Clic IZQ",
	SkillTreeCatalog.SLOT_RMB: "Clic DER",
	SkillTreeCatalog.SLOT_SPACE: "Espacio",
	SkillTreeCatalog.SLOT_Q: "Q",
	SkillTreeCatalog.SLOT_E: "E",
}

const _VfxRegistry = preload("res://data/skill_vfx_registry.gd")


static func get_vfx_config(skill_id: String, role_key: String = "projectile") -> SkillVfxSheetConfig:
	return _VfxRegistry.get_config(skill_id, role_key)


static func has_vfx_config(skill_id: String, role_key: String = "projectile") -> bool:
	return _VfxRegistry.has_config(skill_id, role_key)


static func get_icon_texture(skill_id: String) -> Texture2D:
	var path: String = String(SkillTreeCatalog.get_skill(skill_id).get("icon_path", DEFAULT_ICON))
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	if ResourceLoader.exists(DEFAULT_ICON):
		return load(DEFAULT_ICON) as Texture2D
	return null
