## Panel de prueba durante la run (tiempo, nivel, jefe).
extends CanvasLayer

@onready var _card_drop_btn: Button = $Panel/Margin/VBox/CardDropBtn


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	$Panel/Margin/VBox/Time30Btn.pressed.connect(_on_time_30)
	$Panel/Margin/VBox/Time60Btn.pressed.connect(_on_time_60)
	$Panel/Margin/VBox/TimeBossBtn.pressed.connect(_on_time_boss)
	$Panel/Margin/VBox/LevelUpBtn.pressed.connect(_on_level_up)
	$Panel/Margin/VBox/XpFillBtn.pressed.connect(_on_xp_fill)
	$Panel/Margin/VBox/BossBtn.pressed.connect(_on_spawn_boss_pressed)
	_card_drop_btn.pressed.connect(_on_card_drop_toggle)
	_refresh_card_drop_button()


func _on_time_30() -> void:
	Global.debug_add_time(30.0)


func _on_time_60() -> void:
	Global.debug_add_time(60.0)


func _on_time_boss() -> void:
	Global.debug_add_time(480.0)


func _on_level_up() -> void:
	Global.debug_force_level_up()


func _on_xp_fill() -> void:
	Global.debug_add_xp(9999)


func _on_spawn_boss_pressed() -> void:
	var main: Node = get_tree().current_scene
	if main and main.has_method("debug_spawn_boss"):
		main.call("debug_spawn_boss")


func _on_card_drop_toggle() -> void:
	Global.debug_toggle_card_drop_test()
	_refresh_card_drop_button()


func _refresh_card_drop_button() -> void:
	if Global.debug_is_card_drop_test_mode():
		_card_drop_btn.text = "Drop cartas 10%: ON"
	else:
		_card_drop_btn.text = "Drop cartas 10%: OFF"
