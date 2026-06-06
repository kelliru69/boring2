## Pantalla de fin de partida con resumen incentivador de la run.
extends CanvasLayer

const _Theme = preload("res://scripts/ui/modern_ui_theme.gd")
const _Catalog = preload("res://data/card_catalog.gd")
const _MapConfig = preload("res://data/map_config.gd")

@onready var title_label: Label = $Panel/Margin/VBox/TitleLabel
@onready var zeny_label: Label = $Panel/Margin/VBox/ZenyLabel
@onready var stats_label: Label = $Panel/Margin/VBox/StatsLabel
@onready var loot_label: Label = $Panel/Margin/VBox/LootLabel
@onready var continue_button: Button = $Panel/Margin/VBox/ContinueButton
@onready var menu_button: Button = $Panel/Margin/VBox/MenuButton

var _can_continue: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_Theme.style_title(title_label, 22)
	_Theme.style_zeny(zeny_label, 16)
	_Theme.style_body(stats_label, 13)
	_Theme.style_accent(loot_label, 12)
	continue_button.pressed.connect(_on_continue_pressed)
	menu_button.pressed.connect(_on_menu_pressed)


func show_result(victory: bool, run_zeny: int) -> void:
	title_label.text = "¡Victoria!" if victory else "Fin de la run"
	title_label.modulate = Color(0.5, 1.0, 0.55) if victory else Color(1.0, 0.45, 0.45)
	zeny_label.text = "Oro recolectado: %s Z" % _format_int(run_zeny)
	var snap: Dictionary = Global.get_session_snapshot()
	var elapsed_sec: int = int(snap.get("elapsed_time", 0.0))
	var job_display: String = String(snap.get("class_id", "aventurero")).capitalize()
	stats_label.text = (
		"Clase: %s  ·  Nivel %d  ·  Tiempo %02d:%02d\nMapa: %s"
		% [
			job_display,
			int(snap.get("level", 1)),
			int(elapsed_sec / 60.0),
			elapsed_sec % 60,
			String(_MapConfig.get_definition(String(snap.get("map_id", ""))).get("display_name", "—")),
		]
	)
	loot_label.text = _build_loot_summary(snap)
	_can_continue = victory and Game.can_continue_after_victory(Game.selected_map_id)
	continue_button.visible = _can_continue
	if _can_continue:
		var next_name: String = Game.get_continue_map_display_name(Game.selected_map_id)
		continue_button.text = "Continuar a %s" % next_name
	menu_button.text = "Volver al Menú Principal"
	visible = true
	get_tree().paused = true


func _build_loot_summary(snap: Dictionary) -> String:
	var lines: PackedStringArray = PackedStringArray()
	var drops: Dictionary = snap.get("run_card_drops", {})
	if drops.is_empty():
		lines.append("Cartas en esta run: ninguna nueva")
	else:
		lines.append("Cartas obtenidas:")
		for card_id: Variant in drops:
			var count: int = int(drops[card_id])
			var name: String = String(_Catalog.get_definition(String(card_id)).get("name", card_id))
			lines.append("  • %s x%d" % [name, count])
	var consumables: Dictionary = snap.get("run_consumables", {})
	if not consumables.is_empty():
		lines.append("Consumibles en bolsa:")
		for item_id: Variant in consumables:
			lines.append("  • %s x%d" % [String(item_id), int(consumables[item_id])])
	var total_cards: int = int(snap.get("cards_count", 0))
	lines.append("Colección total: %d cartas en perfil" % total_cards)
	if Global.map_1_cleared:
		lines.append("Progreso: Mapa 1 superado ✓")
	if Global.map_2_cleared:
		lines.append("Progreso: Mapa 2 superado ✓")
	return "\n".join(lines)


static func _format_int(value: int) -> String:
	var s: String = str(maxi(value, 0))
	if s.length() <= 3:
		return s
	var parts: PackedStringArray = PackedStringArray()
	while s.length() > 3:
		parts.insert(0, s.substr(s.length() - 3, 3))
		s = s.substr(0, s.length() - 3)
	if not s.is_empty():
		parts.insert(0, s)
	return ",".join(parts)


func _on_continue_pressed() -> void:
	if not _can_continue:
		return
	Audio.play_ui_click()
	get_tree().paused = false
	visible = false
	Game.go_to_post_boss_preparation()


func _on_menu_pressed() -> void:
	Audio.play_ui_click()
	get_tree().paused = false
	Game.go_to_preparation()
