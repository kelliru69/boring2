## Menú de pausa (ESC): sonido, gráficos, controles y habilidades.
extends CanvasLayer

const _Theme = preload("res://scripts/ui/modern_ui_theme.gd")
const _MenuEsc = preload("res://scripts/ui/menu_esc_handler.gd")
const _Pause = preload("res://scripts/ui/run_pause_guard.gd")
const _CombatKitScene: PackedScene = preload("res://scenes/ui/components/CombatKitOverlay.tscn")

@onready var dimmer: ColorRect = $Dimmer
@onready var panel: PanelContainer = $PanelContainer
@onready var title_label: Label = $PanelContainer/Margin/VBox/TitleLabel
@onready var tab_container: TabContainer = $PanelContainer/Margin/VBox/TabContainer
@onready var master_slider: HSlider = $PanelContainer/Margin/VBox/TabContainer/Sonido/MasterRow/MasterSlider
@onready var bgm_slider: HSlider = $PanelContainer/Margin/VBox/TabContainer/Sonido/BgmRow/BgmSlider
@onready var sfx_slider: HSlider = $PanelContainer/Margin/VBox/TabContainer/Sonido/SfxRow/SfxSlider
@onready var master_value_label: Label = $PanelContainer/Margin/VBox/TabContainer/Sonido/MasterRow/MasterValue
@onready var bgm_value_label: Label = $PanelContainer/Margin/VBox/TabContainer/Sonido/BgmRow/BgmValue
@onready var sfx_value_label: Label = $PanelContainer/Margin/VBox/TabContainer/Sonido/SfxRow/SfxValue
@onready var fullscreen_check: CheckButton = $PanelContainer/Margin/VBox/TabContainer/Graficos/FullscreenCheck
@onready var pixel_filter_check: CheckButton = $PanelContainer/Margin/VBox/TabContainer/Graficos/PixelFilterCheck
@onready var brightness_slider: HSlider = $PanelContainer/Margin/VBox/TabContainer/Graficos/BrightnessRow/BrightnessSlider
@onready var brightness_value_label: Label = $PanelContainer/Margin/VBox/TabContainer/Graficos/BrightnessRow/BrightnessValue
@onready var tile_grid_check: CheckButton = $PanelContainer/Margin/VBox/TabContainer/Graficos/TileGridCheck
@onready var aim_ring_check: CheckButton = $PanelContainer/Margin/VBox/TabContainer/Graficos/AimRingCheck
@onready var controls_host: VBoxContainer = $PanelContainer/Margin/VBox/TabContainer/Controles/ControlsHost
@onready var kit_button: Button = $PanelContainer/Margin/VBox/TabContainer/Habilidades/KitButton
@onready var skill_tree_menu: Control = $PanelContainer/Margin/VBox/TabContainer/Habilidades/SkillTreeMenu
@onready var resume_button: Button = $PanelContainer/Margin/VBox/ResumeButton
@onready var abandon_button: Button = $PanelContainer/Margin/VBox/AbandonButton
@onready var esc_hint: Label = $PanelContainer/Margin/VBox/EscHint

