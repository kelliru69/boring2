## GameHUD.gd — UI reactiva conectada a señales de Global y del jugador.
extends CanvasLayer

const _MapConfig = preload("res://data/map_config.gd")

@onready var level_label: Label = $MarginContainer/VBox/LevelLabel
@onready var xp_label: Label = $MarginContainer/VBox/XpLabel
@onready var zeny_label: Label = $MarginContainer/VBox/ZenyLabel
@onready var fighter_health_hud: FighterHealthHud = $FighterHealthHud
@onready var zeny_counter_hud: ZenyCounterHud = $ZenyCounterHud
@onready var consumable_hud: ConsumableHudBar = $ConsumableHudBar
@onready var time_label: Label = $MarginContainer/VBox/TimeLabel
@onready var run_clock_label: Label = $NorthClockDock/Center/RunClockLabel
@onready var run_hud_right_panel: VBoxContainer = $RightHudDock/RunHudRightPanel
@onready var cards_label: Label = $MarginContainer/VBox/CardsLabel
@onready var hp_label: Label = $MarginContainer/VBox/HpLabel
@onready var wave_label: Label = $MarginContainer/VBox/WaveLabel
@onready var run_passive_label: Label = $MarginContainer/VBox/RunPassiveLabel
@onready var energy_coat_label: Label = $MarginContainer/VBox/EnergyCoatLabel
@onready var dps_label: Label = $MarginContainer/VBox/DpsLabel
@onready var class_label: Label = $MarginContainer/VBox/ClassLabel
@onready var left_stats_panel: MarginContainer = $MarginContainer
@onready var xp_progress_bar: ProgressBar = $XpBarDock/XpBarMargin/HBox/XpProgressBar
@onready var xp_bar_level_badge: Label = $XpBarDock/XpBarMargin/HBox/LevelBadge
@onready var xp_fraction_label: Label = $XpBarDock/XpBarMargin/HBox/XpFractionLabel
@onready var skill_action_bar: HBoxContainer = $SkillBarDock/SkillActionBar
@onready var passive_skill_strip: HBoxContainer = $PassiveSkillDock/PassiveSkillStrip
@onready var buff_status_overlay: HBoxContainer = $BuffOverlayDock/BuffStatusOverlay
@onready var buff_overlay_dock: Control = $BuffOverlayDock
@onready var map_exit_overlay: Control = $MapExitOverlay
@onready var map_exit_center: VBoxContainer = $MapExitOverlay/Center
@onready var map_exit_countdown_label: Label = $MapExitOverlay/Center/CountdownLabel
@onready var boss_warning_overlay: Control = $BossWarningOverlay
@onready var boss_warning_label: Label = $BossWarningOverlay/Center/WarningLabel
@onready var wall_wave_warning: WallWaveWarningOverlay = $WallWaveWarningOverlay
@onready var boss_health_bar: BossHealthBarPanel = $BossHealthBarPanel


var _wave_banner_text: String = ""
var _wave_banner_timer: float = 0.0
var _map_exit_visible: bool = false
var _map_exit_seconds_left: float = 0.0
var _boss_warning_visible: bool = false
var _boss_warning_timer: float = 0.0
var _debug_panel: CanvasLayer = null
var _key_buffer: String = ""
var _key_buffer_timeout: float = 0.0
var _player: Player = null

const MAP_EXIT_PULSE_THRESHOLD: float = 5.0
const OVERLAY_PULSE_SPEED: float = 7.0
const KEY_BUFFER_MAX_LEN: int = 4
const KEY_BUFFER_RESET_SEC: float = 2.0
const DEBUG_SHOW_CODE: String = "9090"
const DEBUG_HIDE_CODE: String = "8989"
const DPS_REFRESH_INTERVAL: float = 0.5

var _dps_refresh_timer: float = 0.0
var _left_stats_visible: bool = true


