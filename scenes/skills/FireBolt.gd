## Fire Bolt — proyectil en línea recta (dirección fija, no homing).
class_name FireBolt
extends Area2D

const _SkillDefs = preload("res://data/skill_definitions.gd")
const _Vfx = preload("res://scripts/vfx/elemental_vfx_spawner.gd")
const _HitFlash = preload("res://scripts/vfx/enemy_hit_flash.gd")
const _MageVfx = preload("res://scripts/vfx/mage_skill_vfx.gd")
const _SkillVisual = preload("res://scripts/skills/skill_visual_service.gd")
const _ProjectileBase = preload("res://scripts/skills/projectile_skill_base.gd")
const _ProjectileRegistry = preload("res://scripts/vfx/player_projectile_registry.gd")

@export var speed: float = 520.0
@export var damage: int = 25
@export var max_travel_distance: float = 1400.0
@export var lifetime_seconds: float = 3.5

var _direction: Vector2 = Vector2.RIGHT
var _spawn_position: Vector2 = Vector2.ZERO
var _alive: bool = true
var _hit_enemy_ids: Dictionary = {}
var _trail_preset: StringName = _Vfx.TRAIL_PRESET_FIRE
var _skill_id: String = "fire_bolt"
var _hit_element: StringName = _HitFlash.ELEMENT_FIRE
var _vfx_element: StringName = &"fire"
var _vfx_time: float = 0.0
var _vfx_initialized: bool = false

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
	_SkillVisual.apply_mage_projectile(self, sprite, _skill_id, _vfx_element)
	if _SkillVisual.use_legacy_particle_vfx():
		_Vfx.attach_projectile_trail(self, _trail_preset)
	var sheet: AnimatedSprite2D = _ProjectileBase.get_sheet_visual(self)
	if sheet != null:
		_tween_projectile_scale()
	elif sprite and sprite.visible:
		_tween_projectile_scale()
	_ProjectileRegistry.track(self)


func force_despawn() -> void:
	_destroy(false)


func _destroy_from_lifetime() -> void:
	_destroy(false)


## Dispara en [direction] normalizada desde la posición actual.
func setup_direction(direction: Vector2, bolt_damage: int = -1) -> void:
	if direction.length_squared() < 0.001:
		direction = Vector2.RIGHT
	_direction = direction.normalized()
	if bolt_damage > 0:
		damage = bolt_damage
	rotation = _direction.angle()
	Audio.play_sfx_varied("fire_bolt_launch")


func set_trail_preset(preset: StringName) -> void:
	_trail_preset = preset
	if preset == _Vfx.TRAIL_PRESET_SOUL:
		_hit_element = _HitFlash.ELEMENT_SOUL
		_vfx_element = &"soul"
		_skill_id = "soul_strike"
	else:
		_hit_element = _HitFlash.ELEMENT_FIRE
		_vfx_element = &"fire"
		_skill_id = "fire_bolt"
	if _vfx_initialized and sprite:
		_SkillVisual.apply_mage_projectile(self, sprite, _skill_id, _vfx_element)


func set_skill_id(skill_id: String) -> void:
	_skill_id = skill_id


func _stop_trail_vfx() -> void:
	for child: Node in get_children():
		if child is VfxParticles:
			(child as VfxParticles).stop_emission_and_fade(0.1)
		elif child is GPUParticles2D:
			var particles: GPUParticles2D = child as GPUParticles2D
			particles.emitting = false
			particles.modulate.a = 0.0


func _physics_process(delta: float) -> void:
	if not _alive:
		return
	_vfx_time += delta
	_ProjectileBase.tick_hold_spin(self, delta)
	var sheet: AnimatedSprite2D = _ProjectileBase.get_sheet_visual(self)
	if sheet == null and sprite and sprite.visible:
		_MageVfx.pulse_projectile_modulate(sprite, _vfx_element, _vfx_time)
	global_position += _direction * speed * delta
	if global_position.distance_squared_to(_spawn_position) >= max_travel_distance * max_travel_distance:
		_destroy(false)
	elif Arena.is_ready() and not Arena.is_inside_playable(global_position, 0.0):
		_destroy(false)


func _on_body_entered(body: Node2D) -> void:
	_try_hit_enemy(body)


func _try_hit_enemy(body: Node2D) -> void:
	if not _alive or not body.is_in_group(_SkillDefs.GROUP_ENEMIES):
		return
	var enemy_id: int = body.get_instance_id()
	if _hit_enemy_ids.has(enemy_id):
		return
	if not body.has_method("take_damage"):
		return
	_hit_enemy_ids[enemy_id] = true
	body.take_damage(damage, _hit_element)
	Audio.play_sfx_varied("hit")
	if _can_spell_pierce():
		return
	_stop_trail_vfx()
	_destroy(true)


func _can_spell_pierce() -> bool:
	var chance: float = Global.get_spell_pierce_chance()
	return chance > 0.0 and randf() < chance


func _tween_projectile_scale() -> void:
	var visual: Node2D = _ProjectileBase.get_sheet_visual(self)
	if visual == null:
		visual = sprite
	if visual == null:
		return
	var base: Vector2 = visual.scale
	visual.scale = base * 0.65
	var tw: Tween = create_tween()
	tw.set_trans(Tween.TRANS_BACK)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(visual, "scale", base, 0.14)


func _spawn_destroy_vfx() -> void:
	if not _SkillVisual.use_legacy_particle_vfx():
		return
	var parent: Node = get_parent()
	if parent == null:
		return
	if _vfx_element == &"soul":
		_MageVfx.spawn_soul_impact(parent, global_position)
	else:
		_MageVfx.spawn_fire_impact(parent, global_position)


func _destroy(spawn_impact_vfx: bool = false) -> void:
	if not _alive:
		return
	_alive = false
	set_physics_process(false)
	_stop_trail_vfx()
	if _skill_id == "soul_strike":
		_ProjectileBase.hold_sheet_frame(self, 6)
	if spawn_impact_vfx:
		_spawn_destroy_vfx()
	queue_free()
