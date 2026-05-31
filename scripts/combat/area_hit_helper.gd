## Consultas de área reutilizables (sin alloc por pulsación).
class_name AreaHitHelper
extends RefCounted

const ENEMY_MASK: int = 2
const MAX_HITS: int = 48

static var _circle_shape: CircleShape2D
static var _query_params: PhysicsShapeQueryParameters2D


static func for_each_enemy_body_in_circle(
	center: Vector2,
	radius: float,
	world: World2D,
	callback: Callable
) -> void:
	if world == null or callback == null:
		return
	var space: PhysicsDirectSpaceState2D = world.direct_space_state
	if space == null:
		return
	_ensure_query_resources()
	_circle_shape.radius = radius
	_query_params.transform = Transform2D(0.0, center)
	var hits: Array[Dictionary] = space.intersect_shape(_query_params, MAX_HITS)
	for hit: Dictionary in hits:
		var collider: Object = hit.get("collider")
		if collider is Node2D:
			callback.call(collider)


static func _ensure_query_resources() -> void:
	if _circle_shape != null:
		return
	_circle_shape = CircleShape2D.new()
	_query_params = PhysicsShapeQueryParameters2D.new()
	_query_params.shape = _circle_shape
	_query_params.collision_mask = ENEMY_MASK
	_query_params.collide_with_areas = false
	_query_params.collide_with_bodies = true