func _ready() -> void:
	if xp_label:
		xp_label.visible = false
	if hp_label:
		hp_label.visible = false
	if zeny_label:
		zeny_label.visible = false
	if xp_fraction_label:
		xp_fraction_label.visible = false
	Global.level_up.connect(_on_level_up)
	Global.zeny_gained.connect(_on_zeny_gained)
	Global.campaign_zeny_gained.connect(_on_campaign_zeny_gained)
	if not Global.zeny_gained.is_connected(_on_zeny_counter_refresh):
		Global.zeny_gained.connect(_on_zeny_counter_refresh)
	if not Global.campaign_zeny_gained.is_connected(_on_zeny_counter_refresh):
		Global.campaign_zeny_gained.connect(_on_zeny_counter_refresh)
	Global.card_collected.connect(_on_card_collected)
	if not Global.skill_tree_changed.is_connected(_on_skill_tree_changed):
		Global.skill_tree_changed.connect(_on_skill_tree_changed)
	if not Arena.wave_announced.is_connected(_on_wave_announced):
		Arena.wave_announced.connect(_on_wave_announced)
	if not Global.fusion_unlocked.is_connected(_on_fusion_unlocked):
		Global.fusion_unlocked.connect(_on_fusion_unlocked)
	if Game.preserve_session_on_next_load:
		_refresh_global_ui()
		if run_hud_right_panel and run_hud_right_panel.has_method("refresh"):
			run_hud_right_panel.refresh()
	else:
		reset_for_new_run()
	_find_player_health()
	call_deferred("_find_debug_panel")
	set_process_unhandled_input(true)


## Llamar tras Global.reset_session() para evitar nivel/reloj de la run anterior.
func reset_for_new_run() -> void:
	if level_label:
		level_label.text = "Nivel: 1"
	if xp_bar_level_badge:
		xp_bar_level_badge.text = "Lv.1"
	if run_clock_label:
		run_clock_label.text = "00:00"
	_refresh_global_ui()
	if run_hud_right_panel and run_hud_right_panel.has_method("refresh"):
		run_hud_right_panel.refresh()


func _on_wave_announced(message: String) -> void:
	_wave_banner_text = message
	_wave_banner_timer = 4.5


func _on_fusion_unlocked(_fusion_id: String, display_name: String) -> void:
	_wave_banner_text = "¡Fusión desbloqueada: %s!" % display_name
	_wave_banner_timer = 5.5
	Audio.play_sfx("level_up")


func _try_toggle_stats_panel(event: InputEvent) -> bool:
	if not (event is InputEventKey):
		return false
	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return false
	if not key_event.alt_pressed:
		return false
	if key_event.keycode != KEY_1 and key_event.physical_keycode != KEY_1:
		return false
	_left_stats_visible = not _left_stats_visible
	if left_stats_panel:
		left_stats_panel.visible = _left_stats_visible
	get_viewport().set_input_as_handled()
	return true


func _process(delta: float) -> void:
	_update_time()
	_refresh_xp()
	_dps_refresh_timer += delta
	if _dps_refresh_timer >= DPS_REFRESH_INTERVAL:
		_dps_refresh_timer = 0.0
		_update_dps_label()
	if _wave_banner_timer > 0.0:
		_wave_banner_timer = maxf(_wave_banner_timer - delta, 0.0)
	if _boss_warning_visible:
		_boss_warning_timer = maxf(_boss_warning_timer - delta, 0.0)
		_apply_overlay_pulse(boss_warning_overlay, boss_warning_label, true)
		if _boss_warning_timer <= 0.0:
			hide_boss_warning()
	if _map_exit_visible:
		var pulse_exit: bool = _map_exit_seconds_left <= MAP_EXIT_PULSE_THRESHOLD
		_apply_overlay_pulse(map_exit_overlay, map_exit_center, pulse_exit)
	_update_wave_info()
	_update_key_buffer_timeout(delta)
	_update_buff_overlay_visibility()
	_update_run_passive_labels()
	_update_dps_label()
	_update_class_label()


func _find_player_health() -> void:
	var players: Array[Node] = get_tree().get_nodes_in_group("Jugador")
	if players.is_empty():
		return
	var player: Player = players[0] as Player
	if player == null:
		return
	_player = player
	if fighter_health_hud:
		fighter_health_hud.bind_player(player)
	if not player.health_changed.is_connected(_on_health_changed):
		player.health_changed.connect(_on_health_changed)
	_on_health_changed(player.current_hp, player.max_hp)
	if player.active_skills and skill_action_bar and skill_action_bar.has_method("bind_controller"):
		skill_action_bar.bind_controller(player.active_skills)
	if passive_skill_strip and passive_skill_strip.has_method("_refresh"):
		passive_skill_strip._refresh()
	if buff_status_overlay and buff_status_overlay.has_method("bind_player"):
		buff_status_overlay.bind_player(player)
	_update_run_passive_labels()


func _find_debug_panel() -> void:
	var main: Node = get_tree().current_scene
	if main == null:
		return
	_debug_panel = main.get_node_or_null("DebugRunPanel") as CanvasLayer


func _unhandled_input(event: InputEvent) -> void:
	if _try_toggle_stats_panel(event):
		return
	var digit: int = _key_event_to_digit(event)
	if digit < 0:
		return
	_key_buffer_timeout = KEY_BUFFER_RESET_SEC
	_key_buffer = (_key_buffer + str(digit)).right(KEY_BUFFER_MAX_LEN)
	_evaluate_debug_code_buffer()


