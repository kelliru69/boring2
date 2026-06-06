## =============================================================================
## GUÍA DE ICONOS HUD — dónde registrar rutas de habilidades y pasivas
## =============================================================================
##
## 1) HABILIDADES (árbol, barra de acción, panel derecho, tómbola)
##    Archivo principal: res://data/skill_tree_catalog.gd
##    Por cada skill en _ALL_SKILLS añade o edita:
##      "icon_path": "res://assets/skills/mage/fire_bolt.png"
##
##    Carga en runtime:
##      SkillDefinitions.get_icon_texture(skill_id)
##    Usado por: SkillBarSlot, UpgradeChoiceCard, SkillTreeNodeButton,
##               RunHudRightPanel, ControlsRemapPanel.
##
## 2) ICONO POR DEFECTO (fallback)
##      res://art/skills/default_icon.png
##      Constante: SkillDefinitions.DEFAULT_ICON
##
## 3) PASIVAS DE RUN / STATS DE TÓMBOLA (chips del panel derecho)
##    Archivo: res://data/run_stat_catalog.gd
##    Añade en cada entrada de stat:
##      "icon_path": "res://assets/ui/stats/move_speed.png"
##
##    Para exponer en HUD:
##      HudIconRegistry.get_run_stat_icon(stat_id)
##
## 4) PASIVAS DE CARTAS (no usan skill_id; van por card_id)
##    Archivo: res://data/card_visual_catalog.gd
##    Rutas de arte de álbum/drop; stats en card_stats.gd
##
## 5) CONSUMIBLES (bolsa 1–9)
##    Archivo: res://scripts/inventory/consumable_inventory.gd
##    Diccionario ITEM_ICONS al final del script.
##
## 6) MONEDA ZENY (contador superior derecho)
##    Ruta: HudIconRegistry.ZENY_COIN_ICON
## =============================================================================
class_name HudIconRegistry
extends RefCounted

const ZENY_COIN_ICON: String = "res://art/ui/zeny_coin.png"
const DEFAULT_STAT_ICON: String = "res://art/skills/default_icon.png"

const _RunStats = preload("res://data/run_stat_catalog.gd")
const _SkillDefs = preload("res://data/skill_definitions.gd")


static func get_skill_icon(skill_id: String) -> Texture2D:
	return _SkillDefs.get_icon_texture(skill_id)


static func get_run_stat_icon(stat_id: String) -> Texture2D:
	var def: Dictionary = _RunStats.get_definition(stat_id)
	var path: String = String(def.get("icon_path", DEFAULT_STAT_ICON))
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	if ResourceLoader.exists(DEFAULT_STAT_ICON):
		return load(DEFAULT_STAT_ICON) as Texture2D
	return null


static func get_zeny_coin_icon() -> Texture2D:
	if ResourceLoader.exists(ZENY_COIN_ICON):
		return load(ZENY_COIN_ICON) as Texture2D
	return null
