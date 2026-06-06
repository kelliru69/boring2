## Jefe final Orc Village — pilares, terremoto y embestida.
extends Enemy
class_name OrcHeroBoss

signal defeated
signal boss_health_changed(current_hp: int, max_hp: int)

const _EarthPillarScene: PackedScene = preload("res://scenes/boss/EarthPillar.tscn")
const _ThreatVfx = preload("res://scripts/vfx/enemy_threat_vfx.gd")

enum State { CHASE, PILLAR_CAST, QUAKE_WINDUP, QUAKE_ACTIVE, CHARGE_WINDUP, CHARGING }
enum BossAbility { PILLARS, QUAKE, CHARGE }

@export var boss_display_name: String = "Orc Hero"
@export var visual_scale: float = 2.2
@export var pillar_interval: float = 8.5
@export var pillar_count_min: int = 5
@export var pillar_count_max: int = 5
@export var quake_interval: float = 15.0
@export var quake_windup_seconds: float = 1.6
@export var quake_radius: float = 292.5
@export var quake_damage: int = 115
@export var charge_interval: float = 10.5
@export var charge_windup_seconds: float = 1.15
@export var charge_speed_mult: float = 2.6
@export var charge_damage: int = 155
@export var charge_max_seconds: float = 0.78

var _state: int = State.CHASE
var _state_time_left: float = 0.0
var _pillar_cooldown: float = 3.5
var _quake_cooldown: float = 6.0
var _charge_cooldown: float = 8.0
var _charge_direction: Vector2 = Vector2.RIGHT
var _charge_target: Vector2 = Vector2.ZERO
var _quake_telegraph: EnemyGroundTelegraph = null
var _ability_cycle: int = 0

@onready var hp_bar: ProgressBar = $UI/HPBar


func _ready() -> void:
	enemy_type = "orc_hero"
	super._ready()
	dies_on_player_contact = false
	# ~4× el jefe de Payon (Moonlight Flower ≈ 11 000 HP).
	max_hp = 44000
	current_hp = max_hp
	move_speed = 102.0
	_base_move_speed = move_speed
	contact_damage = int(round(64.0 * RunBalance.MOB_CONTACT_DAMAGE_MULTIPLIER))
	quake_damage = int(round(float(quake_damage) * RunBalance.MOB_CONTACT_DAMAGE_MULTIPLIER))
	charge_damage = int(round(float(charge_damage) * RunBalance.MOB_CONTACT_DAMAGE_MULTIPLIER))
	zeny_reward = 640
	xp_reward = 1500
	_display_name = boss_display_name
	if visual_root:
		visual_root.scale = Vector2(visual_scale, visual_scale)
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = current_hp
	z_index = 8


func _exit_tree() -> void:
	_hide_quake_telegraph()


func take_damage(amount: int, hit_element: StringName = _HitFlash.ELEMENT_DEFAULT) -> void:
	if amount <= 0:
		return
	if Arena.is_ready() and not Arena.can_damage_enemy_at(global_position):
		return
	Global.record_damage_dealt(amount)
	if _is_damage_number_visible():
		var parent: Node = get_tree().current_scene
		if parent:
			_DamageNumber.spawn(global_position, amount, parent)
	current_hp = maxi(current_hp - amount, 0)
	if hp_bar:
		hp_bar.value = current_hp
	_emit_boss_health()
	if hit_sound_player:
		hit_sound_player.play_hit(global_position)
	if current_hp <= 0:
		die()


func die() -> void:
	Audio.play_sfx("enemy_death", randf_range(0.85, 1.0))
	_try_drop_card()
	_spawn_loot_drops()
	defeated.emit()
	queue_free()


func _emit_boss_health() -> void:
	boss_health_changed.emit(current_hp, max_hp)


func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_find_player()
		return
	_state_time_left = maxf(_state_time_left - delta, 0.0)
	_pillar_cooldown = maxf(_pillar_cooldown - delta, 0.0)
	_quake_cooldown = maxf(_quake_cooldown - delta, 0.0)
	_charge_cooldown = maxf(_charge_cooldown - delta, 0.0)
	match _state:
		State.CHASE:
			_process_chase(delta)
		State.PILLAR_CAST:
			velocity = Vector2.ZERO
			move_and_slide()
			if _state_time_left <= 0.0:
				_state = State.CHASE
		State.QUAKE_WINDUP:
			_process_quake_windup(delta)
		State.QUAKE_ACTIVE:
			_execute_quake_damage()
			_state = State.CHASE
		State.CHARGE_WINDUP:
			_process_charge_windup(delta)
		State.CHARGING:
			_process_charge(delta)
	_update_tile_depth_sort()


