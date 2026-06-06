## Jefe final de Payon: Moonlight Flower.
## Mecánicas: ráfagas de rayos lineales + espíritus orbitales amplios.
extends Enemy
class_name MoonlightFlowerBoss

signal defeated
signal boss_health_changed(current_hp: int, max_hp: int)

@export var boss_display_name: String = "Moonlight Flower"
@export var visual_scale: float = 2.6
@export var line_attack_interval: float = 3.6
@export var line_telegraph_time: float = 2.0
@export var line_ray_count: int = 5
@export var line_ray_spread: float = 0.92
@export var line_ray_length: float = 760.0
@export var line_ray_width: float = 26.0
@export var line_ray_damage: int = 46
@export var spirit_count: int = 3
@export var spirit_orbit_radius: float = 180.0
@export var spirit_orbit_speed: float = 1.95
@export var spirit_hit_radius: float = 28.0
@export var spirit_damage: int = 30
@export var spirit_hit_cooldown: float = 0.42

var _line_cooldown: float = 1.5
var _line_telegraph_left: float = 0.0
var _line_telegraph_elapsed: float = 0.0
var _spirit_angle: float = 0.0
var _spirit_hit_cooldown_left: float = 0.0
var _pending_rays: Array[Vector2] = []
var _recent_rays: Array[Vector2] = []
var _ray_flash_timer: float = 0.0
var _vfx_time: float = 0.0
var _spirit_ground_markers: Array[EnemyGroundTelegraph] = []

@onready var hp_bar: ProgressBar = $UI/HPBar


func _ready() -> void:
	enemy_type = "moonlight_flower"
	super._ready()
	dies_on_player_contact = false
	max_hp = 20000
	current_hp = max_hp
	move_speed = 128.0
	_base_move_speed = move_speed
	contact_damage = int(round(34.0 * RunBalance.MOB_CONTACT_DAMAGE_MULTIPLIER))
	line_ray_damage = int(round(float(line_ray_damage) * RunBalance.MOB_CONTACT_DAMAGE_MULTIPLIER))
	spirit_damage = int(round(float(spirit_damage) * RunBalance.MOB_CONTACT_DAMAGE_MULTIPLIER))
	zeny_reward = 520
	xp_reward = 1200
	_display_name = boss_display_name
	if visual_root:
		visual_root.scale = Vector2(visual_scale, visual_scale)
		_set_visual_modulate(Color(0.95, 0.72, 1.0, 1.0))
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = current_hp
	z_index = 8
	_ensure_spirit_ground_markers()


func _exit_tree() -> void:
	for marker: EnemyGroundTelegraph in _spirit_ground_markers:
		if marker and is_instance_valid(marker):
			marker.queue_free()
	_spirit_ground_markers.clear()


func _ensure_spirit_ground_markers() -> void:
	var parent: Node = get_tree().current_scene
	if parent == null:
		return
	while _spirit_ground_markers.size() < spirit_count:
		var marker: EnemyGroundTelegraph = EnemyGroundTelegraph.new()
		parent.add_child(marker)
		_spirit_ground_markers.append(marker)


func _update_spirit_ground_markers() -> void:
	_ensure_spirit_ground_markers()
	for i: int in spirit_count:
		if i >= _spirit_ground_markers.size():
			break
		var angle: float = _spirit_angle + float(i) * (TAU / maxf(float(spirit_count), 1.0))
		var world_pos: Vector2 = global_position + Vector2.from_angle(angle) * spirit_orbit_radius
		_spirit_ground_markers[i].update_telegraph(
			world_pos,
			spirit_hit_radius,
			_vfx_time + float(i) * 0.4,
			-1.0
		)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_vfx_time += delta
	if _player == null or not is_instance_valid(_player):
		_find_player()
		return
	_line_cooldown -= delta
	if _line_telegraph_left > 0.0:
		_line_telegraph_elapsed += delta
		_line_telegraph_left = maxf(_line_telegraph_left - delta, 0.0)
		if _line_telegraph_left <= 0.0:
			_execute_line_rays()
	_spirit_hit_cooldown_left = maxf(_spirit_hit_cooldown_left - delta, 0.0)
	_spirit_angle = wrapf(_spirit_angle + spirit_orbit_speed * delta, -TAU, TAU)
	if _line_cooldown <= 0.0 and _line_telegraph_left <= 0.0:
		_begin_line_telegraph()
		_line_cooldown = line_attack_interval
	_process_spirit_hits()
	_update_spirit_ground_markers()
	if _ray_flash_timer > 0.0:
		_ray_flash_timer = maxf(_ray_flash_timer - delta, 0.0)
	queue_redraw()


