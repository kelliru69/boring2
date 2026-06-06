## Estocada frontal estrecha: golpes múltiples según tamaño del enemigo.
class_name PierceThrust
extends Node2D

const _SkillDefs = preload("res://data/skill_definitions.gd")
const _AreaHitHelper = preload("res://scripts/combat/area_hit_helper.gd")
const _Vfx = preload("res://scripts/vfx/swordman_skill_vfx.gd")

const FILL: Color = Color(0.55, 0.78, 1.0, 0.7)
const EDGE: Color = Color(0.75, 0.92, 1.0, 1.0)
const CHEVRON: Color = Color(0.9, 0.97, 1.0, 1.0)
const VISUAL_DURATION: float = 0.22
const HIT_DELAY: float = 0.07

var _direction: Vector2 = Vector2.RIGHT
var _damage: int = 20
var _width: float = 22.0
var _length: float = 64.0
var _hit_ids: Dictionary = {}
var _flash_elapsed: float = 0.0
var _hits_applied: bool = false


func _ready() -> void:
	_Vfx.setup_canvas_item(self)
	set_process(true)


func setup_from_player(
	origin: Vector2,
	direction: Vector2,
	thrust_damage: int,
	width: float,
	length: float
) -> void:
	global_position = origin
	if direction.length_squared() < 0.001:
		direction = Vector2.RIGHT
	_direction = direction.normalized()
	_damage = thrust_damage
	_width = width
	_length = length
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
	var hit_count: int = 2
	if body.has_method("get_pierce_hit_count"):
		hit_count = int(body.call("get_pierce_hit_count"))
	hit_count = maxi(hit_count, 1)
	for _i: int in hit_count:
		if body.has_method("take_damage"):
			body.take_damage(_damage)
	Audio.play_sfx("hit", randf_range(0.92, 1.05))


func _draw() -> void:
	var alpha: float = _Vfx.flash_alpha(_flash_elapsed, VISUAL_DURATION)
	_Vfx.draw_slash_box(self, _length, _width * 0.5, FILL, EDGE, CHEVRON, alpha, 5)
