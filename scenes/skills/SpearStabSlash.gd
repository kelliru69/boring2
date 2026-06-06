## Tajo horizontal frontal: alto daño y knockback en línea.
class_name SpearStabSlash
extends Node2D

const _SkillDefs = preload("res://data/skill_definitions.gd")
const _AreaHitHelper = preload("res://scripts/combat/area_hit_helper.gd")
const _Vfx = preload("res://scripts/vfx/swordman_skill_vfx.gd")

const FILL: Color = Color(1.0, 0.88, 0.35, 0.75)
const EDGE: Color = Color(1.0, 0.95, 0.5, 1.0)
const CHEVRON: Color = Color(1.0, 1.0, 0.75, 1.0)
const VISUAL_DURATION: float = 0.24
const HIT_DELAY: float = 0.08

var _direction: Vector2 = Vector2.RIGHT
var _damage: int = 30
var _width: float = 56.0
var _length: float = 88.0
var _knockback: float = 220.0
var _hit_ids: Dictionary = {}
var _flash_elapsed: float = 0.0
var _hits_applied: bool = false
var _slash_scale: float = 0.6


func _ready() -> void:
	_Vfx.setup_world_vfx(self)
	set_process(true)


func setup_from_player(
	origin: Vector2,
	direction: Vector2,
	slash_damage: int,
	width: float,
	length: float,
	knockback_force: float
) -> void:
	global_position = origin
	if direction.length_squared() < 0.001:
		direction = Vector2.RIGHT
	_direction = direction.normalized()
	_damage = slash_damage
	_width = width
	_length = length
	_knockback = knockback_force
	rotation = _direction.angle()
	_flash_elapsed = 0.0
	_hits_applied = false
	_slash_scale = 0.6
	queue_redraw()
	call_deferred("_apply_hits")


func _process(delta: float) -> void:
	_flash_elapsed += delta
	_slash_scale = lerpf(_slash_scale, 1.12, clampf(delta * 16.0, 0.0, 1.0))
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
	Audio.play_sfx("hit", randf_range(0.95, 1.08))


func _draw() -> void:
	var alpha: float = _Vfx.flash_alpha(_flash_elapsed, VISUAL_DURATION)
	_Vfx.draw_slash_box(self, _length, _width * 0.5, FILL, EDGE, CHEVRON, alpha, 4, _slash_scale)
