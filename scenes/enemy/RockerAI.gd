## RockerAI.gd — Enemigo semi-élite con salto telegrafiado y golpe en área.
##
## Ciclo:
## - Carga: quieto; marca el suelo una vez (punto fijo de caída).
## - Vuelo: tween + arco visual.
## - Impacto: daño AoE al jugador si está dentro del círculo.
class_name RockerAI
extends Enemy

const _ThreatVfx = preload("res://scripts/vfx/enemy_threat_vfx.gd")

enum State { CHARGING, JUMPING, RECOVERING }

@export_group("Rocker — Salto")
@export var charge_seconds: float = 1.0
@export var jump_seconds: float = 1.1
@export var recovery_seconds: float = 0.2
@export var jump_max_distance: float = 240.0
@export var jump_arc_height: float = 34.0

@export_group("Rocker — Impacto")
@export var impact_radius: float = 64.0
@export var impact_damage: int = 36

var _state: int = State.CHARGING
var _state_time_left: float = 0.0
var _target_world: Vector2 = Vector2.ZERO
var _jump_tween: Tween = null


func _ready() -> void:
	super._ready()
	contact_damage = 0
	_enter_charging()


func _apply_body_collision_layers() -> void:
	collision_layer = _CollisionLayers.LAYER_ENEMIES
	# Sin body block: el daño solo ocurre en el impacto AoE del salto.
	collision_mask = 0


func _process_contact_damage() -> void:
	pass


func _exit_tree() -> void:
	_ThreatVfx.release_ground_telegraph(self)


func apply_type(type_id: String) -> void:
	super.apply_type(type_id)
	contact_damage = 0
	collision_mask = 0
	impact_radius = float(_enemy_visual_def.get("impact_radius", impact_radius))
	impact_damage = int(_enemy_visual_def.get("impact_damage", impact_damage))


func should_skip_overlap_separation() -> bool:
	return _state == State.JUMPING


func apply_knockback(force: Vector2) -> void:
	if _state == State.CHARGING:
		return
	super.apply_knockback(force)


func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_find_player()
		return
	if _is_stunned:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_tile_depth_sort()
		_hide_ground_telegraph()
		return

	match _state:
		State.CHARGING:
			_state_time_left -= delta
			_knockback_velocity = Vector2.ZERO
			velocity = Vector2.ZERO
			move_and_slide()
			_update_ground_telegraph()
			if _state_time_left <= 0.0:
				_start_jump()
		State.JUMPING:
			_knockback_velocity = _knockback_velocity.lerp(Vector2.ZERO, delta * 10.0)
		State.RECOVERING:
			_state_time_left -= delta
			velocity = Vector2.ZERO
			move_and_slide()
			_hide_ground_telegraph()
			if _state_time_left <= 0.0:
				_enter_charging()
	_update_tile_depth_sort()


func _enter_charging() -> void:
	_state = State.CHARGING
	_state_time_left = maxf(charge_seconds, 0.05)
	if _player == null or not is_instance_valid(_player):
		_find_player()
	_update_target()


func _update_target() -> void:
	if _player == null or not is_instance_valid(_player):
		_target_world = global_position
		return
	var to_player: Vector2 = _player.global_position - global_position
	var dist: float = to_player.length()
	if dist < 0.001:
		_target_world = global_position
		return
	var dir: Vector2 = to_player / dist
	var travel: float = minf(dist, jump_max_distance)
	_target_world = global_position + dir * travel


func _update_ground_telegraph() -> void:
	if _state != State.CHARGING:
		return
	var telegraph: EnemyGroundTelegraph = _ThreatVfx.ensure_ground_telegraph(self)
	if telegraph == null:
		return
	var r: float = maxf(impact_radius, 8.0)
	var charge_elapsed: float = maxf(charge_seconds - _state_time_left, 0.0)
	telegraph.update_telegraph(_target_world, r, charge_elapsed, charge_seconds)


func _hide_ground_telegraph() -> void:
	if not has_meta(_ThreatVfx.GROUND_TELEGRAPH_META):
		return
	var telegraph: EnemyGroundTelegraph = get_meta(_ThreatVfx.GROUND_TELEGRAPH_META) as EnemyGroundTelegraph
	if telegraph and is_instance_valid(telegraph):
		telegraph.hide_telegraph()


func _start_jump() -> void:
	_state = State.JUMPING
	_hide_ground_telegraph()
	if _jump_tween != null:
		_jump_tween.kill()

	var end_pos: Vector2 = _target_world

	_jump_tween = create_tween()
	_jump_tween.set_trans(Tween.TRANS_SINE)
	_jump_tween.set_ease(Tween.EASE_IN_OUT)
	_jump_tween.tween_property(self, "global_position", end_pos, jump_seconds)

	if visual_root:
		_jump_tween.parallel().tween_method(
			func(t: float) -> void:
				visual_root.position.y = -sin(t * PI) * jump_arc_height,
			0.0, 1.0, jump_seconds
		)

	_jump_tween.finished.connect(func() -> void:
		if visual_root:
			visual_root.position.y = 0.0
		_do_impact()
		_state = State.RECOVERING
		_state_time_left = maxf(recovery_seconds, 0.05)
	)


func _do_impact() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var r: float = maxf(impact_radius, 8.0)
	if _player.global_position.distance_squared_to(_target_world) <= r * r:
		if _player.has_method("take_damage"):
			_player.take_damage(impact_damage)
