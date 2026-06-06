## Pantalla de nivel: tarjetas visuales + reroll/eliminar (1 uso por mapa).
extends CanvasLayer

const _UpgradePool = preload("res://data/upgrade_pool.gd")
const _Theme = preload("res://scripts/ui/modern_ui_theme.gd")
const _Fusion = preload("res://data/job_fusion_catalog.gd")

signal upgrade_chosen(upgrade_id: String)

@onready var dimmer: ColorRect = $Dimmer
@onready var panel: PanelContainer = $PanelContainer
@onready var title_label: Label = $PanelContainer/Margin/VBox/TitleLabel
@onready var tools_row: HBoxContainer = $PanelContainer/Margin/VBox/ToolsRow
@onready var choice_cards: Array[PanelContainer] = [
	$PanelContainer/Margin/VBox/Choices/ChoiceCard1,
	$PanelContainer/Margin/VBox/Choices/ChoiceCard2,
	$PanelContainer/Margin/VBox/Choices/ChoiceCard3,
]

@onready var reroll_button: Button = $PanelContainer/Margin/VBox/ToolsRow/RerollButton
@onready var eliminate_button: Button = $PanelContainer/Margin/VBox/ToolsRow/EliminateButton

var _pending_picks: int = 0
var _current_choice_ids: Array[String] = []
var _player: Player = null
var _eliminate_mode: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	dimmer.color = _Theme.DIMMER
	_Theme.apply_panel(panel)
	_Theme.style_title(title_label, 20)
	if reroll_button:
		reroll_button.pressed.connect(_on_reroll_pressed)
	if eliminate_button:
		eliminate_button.pressed.connect(_on_eliminate_pressed)
	Global.level_up.connect(_on_global_level_up)
	for card: PanelContainer in choice_cards:
		if card.has_signal("chosen"):
			card.chosen.connect(_on_card_chosen)


func _on_global_level_up(new_level: int) -> void:
	_pending_picks += 1
	if not visible:
		_open_selection(new_level)


func _open_selection(new_level: int) -> void:
	_player = _find_player()
	_eliminate_mode = false
	_roll_choices()
	title_label.text = "Nivel %d — Elige una mejora" % new_level
	_refresh_cards()
	_update_tool_buttons()
	get_tree().paused = true
	visible = true


func _roll_choices() -> void:
	_current_choice_ids = _UpgradePool.roll_choices(3, _player)


func _refresh_cards() -> void:
	for i: int in choice_cards.size():
		var card: PanelContainer = choice_cards[i]
		if i < _current_choice_ids.size() and _current_choice_ids[i] != "":
			var upgrade_id: String = _current_choice_ids[i]
			var def: Dictionary = _UpgradePool.get_definition(upgrade_id)
			card.visible = true
			if card.has_method("setup"):
				card.setup(
					upgrade_id,
					def.get("title", upgrade_id),
					def.get("description", ""),
					_level_hint_for(upgrade_id)
				)
			if card.has_method("set_skill_icon"):
				var icon_skill_id: String = ""
				if _UpgradePool.is_skill_choice(upgrade_id):
					icon_skill_id = _UpgradePool.parse_skill_id(upgrade_id)
				card.set_skill_icon(icon_skill_id)
		else:
			card.visible = false


func _update_tool_buttons() -> void:
	if reroll_button:
		reroll_button.visible = Global.has_meta_shop_reroll()
		if Global.run_reroll_used:
			reroll_button.text = "Volver a tirar (usado)"
			reroll_button.disabled = true
		else:
			reroll_button.text = "Volver a tirar"
			reroll_button.disabled = not Global.can_use_run_reroll()
	if eliminate_button:
		eliminate_button.visible = Global.has_meta_shop_eliminate()
		if Global.run_eliminate_used:
			eliminate_button.text = "Eliminar del pool (usado)"
			eliminate_button.disabled = true
		elif _eliminate_mode:
			eliminate_button.text = "Elige qué banear del pool"
			eliminate_button.disabled = false
		else:
			eliminate_button.text = "Eliminar del pool"
			eliminate_button.disabled = not Global.can_use_run_eliminate()


func _on_reroll_pressed() -> void:
	if not Global.can_use_run_reroll():
		return
	Audio.play_ui_click()
	Global.mark_run_reroll_used()
	_eliminate_mode = false
	_roll_choices()
	_refresh_cards()
	_update_tool_buttons()


func _on_eliminate_pressed() -> void:
	if not Global.can_use_run_eliminate():
		return
	Audio.play_ui_click()
	_eliminate_mode = true
	_update_tool_buttons()


func _on_card_chosen(upgrade_id: String) -> void:
	if upgrade_id.is_empty():
		return
	if _eliminate_mode and Global.can_use_run_eliminate():
		Audio.play_ui_click()
		Global.ban_tombola_choice(upgrade_id)
		_eliminate_mode = false
		_roll_choices()
		_refresh_cards()
		_update_tool_buttons()
		return
	Audio.play_ui_click()
	if _player and is_instance_valid(_player):
		_UpgradePool.apply(upgrade_id, _player)
	upgrade_chosen.emit(upgrade_id)
	_pending_picks = maxi(_pending_picks - 1, 0)
	if _pending_picks > 0:
		_open_selection(Global.session_level)
		return
	visible = false
	get_tree().paused = false


func _level_hint_for(upgrade_id: String) -> String:
	if _eliminate_mode and Global.can_use_run_eliminate():
		return "Banear del pool"
	var fusion_hint: String = _fusion_hint_for_upgrade(upgrade_id)
	if not fusion_hint.is_empty():
		return fusion_hint
	if _UpgradePool.is_stat_choice(upgrade_id):
		return "Stat global"
	if _UpgradePool.is_zeny_bag_choice(upgrade_id):
		return "Zeny"
	if _UpgradePool.is_skill_choice(upgrade_id):
		var skill_id: String = _UpgradePool.parse_skill_id(upgrade_id)
		if Global.get_skill_level(skill_id) > 0:
			return "Subir habilidad"
		if SkillTreeCatalog.is_manual_slot_skill(skill_id):
			return "Habilidad activa (ratón)"
		if SkillTreeCatalog.is_autonomous_skill(skill_id):
			return "Automática"
		if SkillTreeCatalog.is_passive_skill(skill_id):
			return "Pasiva"
		if SkillTreeCatalog.is_basic_auto_skill(skill_id):
			return "Ataque básico"
		return "Nueva habilidad"
	return ""


func _fusion_hint_for_upgrade(upgrade_id: String) -> String:
	if not _Fusion.is_advanced_job(Global.current_class):
		return ""
	var upgrade_key: String = ""
	if _UpgradePool.is_skill_choice(upgrade_id):
		upgrade_key = _UpgradePool.parse_skill_id(upgrade_id)
	elif _UpgradePool.is_stat_choice(upgrade_id):
		upgrade_key = _UpgradePool.parse_stat_id(upgrade_id)
	else:
		return ""
	var names: Array[String] = _Fusion.get_imminent_fusion_names(Global.current_class, upgrade_key)
	if names.is_empty():
		return ""
	if names.size() == 1:
		return "¡Fusión: %s!" % names[0]
	return "¡Fusión: %s!" % ", ".join(names)


func _find_player() -> Player:
	var players: Array[Node] = get_tree().get_nodes_in_group("Jugador")
	for node: Node in players:
		if node is Player:
			return node as Player
		if node.has_method("is_mage") and node.has_method("take_damage"):
			return node as Player
	return null