var _is_open: bool = false
var _kit_overlay: CombatKitOverlay = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	dimmer.color = _Theme.DIMMER
	_Theme.apply_panel(panel)
	_Theme.style_title(title_label, 22)
	for lbl: Label in [master_value_label, bgm_value_label, sfx_value_label, brightness_value_label]:
		_Theme.style_accent(lbl, 12)
	for lbl: Label in [
		$PanelContainer/Margin/VBox/TabContainer/Sonido/MasterRow/MasterLabel,
		$PanelContainer/Margin/VBox/TabContainer/Sonido/BgmRow/BgmLabel,
		$PanelContainer/Margin/VBox/TabContainer/Sonido/SfxRow/SfxLabel,
		$PanelContainer/Margin/VBox/TabContainer/Graficos/BrightnessRow/BrightnessLabel,
	]:
		_Theme.style_body(lbl as Label, 13)
	for chk: CheckButton in [tile_grid_check, aim_ring_check, fullscreen_check, pixel_filter_check]:
		chk.add_theme_color_override(&"font_color", _Theme.TEXT_PRIMARY)
		chk.add_theme_font_size_override(&"font_size", 13)
	_Theme.style_subtitle(esc_hint, 11)
	_Theme.apply_button(resume_button, 46.0)
	_Theme.apply_button(abandon_button, 46.0)
	_Theme.apply_button(kit_button, 40.0)
	abandon_button.add_theme_color_override("font_color", Color(1.0, 0.55, 0.5, 1.0))
	_Theme.apply_slider(master_slider)
	_Theme.apply_slider(bgm_slider)
	_Theme.apply_slider(sfx_slider)
	_Theme.apply_slider(brightness_slider)
	_sync_sliders_from_audio()
	_sync_graphics_from_settings()
	master_slider.value_changed.connect(_on_master_changed)
	bgm_slider.value_changed.connect(_on_bgm_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	brightness_slider.value_changed.connect(_on_brightness_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	pixel_filter_check.toggled.connect(_on_pixel_filter_toggled)
	tile_grid_check.toggled.connect(_on_tile_grid_toggled)
	aim_ring_check.toggled.connect(_on_aim_ring_toggled)
	resume_button.pressed.connect(_close_pause)
	abandon_button.pressed.connect(_on_abandon_pressed)
	kit_button.pressed.connect(_on_kit_pressed)
	var controls_panel := ControlsRemapPanel.new()
	controls_host.add_child(controls_panel)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	if _is_kit_overlay_open():
		Audio.play_ui_click()
		_kit_overlay.close()
		_MenuEsc.mark_input_handled(self)
		return
	if _should_block_pause():
		return
	if _is_open:
		_close_pause()
	else:
		_open_pause()
	_MenuEsc.mark_input_handled(self)


func _should_block_pause() -> bool:
	var main: Node = get_parent()
	if main == null:
		return false
	var level_up: CanvasLayer = main.get_node_or_null("LevelUpUI") as CanvasLayer
	if level_up != null and level_up.visible:
		return true
	var game_over: CanvasLayer = main.get_node_or_null("GameOverUI") as CanvasLayer
	if game_over != null and game_over.visible:
		return true
	return false


func _open_pause() -> void:
	_is_open = true
	_sync_sliders_from_audio()
	_sync_graphics_from_settings()
	if skill_tree_menu and skill_tree_menu.has_method("_refresh"):
		skill_tree_menu.call("_refresh")
	visible = true
	_Pause.lock_pause(get_tree())
	Audio.resume_bgm_if_needed()


func close_pause_menu() -> void:
	_close_pause()


func _close_pause() -> void:
	if not _is_open:
		return
	if _is_kit_overlay_open():
		_kit_overlay.close()
	_is_open = false
	visible = false
	_Pause.force_unlock(get_tree())
	Audio.save_volume_settings()
	GraphicsSettings.save_graphics_settings()
	Audio.play_ui_click()


func _on_abandon_pressed() -> void:
	if _is_kit_overlay_open():
		_kit_overlay.close()
	_is_open = false
	visible = false
	_Pause.force_unlock(get_tree())
	Audio.save_volume_settings()
	GraphicsSettings.save_graphics_settings()
	Audio.play_ui_click()
	Game.abandon_run_to_title()


func _is_kit_overlay_open() -> bool:
	return _kit_overlay != null and is_instance_valid(_kit_overlay) and _kit_overlay.visible


func _on_kit_pressed() -> void:
	Audio.play_ui_click()
	if _kit_overlay == null or not is_instance_valid(_kit_overlay):
		_kit_overlay = _CombatKitScene.instantiate() as CombatKitOverlay
		get_tree().root.add_child(_kit_overlay)
	if _kit_overlay:
		_kit_overlay.open()


func _sync_sliders_from_audio() -> void:
	var settings: Dictionary = Audio.get_volume_settings()
	master_slider.set_value_no_signal(settings.get("master", 1.0) * 100.0)
	bgm_slider.set_value_no_signal(settings.get("bgm", 0.55) * 100.0)
	sfx_slider.set_value_no_signal(settings.get("sfx", 0.7) * 100.0)
	_refresh_value_labels()


func _on_master_changed(value: float) -> void:
	Audio.set_master_volume(value / 100.0)
	_refresh_value_labels()


func _on_bgm_changed(value: float) -> void:
	Audio.set_bgm_volume(value / 100.0)
	_refresh_value_labels()


func _on_sfx_changed(value: float) -> void:
	Audio.set_sfx_volume(value / 100.0)
	_refresh_value_labels()


func _sync_graphics_from_settings() -> void:
	var settings: Dictionary = GraphicsSettings.get_settings()
	tile_grid_check.set_pressed_no_signal(bool(settings.get("show_tile_grid_selector", true)))
	aim_ring_check.set_pressed_no_signal(bool(settings.get("show_aim_direction_ring", true)))
	fullscreen_check.set_pressed_no_signal(bool(settings.get("fullscreen", false)))
	pixel_filter_check.set_pressed_no_signal(bool(settings.get("pixel_filter", true)))
	brightness_slider.set_value_no_signal(float(settings.get("brightness", 1.0)) * 100.0)
	brightness_value_label.text = "%d%%" % int(brightness_slider.value)


func _on_tile_grid_toggled(enabled: bool) -> void:
	GraphicsSettings.set_show_tile_grid_selector(enabled)
	GraphicsSettings.save_graphics_settings()


func _on_aim_ring_toggled(enabled: bool) -> void:
	GraphicsSettings.set_show_aim_direction_ring(enabled)
	GraphicsSettings.save_graphics_settings()


func _on_fullscreen_toggled(enabled: bool) -> void:
	GraphicsSettings.set_fullscreen(enabled)
	GraphicsSettings.save_graphics_settings()


func _on_pixel_filter_toggled(enabled: bool) -> void:
	GraphicsSettings.set_pixel_filter(enabled)
	GraphicsSettings.save_graphics_settings()


func _on_brightness_changed(value: float) -> void:
	GraphicsSettings.set_brightness(value / 100.0)
	brightness_value_label.text = "%d%%" % int(value)
	GraphicsSettings.save_graphics_settings()


func _refresh_value_labels() -> void:
	master_value_label.text = "%d%%" % int(master_slider.value)
	bgm_value_label.text = "%d%%" % int(bgm_slider.value)
	sfx_value_label.text = "%d%%" % int(sfx_slider.value)
