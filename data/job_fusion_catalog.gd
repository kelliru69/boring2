## Fusión de habilidades (Job Change) — 4 por clase avanzada.
class_name JobFusionCatalog
extends RefCounted

# Wizard
const SKILL_LORD_OF_VERMILION: String = "lord_of_vermilion"
const SKILL_STORM_GUST: String = "storm_gust"
const SKILL_METEOR_STORM: String = "meteor_storm"
const SKILL_JUPITEL_THUNDER: String = "jupitel_thunder"

# Sage
const SKILL_LAND_PROTECTOR: String = "land_protector"
const SKILL_HEAVENS_DRIVE: String = "heavens_drive"
const SKILL_AUTOCAST: String = "autocast"
const SKILL_DIAMOND_DUST: String = "diamond_dust"

# Knight
const SKILL_VANGUARD_FORCE: String = "vanguard_force"
const SKILL_SPIRAL_PIERCE: String = "spiral_pierce"
const SKILL_KNIGHTS_RUSH: String = "knights_rush"
const SKILL_TWO_HAND_QUICKEN: String = "two_hand_quicken"

# Crusader
const SKILL_GRAND_CROSS: String = "grand_cross"
const SKILL_SHIELD_BOOMERANG: String = "shield_boomerang"
const SKILL_REFLECT_SHIELD: String = "reflect_shield"
const SKILL_SACRED_HAMMER: String = "sacred_hammer"

const FUSION_REQUIRED_LEVEL: int = 5

const _SkillTree = preload("res://data/skill_tree_catalog.gd")
const _RunStats = preload("res://data/run_stat_catalog.gd")


static func is_advanced_job(job_id: String) -> bool:
	return job_id in [Game.JOB_WIZARD, Game.JOB_SAGE, Game.JOB_KNIGHT, Game.JOB_CRUSADER]


static func is_fusion_owned(fusion_id: String) -> bool:
	return Global.get_skill_level(fusion_id) > 0


static func get_job_display_name(job_id: String) -> String:
	match job_id:
		Game.JOB_WIZARD:
			return "Wizard"
		Game.JOB_SAGE:
			return "Sage"
		Game.JOB_KNIGHT:
			return "Knight"
		Game.JOB_CRUSADER:
			return "Crusader"
		_:
			return job_id.capitalize()


static func get_job_description(job_id: String) -> String:
	match job_id:
		Game.JOB_WIZARD:
			return "AoE devastador: tormentas, meteoros y rayos con knockback."
		Game.JOB_SAGE:
			return "Control: zona segura, Heaven's Drive, Autocast y Diamond Dust."
		Game.JOB_KNIGHT:
			return "Melee explosivo + Two-Hand Quicken (×2 velocidad de ataque)."
		Game.JOB_CRUSADER:
			return "Sagrado: Grand Cross, Shield Boomerang y Reflect Shield."
		_:
			return ""


static func get_fusion_recipes_for_job(job_id: String) -> Array[Dictionary]:
	var recipes: Array[Dictionary] = []
	match job_id:
		Game.JOB_WIZARD:
			recipes.append(_recipe(SKILL_LORD_OF_VERMILION, ["thunderstorm", "sight"], "Lord of Vermilion"))
			recipes.append(_recipe(SKILL_STORM_GUST, ["frost_diver", "cold_bolt"], "Storm Gust"))
			recipes.append(_recipe(SKILL_METEOR_STORM, ["fire_bolt", "firewall"], "Meteor Storm"))
			recipes.append(_recipe(SKILL_JUPITEL_THUNDER, ["soul_strike", "lightning_bolt"], "Jupitel Thunder"))
		Game.JOB_SAGE:
			recipes.append(_recipe(SKILL_LAND_PROTECTOR, ["sight", "firewall"], "Land Protector"))
			recipes.append(_recipe(SKILL_HEAVENS_DRIVE, ["frost_diver", "thunderstorm"], "Heaven's Drive"))
			recipes.append(_recipe(SKILL_AUTOCAST, ["soul_strike", "cold_bolt"], "Autocast"))
			recipes.append(_recipe(SKILL_DIAMOND_DUST, ["fire_bolt", "lightning_bolt"], "Diamond Dust"))
		Game.JOB_KNIGHT:
			recipes.append(_recipe(
				SKILL_VANGUARD_FORCE,
				["bowling_bash", "bash"],
				"Vanguard Force",
				["bowling_bash", "stat_fatal_blow"]
			))
			recipes.append(_recipe(SKILL_SPIRAL_PIERCE, ["spear_stab", "magnum_break"], "Spiral Pierce"))
			recipes.append(_recipe(SKILL_KNIGHTS_RUSH, ["endure", "moving_recovery"], "Knight's Rush"))
			recipes.append(_recipe(SKILL_TWO_HAND_QUICKEN, ["auto_berserk", "spear_stab"], "Two-Hand Quicken"))
		Game.JOB_CRUSADER:
			recipes.append(_recipe(SKILL_GRAND_CROSS, ["magnum_break", "endure"], "Grand Cross"))
			recipes.append(_recipe(SKILL_SHIELD_BOOMERANG, ["bowling_bash", "bash"], "Shield Boomerang"))
			recipes.append(_recipe(SKILL_REFLECT_SHIELD, ["increase_hp_recovery", "auto_berserk"], "Reflect Shield"))
			recipes.append(_recipe(SKILL_SACRED_HAMMER, ["moving_recovery", "spear_stab"], "Sacred Hammer"))
	return recipes


