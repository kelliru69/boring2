## Magnum Break — explosión de fuego alrededor del jugador con knockback.
class_name MagnumBreak
extends Area2D

const _SkillDefs = preload("res://data/skill_definitions.gd")
const _AreaHitHelper = preload("res://scripts/combat/area_hit_helper.gd")
const _Vfx = preload("res://scripts/vfx/swordman_skill_vfx.gd")
const _SkillVisual = preload("res://scripts/skills/skill_visual_service.gd")
const _ProjectileBase = preload("res://scripts/skills/projectile_skill_base.gd")

const VISUAL_DURATION: float = 0.32

@export var radius: float = 90.0
@export var damage: int = 28
@export var knockback_force: float = 200.0

var _flash_elapsed: float = 0.0
var _hits_applied: bool = false


func _ready() -> void:
	_Vfx.setup_world_vfx(self)
	set_process(true)


func setup_at_center(world_pos: Vector2, explosion_radius: float, explosion_damage: int) -> void:
	global_position = world_pos
	radius = explosion_radius
	damage = explosion_damage
	_flash_elapsed = 0.0
	_hits_applied = false
	_SkillVisual.attach_swordman_slash(self, "magnum_break", "impact")
	queue_redraw()
	call_deferred("_apply_burst")


func _process(delta: float) -> void:
	_flash_elapsed += delta
	queue_redraw()
	if _flash_elapsed >= VISUAL_DURATION:
		queue_free()


func _apply_burst() -> void:
	await get_tree().create_timer(0.08).timeout
	if not is_inside_tree() or _hits_applied:
		return
	_hits_applied = true
	await get_tree().physics_frame
	_hit_enemies()
	Audio.play_sfx("fire_bolt", randf_range(0.8, 0.95))


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
	if has_meta(_ProjectileBase.META_USES_SHEET):
		return
	var alpha: float = _Vfx.flash_alpha(_flash_elapsed, VISUAL_DURATION)
	var ring_t: float = clampf(_flash_elapsed / VISUAL_DURATION, 0.0, 1.0)
	_Vfx.draw_fire_shockwave(self, radius, ring_t, alpha)
