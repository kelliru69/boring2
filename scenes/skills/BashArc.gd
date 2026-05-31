## Bash — arco de corte físico corto frente al jugador (apuntado con mouse).
class_name BashArc
extends Area2D

const _SkillDefs = preload("res://data/skill_definitions.gd")
const _AreaHitHelper = preload("res://scripts/combat/area_hit_helper.gd")

@export var arc_radius: float = 48.0
@export var arc_angle_deg: float = 70.0
@export var damage: int = 22
@export var stun_chance: float = 0.0
@export var stun_duration: float = 1.5
@export var active_time: float = 0.14

var _direction: Vector2 = Vector2.RIGHT
var _hit_ids: Dictionary = {}


func setup_from_player(
	origin: Vector2,
	direction: Vector2,
	bash_damage: int,
	radius: float,
	angle_deg: float,
	stun_roll: float = 0.0
) -> void:
	global_position = origin
	if direction.length_squared() < 0.001:
		direction = Vector2.RIGHT
	_direction = direction.normalized()
	damage = bash_damage
	arc_radius = radius
	arc_angle_deg = angle_deg
	stun_chance = stun_roll
	rotation = _direction.angle()
	queue_redraw()
	_apply_hits_deferred()


func _apply_hits_deferred() -> void:
	await get_tree().create_timer(active_time).timeout
	await get_tree().physics_frame
	_AreaHitHelper.for_each_enemy_body_in_circle(global_position, arc_radius + 8.0, get_world_2d(), _try_hit)
	queue_free()


func _try_hit(body: Node2D) -> void:
	if not body.is_in_group(_SkillDefs.GROUP_ENEMIES):
		return
	if not _is_in_arc(body.global_position):
		return
	var id: int = body.get_instance_id()
	if _hit_ids.has(id):
		return
	_hit_ids[id] = true
	if body.has_method("take_damage"):
		body.take_damage(damage)
	if stun_chance > 0.0 and randf() < stun_chance and body.has_method("apply_stun"):
		body.apply_stun(stun_duration)
	Audio.play_sfx("hit", randf_range(0.9, 1.05))


func _is_in_arc(world_pos: Vector2) -> bool:
	var local: Vector2 = to_local(world_pos)
	if local.length() > arc_radius + 12.0:
		return false
	var half_angle: float = deg_to_rad(arc_angle_deg * 0.5)
	var ang: float = local.angle()
	return absf(ang) <= half_angle


func _draw() -> void:
	var half: float = deg_to_rad(arc_angle_deg * 0.5)
	draw_arc(Vector2.ZERO, arc_radius, -half, half, 16, Color(0.9, 0.85, 0.7, 0.35), 3.0)
