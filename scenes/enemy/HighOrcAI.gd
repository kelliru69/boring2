## High Orc — semi-élite con escudo frontal (30%) y hachazo AoE.
class_name HighOrcAI
extends Enemy

const _ThreatVfx = preload("res://scripts/vfx/enemy_threat_vfx.gd")

enum State { CHASING, AXE_WINDUP, AXE_RECOVERY }

@export_group("High Orc — Escudo")
@export var frontal_block_pct: float = 0.30

@export_group("High Orc — Hachazo")
@export var axe_windup_seconds: float = 0.9
@export var axe_recovery_seconds: float = 0.55
@export var axe_interval_seconds: float = 2.4
@export var axe_damage: int = 72
@export var axe_radius: float = 72.0

var _state: int = State.CHASING
var _state_time_left: float = 0.0
var _axe_cooldown: float = 1.2
var _facing: Vector2 = Vector2.RIGHT


func _ready() -> void:
	super._ready()


func apply_type(type_id: String) -> void:
	super.apply_type(type_id)
	axe_damage = int(_enemy_visual_def.get("axe_damage", axe_damage))
	axe_radius = float(_enemy_visual_def.get("axe_radius", axe_radius))
	frontal_block_pct = float(_enemy_visual_def.get("frontal_block_pct", frontal_block_pct))


func take_damage(amount: int, hit_element: StringName = _HitFlash.ELEMENT_DEFAULT) -> void:
	var reduced: int = _apply_frontal_block(amount)
	super.take_damage(reduced, hit_element)


func _apply_frontal_block(amount: int) -> int:
	if amount <= 0 or _player == null or not is_instance_valid(_player):
		return amount
	var to_player: Vector2 = (_player.global_position - global_position).normalized()
	if to_player.dot(_facing) > 0.55:
		return maxi(int(round(float(amount) * (1.0 - frontal_block_pct))), 1)
	return amount


func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_find_player()
		return
	if _is_stunned:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_tile_depth_sort()
		return
	_state_time_left = maxf(_state_time_left - delta, 0.0)
	_axe_cooldown = maxf(_axe_cooldown - delta, 0.0)
	match _state:
		State.CHASING:
			_process_chasing(delta)
		State.AXE_WINDUP:
			_process_axe_windup(delta)
		State.AXE_RECOVERY:
			_process_axe_recovery(delta)
	_process_contact_damage()
	_update_tile_depth_sort()


func _process_chasing(_delta: float) -> void:
	var to_player: Vector2 = _player.global_position - global_position
	if to_player.length_squared() > 4.0:
		_facing = to_player.normalized()
	velocity = _facing * move_speed
	move_and_slide()
	if _axe_cooldown <= 0.0 and to_player.length() <= axe_radius * 1.35:
		_enter_axe_windup()


func _enter_axe_windup() -> void:
	_state = State.AXE_WINDUP
	_state_time_left = axe_windup_seconds
	velocity = Vector2.ZERO
	var telegraph: EnemyGroundTelegraph = _ThreatVfx.ensure_ground_telegraph(self)
	if telegraph:
		telegraph.update_telegraph(global_position, axe_radius, 0.0, axe_windup_seconds)


func _process_axe_windup(delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()
	var telegraph: EnemyGroundTelegraph = _ThreatVfx.ensure_ground_telegraph(self)
	if telegraph:
		var elapsed: float = axe_windup_seconds - _state_time_left
		telegraph.update_telegraph(global_position, axe_radius, elapsed, axe_windup_seconds)
	if _state_time_left <= 0.0:
		_execute_axe_impact()
		_state = State.AXE_RECOVERY
		_state_time_left = axe_recovery_seconds
		_axe_cooldown = axe_interval_seconds
		_ThreatVfx.release_ground_telegraph(self)


func _process_axe_recovery(_delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()
	if _state_time_left <= 0.0:
		_state = State.CHASING


func _execute_axe_impact() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if _player.global_position.distance_to(global_position) <= axe_radius:
		if _player.has_method("take_damage"):
			_player.call("take_damage", axe_damage)
