## Panel de prueba durante la run (tiempo, nivel, jefe).
extends CanvasLayer

const _MapConfig = preload("res://data/map_config.gd")

@onready var _card_drop_btn: Button = $Panel/Margin/VBox/CardDropBtn
@onready var _card_drop_100_btn: Button = $Panel/Margin/VBox/CardDrop100Btn
@onready var _zeny_100k_btn: Button = $Panel/Margin/VBox/Zeny100kBtn
@onready var _max_hp_btn: Button = $Panel/Margin/VBox/MaxHpBtn
@onready var _unlock_map3_btn: Button = $Panel/Margin/VBox/UnlockMap3Btn


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	$Panel.visible = false
	$Panel/Margin/VBox/Time30Btn.pressed.connect(_on_time_30)
	$Panel/Margin/VBox/Time60Btn.pressed.connect(_on_time_60)
	$Panel/Margin/VBox/TimeBossBtn.pressed.connect(_on_time_boss)
	$Panel/Margin/VBox/LevelUpBtn.pressed.connect(_on_level_up)
	$Panel/Margin/VBox/XpFillBtn.pressed.connect(_on_xp_fill)
	$Panel/Margin/VBox/BossBtn.pressed.connect(_on_spawn_boss_pressed)
	$Panel/Margin/VBox/KillBossBtn.pressed.connect(_on_kill_boss_pressed)
	_card_drop_btn.pressed.connect(_on_card_drop_toggle)
	_card_drop_100_btn.pressed.connect(_on_card_drop_100_pressed)
	_zeny_100k_btn.pressed.connect(_on_add_zeny_100k_pressed)
	_max_hp_btn.pressed.connect(_on_set_max_hp_99999_pressed)
	_unlock_map3_btn.pressed.connect(_on_unlock_map3_pressed)
	_refresh_card_drop_button()
	_refresh_unlock_map3_button()


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


func _on_kill_boss_pressed() -> void:
	var main: Node = get_tree().current_scene
	if main and main.has_method("debug_kill_boss"):
		main.call("debug_kill_boss")


func _on_card_drop_toggle() -> void:
	Global.debug_toggle_card_drop_test()
	_refresh_card_drop_button()


func _on_card_drop_100_pressed() -> void:
	Global.debug_set_card_drop_test_percent(1.0)
	_refresh_card_drop_button()


func _on_add_zeny_100k_pressed() -> void:
	Global.add_zeny(100000)


func _refresh_card_drop_button() -> void:
	if Global.debug_card_drop_chance < 0.0:
		_card_drop_btn.text = "Drop cartas 10%: OFF"
		return
	if is_equal_approx(Global.debug_card_drop_chance, 1.0):
		_card_drop_btn.text = "Drop cartas 100%: ON"
	else:
		_card_drop_btn.text = "Drop cartas 10%: ON"


func _on_unlock_map3_pressed() -> void:
	Global.debug_unlock_orc_village()
	_refresh_unlock_map3_button()


func _refresh_unlock_map3_button() -> void:
	if Global.is_map_unlocked(_MapConfig.MAP_ORC_VILLAGE):
		_unlock_map3_btn.text = "Mapa 3: desbloqueado"
		_unlock_map3_btn.disabled = true
	else:
		_unlock_map3_btn.text = "Desbloquear Mapa 3"
		_unlock_map3_btn.disabled = false


func _on_set_max_hp_99999_pressed() -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	var players: Array[Node] = tree.get_nodes_in_group("Jugador")
	if players.is_empty() or not (players[0] is Player):
		return
	var player: Player = players[0] as Player
	player.max_hp = 99999
	player.current_hp = 99999
	player.health_changed.emit(player.current_hp, player.max_hp)


func set_debug_visible(show_panel: bool) -> void:
	$Panel.visible = show_panel
	if show_panel:
		_refresh_unlock_map3_button()


func is_debug_visible() -> bool:
	return $Panel.visible
