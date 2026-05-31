## Fire Wall — barrera ígnea estática que dura unos segundos.
class_name FireWall
extends Area2D

const _SkillDefs = preload("res://data/skill_definitions.gd")
const _AreaHitHelper = preload("res://scripts/combat/area_hit_helper.gd")

@export var radius: float = 40.0
@export var damage: int = 16
@export var duration: float = 3.0
@export var knockback_force: float = 0.0
@export var pulse_interval: float = 0.45

var _elapsed: float = 0.0
var _pulse_accum: float = 0.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func setup_barrier(world_pos: Vector2, barrier_radius: float, barrier_damage: int, kb: float, life: float) -> void:
	global_position = world_pos
	radius = barrier_radius
	damage = barrier_damage
	knockback_force = kb
	duration = life
	if collision_shape and collision_shape.shape is CircleShape2D:
		(collision_shape.shape as CircleShape2D).radius = radius
	queue_redraw()


func _process(delta: float) -> void:
	_elapsed += delta
	_pulse_accum += delta
	if _elapsed >= duration:
		queue_free()
		return
	if _pulse_accum >= pulse_interval:
		_pulse_accum = 0.0
		_pulse_damage()


func _pulse_damage() -> void:
	var world: World2D = get_world_2d()
	_AreaHitHelper.for_each_enemy_body_in_circle(global_position, radius, world, _on_hit)


func _on_hit(body: Node2D) -> void:
	if not body.is_in_group(_SkillDefs.GROUP_ENEMIES):
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
	if knockback_force > 0.0 and body.has_method("apply_knockback"):
		var away: Vector2 = (body.global_position - global_position).normalized()
		if away.length_squared() < 0.001:
			away = Vector2.RIGHT
		body.apply_knockback(away * knockback_force)


func _draw() -> void:
	var alpha: float = 0.3 * (1.0 - _elapsed / maxf(duration, 0.01))
	draw_circle(Vector2.ZERO, radius, Color(1.0, 0.35, 0.05, alpha))
