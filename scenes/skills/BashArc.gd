## Bash — arco de corte físico frente al jugador (apuntado con mouse).
class_name BashArc
extends Area2D

const _SkillDefs = preload("res://data/skill_definitions.gd")
const _AreaHitHelper = preload("res://scripts/combat/area_hit_helper.gd")
const _Vfx = preload("res://scripts/vfx/swordman_skill_vfx.gd")
const _SkillVisual = preload("res://scripts/skills/skill_visual_service.gd")
const _ProjectileBase = preload("res://scripts/skills/projectile_skill_base.gd")

const FILL: Color = Color(0.92, 0.88, 0.55, 0.72)
const EDGE: Color = Color(1.0, 0.95, 0.65, 1.0)
const VISUAL_DURATION: float = 0.28
const HIT_DELAY: float = 0.11

@export var arc_radius: float = 48.0
@export var arc_angle_deg: float = 70.0
@export var damage: int = 22
@export var stun_chance: float = 0.0
@export var stun_duration: float = 1.0

var _direction: Vector2 = Vector2.RIGHT
var _hit_ids: Dictionary = {}
var _bash_source: Node2D = null
var _flash_elapsed: float = 0.0
var _hits_applied: bool = false
var _slash_scale: float = 0.55


func _ready() -> void:
	_Vfx.setup_world_vfx(self)
	set_process(true)


func setup_from_player(
	origin: Vector2,
	direction: Vector2,
	bash_damage: int,
	radius: float,
	angle_deg: float,
	stun_roll: float = 0.0,
	stun_sec: float = 1.0,
	source: Node2D = null
) -> void:
	global_position = origin
	_bash_source = source
	if direction.length_squared() < 0.001:
		direction = Vector2.RIGHT
	_direction = direction.normalized()
	damage = bash_damage
	arc_radius = radius
	arc_angle_deg = angle_deg
	stun_chance = stun_roll
	stun_duration = stun_sec
	rotation = _direction.angle()
	_flash_elapsed = 0.0
	_hits_applied = false
	_slash_scale = 0.55
	_SkillVisual.attach_swordman_slash(self, "bash")
	queue_redraw()
	call_deferred("_apply_hits_deferred")


func _process(delta: float) -> void:
	_flash_elapsed += delta
	_slash_scale = lerpf(_slash_scale, 1.18, clampf(delta * 14.0, 0.0, 1.0))
	queue_redraw()
	if _flash_elapsed >= VISUAL_DURATION:
		queue_free()


func _apply_hits_deferred() -> void:
	await get_tree().create_timer(HIT_DELAY).timeout
	if not is_inside_tree() or _hits_applied:
		return
	_hits_applied = true
	await get_tree().physics_frame
	_AreaHitHelper.for_each_enemy_body_in_circle(global_position, arc_radius + 10.0, get_world_2d(), _try_hit)


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
	if _bash_source != null and _bash_source.has_method("try_fatal_blow_heal"):
		_bash_source.try_fatal_blow_heal(damage)
	if stun_chance > 0.0 and randf() < stun_chance and body.has_method("apply_stun"):
		body.apply_stun(stun_duration)
	Audio.play_sfx("hit", randf_range(0.9, 1.05))


func _is_in_arc(world_pos: Vector2) -> bool:
	var local: Vector2 = to_local(world_pos)
	if local.length() > arc_radius + 14.0:
		return false
	var half_angle: float = deg_to_rad(arc_angle_deg * 0.5)
	return absf(local.angle()) <= half_angle


func _draw() -> void:
	if has_meta(_ProjectileBase.META_USES_SHEET):
		return
	var alpha: float = _Vfx.flash_alpha(_flash_elapsed, VISUAL_DURATION)
	var half: float = deg_to_rad(arc_angle_deg * 0.5)
	_Vfx.draw_bash_arc(self, arc_radius, half, FILL, EDGE, alpha, _slash_scale)
