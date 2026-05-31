class_name GameOverUI
extends CanvasLayer

@onready var message_label: Label = $PanelContainer/Margin/VBox/MessageLabel
@onready var stats_label: Label = $PanelContainer/Margin/VBox/StatsLabel
@onready var restart_button: Button = $PanelContainer/Margin/VBox/RestartButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	restart_button.pressed.connect(_on_restart_pressed)


func show_game_over() -> void:
	var snap: Dictionary = Global.get_session_snapshot()
	message_label.text = "Has caído"
	var elapsed_sec: int = int(snap.get("elapsed_time", 0.0))
	stats_label.text = "Nivel %d | Zeny %d | Tiempo %02d:%02d | Cartas %d" % [
		snap.get("level", 1),
		snap.get("zeny", 0),
		int(elapsed_sec / 60.0),
		elapsed_sec % 60,
		snap.get("cards_count", 0),
	]
	visible = true
	get_tree().paused = true


func _on_restart_pressed() -> void:
	Audio.play_ui_click()
	get_tree().paused = false
	get_tree().reload_current_scene()