static func _recipe(
	fusion_skill: String,
	ingredients: Array,
	display_name: String,
	alt_ingredients: Array = []
) -> Dictionary:
	var recipe: Dictionary = {
		"fusion_skill": fusion_skill,
		"ingredients": ingredients,
		"display_name": display_name,
	}
	if not alt_ingredients.is_empty():
		recipe["alt_ingredients"] = alt_ingredients
	return recipe


static func try_apply_fusions(job_id: String) -> Array[String]:
	var granted: Array[String] = []
	for recipe: Dictionary in get_fusion_recipes_for_job(job_id):
		var fusion_id: String = String(recipe.get("fusion_skill", ""))
		if fusion_id.is_empty() or is_fusion_owned(fusion_id):
			continue
		if not _recipe_satisfied(recipe):
			continue
		_consume_recipe_ingredients(recipe)
		granted.append(fusion_id)
	return granted


static func get_map3_passive_stat_ids(job_id: String) -> Array[String]:
	match job_id:
		Game.JOB_WIZARD:
			return [_RunStats.STAT_AOE_MASTERY]
		Game.JOB_SAGE:
			return [_RunStats.STAT_FREE_CAST, _RunStats.STAT_PROJECTILE_MULT]
		Game.JOB_KNIGHT:
			return [_RunStats.STAT_MELEE_FURY]
		Game.JOB_CRUSADER:
			return [_RunStats.STAT_SACRED_REGEN]
		_:
			return []


static func describe_recipe_for_job_change(recipe: Dictionary) -> String:
	var fusion_name: String = String(recipe.get("display_name", ""))
	if _recipe_satisfied(recipe):
		return "%s — se fusionará al elegir esta clase" % fusion_name
	var missing: String = _format_missing_requirements(recipe)
	return "%s — se desbloqueará al subir %s a Nv.5" % [fusion_name, missing]


static func get_imminent_fusion_names(job_id: String, upgrade_id: String) -> Array[String]:
	var names: Array[String] = []
	if not is_advanced_job(job_id):
		return names
	for recipe: Dictionary in get_fusion_recipes_for_job(job_id):
		var fusion_id: String = String(recipe.get("fusion_skill", ""))
		if fusion_id.is_empty() or is_fusion_owned(fusion_id):
			continue
		if not _recipe_will_satisfy_after_upgrade(recipe, upgrade_id):
			continue
		names.append(String(recipe.get("display_name", fusion_id)))
	return names


static func _recipe_satisfied(recipe: Dictionary) -> bool:
	var ingredients: Array = recipe.get("ingredients", [])
	if _ingredients_at_level(ingredients, FUSION_REQUIRED_LEVEL):
		return true
	var alt: Array = recipe.get("alt_ingredients", [])
	return not alt.is_empty() and _alt_ingredients_satisfied(alt)


