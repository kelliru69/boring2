## Jefe Creamy: casteo, balas y stats ajustados.
class_name CreamyBoss
extends Enemy

signal defeated
signal boss_health_changed(current_hp: int, max_hp: int)

const DIFFICULTY_MULT: float = 10.0
const DAMAGE_SCALE: float = 0.2
const BULLET_AMOUNT_SCALE: float = 0.1
const BULLET_SPREAD_ANGLES: Array[float] = [0.0]

@export var boss_display_name: String = "Creamy"
@export var cast_interval: float = 2.64
@export var cast_charge_time: float = 1.35
@export var cast_telegraph_radius: float = 78.0
@export var cast_impact_damage: int = 75
@export var visual_scale: float = 2.6

@export var cast_telegraph_scene: PackedScene
@export var bullet_scene: PackedScene
@export var bullet_interval: float = 2.8
@export var bullet_damage: int = 37
@export var bullet_speed: float = 250.0
@export var bullet_visual_scale: float = 1.65
@export var radial_bullet_interval: float = 22.0

enum BossState { CHASE, CASTING }

var _state: BossState = BossState.CHASE
var _cast_cooldown: float = 0.8
var _cast_elapsed: float = 0.0
var _bullet_cooldown: float = 0.2
var _radial_cooldown: float = 1.0
var _active_telegraph: Node2D = null

@onready var hp_bar: ProgressBar = $UI/HPBar
@onready var cast_bar: ProgressBar = $UI/CastBar


func _ready() -> void:
	enemy_type = "creamy"
	super._ready()
	dies_on_player_contact = false
	max_hp = int(2000.0 * DIFFICULTY_MULT * 0.5)
	current_hp = max_hp
	move_speed = 128.0 * 3.2 * 0.25
	_base_move_speed = move_speed
	contact_damage = maxi(int(round(
		float(26 * DIFFICULTY_MULT) * DAMAGE_SCALE * RunBalance.MOB_CONTACT_DAMAGE_MULTIPLIER
	)), 1)
	cast_impact_damage = int(round(75.0 * RunBalance.MOB_CONTACT_DAMAGE_MULTIPLIER))
	bullet_damage = maxi(int(round(float(bullet_damage))), 1)
	zeny_reward = 180
	xp_reward = 400
	_display_name = boss_display_name
	_apply_boss_scale()
	_setup_bars()
	if cast_bar:
		cast_bar.visible = false


func _apply_boss_scale() -> void:
	if visual_root:
		visual_root.scale = Vector2(visual_scale, visual_scale)
	var shape: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape and shape.shape is CircleShape2D:
		(shape.shape as CircleShape2D).radius *= visual_scale
	_base_modulate = Color(1.0, 0.92, 0.45)
	_set_visual_modulate(_base_modulate)


func _setup_bars() -> void:
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = current_hp
	if cast_bar:
		cast_bar.max_value = cast_charge_time
		cast_bar.value = 0.0
		cast_bar.show_percentage = false


func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_find_player()
		return
	_process_bullet_timers(delta)
	match _state:
		BossState.CHASE:
			_process_chase(delta)
			_cast_cooldown -= delta
			if _cast_cooldown <= 0.0:
				_begin_cast()
		BossState.CASTING:
			_process_casting(delta)
	_update_motion_visuals(Vector2.ZERO, delta)
	_update_tile_depth_sort()


func _process_bullet_timers(delta: float) -> void:
	_bullet_cooldown -= delta
	_radial_cooldown -= delta
	if bullet_scene == null or _player == null or not is_instance_valid(_player):
		return
	if _bullet_cooldown <= 0.0:
		_fire_aimed_bullet_fan()
		_bullet_cooldown = bullet_interval
	if _radial_cooldown <= 0.0:
		_fire_radial_bullets()
		_radial_cooldown = radial_bullet_interval


func _fire_aimed_bullet_fan() -> void:
	var base_dir: Vector2 = (_player.global_position - global_position).normalized()
	if base_dir.length_squared() < 0.001:
		base_dir = Vector2.RIGHT
	for angle_offset: float in BULLET_SPREAD_ANGLES:
		_spawn_bullet(base_dir.rotated(angle_offset))


func _fire_radial_bullets() -> void:
	var dir: Vector2 = Vector2.from_angle(randf() * TAU)
	_spawn_bullet(dir)


func _spawn_bullet(direction: Vector2) -> void:
	if bullet_scene == null:
		return
	var bolt: Node = bullet_scene.instantiate()
	if bolt == null or not bolt.has_method("setup_direction"):
		return
	var parent: Node = get_tree().current_scene
	if parent == null:
		return
	parent.add_child(bolt)
	if bolt is Node2D:
		(bolt as Node2D).global_position = global_position
	if bolt.get("speed") != null:
		bolt.speed = bullet_speed
	if bolt.has_method("apply_visual_scale"):
		bolt.apply_visual_scale(bullet_visual_scale)
	bolt.setup_direction(direction, bullet_damage)


func _process_chase(delta: float) -> void:
	if _player == null:
		return
	var direction: Vector2 = (_player.global_position - global_position).normalized()
	velocity = direction * move_speed + _knockback_velocity
	move_and_slide()
	_knockback_velocity = _knockback_velocity.lerp(Vector2.ZERO, delta * 10.0)
	if Arena.is_ready() and Arena.is_inside_playable(global_position, 0.0):
		global_position = Arena.clamp_to_playable(global_position, 8.0)
	_process_contact_damage()


func _begin_cast() -> void:
	_clear_telegraph()
	_state = BossState.CASTING
	_cast_elapsed = 0.0
	velocity = Vector2.ZERO
	if cast_bar:
		cast_bar.visible = true
		cast_bar.value = 0.0
	if _player and is_instance_valid(_player) and cast_telegraph_scene:
		_active_telegraph = cast_telegraph_scene.instantiate() as Node2D
		if _active_telegraph:
			get_tree().current_scene.add_child(_active_telegraph)
			_active_telegraph.global_position = _player.global_position
			if _active_telegraph.has_method("configure"):
				_active_telegraph.configure(cast_telegraph_radius, cast_charge_time, cast_impact_damage)


func _process_casting(delta: float) -> void:
	_cast_elapsed += delta
	if cast_bar:
		cast_bar.value = _cast_elapsed
	if _cast_elapsed >= cast_charge_time:
		_end_cast()


func _end_cast() -> void:
	_state = BossState.CHASE
	_cast_cooldown = cast_interval
	if cast_bar:
		cast_bar.visible = false
	_clear_telegraph()


func _clear_telegraph() -> void:
	if _active_telegraph and is_instance_valid(_active_telegraph):
		_active_telegraph.queue_free()
	_active_telegraph = null


func take_damage(amount: int, hit_element: StringName = EnemyHitFlash.ELEMENT_DEFAULT) -> void:
	if amount <= 0:
		return
	if Arena.is_ready() and not Arena.can_damage_enemy_at(global_position):
		return
	if _is_damage_number_visible():
		var parent: Node = get_tree().current_scene
		if parent:
			_DamageNumber.spawn(global_position, amount, parent)
	current_hp = maxi(current_hp - amount, 0)
	if hp_bar:
		hp_bar.value = current_hp
	_emit_boss_health()
	_flash_damage_feedback(hit_element)
	if current_hp <= 0:
		die()


func _emit_boss_health() -> void:
	boss_health_changed.emit(current_hp, max_hp)


func die() -> void:
	_clear_telegraph()
	Audio.play_sfx("enemy_death", randf_range(0.85, 1.0))
	_try_drop_card()
	_spawn_loot_drops()
	defeated.emit()
	queue_free()
