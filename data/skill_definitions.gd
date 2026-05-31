## Registro compartido de habilidades, slots e iconos.
class_name SkillDefinitions
extends RefCounted

const GROUP_ENEMIES: String = "Enemigos"
const DEFAULT_ICON: String = "res://art/skills/default_icon.png"

const INPUT_SPACE: String = "skill_space"

## LMB/RMB se leen como InputEventMouseButton en ActiveSkillController.
const SLOT_TO_INPUT: Dictionary = {
	SkillTreeCatalog.SLOT_LMB: "",
	SkillTreeCatalog.SLOT_RMB: "",
	SkillTreeCatalog.SLOT_SPACE: INPUT_SPACE,
}

const SLOT_LABELS: Dictionary = {
	SkillTreeCatalog.SLOT_LMB: "Clic IZQ",
	SkillTreeCatalog.SLOT_RMB: "Clic DER",
	SkillTreeCatalog.SLOT_SPACE: "Espacio",
}


static func get_icon_texture(skill_id: String) -> Texture2D:
	var path: String = String(SkillTreeCatalog.get_skill(skill_id).get("icon_path", DEFAULT_ICON))
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	if ResourceLoader.exists(DEFAULT_ICON):
		return load(DEFAULT_ICON) as Texture2D
	return null
