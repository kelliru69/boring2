## Dispara oleadas especiales según el tiempo de sesión.
class_name WaveEventController
extends Node

const _Catalog = preload("res://data/wave_event_catalog.gd")

var _main: Node = null
var _schedule: Array[Dictionary] = []
var _next_index: int = 0
var _active: bool = true


func setup(main_node: Node) -> void:
	_main = main_node
	_schedule = _Catalog.get_schedule()
	_next_index = 0


func set_active(active: bool) -> void:
	_active = active


func _process(_delta: float) -> void:
	if not _active or _main == null or _next_index >= _schedule.size():
		return
	var entry: Dictionary = _schedule[_next_index]
	if Global.session_elapsed_time < float(entry.get("time", 9999.0)):
		return
	_trigger_wave(entry)
	_next_index += 1


func _trigger_wave(entry: Dictionary) -> void:
	if not _main.has_method("run_wave_event"):
		return
	var announce: String = String(entry.get("announce", ""))
	if not announce.is_empty():
		Arena.announce_wave(announce)
	_main.call("run_wave_event", entry)
