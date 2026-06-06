## Golpe rectangular frontal: lanza enemigos y activa daño en cadena al chocar.
class_name BowlingBashRect
extends Node2D

const _SkillDefs = preload("res://data/skill_definitions.gd")
const _AreaHitHelper = preload("res://scripts/combat/area_hit_helper.gd")
const _Vfx = preload("res://scripts/vfx/swordman_skill_vfx.gd")

const FILL: Color = Color(1.0, 0.45, 0.28, 0.78)
const EDGE: Color = Color(1.0, 0.62, 0.38, 1.0)
const CHEVRON: Color = Color(1.0, 0.85, 0.55, 1.0)
const VISUAL_DURATION: float = 0.3
const HIT_DELAY: float = 0.1

var _direction: Vector2 = Vector2.RIGHT
var _damage: int = 36
var _width: float = 72.0
var _length: float = 96.0
var _knockback: float = 260.0
var _hit_ids: Dictionary = {}
var _flash_elapsed: float = 0.0
var _hits_applied: bool = false


func _ready() -> void:
	_Vfx.setup_world_vfx(self)
	set_process(true)


func setup_from_player(
	origin: Vector2,
	direction: Vector2,
	bash_damage: int,
	width: float,
	length: float,
	knockback_force: float
) -> void:
	global_position = origin
	if direction.length_squared() < 0.001:
		direction = Vector2.RIGHT
	_direction = direction.normalized()
	_damage = bash_damage
	_width = width
	_length = length
	_knockback = knockback_force
	rotation = _direction.angle()
	_flash_elapsed = 0.0
	_hits_applied = false
	queue_redraw()
	call_deferred("_apply_hits")


func _process(delta: float) -> void:
	_flash_elapsed += delta
	queue_redraw()
	if _flash_elapsed >= VISUAL_DURATION:
		queue_free()


func _apply_hits() -> void:
	await get_tree().create_timer(HIT_DELAY).timeout
	if not is_inside_tree() or _hits_applied:
		return
	_hits_applied = true
	await get_tree().physics_frame
	_AreaHitHelper.for_each_enemy_body_in_box(
		global_position, _direction, _width, _length, get_world_2d(), _try_hit
	)


func _try_hit(body: Node2D) -> void:
	if not body.is_in_group(_SkillDefs.GROUP_ENEMIES):
		return
	var id: int = body.get_instance_id()
	if _hit_ids.has(id):
		return
	_hit_ids[id] = true
	if body.has_method("take_damage"):
		body.take_damage(_damage)
	if body.has_method("apply_knockback"):
		body.apply_knockback(_direction * _knockback)
	if body.has_method("mark_bowling_chain"):
		body.call("mark_bowling_chain", _damage)
	Audio.play_sfx("hit", randf_range(0.88, 1.02))


func _draw() -> void:
	var alpha: float = _Vfx.flash_alpha(_flash_elapsed, VISUAL_DURATION)
	_Vfx.draw_slash_box(self, _length, _width * 0.5, FILL, EDGE, CHEVRON, alpha, 3)
	var center: Vector2 = Vector2(_length * 0.42, 0.0)
	draw_set_transform(center, 0.0, Vector2.ONE)
	_Vfx.draw_magnum_burst(
		self,
		_width * 0.5,
		Color(1.0, 0.7, 0.4, 1.0),
		Color(1.0, 0.5, 0.25, 1.0),
		Color(1.0, 0.9, 0.6, 1.0),
		alpha * 0.85,
		_flash_elapsed / VISUAL_DURATION
	)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_impact_cross(center, _width * 0.32, EDGE, alpha)


func _draw_impact_cross(pos: Vector2, size: float, color: Color, alpha: float) -> void:
	var c: Color = color
	c.a *= alpha
	draw_line(pos + Vector2(-size, 0.0), pos + Vector2(size, 0.0), c, 5.0, true)
	draw_line(pos + Vector2(0.0, -size * 0.45), pos + Vector2(0.0, size * 0.45), c, 5.0, true)
