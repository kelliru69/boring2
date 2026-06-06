## Overlay compacto de bufos de soporte (Blessing + Increase AGI) con barra de tiempo restante.
extends HBoxContainer

const _Theme = preload("res://scripts/ui/modern_ui_theme.gd")

const BUFF_DURATION_SEC: float = 20.0
const LOW_TIME_THRESHOLD_SEC: float = 3.0
const PULSE_SPEED: float = 8.0

var _player: Player = null
var _blessing_chip: PanelContainer = null
var _agi_chip: PanelContainer = null
var _blessing_bar: ProgressBar = null
var _agi_bar: ProgressBar = null


func _ready() -> void:
	add_theme_constant_override("separation", 6)
	visible = false
	_blessing_chip = _build_buff_chip("BLS", Color(0.95, 0.82, 0.28, 1.0), "Blessing (×2 daño)")
	_agi_chip = _build_buff_chip("AGI", Color(0.35, 0.88, 1.0, 1.0), "Increase AGI (+50% velocidad)")
	add_child(_blessing_chip)
	add_child(_agi_chip)


func bind_player(player: Player) -> void:
	_player = player


func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		visible = false
		return
	var remaining: float = _player.get_support_buff_time_left()
	var active: bool = remaining > 0.0
	visible = active
	if not active:
		_reset_chip_visuals()
		return
	_update_chip(_blessing_chip, _blessing_bar, remaining)
	_update_chip(_agi_chip, _agi_bar, remaining)


func _build_buff_chip(label_text: String, accent: Color, tooltip: String) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(52, 56)
	panel.tooltip_text = tooltip
	_Theme.apply_panel(panel)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_top", 3)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_bottom", 3)
	panel.add_child(margin)
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	margin.add_child(vbox)
	var icon: Label = Label.new()
	icon.text = label_text
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 11)
	icon.add_theme_color_override("font_color", accent)
	vbox.add_child(icon)
	var bar: ProgressBar = ProgressBar.new()
	bar.custom_minimum_size = Vector2(44, 6)
	bar.max_value = BUFF_DURATION_SEC
	bar.value = BUFF_DURATION_SEC
	bar.show_percentage = false
	vbox.add_child(bar)
	if label_text == "BLS":
		_blessing_bar = bar
	else:
		_agi_bar = bar
	return panel


func _update_chip(chip: PanelContainer, bar: ProgressBar, remaining: float) -> void:
	if chip == null or bar == null:
		return
	chip.visible = true
	bar.value = remaining
	var low_time: bool = remaining <= LOW_TIME_THRESHOLD_SEC
	if low_time:
		var wave: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * PULSE_SPEED)
		chip.modulate = Color(1.0, lerpf(0.65, 1.0, wave), lerpf(0.65, 1.0, wave), 1.0)
	else:
		chip.modulate = Color.WHITE


func _reset_chip_visuals() -> void:
	for chip: PanelContainer in [_blessing_chip, _agi_chip]:
		if chip:
			chip.modulate = Color.WHITE
