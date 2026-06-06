## Cold Bolt — homing al enemigo con mayor HP máximo en rango; aplica Freeze.
class_name ColdBolt
extends Area2D

const _SkillDefs = preload("res://data/skill_definitions.gd")
const _Vfx = preload("res://scripts/vfx/elemental_vfx_spawner.gd")
const _HitFlash = preload("res://scripts/vfx/enemy_hit_flash.gd")
const _MageVfx = preload("res://scripts/vfx/mage_skill_vfx.gd")
const _SkillVisual = preload("res://scripts/skills/skill_visual_service.gd")
const _ProjectileBase = preload("res://scripts/skills/projectile_skill_base.gd")
const _ProjectileRegistry = preload("res://scripts/vfx/player_projectile_registry.gd")

@export var speed: float = 420.0
@export var damage: int = 18
@export var freeze_duration: float = 3.0
@export var freeze_slow_ratio: float = 0.5
@export var max_travel_distance: float = 1200.0
@export var lifetime_seconds: float = 4.0

var _target: Node2D = null
var _direction: Vector2 = Vector2.RIGHT
var _spawn_position: Vector2 = Vector2.ZERO
var _alive: bool = true
var _hit_enemy_ids: Dictionary = {}
var _vfx_time: float = 0.0
var _vfx_initialized: bool = false
var _skill_id: String = "cold_bolt"

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	if sprite:
		sprite.visible = false
	body_entered.connect(_on_body_entered)
	var life_timer: Timer = Timer.new()
	life_timer.one_shot = true
	life_timer.wait_time = lifetime_seconds
	add_child(life_timer)
	life_timer.timeout.connect(_destroy_from_lifetime)
	life_timer.start()
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
	_SkillVisual.apply_mage_projectile(self, sprite, _skill_id, &"ice")
	if _SkillVisual.use_legacy_particle_vfx():
		_Vfx.attach_projectile_trail(self, _Vfx.TRAIL_PRESET_ICE)
	_ProjectileRegistry.track(self)


func force_despawn() -> void:
	_destroy(false)


func _destroy_from_lifetime() -> void:
	_destroy(false)


func setup_target(target: Node2D, bolt_damage: int = -1) -> void:
	_target = target
	if bolt_damage > 0:
		damage = bolt_damage
	_update_direction()


## Ralentización (Cold Bolt): ratio 0.2–0.5 según nivel, sin stun completo.
func set_slow_ratio(ratio: float) -> void:
	freeze_slow_ratio = clampf(ratio, 0.05, 0.95)
	freeze_duration = 1.4


func _physics_process(delta: float) -> void:
	if not _alive:
		return
	_vfx_time += delta
	var sheet: AnimatedSprite2D = _ProjectileBase.get_sheet_visual(self)
	if sheet == null and sprite and sprite.visible:
		_MageVfx.pulse_projectile_modulate(sprite, &"ice", _vfx_time)
	if _target != null and is_instance_valid(_target):
		_direction = (_target.global_position - global_position).normalized()
	global_position += _direction * speed * delta
	rotation = _direction.angle()
	if global_position.distance_squared_to(_spawn_position) >= max_travel_distance * max_travel_distance:
		_destroy(false)
	elif Arena.is_ready() and not Arena.is_inside_playable(global_position, 0.0):
		_destroy(false)


func _update_direction() -> void:
	if _target != null and is_instance_valid(_target):
		_direction = (_target.global_position - global_position).normalized()


func _on_body_entered(body: Node2D) -> void:
	if not _alive or not body.is_in_group(_SkillDefs.GROUP_ENEMIES):
		return
	var enemy_id: int = body.get_instance_id()
	if _hit_enemy_ids.has(enemy_id):
		return
	if body.has_method("take_damage"):
		body.take_damage(damage, _HitFlash.ELEMENT_ICE)
	if body.has_method("apply_freeze"):
		body.apply_freeze(freeze_duration, freeze_slow_ratio)
	_hit_enemy_ids[enemy_id] = true
	Audio.play_sfx_varied("cold_impact")
	if _can_spell_pierce():
		return
	_stop_trail_vfx()
	_destroy(true)


func _stop_trail_vfx() -> void:
	for child: Node in get_children():
		if child is VfxParticles:
			(child as VfxParticles).stop_emission_and_fade(0.1)
		elif child is GPUParticles2D:
			var particles: GPUParticles2D = child as GPUParticles2D
			particles.emitting = false
			particles.modulate.a = 0.0


func _destroy(spawn_impact_vfx: bool = false) -> void:
	if not _alive:
		return
	_alive = false
	set_physics_process(false)
	_stop_trail_vfx()
	if spawn_impact_vfx and _SkillVisual.use_legacy_particle_vfx():
		var parent: Node = get_parent()
		if parent:
			_MageVfx.spawn_ice_impact(parent, global_position)
	queue_free()


func _can_spell_pierce() -> bool:
	var chance: float = Global.get_spell_pierce_chance()
	return chance > 0.0 and randf() < chance
