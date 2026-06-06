## Thunderstorm — AoE circular: pulsos de daño Viento + knockback.
class_name Thunderstorm
extends Area2D

const _VfxSpawn = preload("res://scripts/vfx/vfx_spawn_helper.gd")
const _SkillDefs = preload("res://data/skill_definitions.gd")
const _MageScale = preload("res://data/mage_skill_scaling.gd")
const _AreaHitHelper = preload("res://scripts/combat/area_hit_helper.gd")
const _Vfx = preload("res://scripts/vfx/elemental_vfx_spawner.gd")
const _HitFlash = preload("res://scripts/vfx/enemy_hit_flash.gd")
const _SkillVisual = preload("res://scripts/skills/skill_visual_service.gd")
const _ProjectileBase = preload("res://scripts/skills/projectile_skill_base.gd")

@export var radius: float = 72.0
@export var pulse_damage: int = 12
@export var duration: float = 1.5
@export var pulse_interval: float = 0.5
@export var knockback_force: float = 140.0

var _elapsed: float = 0.0
var _pulse_accum: float = 0.0
var _opening_strike_done: bool = false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual: Sprite2D = $Sprite2D


func setup_level(level: int, base_damage: int = 12) -> void:
	var lv: int = _MageScale.clamp_level(level)
	radius = _MageScale.get_thunderstorm_radius(lv)
	pulse_damage = base_damage
	duration = _MageScale.get_thunderstorm_duration(lv)
	pulse_interval = _MageScale.get_thunderstorm_pulse_interval(lv)
	knockback_force = _MageScale.get_thunderstorm_knockback(lv)
	_apply_radius_visual()
	_pulse_accum = 0.0
	call_deferred("_apply_pulse")


func set_radius_override(new_radius: float) -> void:
	radius = new_radius
	_apply_radius_visual()


func _ready() -> void:
	_apply_radius_visual()
	_pulse_accum = pulse_interval
	call_deferred("_play_opening_strike_vfx")


func _play_opening_strike_vfx() -> void:
	if _opening_strike_done:
		return
	_opening_strike_done = true
	var parent: Node = get_parent()
	if parent == null:
		return
	if _SkillVisual.use_legacy_particle_vfx():
		_Vfx.spawn_thunderstorm_strike(parent, global_position, radius, true)
	else:
		_SkillVisual.spawn_mage_strike(parent, global_position, "thunderstorm", radius)
		_Vfx.spawn_heavy_magic_shake(5.5 + radius * 0.04, 0.22)
		Audio.play_sfx_varied("thunder_storm", 0.88, 1.05)


func _apply_radius_visual() -> void:
	if collision_shape and collision_shape.shape is CircleShape2D:
		(collision_shape.shape as CircleShape2D).radius = radius
	if visual:
		if _SkillVisual.has_config("thunderstorm", "aura"):
			_SkillVisual.apply_mage_area_aura(self, visual, "thunderstorm", "aura", radius)
		else:
			visual.scale = Vector2(radius / 16.0, radius / 16.0)


func _process(delta: float) -> void:
	_elapsed += delta
	_pulse_accum += delta
	if _elapsed >= duration:
		queue_free()
		return
	if _pulse_accum >= pulse_interval:
		_pulse_accum -= pulse_interval
		_apply_pulse()
	var sheet: AnimatedSprite2D = _ProjectileBase.get_sheet_visual(self)
	if visual and sheet == null:
		var alpha: float = 0.45 + sin(_elapsed * 12.0) * 0.2
		visual.modulate = Color(0.82, 0.95, 1.0, alpha)
	queue_redraw()


func _draw() -> void:
	if _ProjectileBase.uses_skill_sheet(self):
		return
	var ring: float = radius * 0.38
	var pulse: float = 0.3 + 0.2 * sin(_elapsed * 14.0)
	draw_arc(Vector2.ZERO, ring, 0.0, TAU, 36, Color(0.75, 0.92, 1.0, pulse), 2.5, true)


func _apply_pulse() -> void:
	_AreaHitHelper.for_each_enemy_body_in_circle(
		global_position, radius, get_world_2d(), _on_enemy_pulse_hit
	)
	var parent: Node = get_parent()
	if parent == null:
		return
	if _SkillVisual.use_legacy_particle_vfx():
		_Vfx.spawn_electric_ground_ring(parent, global_position, radius * 0.42)
	elif _SkillVisual.has_config("thunderstorm", "pulse"):
		_SkillVisual.spawn_mage_impact(parent, global_position, "thunderstorm", "pulse", radius * 0.42)


func _on_enemy_pulse_hit(body: Node2D) -> void:
	if not body.is_in_group(_SkillDefs.GROUP_ENEMIES):
		return
	if body.has_method("take_damage"):
		body.take_damage(pulse_damage, _HitFlash.ELEMENT_WIND)
	var away: Vector2 = (body.global_position - global_position).normalized()
	if away.length_squared() < 0.001:
		away = Vector2.RIGHT
	if body.has_method("apply_knockback"):
		body.apply_knockback(away * knockback_force)


static func spawn_at(world_pos: Vector2, scene: PackedScene, parent: Node) -> void:
	if scene == null or parent == null:
		return
	var storm: Thunderstorm = scene.instantiate() as Thunderstorm
	if storm == null:
		return
	_VfxSpawn.add_child_at_world(parent, storm, world_pos)
