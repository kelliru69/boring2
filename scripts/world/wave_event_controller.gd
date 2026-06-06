## Dispara oleadas especiales según el tiempo de sesión (aviso de muro 3 s antes).
class_name WaveEventController
extends Node

const _Catalog = preload("res://data/wave_event_catalog.gd")

var _main: Node = null
var _schedule: Array[Dictionary] = []
var _next_index: int = 0
var _wall_warning_armed: bool = false
var _active: bool = true


func setup(main_node: Node, map_id: String = "prontera_fields") -> void:
	_main = main_node
	_schedule = _Catalog.get_schedule(map_id)
	_next_index = 0
	_wall_warning_armed = false


func set_active(active: bool) -> void:
	_active = active
	if not active:
		_hide_wall_warning()


func _process(_delta: float) -> void:
	if not _active or _main == null or _next_index >= _schedule.size():
		return
	var entry: Dictionary = _schedule[_next_index]
	var trigger_time: float = float(entry.get("time", 9999.0))
	var wave_type: String = String(entry.get("type", ""))
	var elapsed: float = Global.session_elapsed_time
	if _Catalog.is_directional_wall_event(wave_type):
		var warn_at: float = trigger_time - _Catalog.WALL_WARNING_LEAD_SECONDS
		if not _wall_warning_armed and elapsed >= warn_at:
			_wall_warning_armed = true
			_show_wall_warning(wave_type)
		if elapsed >= trigger_time:
			_hide_wall_warning()
			_trigger_wave(entry)
			_next_index += 1
			_wall_warning_armed = false
		return
	if elapsed >= trigger_time:
		_trigger_wave(entry)
		_next_index += 1


func _show_wall_warning(wave_type: String) -> void:
	if _main == null or not _main.has_method("show_wall_wave_warning"):
		return
	_main.call("show_wall_wave_warning", wave_type, _Catalog.WALL_WARNING_LEAD_SECONDS)


func _hide_wall_warning() -> void:
	if _main == null or not _main.has_method("hide_wall_wave_warning"):
		return
	_main.call("hide_wall_wave_warning")


func _trigger_wave(entry: Dictionary) -> void:
	if not _main.has_method("run_wave_event"):
		return
	var announce: String = String(entry.get("announce", ""))
	if not announce.is_empty():
		Arena.announce_wave(announce)
	_main.call("run_wave_event", entry)
