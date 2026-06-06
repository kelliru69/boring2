## Utilidades para evitar que CharacterBody2D queden pegados en top-down.
class_name BodySeparation
extends RefCounted

const DEFAULT_STANDOFF_EXTRA: float = 2.0


static func standoff_distance(radius_a: float, radius_b: float, extra: float = DEFAULT_STANDOFF_EXTRA) -> float:
	return radius_a + radius_b + extra


## Quita la componente de velocidad que acerca el cuerpo al ancla si ya está en rango de contacto.
static func clip_chase_velocity(
	from_pos: Vector2,
	anchor_pos: Vector2,
	speed: float,
	radius_from: float,
	radius_anchor: float,
	knockback: Vector2 = Vector2.ZERO,
	extra: float = DEFAULT_STANDOFF_EXTRA,
) -> Vector2:
	var to_anchor: Vector2 = anchor_pos - from_pos
	var dist: float = to_anchor.length()
	if dist <= 0.001:
		return knockback
	var dir: Vector2 = to_anchor / dist
	var desired: Vector2 = dir * speed
	var min_dist: float = standoff_distance(radius_from, radius_anchor, extra)
	if dist < min_dist:
		var inward_speed: float = maxf(desired.dot(dir), 0.0)
		desired -= dir * inward_speed
	return desired + knockback


static func resolve_position(
	body_pos: Vector2,
	anchor_pos: Vector2,
	body_radius: float,
	anchor_radius: float,
	extra: float = DEFAULT_STANDOFF_EXTRA,
) -> Vector2:
	var away: Vector2 = body_pos - anchor_pos
	var dist: float = away.length()
	var min_dist: float = standoff_distance(body_radius, anchor_radius, extra)
	if dist >= min_dist:
		return body_pos
	if dist > 0.001:
		return anchor_pos + (away / dist) * min_dist
	return anchor_pos + Vector2(min_dist, 0.0)
