## Lightning Bolt — boomerang eléctrico con rayo Line2D dinámico + chispas al impactar.
extends Area2D
class_name LightningBolt

const _SkillDefs = preload("res://data/skill_definitions.gd")
const _Vfx = preload("res://scripts/vfx/elemental_vfx_spawner.gd")
const _HitFlash = preload("res://scripts/vfx/enemy_hit_flash.gd")
const _MageVfx = preload("res://scripts/vfx/mage_skill_vfx.gd")
const _SkillVisual = preload("res://scripts/skills/skill_visual_service.gd")
const _ProjectileBase = preload("res://scripts/skills/projectile_skill_base.gd")
const _ProjectileRegistry = preload("res://scripts/vfx/player_projectile_registry.gd")

@export var speed: float = 480.0
@export var damage: int = 20
@export var max_travel_distance: float = 200.0
@export var beam_tail_length: float = 56.0
@export var beam_head_length: float = 22.0
@export var knockback_on_hit: float = 0.0

var _direction: Vector2 = Vector2.RIGHT
var _spawn_position: Vector2 = Vector2.ZERO
var _traveled: float = 0.0
var _returning: bool = false
var _alive: bool = true
var _hit_ids: Dictionary = {}
var _vfx_time: float = 0.0
var _beam: LightningBoltBeam
var _vfx_initialized: bool = false

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	if sprite:
		sprite.visible = false
	body_entered.connect(_on_body_entered)
	call_deferred("_ensure_vfx_initialized")


func on_spawned_at_world(world_pos: Vector2) -> void:
	global_position = world_pos
	_spawn_position = world_pos
	_init_projectile_vfx()


func _ensure_vfx_initialized() -> void:
	if not _vfx_initialized:
		_init_projectile_vfx()


func _init_projectile_vfx() -> void:
	if _vfx_initialized or not _alive or not is_inside_tree():
		return
	_vfx_initialized = true
	_spawn_position = global_position
	if _beam == null:
		_beam = LightningBoltBeam.new()
		add_child(_beam)
	_SkillVisual.apply_mage_projectile(self, sprite, "lightning_bolt", &"lightning")
	_update_beam_visibility()
	if _SkillVisual.use_legacy_particle_vfx():
		_Vfx.attach_projectile_trail(self, _Vfx.TRAIL_PRESET_LIGHTNING)
	_ProjectileRegistry.track(self)


func _update_beam_visibility() -> void:
	if _beam:
		_beam.visible = not _ProjectileBase.uses_skill_sheet(self)


func force_despawn() -> void:
	_destroy()


func setup_boomerang(direction: Vector2, bolt_damage: int, travel_distance: float) -> void:
	if direction.length_squared() < 0.001:
		direction = Vector2.RIGHT
	_direction = direction.normalized()
	damage = bolt_damage
	max_travel_distance = travel_distance


func _physics_process(delta: float) -> void:
	if not _alive:
		return
	_vfx_time += delta
	var step: float = speed * delta
	global_position += _direction * step
	_traveled += step
	rotation = _direction.angle()
	_update_beam_visual()
	if Arena.is_ready() and not Arena.is_inside_playable(global_position, 0.0):
		_destroy()
		return
	if not _returning and _traveled >= max_travel_distance:
		_returning = true
		_direction = -_direction
		_traveled = 0.0
	elif _returning and _traveled >= max_travel_distance:
		_destroy()


func _update_beam_visual() -> void:
	if _beam == null or not _beam.visible:
		return
	var tail: Vector2 = global_position - _direction * beam_tail_length
	var head: Vector2 = global_position + _direction * beam_head_length
	_beam.update_beam(tail, head, _vfx_time)


func _on_body_entered(body: Node2D) -> void:
	if not _alive or not body.is_in_group(_SkillDefs.GROUP_ENEMIES):
		return
	var id: int = body.get_instance_id()
	if _hit_ids.has(id):
		return
	if body.has_method("take_damage"):
		body.take_damage(damage, _HitFlash.ELEMENT_LIGHTNING)
		_hit_ids[id] = true
		if knockback_on_hit > 0.0 and body.has_method("apply_knockback"):
			body.apply_knockback(_direction * knockback_on_hit)
		Audio.play_sfx_varied("hit")
		var parent: Node = get_parent()
		if parent:
			if _SkillVisual.use_legacy_particle_vfx():
				_MageVfx.spawn_lightning_impact(parent, body.global_position, max_travel_distance)
			else:
				_SkillVisual.spawn_mage_impact(
					parent, body.global_position, "lightning_bolt", "impact", maxf(max_travel_distance * 0.35, 14.0)
				)


func _destroy() -> void:
	if not _alive:
		return
	_alive = false
	set_physics_process(false)
	_stop_trail_vfx()
	queue_free()


func _stop_trail_vfx() -> void:
	for child: Node in get_children():
		if child is VfxParticles:
			(child as VfxParticles).stop_emission_and_fade(0.1)
		elif child is GPUParticles2D:
			var particles: GPUParticles2D = child as GPUParticles2D
			particles.emitting = false
			particles.modulate.a = 0.0