func _key_event_to_digit(event: InputEvent) -> int:
	if not (event is InputEventKey):
		return -1
	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return -1
	var key: Key = key_event.physical_keycode
	if key >= KEY_0 and key <= KEY_9:
		return int(key - KEY_0)
	if key >= KEY_KP_0 and key <= KEY_KP_9:
		return int(key - KEY_KP_0)
	return -1


func _update_key_buffer_timeout(delta: float) -> void:
	if _key_buffer.is_empty():
		return
	_key_buffer_timeout = maxf(_key_buffer_timeout - delta, 0.0)
	if _key_buffer_timeout <= 0.0:
		_key_buffer = ""


func _evaluate_debug_code_buffer() -> void:
	if _debug_panel == null or not _debug_panel.has_method("set_debug_visible"):
		return
	if _key_buffer == DEBUG_SHOW_CODE:
		_debug_panel.set_debug_visible(true)
		_key_buffer = ""
	elif _key_buffer == DEBUG_HIDE_CODE:
		_debug_panel.set_debug_visible(false)
		_key_buffer = ""


func _update_buff_overlay_visibility() -> void:
	if buff_overlay_dock == null:
		return
	var debug_visible: bool = _debug_panel != null and _debug_panel.has_method("is_debug_visible") and _debug_panel.is_debug_visible()
	buff_overlay_dock.visible = not debug_visible


func _on_health_changed(current_hp: int, max_hp: int) -> void:
	hp_label.text = "HP: %d / %d" % [current_hp, max_hp]


func _on_level_up(new_level: int) -> void:
	if level_label:
		level_label.text = "Nivel: %d" % new_level
	if xp_bar_level_badge:
		xp_bar_level_badge.text = "Lv.%d" % new_level
	_refresh_xp()


func _on_zeny_gained(_amount: int, _total: int) -> void:
	pass


func _on_campaign_zeny_gained(_amount: int, _total: int) -> void:
	pass


func _on_zeny_counter_refresh(_amount: int = 0, _total: int = 0) -> void:
	if zeny_counter_hud:
		zeny_counter_hud.refresh()


func _on_skill_tree_changed() -> void:
	_update_class_label()
	if fighter_health_hud:
		fighter_health_hud.set_fighter_name(
			Global.current_class if not Global.current_class.is_empty() else Game.selected_class_id
		)
	if run_hud_right_panel and run_hud_right_panel.has_method("refresh"):
		run_hud_right_panel.refresh()


func _on_card_collected(card_id: String, _data: Dictionary) -> void:
	if cards_label:
		cards_label.text = "Cartas: %d (%s)" % [Global.get_total_owned_card_copies(), card_id]
	if run_hud_right_panel and run_hud_right_panel.has_method("refresh"):
		run_hud_right_panel.refresh()


func _refresh_global_ui() -> void:
	if level_label:
		level_label.text = "Nivel: %d" % Global.session_level
	if xp_bar_level_badge:
		xp_bar_level_badge.text = "Lv.%d" % Global.session_level
	if zeny_counter_hud:
		zeny_counter_hud.refresh()
	if cards_label:
		cards_label.text = "Cartas: %d" % Global.get_total_owned_card_copies()
	_refresh_xp()


func _refresh_xp() -> void:
	var current: int = Global.session_xp
	var required: int = maxi(Global.session_xp_required, 1)
	if xp_progress_bar:
		xp_progress_bar.max_value = float(required)
		xp_progress_bar.value = float(current)
		var ratio: float = float(current) / float(required)
		if ratio > 0.66:
			xp_progress_bar.modulate = Color(0.35, 0.72, 1.0, 1.0)
		elif ratio > 0.33:
			xp_progress_bar.modulate = Color(0.55, 0.82, 1.0, 1.0)
		else:
			xp_progress_bar.modulate = Color(0.42, 0.58, 0.95, 1.0)


func _update_time() -> void:
	var t: float = Global.session_elapsed_time
	var seconds_total: int = int(t)
	var minutes: int = int(seconds_total / 60.0)
	var seconds: int = seconds_total % 60
	var clock_text: String = "%02d:%02d" % [minutes, seconds]
	if run_clock_label:
		run_clock_label.text = clock_text
	if time_label:
		time_label.text = "Tiempo: %s" % clock_text


func _update_dps_label() -> void:
	if dps_label == null:
		return
	var dps: float = Global.get_dps_last_seconds(Global.DPS_WINDOW_SEC)
	dps_label.text = "DPS (3s): %d" % int(round(dps))


