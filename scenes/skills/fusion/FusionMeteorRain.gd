## Lluvia de meteoros — daño por tic en zona (fusión Wizard).
extends Node2D

const _AreaHitHelper = preload("res://scripts/combat/area_hit_helper.gd")
const _HitFlash = preload("res://scripts/vfx/enemy_hit_flash.gd")
const _Vfx = preload("res://scripts/vfx/elemental_vfx_spawner.gd")

var _center: Vector2 = Vector2.ZERO
var _radius: float = 160.0
var _tick_damage: int = 18
var _duration: float = 4.5
var tick_interval: float = 0.32
var _elapsed: float = 0.0
var _tick_accum: float = 0.0


func setup(
	world_center: Vector2,
	radius: float,
	tick_damage: int,
	duration: float = 4.5,
	strike_interval: float = 0.32
) -> void:
	global_position = world_center
	_center = world_center
	_radius = maxf(radius, 40.0)
	_tick_damage = maxi(tick_damage, 1)
	_duration = maxf(duration, 1.0)
	tick_interval = maxf(strike_interval, 0.08)


func _process(delta: float) -> void:
	_elapsed += delta
	_tick_accum += delta
	if _elapsed >= _duration:
		queue_free()
		return
	if _tick_accum >= tick_interval:
		_tick_accum = 0.0
		_strike_random_meteor()


func _strike_random_meteor() -> void:
	var angle: float = randf() * TAU
	var dist: float = randf() * _radius
	var hit_pos: Vector2 = _center + Vector2.from_angle(angle) * dist
	var parent: Node = get_parent()
	if parent:
		_Vfx.spawn_fire_impact(parent, hit_pos)
	var world: World2D = get_world_2d()
	if world == null:
		return
	_AreaHitHelper.for_each_enemy_body_in_circle(hit_pos, _radius * 0.28, world, _on_hit)


func _on_hit(body: Node2D) -> void:
	if body and body.has_method("take_damage"):
		body.take_damage(_tick_damage, _HitFlash.ELEMENT_FIRE)
