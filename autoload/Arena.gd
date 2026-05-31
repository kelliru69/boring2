## Límites jugables del mapa (autoload).
extends Node

signal bounds_ready(playable_rect: Rect2)
signal wave_announced(message: String)

var playable_rect: Rect2 = Rect2()
var world_rect: Rect2 = Rect2()
var _is_ready: bool = false


func setup(world: Rect2, border_pixels: float = 64.0) -> void:
	world_rect = world
	playable_rect = world.grow(-border_pixels)
	_is_ready = true
	bounds_ready.emit(playable_rect)


func setup_tilemap(world: Rect2, playable: Rect2) -> void:
	world_rect = world
	playable_rect = playable
	_is_ready = true
	bounds_ready.emit(playable_rect)


func is_ready() -> bool:
	return _is_ready


func clamp_to_playable(world_pos: Vector2, margin: float = 14.0) -> Vector2:
	if not _is_ready:
		return world_pos
	var inner: Rect2 = playable_rect.grow(-margin)
	return Vector2(
		clampf(world_pos.x, inner.position.x, inner.end.x),
		clampf(world_pos.y, inner.position.y, inner.end.y)
	)


func is_inside_playable(world_pos: Vector2, margin: float = 0.0) -> bool:
	if not _is_ready:
		return true
	return playable_rect.grow(-margin).has_point(world_pos)


func can_damage_enemy_at(world_pos: Vector2) -> bool:
	return is_inside_playable(world_pos, 0.0)


func get_center() -> Vector2:
	return playable_rect.get_center() if _is_ready else Vector2.ZERO


func announce_wave(message: String) -> void:
	if not message.is_empty():
		wave_announced.emit(message)


func random_point_outside_playable(outside_distance: float = 72.0) -> Vector2:
	if not _is_ready:
		return Vector2.ZERO
	var rect: Rect2 = playable_rect
	var side: int = randi() % 4
	match side:
		0:
			return Vector2(
				rect.position.x - outside_distance,
				randf_range(rect.position.y, rect.end.y)
			)
		1:
			return Vector2(
				rect.end.x + outside_distance,
				randf_range(rect.position.y, rect.end.y)
			)
		2:
			return Vector2(
				randf_range(rect.position.x, rect.end.x),
				rect.position.y - outside_distance
			)
		_:
			return Vector2(
				randf_range(rect.position.x, rect.end.x),
				rect.end.y + outside_distance
			)


func is_past_despawn_margin(world_pos: Vector2, margin: float = 96.0) -> bool:
	if not _is_ready:
		return false
	var outer: Rect2 = playable_rect.grow(margin)
	return not outer.has_point(world_pos)
