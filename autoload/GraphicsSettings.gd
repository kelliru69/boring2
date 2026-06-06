## Preferencias gráficas persistentes: indicadores, pantalla completa, filtro pixel y brillo HUD.
extends Node

signal settings_changed

const SETTINGS_PATH: String = "user://graphics_settings.cfg"

var show_tile_grid_selector: bool = true
var show_aim_direction_ring: bool = true
var fullscreen: bool = false
var pixel_filter: bool = true
var brightness: float = 1.0

var _brightness_canvas: CanvasLayer = null


func _ready() -> void:
	_load_settings()
	_apply_runtime_settings()


func get_settings() -> Dictionary:
	return {
		"show_tile_grid_selector": show_tile_grid_selector,
		"show_aim_direction_ring": show_aim_direction_ring,
		"fullscreen": fullscreen,
		"pixel_filter": pixel_filter,
		"brightness": brightness,
	}


func set_show_tile_grid_selector(enabled: bool) -> void:
	if show_tile_grid_selector == enabled:
		return
	show_tile_grid_selector = enabled
	settings_changed.emit()


func set_show_aim_direction_ring(enabled: bool) -> void:
	if show_aim_direction_ring == enabled:
		return
	show_aim_direction_ring = enabled
	settings_changed.emit()


func set_fullscreen(enabled: bool) -> void:
	if fullscreen == enabled:
		return
	fullscreen = enabled
	_apply_fullscreen()
	settings_changed.emit()


func set_pixel_filter(enabled: bool) -> void:
	if pixel_filter == enabled:
		return
	pixel_filter = enabled
	_apply_pixel_filter()
	settings_changed.emit()


func set_brightness(value: float) -> void:
	brightness = clampf(value, 0.5, 1.5)
	_apply_brightness_overlay()
	settings_changed.emit()


func save_graphics_settings() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.set_value("graphics", "show_tile_grid_selector", show_tile_grid_selector)
	cfg.set_value("graphics", "show_aim_direction_ring", show_aim_direction_ring)
	cfg.set_value("graphics", "fullscreen", fullscreen)
	cfg.set_value("graphics", "pixel_filter", pixel_filter)
	cfg.set_value("graphics", "brightness", brightness)
	cfg.save(SETTINGS_PATH)


func _load_settings() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	show_tile_grid_selector = bool(cfg.get_value("graphics", "show_tile_grid_selector", true))
	show_aim_direction_ring = bool(cfg.get_value("graphics", "show_aim_direction_ring", true))
	fullscreen = bool(cfg.get_value("graphics", "fullscreen", false))
	pixel_filter = bool(cfg.get_value("graphics", "pixel_filter", true))
	brightness = float(cfg.get_value("graphics", "brightness", 1.0))


func _apply_runtime_settings() -> void:
	_apply_fullscreen()
	_apply_pixel_filter()
	_apply_brightness_overlay()


func _apply_fullscreen() -> void:
	var mode: DisplayServer.WindowMode = (
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen
		else DisplayServer.WINDOW_MODE_WINDOWED
	)
	DisplayServer.window_set_mode(mode)


func _apply_pixel_filter() -> void:
	var filter: int = (
		ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter")
	)
	if pixel_filter:
		ProjectSettings.set_setting("rendering/textures/canvas_textures/default_texture_filter", 0)
	else:
		ProjectSettings.set_setting("rendering/textures/canvas_textures/default_texture_filter", 1)


func _apply_brightness_overlay() -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	if _brightness_canvas == null or not is_instance_valid(_brightness_canvas):
		_brightness_canvas = CanvasLayer.new()
		_brightness_canvas.layer = 120
		_brightness_canvas.name = "BrightnessOverlay"
		var rect := ColorRect.new()
		rect.name = "Tint"
		rect.anchors_preset = Control.PRESET_FULL_RECT
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_brightness_canvas.add_child(rect)
		tree.root.add_child(_brightness_canvas)
	var tint: ColorRect = _brightness_canvas.get_node("Tint") as ColorRect
	if tint == null:
		return
	var delta: float = brightness - 1.0
	if delta >= 0.0:
		tint.color = Color(1.0, 1.0, 1.0, clampf(delta * 0.35, 0.0, 0.35))
	else:
		tint.color = Color(0.0, 0.0, 0.0, clampf(-delta * 0.45, 0.0, 0.45))
