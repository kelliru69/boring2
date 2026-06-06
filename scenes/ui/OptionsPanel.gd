## Panel emergente de opciones — volumen BGM/SFX vía AudioServer.
extends CanvasLayer

const _Theme = preload("res://scripts/ui/modern_ui_theme.gd")
const _MenuEsc = preload("res://scripts/ui/menu_esc_handler.gd")

const BUS_MUSIC: StringName = &"Music"
const BUS_SFX: StringName = &"SFX"

@onready var dimmer: ColorRect = $Dimmer
@onready var panel: PanelContainer = $PanelRoot/Panel
@onready var music_slider: HSlider = $PanelRoot/Panel/Margin/VBox/MusicRow/MusicHBox/MusicSlider
@onready var music_value: Label = $PanelRoot/Panel/Margin/VBox/MusicRow/MusicHBox/MusicValue
@onready var sfx_slider: HSlider = $PanelRoot/Panel/Margin/VBox/SfxRow/SfxHBox/SfxSlider
@onready var sfx_value: Label = $PanelRoot/Panel/Margin/VBox/SfxRow/SfxHBox/SfxValue
@onready var wipe_button: Button = $PanelRoot/Panel/Margin/VBox/WipeButton
@onready var close_button: Button = $PanelRoot/Panel/Margin/VBox/CloseButton
@onready var wipe_confirm: ConfirmationDialog = $WipeConfirmDialog


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	if dimmer.material is ShaderMaterial:
		dimmer.material.set_shader_parameter(&"tint_color", _Theme.DIMMER)
	_Theme.apply_panel(panel)
	_Theme.apply_button(close_button, 44.0)
	_Theme.apply_slider(music_slider)
	_Theme.apply_slider(sfx_slider)
	_Theme.style_title($PanelRoot/Panel/Margin/VBox/TitleLabel, 22)
	for lbl: Label in [$PanelRoot/Panel/Margin/VBox/MusicRow/MusicLabel, $PanelRoot/Panel/Margin/VBox/SfxRow/SfxLabel]:
		_Theme.style_body(lbl, 14)
	music_slider.min_value = 0.0
	music_slider.max_value = 100.0
	music_slider.step = 1.0
	sfx_slider.min_value = 0.0
	sfx_slider.max_value = 100.0
	sfx_slider.step = 1.0
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	close_button.pressed.connect(hide_options)
	if wipe_button:
		_Theme.apply_button(wipe_button, 44.0)
		wipe_button.pressed.connect(_on_wipe_pressed)
	if wipe_confirm:
		wipe_confirm.confirmed.connect(_on_wipe_confirmed)
	dimmer.gui_input.connect(_on_dimmer_input)
	set_process_unhandled_input(true)


func _unhandled_input(event: InputEvent) -> void:
	if visible and _MenuEsc.is_back_pressed(event):
		hide_options()
		_MenuEsc.mark_input_handled(self)


func show_options() -> void:
	_sync_sliders_from_buses()
	visible = true


func hide_options() -> void:
	Audio.play_ui_click()
	Audio.save_volume_settings()
	visible = false


func _sync_sliders_from_buses() -> void:
	music_slider.set_value_no_signal(_bus_linear_percent(BUS_MUSIC))
	sfx_slider.set_value_no_signal(_bus_linear_percent(BUS_SFX))
	_update_value_labels()


func _on_music_changed(value: float) -> void:
	_set_bus_linear_percent(BUS_MUSIC, value)
	music_value.text = "%d%%" % int(round(value))
	Audio.set_bgm_volume(value / 100.0)


func _on_sfx_changed(value: float) -> void:
	_set_bus_linear_percent(BUS_SFX, value)
	sfx_value.text = "%d%%" % int(round(value))
	Audio.set_sfx_volume(value / 100.0)


func _update_value_labels() -> void:
	music_value.text = "%d%%" % int(round(music_slider.value))
	sfx_value.text = "%d%%" % int(round(sfx_slider.value))


func _bus_linear_percent(bus_name: StringName) -> float:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return 100.0
	var db: float = AudioServer.get_bus_volume_db(idx)
	if db <= -79.0:
		return 0.0
	return clampf(db_to_linear(db) * 100.0, 0.0, 100.0)


func _set_bus_linear_percent(bus_name: StringName, percent: float) -> void:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	var linear: float = clampf(percent / 100.0, 0.0, 1.0)
	var db: float = -80.0 if linear <= 0.001 else linear_to_db(linear)
	AudioServer.set_bus_volume_db(idx, db)


func _on_dimmer_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		hide_options()


func _on_wipe_pressed() -> void:
	Audio.play_ui_click()
	if wipe_confirm:
		wipe_confirm.popup_centered()


func _on_wipe_confirmed() -> void:
	Audio.play_ui_click()
	Global.wipe_all_progress()
	Game.intermap_preparation_mode = false
	hide_options()
	Game.go_to_title()
