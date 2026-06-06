## ArcherAI.gd — Enemigo a distancia (Archer Skeleton).
##
## - Persigue al jugador.
## - Al entrar en rango (<= 11 tiles), se detiene, carga 0.8s y dispara una flecha
##   hacia la posición del jugador al terminar la carga.
class_name ArcherAI
extends Enemy

const _ThreatVfx = preload("res://scripts/vfx/enemy_threat_vfx.gd")

enum State { CHASING, CHARGING, COOLDOWN }

@export_group("Archer — Rango")
@export var tile_size_px: float = 32.0
@export var stop_range_tiles: float = 11.0

@export_group("Archer — Disparo")
@export var charge_seconds: float = 0.8
@export var cooldown_seconds: float = 0.65
@export var arrow_speed: float = 520.0
@export var ranged_damage: int = 100
@export var arrow_scene: PackedScene = preload("res://scenes/projectile/ArrowProjectil.tscn")

var _state: int = State.CHASING
var _state_time_left: float = 0.0
var _shot_target_world: Vector2 = Vector2.ZERO


func _ready() -> void:
	super._ready()


func _exit_tree() -> void:
	_ThreatVfx.release_ground_telegraph(self)


func apply_type(type_id: String) -> void:
	super.apply_type(type_id)
	ranged_damage = int(_enemy_visual_def.get("ranged_damage", ranged_damage))
	stop_range_tiles = float(_enemy_visual_def.get("ranged_range_tiles", stop_range_tiles))


func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_find_player()
		return
	if _is_stunned:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_tile_depth_sort()
		return

	var stop_range_px: float = maxf(tile_size_px * stop_range_tiles, 1.0)
	var to_player: Vector2 = _player.global_position - global_position
	var dist_sq: float = to_player.length_squared()
	var stop_sq: float = stop_range_px * stop_range_px

	match _state:
		State.CHASING:
			_hide_charge_telegraph()
			if dist_sq <= stop_sq:
				_enter_charging()
				_update_tile_depth_sort()
				return
			var anchor: Vector2 = _get_player_hurt_position()
			velocity = _compute_chase_velocity()
			move_and_slide()
			_enforce_standoff_from_player()
			_knockback_velocity = _knockback_velocity.lerp(Vector2.ZERO, delta * 10.0)
			var dir: Vector2 = velocity
			if dir.length_squared() < 0.01:
				dir = anchor - global_position
			if Arena.is_ready() and Arena.is_inside_playable(global_position, 0.0):
				global_position = Arena.clamp_to_playable(global_position, 8.0)
			_update_motion_visuals(dir, delta)
			if (Engine.get_physics_frames() & 1) == 0:
				_process_contact_damage()
		State.CHARGING:
			_state_time_left -= delta
			_update_charge_telegraph()
			queue_redraw()
			velocity = Vector2.ZERO
			move_and_slide()
			_knockback_velocity = _knockback_velocity.lerp(Vector2.ZERO, delta * 10.0)
			_update_motion_visuals(Vector2.RIGHT if to_player.x >= 0.0 else Vector2.LEFT, delta)
			# Congela animación de caminata durante carga.
			if _uses_animation and animated_visual and animated_visual.visible and animated_visual.is_playing():
				animated_visual.stop()
			if _state_time_left <= 0.0:
				_fire_arrow()
				_enter_cooldown()
		State.COOLDOWN:
			_state_time_left -= delta
			_hide_charge_telegraph()
			velocity = Vector2.ZERO
			move_and_slide()
			_knockback_velocity = _knockback_velocity.lerp(Vector2.ZERO, delta * 10.0)
			if _state_time_left <= 0.0:
				_state = State.CHASING
	_update_tile_depth_sort()


func _enter_charging() -> void:
	_state = State.CHARGING
	_state_time_left = maxf(charge_seconds, 0.05)
	_shot_target_world = _player.global_position


func _enter_cooldown() -> void:
	_state = State.COOLDOWN
	_state_time_left = maxf(cooldown_seconds, 0.05)
	_hide_charge_telegraph()


func _update_charge_telegraph() -> void:
	queue_redraw()


func _hide_charge_telegraph() -> void:
	queue_redraw()


func _fire_arrow() -> void:
	if arrow_scene == null:
		return
	var arrow: Node = arrow_scene.instantiate()
	if arrow == null:
		return
	var parent: Node = get_tree().current_scene
	if parent == null:
		parent = get_parent()
	if parent == null:
		return
	parent.add_child(arrow)
	if arrow is Node2D:
		(arrow as Node2D).global_position = global_position
	if arrow.has_method("setup"):
		arrow.call("setup", _shot_target_world, ranged_damage, arrow_speed, self)


func _draw() -> void:
	if _state != State.CHARGING:
		return
	var local_target: Vector2 = to_local(_shot_target_world)
	var charge_elapsed: float = maxf(charge_seconds - _state_time_left, 0.0)
	_ThreatVfx.draw_ground_telegraph(self, local_target, 22.0, charge_elapsed, charge_seconds)
	var aim: Color = Color(1.0, 0.15, 0.1, 0.35)
	draw_line(Vector2.ZERO, local_target, aim, 2.0)

