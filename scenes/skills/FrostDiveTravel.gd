## FrostDiveTravel — proyectil de hielo: haz cristalino + explosión de escarcha.
extends Node2D
class_name FrostDiveTravel

const _SkillDefs = preload("res://data/skill_definitions.gd")
const _AreaHitHelper = preload("res://scripts/combat/area_hit_helper.gd")
const _Vfx = preload("res://scripts/vfx/elemental_vfx_spawner.gd")
const _HitFlash = preload("res://scripts/vfx/enemy_hit_flash.gd")
const _MageVfx = preload("res://scripts/vfx/mage_skill_vfx.gd")
const _SkillVisual = preload("res://scripts/skills/skill_visual_service.gd")
const _ProjectileBase = preload("res://scripts/skills/projectile_skill_base.gd")

@export var travel_speed: float = 700.0
@export var line_hit_radius: float = 22.0
@export var line_tick_interval: float = 0.06
@export var hit_cooldown_sec: float = 0.16

var _target: Vector2 = Vector2.ZERO
var _damage: int = 0
var _radius: float = 48.0
var _stun_sec: float = 1.0
var _spawn_pos: Vector2 = Vector2.ZERO

var _tick_accum: float = 0.0
var _prev_pos: Vector2 = Vector2.ZERO
var _hit_cooldowns: Dictionary = {}
var _vfx_time: float = 0.0
var _beam: FrostDiverBeam
var _trail: VfxParticles
var _head_sprite: Sprite2D
var _vfx_initialized: bool = false


func _ready() -> void:
	z_index = 11
	set_physics_process(false)


func on_spawned_at_world(world_pos: Vector2) -> void:
	global_position = world_pos
	_spawn_pos = world_pos
	_prev_pos = world_pos


func setup(start_pos: Vector2, target_pos: Vector2, damage: int, radius: float, stun_sec: float) -> void:
	global_position = start_pos
	_spawn_pos = start_pos
	_prev_pos = start_pos
	_target = target_pos
	_damage = maxi(damage, 0)
	_radius = maxf(radius, 1.0)
	_stun_sec = maxf(stun_sec, 0.0)
	_init_travel_visual()
	if _beam == null and not _ProjectileBase.uses_skill_sheet(self):
		_beam = FrostDiverBeam.new()
		add_child(_beam)
	if _SkillVisual.use_legacy_particle_vfx():
		_trail = _Vfx.attach_projectile_trail(self, _Vfx.TRAIL_PRESET_ICE)
	set_physics_process(true)
	Audio.play_sfx_varied("frost_diver_cast")


func _init_travel_visual() -> void:
	if _vfx_initialized:
		return
	_vfx_initialized = true
	if _head_sprite == null:
		_head_sprite = Sprite2D.new()
		_head_sprite.visible = false
		add_child(_head_sprite)
	_SkillVisual.apply_mage_projectile(self, _head_sprite, "frost_diver", &"ice")
	_update_beam_visibility()


func _update_beam_visibility() -> void:
	if _beam:
		_beam.visible = not _ProjectileBase.uses_skill_sheet(self)


func _physics_process(delta: float) -> void:
	_vfx_time += delta
	queue_redraw()
	_tick_accum += delta
	_decay_hit_cooldowns(delta)
	var uses_sheet: bool = _ProjectileBase.uses_skill_sheet(self)
	if _beam and uses_sheet:
		_beam.visible = false
	elif _beam:
		_beam.update_beam(_prev_pos, global_position, _vfx_time)
	var to_target: Vector2 = _target - global_position
	var sheet: AnimatedSprite2D = _ProjectileBase.get_sheet_visual(self)
	if sheet and to_target.length_squared() > 0.001:
		sheet.rotation = to_target.angle()

	var dist: float = to_target.length()
	if dist <= maxf(travel_speed * delta, 1.0):
		_apply_line_damage_segment(_prev_pos, _target)
		global_position = _target
		_explode()
		queue_free()
		return

	var step: Vector2 = to_target / dist * travel_speed * delta
	var next_pos: Vector2 = global_position + step
	if _tick_accum >= line_tick_interval:
		_tick_accum = 0.0
		_apply_line_damage_segment(_prev_pos, next_pos)
	_prev_pos = next_pos
	global_position = next_pos


func _draw() -> void:
	if _ProjectileBase.uses_skill_sheet(self):
		return
	_MageVfx.draw_frost_diver_head(self, line_hit_radius * 1.1, _vfx_time)


func _explode() -> void:
	var world: World2D = get_world_2d()
	if world == null:
		return
	Audio.play_sfx_varied("frost_diver_impact")
	_Vfx.spawn_heavy_magic_shake(3.5, 0.14)
	var parent: Node = get_parent()
	if parent:
		if _SkillVisual.use_legacy_particle_vfx():
			_MageVfx.spawn_frost_diver_impact(parent, global_position, _radius)
		else:
			_SkillVisual.spawn_mage_impact(parent, global_position, "frost_diver", "impact", _radius)
	_AreaHitHelper.for_each_enemy_body_in_circle(global_position, _radius, world, _on_explosion_hit)


func _on_explosion_hit(body: Node2D) -> void:
	if body == null or not body.is_in_group(_SkillDefs.GROUP_ENEMIES):
		return
	if body.has_method("take_damage"):
		body.take_damage(_damage, _HitFlash.ELEMENT_ICE)
	if _stun_sec > 0.0 and body.has_method("apply_freeze"):
		body.apply_freeze(_stun_sec, 0.0)


func _apply_line_damage_segment(a: Vector2, b: Vector2) -> void:
	if _damage <= 0:
		return
	var world: World2D = get_world_2d()
	if world == null:
		return
	var seg: Vector2 = b - a
	var seg_len: float = seg.length()
	if seg_len <= 0.001:
		_AreaHitHelper.for_each_enemy_body_in_circle(b, line_hit_radius, world, _on_line_hit)
		return
	var steps: int = clampi(int(ceil(seg_len / maxf(line_hit_radius * 0.9, 8.0))), 1, 8)
	for i: int in steps + 1:
		var t: float = float(i) / float(steps)
		var p: Vector2 = a + seg * t
		_AreaHitHelper.for_each_enemy_body_in_circle(p, line_hit_radius, world, _on_line_hit)


func _on_line_hit(body: Node2D) -> void:
	if body == null or not body.is_in_group(_SkillDefs.GROUP_ENEMIES):
		return
	var body_id: int = body.get_instance_id()
	if _hit_cooldowns.has(body_id):
		return
	if body.has_method("take_damage"):
		body.take_damage(_damage, _HitFlash.ELEMENT_ICE)
		_hit_cooldowns[body_id] = hit_cooldown_sec


func _decay_hit_cooldowns(delta: float) -> void:
	if _hit_cooldowns.is_empty():
		return
	var expired: Array[int] = []
	for body_id: int in _hit_cooldowns:
		_hit_cooldowns[body_id] = float(_hit_cooldowns[body_id]) - delta
		if float(_hit_cooldowns[body_id]) <= 0.0:
			expired.append(body_id)
	for body_id: int in expired:
		_hit_cooldowns.erase(body_id)
