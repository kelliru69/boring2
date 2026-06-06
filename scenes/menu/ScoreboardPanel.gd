## Panel Top 10 — lee user://scoreboard.json.
extends Control

const _Theme = preload("res://scripts/ui/modern_ui_theme.gd")
const _Scoreboard = preload("res://scripts/persistence/local_scoreboard.gd")
const _MapConfig = preload("res://data/map_config.gd")

@onready var list_container: VBoxContainer = $Panel/Margin/VBox/Scroll/ListVBox
@onready var empty_label: Label = $Panel/Margin/VBox/EmptyLabel
@onready var close_button: Button = $Panel/Margin/VBox/CloseButton


func _ready() -> void:
	_Theme.apply_panel($Panel)
	_Theme.apply_button(close_button, 40.0)
	close_button.pressed.connect(_on_close_pressed)
	visible = false


func show_scoreboard() -> void:
	_refresh_list()
	visible = true


func hide_scoreboard() -> void:
	visible = false


func _refresh_list() -> void:
	if list_container == null:
		return
	for child: Node in list_container.get_children():
		child.queue_free()
	var entries: Array[Dictionary] = _Scoreboard.get_top_entries()
	var is_empty: bool = entries.is_empty()
	if empty_label:
		empty_label.visible = is_empty
	if is_empty:
		return
	var rank: int = 1
	for entry: Dictionary in entries:
		var row: Label = Label.new()
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var map_name: String = String(entry.get("map_name", entry.get("map_id", "?")))
		var time_str: String = _Scoreboard.format_time(float(entry.get("survival_seconds", 0.0)))
		var victory_tag: String = " ✓" if bool(entry.get("victory", false)) else ""
		var zeny: int = int(entry.get("zeny", 0))
		row.text = "%d. %s — %s (%s) — %d Zeny%s" % [
			rank,
			String(entry.get("player_name", "Aventurero")),
			map_name,
			time_str,
			zeny,
			victory_tag,
		]
		_Theme.style_subtitle(row, 13)
		list_container.add_child(row)
		rank += 1


func _on_close_pressed() -> void:
	Audio.play_ui_click()
	hide_scoreboard()
