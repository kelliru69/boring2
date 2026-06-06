## Catálogo de oleadas especiales durante la run (antes del jefe ~9 min).
class_name WaveEventCatalog
extends RefCounted

const _MapConfig = preload("res://data/map_config.gd")

const WALL_LEFT_RIGHT: String = "wall_left_right"
const WALL_RIGHT_LEFT: String = "wall_right_left"
const WALL_TOP_BOTTOM: String = "wall_top_bottom"
const WALL_BOTTOM_TOP: String = "wall_bottom_top"
const HORDE_BURST: String = "horde_burst"
const PINCH_HORIZONTAL: String = "pinch_horizontal"
const CROSS_WALLS: String = "cross_walls"

## Segundos de aviso en borde de pantalla antes de que el muro aparezca.
const WALL_WARNING_LEAD_SECONDS: float = 3.0


static func is_directional_wall_event(wave_type: String) -> bool:
	match wave_type:
		WALL_LEFT_RIGHT, WALL_RIGHT_LEFT, WALL_TOP_BOTTOM, WALL_BOTTOM_TOP, PINCH_HORIZONTAL, CROSS_WALLS:
			return true
		_:
			return false


## Cada entrada: edge (left|right|top|bottom), direction (Vector2 hacia donde avanza el muro).
static func get_wall_warning_arrows(wave_type: String) -> Array[Dictionary]:
	var specs: Array[Dictionary] = []
	match wave_type:
		WALL_LEFT_RIGHT:
			specs.append(_arrow_spec("left", Vector2.RIGHT))
		WALL_RIGHT_LEFT:
			specs.append(_arrow_spec("right", Vector2.LEFT))
		WALL_TOP_BOTTOM:
			specs.append(_arrow_spec("top", Vector2.DOWN))
		WALL_BOTTOM_TOP:
			specs.append(_arrow_spec("bottom", Vector2.UP))
		PINCH_HORIZONTAL:
			specs.append(_arrow_spec("left", Vector2.RIGHT))
			specs.append(_arrow_spec("right", Vector2.LEFT))
		CROSS_WALLS:
			specs.append(_arrow_spec("left", Vector2.RIGHT))
			specs.append(_arrow_spec("top", Vector2.DOWN))
		_:
			pass
	return specs


static func _arrow_spec(edge: String, direction: Vector2) -> Dictionary:
	return {"edge": edge, "direction": direction}


static func get_schedule(map_id: String = _MapConfig.MAP_PRONTERA) -> Array[Dictionary]:
	if map_id == _MapConfig.MAP_ORC_VILLAGE:
		return [
			_make(HORDE_BURST, 40.0, 62, 0.0, "¡Orc Village! Horda de Orc Lady"),
			_make(WALL_LEFT_RIGHT, 72.0, 38, 135.0, "¡Orc Village! Muro de guerra"),
			_make(HORDE_BURST, 105.0, 78, 0.0, "¡Orc Village! Enjambre orco"),
			_make(PINCH_HORIZONTAL, 150.0, 55, 128.0, "¡Orc Village! Pinza de hierro"),
			_make(CROSS_WALLS, 198.0, 40, 150.0, "¡Orc Village! Cruce brutal"),
			_make(HORDE_BURST, 250.0, 92, 0.0, "¡Orc Village! Marea verde"),
			_make(WALL_TOP_BOTTOM, 310.0, 44, 145.0, "¡Orc Village! Asedio"),
			_make(PINCH_HORIZONTAL, 365.0, 64, 132.0, "¡Orc Village! Pinza final"),
			_make(HORDE_BURST, 420.0, 98, 0.0, "¡Orc Village! Última horda"),
		]
	if map_id == _MapConfig.MAP_PAYON:
		return [
			_make(WALL_LEFT_RIGHT, 45.0, 35, 125.0, "¡Payon! Muro espectral"),
			_make(HORDE_BURST, 58.0, 51, 0.0, "¡Payon! Horda maldita"),
			_make(WALL_TOP_BOTTOM, 92.0, 32, 132.0, "¡Payon! Muro desde arriba"),
			_make(PINCH_HORIZONTAL, 128.0, 52, 112.0, "¡Payon! Pinza doble"),
			_make(CROSS_WALLS, 168.0, 36, 140.0, "¡Payon! Cruce infernal"),
			_make(HORDE_BURST, 210.0, 74, 0.0, "¡Payon! Enjambre de familiares"),
			_make(WALL_BOTTOM_TOP, 254.0, 42, 138.0, "¡Payon! Muro ascendente"),
			_make(PINCH_HORIZONTAL, 300.0, 58, 122.0, "¡Payon! Pinza reforzada"),
			_make(CROSS_WALLS, 350.0, 42, 148.0, "¡Payon! Cruce final"),
			_make(HORDE_BURST, 405.0, 84, 0.0, "¡Payon! Horda masiva"),
			_make(WALL_RIGHT_LEFT, 465.0, 56, 155.0, "¡Payon! Asalto final"),
		]
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
