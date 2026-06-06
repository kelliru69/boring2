## Indicador de celda (snap al TileMap) — marco rojo estilo Ragnarok Online.
class_name GridSelector
extends Node2D

const DEFAULT_TILE_PX: int = 32

@export_group("Apariencia")
@export var border_color: Color = Color(1.0, 0.2, 0.12, 0.45)
@export var fill_color: Color = Color(1.0, 0.15, 0.1, 0.12)
@export var border_width: float = 3.0
@export var world_z_index: int = -10

var _tile_layer: TileMapLayer = null
var _world_tile_extent: float = float(DEFAULT_TILE_PX)
var _active: bool = false
var _fill_poly: Polygon2D = null
var _outline: Line2D = null


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_as_top_level(true)
	z_as_relative = false
	z_index = world_z_index
	_build_visuals()
	set_process(false)
	visible = false


func _build_visuals() -> void:
	_fill_poly = Polygon2D.new()
	_fill_poly.name = "Fill"
	_fill_poly.color = fill_color
	_fill_poly.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_fill_poly)
	_outline = Line2D.new()
	_outline.name = "Outline"
	_outline.closed = true
	_outline.width = border_width
	_outline.default_color = border_color
	_outline.antialiased = false
	_outline.joint_mode = Line2D.LINE_JOINT_SHARP
	_outline.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_outline)


func setup(tile_layer: TileMapLayer, fallback_world_tile_px: int = DEFAULT_TILE_PX) -> void:
	_tile_layer = tile_layer
	_world_tile_extent = _measure_world_tile_extent(maxi(fallback_world_tile_px, 1))
	z_index = world_z_index
	_update_visual_shape()


func set_selector_active(active: bool) -> void:
	_active = active
	visible = active
	set_process(active)
	if _fill_poly:
		_fill_poly.visible = active
	if _outline:
		_outline.visible = active
	if active:
		_update_visual_shape()


func _process(_delta: float) -> void:
	if not _active or _tile_layer == null or not is_instance_valid(_tile_layer):
		visible = false
		return
	if get_tree().paused:
		visible = false
		return
	visible = true
	global_position = _snapped_global_center()


func _snapped_global_center() -> Vector2:
	var global_mouse: Vector2 = get_global_mouse_position()
	var local_in_layer: Vector2 = _tile_layer.to_local(global_mouse)
	var cell: Vector2i = _tile_layer.local_to_map(local_in_layer)
	# Godot 4: map_to_local ya devuelve el CENTRO de la celda.
	var local_center: Vector2 = _tile_layer.map_to_local(cell)
	return _tile_layer.to_global(local_center)


func _measure_world_tile_extent(fallback_px: int) -> float:
	if _tile_layer == null:
		return float(fallback_px)
	var origin: Vector2 = _tile_layer.to_global(_tile_layer.map_to_local(Vector2i.ZERO))
	var east: Vector2 = _tile_layer.to_global(_tile_layer.map_to_local(Vector2i(1, 0)))
	return maxf(origin.distance_to(east), 1.0)


func _update_visual_shape() -> void:
	if _fill_poly == null or _outline == null:
		return
	var half: float = _world_tile_extent * 0.5
	var points := PackedVector2Array([
		Vector2(-half, -half),
		Vector2(half, -half),
		Vector2(half, half),
		Vector2(-half, half),
	])
	_fill_poly.polygon = points
	_outline.points = points
	_outline.default_color = border_color
	_outline.width = border_width
	_fill_poly.color = fill_color
