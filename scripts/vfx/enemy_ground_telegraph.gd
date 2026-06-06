## Círculo de amenaza en el suelo — z_index por fila de tile (siempre bajo el jugador en la misma fila).
extends Node2D
class_name EnemyGroundTelegraph

const _ThreatVfx = preload("res://scripts/vfx/enemy_threat_vfx.gd")
const _TileDepthSort = preload("res://scripts/visual/tile_depth_sort.gd")

var _radius: float = 32.0
var _elapsed: float = 0.0
var _duration: float = -1.0
var _visible_telegraph: bool = false


func _ready() -> void:
	z_as_relative = false


func update_telegraph(world_pos: Vector2, radius: float, elapsed: float, duration: float = -1.0) -> void:
	global_position = world_pos
	_radius = maxf(radius, 4.0)
	_elapsed = elapsed
	_duration = duration
	_visible_telegraph = true
	visible = true
	z_index = _TileDepthSort.compute_ground_telegraph_z_index(world_pos.y)
	queue_redraw()


func hide_telegraph() -> void:
	if not _visible_telegraph:
		return
	_visible_telegraph = false
	visible = false
	queue_redraw()


func _draw() -> void:
	if not _visible_telegraph:
		return
	_ThreatVfx.draw_ground_telegraph(self, Vector2.ZERO, _radius, _elapsed, _duration)