func _process_chase(_delta: float) -> void:
	var to_player: Vector2 = _player.global_position - global_position
	var dist: float = to_player.length()
	if dist > 20.0:
		velocity = to_player.normalized() * move_speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	_try_cast_rotating_ability(dist)


func _try_cast_rotating_ability(dist_to_player: float) -> bool:
	for step: int in 3:
		var ability: int = (_ability_cycle + step) % 3
		match ability:
			BossAbility.PILLARS:
				if _pillar_cooldown <= 0.0:
					_cast_earth_pillars()
					_advance_ability_cycle()
					return true
			BossAbility.QUAKE:
				if _quake_cooldown <= 0.0 and dist_to_player <= quake_radius * 1.15:
					_begin_quake()
					_advance_ability_cycle()
					return true
			BossAbility.CHARGE:
				if _charge_cooldown <= 0.0 and dist_to_player >= 90.0:
					_begin_charge()
					_advance_ability_cycle()
					return true
	return false


func _advance_ability_cycle() -> void:
	_ability_cycle = (_ability_cycle + 1) % 3


func _cast_earth_pillars() -> void:
	_state = State.PILLAR_CAST
	_state_time_left = 0.5
	_pillar_cooldown = pillar_interval
	var count: int = randi_range(pillar_count_min, pillar_count_max)
	var parent: Node = get_tree().current_scene
	if parent == null or _player == null:
		return
	for _i: int in count:
		var offset: Vector2 = Vector2(randf_range(-110.0, 110.0), randf_range(-80.0, 80.0))
		var pos: Vector2 = _player.global_position + offset
		if Arena.is_ready():
			pos = Arena.clamp_to_playable(pos, 24.0)
		var pillar: EarthPillar = _EarthPillarScene.instantiate() as EarthPillar
		if pillar == null:
			continue
		parent.add_child(pillar)
		pillar.global_position = pos


func _begin_quake() -> void:
	_state = State.QUAKE_WINDUP
	_state_time_left = quake_windup_seconds
	_quake_cooldown = quake_interval
	velocity = Vector2.ZERO
	_quake_telegraph = _ThreatVfx.ensure_ground_telegraph(self)
	if _quake_telegraph:
		_quake_telegraph.update_telegraph(global_position, quake_radius, 0.0, quake_windup_seconds)


func _process_quake_windup(_delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()
	if _quake_telegraph:
		var elapsed: float = quake_windup_seconds - _state_time_left
		_quake_telegraph.update_telegraph(global_position, quake_radius, elapsed, quake_windup_seconds)
	if _state_time_left <= 0.0:
		_hide_quake_telegraph()
		_state = State.QUAKE_ACTIVE


func _execute_quake_damage() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if _player.global_position.distance_to(global_position) <= quake_radius:
		if _player.has_method("take_damage"):
			_player.call("take_damage", quake_damage)


func _hide_quake_telegraph() -> void:
	_ThreatVfx.release_ground_telegraph(self)
	_quake_telegraph = null


func _begin_charge() -> void:
	if _player == null:
		return
	_state = State.CHARGE_WINDUP
	_state_time_left = charge_windup_seconds
	_charge_cooldown = charge_interval
	_charge_target = _player.global_position
	var dir: Vector2 = _charge_target - global_position
	_charge_direction = dir.normalized() if dir.length_squared() > 1.0 else Vector2.RIGHT
	velocity = Vector2.ZERO


func _process_charge_windup(_delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()
	if _state_time_left <= 0.0:
		_state = State.CHARGING
		_state_time_left = charge_max_seconds


func _process_charge(_delta: float) -> void:
	velocity = _charge_direction * move_speed * charge_speed_mult
	move_and_slide()
	if _player and is_instance_valid(_player):
		if global_position.distance_to(_player.global_position) <= 34.0:
			if _player.has_method("take_damage"):
				_player.call("take_damage", charge_damage)
			_state = State.CHASE
			velocity = Vector2.ZERO
			return
	_state_time_left -= _delta
	if _state_time_left <= 0.0:
		_state = State.CHASE
		velocity = Vector2.ZERO
