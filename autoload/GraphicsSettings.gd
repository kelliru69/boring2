## Preferencias gráficas de partida (indicadores de apuntado). Persisten en user://.
extends Node

signal settings_changed

const SETTINGS_PATH: String = "user://graphics_settings.cfg"

var show_tile_grid_selector: bool = true
var show_aim_direction_ring: bool = true


func _ready() -> void:
	_load_settings()


func get_settings() -> Dictionary:
	return {
		"show_tile_grid_selector": show_tile_grid_selector,
		"show_aim_direction_ring": show_aim_direction_ring,
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


func save_graphics_settings() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.set_value("graphics", "show_tile_grid_selector", show_tile_grid_selector)
	cfg.set_value("graphics", "show_aim_direction_ring", show_aim_direction_ring)
	cfg.save(SETTINGS_PATH)


func _load_settings() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	show_tile_grid_selector = bool(cfg.get_value("graphics", "show_tile_grid_selector", true))
	show_aim_direction_ring = bool(cfg.get_value("graphics", "show_aim_direction_ring", true))