static func _ingredients_at_level(ingredients: Array, required_level: int) -> bool:
	if ingredients.is_empty():
		return false
	for raw_id: Variant in ingredients:
		var ingredient_id: String = String(raw_id)
		if ingredient_id.begins_with("stat_"):
			if Global.get_run_stat_level(ingredient_id) < required_level:
				return false
		elif Global.get_skill_level(ingredient_id) < required_level:
			return false
	return true


static func _alt_ingredients_satisfied(alt: Array) -> bool:
	if alt.size() < 2:
		return false
	var first: String = String(alt[0])
	if Global.get_skill_level(first) < FUSION_REQUIRED_LEVEL:
		return false
	var second: String = String(alt[1])
	if second.begins_with("stat_"):
		return Global.get_run_stat_level(second) >= FUSION_REQUIRED_LEVEL
	return Global.get_skill_level(second) >= FUSION_REQUIRED_LEVEL


static func _consume_recipe_ingredients(recipe: Dictionary) -> void:
	var used_alt: bool = not _ingredients_at_level(recipe.get("ingredients", []), FUSION_REQUIRED_LEVEL)
	var consumed: Array = recipe.get("alt_ingredients", []) if used_alt else recipe.get("ingredients", [])
	for raw_id: Variant in consumed:
		var ingredient_id: String = String(raw_id)
		if ingredient_id.begins_with("stat_"):
			# Stats = mejoras de tómbola (ej. Fatal Blow). Se conservan en Nv.5 para otras fusiones y bonuses.
			continue
		# Skills ingrediente: conservar nivel (sinergias futuras) pero dejar de ejecutarse en combate.
		Global.disable_skill_for_combat(ingredient_id)


static func _recipe_will_satisfy_after_upgrade(recipe: Dictionary, upgrade_id: String) -> bool:
	if upgrade_id.is_empty():
		return false
	if _ingredients_at_level_with_bonus(recipe.get("ingredients", []), FUSION_REQUIRED_LEVEL, upgrade_id):
		return true
	var alt: Array = recipe.get("alt_ingredients", [])
	return not alt.is_empty() and _ingredients_at_level_with_bonus(alt, FUSION_REQUIRED_LEVEL, upgrade_id)


static func _ingredients_at_level_with_bonus(ingredients: Array, required_level: int, bonus_id: String) -> bool:
	if ingredients.is_empty():
		return false
	for raw_id: Variant in ingredients:
		var ingredient_id: String = String(raw_id)
		var level: int = _get_ingredient_level(ingredient_id)
		if ingredient_id == bonus_id:
			level += 1
		if level < required_level:
			return false
	return true


static func _get_ingredient_level(ingredient_id: String) -> int:
	if ingredient_id.begins_with("stat_"):
		return Global.get_run_stat_level(ingredient_id)
	return Global.get_skill_level(ingredient_id)


static func _format_missing_requirements(recipe: Dictionary) -> String:
	if _recipe_satisfied(recipe):
		return ""
	var primary: Array = recipe.get("ingredients", [])
	var labels: PackedStringArray = PackedStringArray()
	for raw_id: Variant in primary:
		var ingredient_id: String = String(raw_id)
		if _get_ingredient_level(ingredient_id) >= FUSION_REQUIRED_LEVEL:
			continue
		labels.append("%s (%d/5)" % [_ingredient_display_name(ingredient_id), _get_ingredient_level(ingredient_id)])
	var alt: Array = recipe.get("alt_ingredients", [])
	if not alt.is_empty() and labels.is_empty():
		for raw_id: Variant in alt:
			var ingredient_id: String = String(raw_id)
			if _get_ingredient_level(ingredient_id) >= FUSION_REQUIRED_LEVEL:
				continue
			labels.append("%s (%d/5)" % [_ingredient_display_name(ingredient_id), _get_ingredient_level(ingredient_id)])
	return ", ".join(labels)


static func _ingredient_display_name(ingredient_id: String) -> String:
	if ingredient_id.begins_with("stat_"):
		var stat_def: Dictionary = _RunStats.get_definition(ingredient_id)
		return String(stat_def.get("title", ingredient_id))
	var skill_def: Dictionary = _SkillTree.get_skill(ingredient_id)
	return String(skill_def.get("display_name", ingredient_id))
