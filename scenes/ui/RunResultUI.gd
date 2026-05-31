## Pantalla de fin de partida: Victoria o Derrota + Zeny de la run.
extends CanvasLayer

@onready var title_label: Label = $Panel/Margin/VBox/TitleLabel
@onready var zeny_label: Label = $Panel/Margin/VBox/ZenyLabel
@onready var stats_label: Label = $Panel/Margin/VBox/StatsLabel
@onready var continue_button: Button = $Panel/Margin/VBox/ContinueButton
@onready var menu_button: Button = $Panel/Margin/VBox/MenuButton

var _can_continue: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	continue_button.pressed.connect(_on_continue_pressed)
	menu_button.pressed.connect(_on_menu_pressed)	


func show_result(victory: bool, run_zeny: int) -> void:
	title_label.text = "¡Victoria!" if victory else "Derrota"
	title_label.modulate = Color(0.5, 1.0, 0.55) if victory else Color(1.0, 0.45, 0.45)
	zeny_label.text = "Zeny recolectado en esta partida: %d" % run_zeny
	var snap: Dictionary = Global.get_session_snapshot()
	var elapsed_sec: int = int(snap.get("elapsed_time", 0.0))
	stats_label.text = "Nivel %d | Tiempo %02d:%02d | Cartas %d" % [
		snap.get("level", 1),
		int(elapsed_sec / 60.0),
		elapsed_sec % 60,
		snap.get("cards_count", 0),
	]
	_can_continue = victory and Game.can_continue_after_victory(Game.selected_map_id)
	continue_button.visible = _can_continue
	if _can_continue:
		var next_name: String = Game.get_continue_map_display_name(Game.selected_map_id)
		continue_button.text = "Continuar a %s" % next_name
	menu_button.text = "Volver al Menú Principal"
	visible = true
	get_tree().paused = true


func _on_continue_pressed() -> void:
	if not _can_continue:
		return
	Audio.play_ui_click()
	get_tree().paused = false
	Game.continue_to_next_map()


func _on_menu_pressed() -> void:
	Audio.play_ui_click()
	get_tree().paused = false
	Game.go_to_preparation()