func _begin_line_telegraph() -> void:
	if _player == null:
		return
	var base_dir: Vector2 = (_player.global_position - global_position).normalized()
	if base_dir.length_squared() < 0.001:
		base_dir = Vector2.RIGHT
	_pending_rays.clear()
	if line_ray_count <= 1:
		_pending_rays.append(base_dir)
	else:
		for i: int in line_ray_count:
			var t: float = float(i) / float(line_ray_count - 1)
			var angle_offset: float = lerpf(-line_ray_spread, line_ray_spread, t)
			var dir: Vector2 = base_dir.rotated(angle_offset)
			_pending_rays.append(dir)
	_line_telegraph_left = maxf(line_telegraph_time, 0.08)
	_line_telegraph_elapsed = 0.0


func _execute_line_rays() -> void:
	if _pending_rays.is_empty():
		return
	_recent_rays = _pending_rays.duplicate()
	for dir: Vector2 in _recent_rays:
		_try_damage_player_by_ray(dir)
	_pending_rays.clear()
	_ray_flash_timer = 0.32
	CameraShakeController.shake_active_scene(4.0, 0.16)
	Audio.play_sfx_varied("hit", 0.75, 0.95)


func _try_damage_player_by_ray(ray_dir: Vector2) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var to_player: Vector2 = _player.global_position - global_position
	var along: float = to_player.dot(ray_dir)
	if along < 0.0 or along > line_ray_length:
		return
	var perp: Vector2 = to_player - ray_dir * along
	if perp.length() <= line_ray_width:
		if _player.has_method("take_damage"):
			_player.take_damage(line_ray_damage)


func _process_spirit_hits() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if _spirit_hit_cooldown_left > 0.0:
		return
	var hit: bool = false
	for i: int in spirit_count:
		var angle: float = _spirit_angle + float(i) * (TAU / maxf(float(spirit_count), 1.0))
		var pos: Vector2 = global_position + Vector2.from_angle(angle) * spirit_orbit_radius
		if pos.distance_to(_player.global_position) <= spirit_hit_radius + 16.0:
			hit = true
			break
	if hit and _player.has_method("take_damage"):
		_player.take_damage(spirit_damage)
		_spirit_hit_cooldown_left = spirit_hit_cooldown


func _draw() -> void:
	if _line_telegraph_left > 0.0 and not _pending_rays.is_empty():
		for dir: Vector2 in _pending_rays:
			var end: Vector2 = dir * line_ray_length
			EnemyThreatVfx.draw_line_telegraph(
				self,
				Vector2.ZERO,
				end,
				_line_telegraph_elapsed,
				line_telegraph_time,
				line_ray_width
			)
	if _ray_flash_timer > 0.0:
		var alpha: float = clampf(_ray_flash_timer / 0.32, 0.0, 1.0)
		for dir: Vector2 in _recent_rays:
			EnemyThreatVfx.draw_line_strike_flash(
				self,
				Vector2.ZERO,
				dir * line_ray_length,
				alpha,
				line_ray_width
			)
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
	Audio.play_sfx("enemy_death", randf_range(0.85, 1.0))
	_try_drop_card()
	_spawn_loot_drops()
	defeated.emit()
	queue_free()
