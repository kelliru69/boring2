## Grand Cross — daño en cruz centrado en el jugador (fusión Crusader).
extends Node2D

const _AreaHitHelper = preload("res://scripts/combat/area_hit_helper.gd")
const _HitFlash = preload("res://scripts/vfx/enemy_hit_flash.gd")

var _player: Player = null
var _arm_length: float = 220.0
var _arm_width: float = 64.0
var _tick_damage: int = 28
var _duration: float = 3.2
var _tick_interval: float = 0.38
var _elapsed: float = 0.0
var _tick_accum: float = 0.0


func setup(player: Player, tick_damage: int, duration: float = 3.2) -> void:
	_player = player
	_tick_damage = maxi(tick_damage, 1)
	_duration = maxf(duration, 0.5)


func _process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		queue_free()
		return
	global_position = _player.global_position
	_elapsed += delta
	_tick_accum += delta
	queue_redraw()
	if _elapsed >= _duration:
		queue_free()
		return
	if _tick_accum >= _tick_interval:
		_tick_accum = 0.0
		_pulse_cross()


func _pulse_cross() -> void:
	var world: World2D = get_world_2d()
	if world == null:
		return
	var center: Vector2 = global_position
	_AreaHitHelper.for_each_enemy_body_in_circle(center, _arm_width * 0.5, world, _on_hit)
	for sign_x: int in [-1, 1]:
		var offset: Vector2 = Vector2(float(sign_x) * _arm_length * 0.5, 0.0)
		_AreaHitHelper.for_each_enemy_body_in_circle(center + offset, _arm_width * 0.5, world, _on_hit)
	for sign_y: int in [-1, 1]:
		var offset_y: Vector2 = Vector2(0.0, float(sign_y) * _arm_length * 0.5)
		_AreaHitHelper.for_each_enemy_body_in_circle(center + offset_y, _arm_width * 0.5, world, _on_hit)


func _on_hit(body: Node2D) -> void:
	if body and body.has_method("take_damage"):
		body.take_damage(_tick_damage, _HitFlash.ELEMENT_SOUL)


func _draw() -> void:
	var col: Color = Color(1.0, 0.92, 0.45, 0.35)
	draw_rect(Rect2(-_arm_length * 0.5, -_arm_width * 0.5, _arm_length, _arm_width), col)
	draw_rect(Rect2(-_arm_width * 0.5, -_arm_length * 0.5, _arm_width, _arm_length), col)