func _update_class_label() -> void:
	if class_label == null:
		return
	var job_name: String = Global.current_class if not Global.current_class.is_empty() else Game.selected_class_id
	class_label.text = "Clase: %s" % job_name.capitalize()


func _update_run_passive_labels() -> void:
	if run_passive_label == null or energy_coat_label == null:
		return
	if _player == null or not is_instance_valid(_player):
		run_passive_label.visible = false
		energy_coat_label.visible = false
		return
	var pierce_chance: float = _player.get_spell_pierce_chance() if _player.has_method("get_spell_pierce_chance") else 0.0
	var shield_vals: Dictionary = _player.get_energy_coat_values() if _player.has_method("get_energy_coat_values") else {"current": 0, "max": 0}
	var shield_now: int = int(shield_vals.get("current", 0))
	var shield_max: int = int(shield_vals.get("max", 0))
	var show_pierce: bool = pierce_chance > 0.0
	var show_shield: bool = shield_max > 0
	run_passive_label.visible = show_pierce
	energy_coat_label.visible = show_shield
	if show_pierce:
		run_passive_label.text = "Spell Pierce: %d%%" % int(round(pierce_chance * 100.0))
	if show_shield:
		var shield_label: String = String(shield_vals.get("label", "Energy Coat"))
		energy_coat_label.text = "%s: %d / %d" % [shield_label, shield_now, shield_max]


func _update_wave_info() -> void:
	if wave_label == null:
		return
	if _map_exit_visible:
		wave_label.text = "Jefe derrotado — recoge botín"
		return
	if _wave_banner_timer > 0.0 and not _wave_banner_text.is_empty():
		wave_label.text = _wave_banner_text
		return
	var step: int = int(Global.session_elapsed_time / 30.0)
	var enemies_alive: int = get_tree().get_nodes_in_group("Enemigos").size()
	wave_label.text = "Oleada %d | Enemigos: %d" % [step + 1, enemies_alive]


func show_map_exit_countdown(seconds_left: float) -> void:
	_map_exit_visible = true
	if map_exit_overlay:
		map_exit_overlay.visible = true
	set_map_exit_countdown(seconds_left)


func hide_map_exit_countdown() -> void:
	_map_exit_visible = false
	_map_exit_seconds_left = 0.0
	if map_exit_overlay:
		map_exit_overlay.visible = false
		_reset_overlay_visual(map_exit_overlay, map_exit_center)


func set_map_exit_countdown(seconds_left: float) -> void:
	_map_exit_seconds_left = maxf(seconds_left, 0.0)
	if map_exit_countdown_label == null:
		return
	var display_sec: int = maxi(int(ceilf(_map_exit_seconds_left)), 0)
	map_exit_countdown_label.text = str(display_sec)


func show_boss_warning(duration: float = 3.0) -> void:
	_boss_warning_visible = true
	_boss_warning_timer = maxf(duration, 0.1)
	if boss_warning_overlay:
		boss_warning_overlay.visible = true


func hide_boss_warning() -> void:
	_boss_warning_visible = false
	_boss_warning_timer = 0.0
	if boss_warning_overlay:
		boss_warning_overlay.visible = false
		_reset_overlay_visual(boss_warning_overlay, boss_warning_label)


func show_wall_wave_warning(wave_type: String, duration: float = 3.0) -> void:
	if wall_wave_warning:
		wall_wave_warning.show_for_wave_type(wave_type, duration)


func hide_wall_wave_warning() -> void:
	if wall_wave_warning:
		wall_wave_warning.hide_warning()


func show_boss_health_bar(boss: Node) -> void:
	if boss_health_bar:
		boss_health_bar.bind_boss(boss)


func hide_boss_health_bar() -> void:
	if boss_health_bar:
		boss_health_bar.hide_boss_bar()


func _apply_overlay_pulse(overlay: Control, pulse_node: Control, active: bool) -> void:
	if overlay == null or pulse_node == null:
		return
	if not active:
		_reset_overlay_visual(overlay, pulse_node)
		return
	var t: float = Time.get_ticks_msec() / 1000.0
	var wave: float = 0.5 + 0.5 * sin(t * OVERLAY_PULSE_SPEED)
	var scale_factor: float = lerpf(1.0, 1.14, wave)
	pulse_node.scale = Vector2(scale_factor, scale_factor)
	overlay.modulate = Color(1.0, 1.0, 1.0, lerpf(0.82, 1.0, wave))


func _reset_overlay_visual(overlay: Control, pulse_node: Control) -> void:
	if overlay:
		overlay.modulate = Color.WHITE
	if pulse_node:
		pulse_node.scale = Vector2.ONE
