## Catálogo de oleadas especiales durante la run (antes del jefe ~9 min).
class_name WaveEventCatalog
extends RefCounted

const WALL_LEFT_RIGHT: String = "wall_left_right"
const WALL_RIGHT_LEFT: String = "wall_right_left"
const WALL_TOP_BOTTOM: String = "wall_top_bottom"
const WALL_BOTTOM_TOP: String = "wall_bottom_top"
const HORDE_BURST: String = "horde_burst"
const PINCH_HORIZONTAL: String = "pinch_horizontal"
const CROSS_WALLS: String = "cross_walls"


static func get_schedule() -> Array[Dictionary]:
	return [
		_make(WALL_LEFT_RIGHT, 42.0, 36, 105.0, "¡Oleada! Muro desde la izquierda"),
		_make(HORDE_BURST, 78.0, 48, 0.0, "¡Oleada! Horda exterior"),
		_make(WALL_RIGHT_LEFT, 115.0, 36, 105.0, "¡Oleada! Muro desde la derecha"),
		_make(WALL_TOP_BOTTOM, 155.0, 32, 98.0, "¡Oleada! Muro desde arriba"),
		_make(PINCH_HORIZONTAL, 195.0, 40, 82.0, "¡Oleada! Pinza horizontal"),
		_make(WALL_BOTTOM_TOP, 235.0, 32, 98.0, "¡Oleada! Muro desde abajo"),
		_make(CROSS_WALLS, 285.0, 28, 115.0, "¡Oleada! Cruce de muros"),
		_make(HORDE_BURST, 330.0, 55, 0.0, "¡Oleada! Horda masiva"),
		_make(WALL_LEFT_RIGHT, 380.0, 42, 125.0, "¡Oleada! Muro rápido"),
		_make(PINCH_HORIZONTAL, 430.0, 44, 100.0, "¡Oleada! Pinza final"),
		_make(WALL_RIGHT_LEFT, 485.0, 48, 130.0, "¡Oleada! Asalto final"),
	]


static func _make(
	wave_type: String,
	time_sec: float,
	count: int,
	speed: float,
	announce: String
) -> Dictionary:
	return {
		"type": wave_type,
		"time": time_sec,
		"count": count,
		"speed": speed,
		"announce": announce,
	}
