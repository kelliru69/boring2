## Barra de vida del jefe (centro superior) con HP numérico estilo RPG.
class_name BossHealthBarPanel
extends Control

const _ScoreboardFmt = preload("res://scripts/persistence/local_scoreboard.gd")

const BAR_SMOOTH_SPEED: float = 14.0
const FILL_COLOR: Color = Color(0.82, 0.1, 0.12, 1.0)
const BG_COLOR: Color = Color(0.12, 0.05, 0.06, 0.92)

@onready var name_label: Label = $VBox/NameLabel
@onready var hp_bar: ProgressBar = $VBox/HpBar
@onready var hp_text_label: Label = $VBox/HpTextLabel

var _boss: Node = null
var _display_hp: float = 0.0
var _target_hp: float = 0.0
var _max_hp: int = 1


func _ready() -> void:
	visible = false
	_apply_bar_theme()
	set_process(true)


func _apply_bar_theme() -> void:
	if hp_bar == null:
		return
	var fill := StyleBoxFlat.new()
	fill.bg_color = FILL_COLOR
	fill.corner_radius_top_left = 4
	fill.corner_radius_top_right = 4
	fill.corner_radius_bottom_left = 4
	fill.corner_radius_bottom_right = 4
	var bg := StyleBoxFlat.new()
	bg.bg_color = BG_COLOR
	bg.corner_radius_top_left = 4
	bg.corner_radius_top_right = 4
	bg.corner_radius_bottom_left = 4
	bg.corner_radius_bottom_right = 4
	hp_bar.add_theme_stylebox_override("fill", fill)
	hp_bar.add_theme_stylebox_override("background", bg)
	hp_bar.show_percentage = false


func bind_boss(boss: Node) -> void:
	_unbind_boss()
	if boss == null or not is_instance_valid(boss):
		hide_boss_bar()
		return
	_boss = boss
	_max_hp = _read_max_hp(boss)
	_target_hp = float(_read_current_hp(boss))
	_display_hp = _target_hp
	if name_label:
		name_label.text = _read_display_name(boss)
	if hp_bar:
		hp_bar.max_value = float(_max_hp)
		hp_bar.value = _display_hp
	_refresh_hp_text()
	visible = true
	if boss.has_signal("boss_health_changed") and not boss.boss_health_changed.is_connected(_on_boss_health_changed):
		boss.boss_health_changed.connect(_on_boss_health_changed)
	if boss.has_signal("defeated") and not boss.defeated.is_connected(_on_boss_defeated):
		boss.defeated.connect(_on_boss_defeated)


func hide_boss_bar() -> void:
	_unbind_boss()
	visible = false


func _unbind_boss() -> void:
	if _boss == null or not is_instance_valid(_boss):
		_boss = null
		return
	if _boss.has_signal("boss_health_changed") and _boss.boss_health_changed.is_connected(_on_boss_health_changed):
		_boss.boss_health_changed.disconnect(_on_boss_health_changed)
	if _boss.has_signal("defeated") and _boss.defeated.is_connected(_on_boss_defeated):
		_boss.defeated.disconnect(_on_boss_defeated)
	_boss = null


func _process(delta: float) -> void:
	if not visible:
		return
	if _boss == null or not is_instance_valid(_boss):
		hide_boss_bar()
		return
	_target_hp = float(_read_current_hp(_boss))
	if hp_bar:
		hp_bar.max_value = float(_max_hp)
	if absf(_display_hp - _target_hp) > 0.5:
		_display_hp = lerpf(_display_hp, _target_hp, clampf(delta * BAR_SMOOTH_SPEED, 0.0, 1.0))
	else:
		_display_hp = _target_hp
	if hp_bar:
		hp_bar.value = _display_hp
	_refresh_hp_text()


func _on_boss_health_changed(current_hp: int, max_hp: int) -> void:
	_max_hp = maxi(max_hp, 1)
	_target_hp = float(maxi(current_hp, 0))
	_refresh_hp_text()


func _on_boss_defeated() -> void:
	hide_boss_bar()


func _refresh_hp_text() -> void:
	if hp_text_label == null:
		return
	var shown: int = maxi(int(roundf(_display_hp)), 0)
	hp_text_label.text = "%s / %s" % [
		_ScoreboardFmt.format_hp_number(shown),
		_ScoreboardFmt.format_hp_number(_max_hp),
	]


func _read_current_hp(boss: Node) -> int:
	if "current_hp" in boss:
		return int(boss.get("current_hp"))
	return 0


func _read_max_hp(boss: Node) -> int:
	if "max_hp" in boss:
		return maxi(int(boss.get("max_hp")), 1)
	return 1


func _read_display_name(boss: Node) -> String:
	if "boss_display_name" in boss:
		var n: String = String(boss.get("boss_display_name"))
		if not n.is_empty():
			return n
	if "display_name" in boss:
		return String(boss.get("display_name"))
	return "Jefe"
