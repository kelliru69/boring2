## Flechas rojas intermitentes en el borde de pantalla antes de oleadas tipo muro.
class_name WallWaveWarningOverlay
extends Control

const _WaveCatalog = preload("res://data/wave_event_catalog.gd")

const EDGE_MARGIN: float = 52.0
const ARROW_SPACING: float = 88.0
const ARROW_SIZE: float = 22.0
const BLINK_HZ: float = 5.5

const ARROW_CORE: Color = Color(1.0, 0.12, 0.1, 1.0)
const ARROW_OUTLINE_DARK: Color = Color(0.05, 0.0, 0.0, 0.95)
const ARROW_OUTLINE_LIGHT: Color = Color(1.0, 0.92, 0.88, 0.9)

var _time_left: float = 0.0
var _arrow_specs: Array[Dictionary] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false
	set_process(true)


func show_for_wave_type(wave_type: String, duration: float = _WaveCatalog.WALL_WARNING_LEAD_SECONDS) -> void:
	_arrow_specs = _WaveCatalog.get_wall_warning_arrows(wave_type)
	if _arrow_specs.is_empty():
		visible = false
		return
	_time_left = maxf(duration, 0.05)
	visible = true
	queue_redraw()


func hide_warning() -> void:
	_time_left = 0.0
	_arrow_specs.clear()
	visible = false
	queue_redraw()


func _process(delta: float) -> void:
	if not visible:
		return
	_time_left = maxf(_time_left - delta, 0.0)
	queue_redraw()
	if _time_left <= 0.0:
		hide_warning()


func _draw() -> void:
	if _arrow_specs.is_empty():
		return
	var blink: float = 0.45 + 0.55 * absf(sin(Time.get_ticks_msec() * 0.001 * TAU * BLINK_HZ))
	var vp_size: Vector2 = size
	if vp_size.x < 8.0 or vp_size.y < 8.0:
		vp_size = get_viewport_rect().size
	for spec: Dictionary in _arrow_specs:
		_draw_edge_arrows(
			String(spec.get("edge", "")),
			spec.get("direction", Vector2.RIGHT) as Vector2,
			vp_size,
			blink
		)


func _draw_edge_arrows(edge: String, direction: Vector2, viewport_size: Vector2, alpha: float) -> void:
	if direction.length_squared() < 0.0001:
		return
	direction = direction.normalized()
	var count: int = maxi(int(viewport_size.y / ARROW_SPACING) if edge == "left" or edge == "right" else int(viewport_size.x / ARROW_SPACING), 3)
	count = mini(count, 7)
	for i: int in count:
		var t: float = 0.0 if count <= 1 else float(i) / float(count - 1)
		var anchor: Vector2 = _edge_anchor(edge, t, viewport_size)
		_draw_directional_arrow(anchor, direction, alpha)


func _edge_anchor(edge: String, t: float, viewport_size: Vector2) -> Vector2:
	match edge:
		"left":
			return Vector2(EDGE_MARGIN, lerpf(EDGE_MARGIN * 2.0, viewport_size.y - EDGE_MARGIN * 2.0, t))
		"right":
			return Vector2(viewport_size.x - EDGE_MARGIN, lerpf(EDGE_MARGIN * 2.0, viewport_size.y - EDGE_MARGIN * 2.0, t))
		"top":
			return Vector2(lerpf(EDGE_MARGIN * 2.0, viewport_size.x - EDGE_MARGIN * 2.0, t), EDGE_MARGIN)
		"bottom":
			return Vector2(lerpf(EDGE_MARGIN * 2.0, viewport_size.x - EDGE_MARGIN * 2.0, t), viewport_size.y - EDGE_MARGIN)
		_:
			return Vector2.ZERO


func _draw_directional_arrow(center: Vector2, direction: Vector2, alpha: float) -> void:
	var forward: Vector2 = direction * ARROW_SIZE
	var side: Vector2 = Vector2(-direction.y, direction.x) * (ARROW_SIZE * 0.55)
	var tip: Vector2 = center + forward
	var back_l: Vector2 = center - forward * 0.35 + side
	var back_r: Vector2 = center - forward * 0.35 - side
	var poly: PackedVector2Array = [tip, back_l, back_r]
	var dark: Color = ARROW_OUTLINE_DARK
	dark.a *= alpha
	var light: Color = ARROW_OUTLINE_LIGHT
	light.a *= alpha
	var core: Color = ARROW_CORE
	core.a *= alpha
	draw_colored_polygon(poly, core)
	var closed: PackedVector2Array = poly.duplicate()
	closed.append(poly[0])
	draw_polyline(closed, dark, 5.0, true)
	draw_polyline(closed, light, 3.0, true)
