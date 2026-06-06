## Consultas de área reutilizables (sin alloc por pulsación).
class_name AreaHitHelper
extends RefCounted

const ENEMY_MASK: int = 2
const MAX_HITS: int = 48

static var _circle_shape: CircleShape2D
static var _rect_shape: RectangleShape2D
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
	_ensure_circle_query()
	_circle_shape.radius = radius
	_query_params.transform = Transform2D(0.0, center)
	var hits: Array[Dictionary] = space.intersect_shape(_query_params, MAX_HITS)
	for hit: Dictionary in hits:
		var collider: Object = hit.get("collider")
		if collider is Node2D:
			callback.call(collider)


static func for_each_enemy_body_in_box(
	origin: Vector2,
	direction: Vector2,
	width: float,
	length: float,
	world: World2D,
	callback: Callable
) -> void:
	if world == null or callback == null or length <= 0.0 or width <= 0.0:
		return
	var space: PhysicsDirectSpaceState2D = world.direct_space_state
	if space == null:
		return
	_ensure_rect_query()
	var dir: Vector2 = direction.normalized() if direction.length_squared() > 0.001 else Vector2.RIGHT
	var center: Vector2 = origin + dir * (length * 0.5)
	_rect_shape.size = Vector2(length, width)
	_query_params.transform = Transform2D(dir.angle(), center)
	var hits: Array[Dictionary] = space.intersect_shape(_query_params, MAX_HITS)
	for hit: Dictionary in hits:
		var collider: Object = hit.get("collider")
		if collider is Node2D:
			callback.call(collider)


static func _ensure_query_resources() -> void:
	if _circle_shape != null:
		return
	_circle_shape = CircleShape2D.new()
	_rect_shape = RectangleShape2D.new()
	_query_params = PhysicsShapeQueryParameters2D.new()
	_query_params.collision_mask = ENEMY_MASK
	_query_params.collide_with_areas = false
	_query_params.collide_with_bodies = true


static func _ensure_circle_query() -> void:
	_ensure_query_resources()
	_query_params.shape = _circle_shape


static func _ensure_rect_query() -> void:
	_ensure_query_resources()
	_query_params.shape = _rect_shape
