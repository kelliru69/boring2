## Magnum Break — explosión de fuego alrededor del jugador con knockback.
class_name MagnumBreak
extends Area2D

const _SkillDefs = preload("res://data/skill_definitions.gd")
const _AreaHitHelper = preload("res://scripts/combat/area_hit_helper.gd")

@export var radius: float = 90.0
@export var damage: int = 28
@export var knockback_force: float = 200.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func setup_at_center(world_pos: Vector2, explosion_radius: float, explosion_damage: int) -> void:
	global_position = world_pos
	radius = explosion_radius
	damage = explosion_damage
	if collision_shape and collision_shape.shape is CircleShape2D:
		(collision_shape.shape as CircleShape2D).radius = radius
	queue_redraw()
	call_deferred("_apply_burst")


func _apply_burst() -> void:
	await get_tree().physics_frame
	_hit_enemies()
	Audio.play_sfx("fire_bolt", randf_range(0.8, 0.95))
	await get_tree().create_timer(0.2).timeout
	queue_free()


func _hit_enemies() -> void:
	var world: World2D = get_world_2d()
	_AreaHitHelper.for_each_enemy_body_in_circle(global_position, radius, world, _on_enemy_hit)


func _on_enemy_hit(body: Node2D) -> void:
	if not body.is_in_group(_SkillDefs.GROUP_ENEMIES):
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
	var away: Vector2 = (body.global_position - global_position).normalized()
	if away.length_squared() < 0.001:
		away = Vector2.RIGHT
	if body.has_method("apply_knockback"):
		body.apply_knockback(away * knockback_force)


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(1.0, 0.45, 0.1, 0.35))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(1.0, 0.7, 0.2, 0.5), 2.0)
