## Timers y habilidades automáticas / autónomas del Swordman.
class_name SwordmanCombatController
extends Node

const _SwordScale = preload("res://data/swordman_scaling.gd")
const _VfxSpawn = preload("res://scripts/vfx/vfx_spawn_helper.gd")

const _AUTO_TIMER_SKILLS: Array[String] = [
	"bash",
	"magnum_break",
	"moving_recovery",
	"spear_stab",
]

var _player: Player = null
var _timers: Dictionary = {}


func setup(player: Node2D) -> void:
	_player = player as Player
	_ensure_timers()
	refresh_all()


func refresh_all() -> void:
	_stop_all()
	if _player == null or not _player.is_swordman():
		return
	if Global.get_skill_level("bash") > 0 and not Global.is_skill_disabled_for_combat("bash"):
		_start_timer("bash", _SwordScale.get_bash_burst_interval(Global.get_skill_level("bash")))
	if Global.get_skill_level("magnum_break") > 0 and not Global.is_skill_disabled_for_combat("magnum_break"):
		_start_timer("magnum_break", _SwordScale.get_magnum_cooldown())
	if Global.get_skill_level("moving_recovery") > 0 and not Global.is_skill_disabled_for_combat("moving_recovery"):
		_start_timer("moving_recovery", _SwordScale.get_moving_recovery_interval())
	if Global.get_skill_level("spear_stab") > 0 and not Global.is_skill_disabled_for_combat("spear_stab"):
		_start_timer("spear_stab", _SwordScale.get_spear_stab_cooldown())
	if _player.has_method("sync_increase_hp_recovery_levels"):
		_player.sync_increase_hp_recovery_levels()


func _ensure_timers() -> void:
	for skill_id: String in _AUTO_TIMER_SKILLS:
		if _timers.has(skill_id):
			continue
		var timer: Timer = Timer.new()
		timer.name = "Timer_%s" % skill_id
		timer.process_callback = Timer.TIMER_PROCESS_IDLE
		add_child(timer)
		timer.timeout.connect(_on_timeout.bind(skill_id))
		_timers[skill_id] = timer


func _start_timer(skill_id: String, interval: float) -> void:
	var timer: Timer = _timers.get(skill_id) as Timer
	if timer == null or _player == null:
		return
	timer.wait_time = _player.get_auto_skill_interval(interval)
	timer.start()


func _stop_all() -> void:
	for skill_id: String in _timers:
		var timer: Timer = _timers[skill_id] as Timer
		if timer:
			timer.stop()


func _on_timeout(skill_id: String) -> void:
	if _player == null or not _player.is_alive():
		return
	match skill_id:
		"bash":
			_cast_bash()
		"magnum_break":
			_cast_magnum_break()
		"moving_recovery":
			_cast_moving_recovery()
		"spear_stab":
			_cast_spear_stab()


func _aim_direction() -> Vector2:
	var forward: Vector2 = _player._get_mouse_aim_direction()
	if forward.length_squared() < 0.01:
		forward = _player._last_input_dir
	if forward.length_squared() < 0.01:
		forward = Vector2.RIGHT
	return forward.normalized()


func _cast_bash() -> void:
	var lv: int = Global.get_skill_level("bash")
	if lv <= 0 or _player.bash_scene == null:
		return
	var forward: Vector2 = _aim_direction()
	var dmg: int = _player.get_scaled_melee_damage(_player.bash_base_damage, _SwordScale.get_bash_damage_mult(lv))
	var stun: float = _SwordScale.get_bash_stun_chance(lv)
	_player._play_action_anim(&"attack")
	var arc: Node = _player.bash_scene.instantiate()
	if arc == null or not arc.has_method("setup_from_player"):
		return
	_VfxSpawn.add_child_at_world(_player.get_main_scene(), arc as Node2D, _player.global_position)
	arc.setup_from_player(
		_player.global_position,
		forward,
		dmg,
		_SwordScale.get_bash_radius(lv),
		_SwordScale.get_bash_arc_angle(lv),
		stun,
		_SwordScale.get_bash_stun_duration(),
		_player
	)


func _cast_magnum_break() -> void:
	var lv: int = Global.get_skill_level("magnum_break")
	if lv <= 0 or _player.magnum_scene == null:
		return
	_player._play_action_anim(&"attack")
	var burst: Node = _player.magnum_scene.instantiate()
	if burst == null or not burst.has_method("setup_at_center"):
		return
	_VfxSpawn.add_child_at_world(_player.get_main_scene(), burst as Node2D, _player.global_position)
	var dmg: int = _player.get_scaled_melee_damage(_player.magnum_base_damage, _SwordScale.get_magnum_damage_mult(lv))
	burst.setup_at_center(
		_player.global_position,
		_SwordScale.get_magnum_radius(lv),
		dmg
	)
	if burst.has_method("set_knockback_force"):
		burst.knockback_force = _SwordScale.get_magnum_knockback(lv)
	if _player.has_method("apply_magnum_fire_buff"):
		_player.apply_magnum_fire_buff()


func _cast_moving_recovery() -> void:
	if _player.has_method("heal_missing_percent"):
		_player.heal_missing_percent(_SwordScale.get_moving_recovery_missing_ratio())


func _cast_spear_stab() -> void:
	var lv: int = Global.get_skill_level("spear_stab")
	if lv <= 0 or _player.spear_stab_scene == null:
		return
	var forward: Vector2 = _aim_direction()
	var dmg: int = _player.get_scaled_melee_damage(
		_player.spear_stab_base_damage,
		_SwordScale.get_spear_stab_damage_mult(lv)
	)
	_player._play_action_anim(&"attack")
	var slash: Node = _player.spear_stab_scene.instantiate()
	if slash == null or not slash.has_method("setup_from_player"):
		return
	_VfxSpawn.add_child_at_world(_player.get_main_scene(), slash as Node2D, _player.global_position)
	slash.setup_from_player(
		_player.global_position,
		forward,
		dmg,
		_SwordScale.get_spear_stab_width(lv),
		_SwordScale.get_spear_stab_length(lv),
		_SwordScale.get_spear_stab_knockback(lv)
	)
