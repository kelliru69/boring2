## Timers y habilidades automáticas del Swordman.
class_name SwordmanCombatController
extends Node

const _SwordScale = preload("res://data/swordman_scaling.gd")

var _player: Node2D = null
var _timers: Dictionary = {}


func setup(player: Node2D) -> void:
	_player = player
	_ensure_timers()
	refresh_all()


func refresh_all() -> void:
	_stop_all()
	if _player == null or not _player.is_swordman():
		return
	if Global.get_skill_level("bash") > 0:
		_start_timer("bash", _SwordScale.get_bash_burst_interval(Global.get_skill_level("bash")))
	if Global.get_skill_level("hp_recovery") > 0:
		_start_timer("hp_recovery", _SwordScale.get_hp_recovery_interval(Global.get_skill_level("hp_recovery")))


func _ensure_timers() -> void:
	for skill_id: String in ["bash", "hp_recovery"]:
		if _timers.has(skill_id):
			continue
		var timer: Timer = Timer.new()
		timer.name = "Timer_%s" % skill_id
		add_child(timer)
		timer.timeout.connect(_on_timeout.bind(skill_id))
		_timers[skill_id] = timer


func _start_timer(skill_id: String, interval: float) -> void:
	var timer: Timer = _timers.get(skill_id) as Timer
	if timer and _player:
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
		"hp_recovery":
			_player.heal(_SwordScale.get_hp_recovery_amount(Global.get_skill_level("hp_recovery")))


func _cast_bash() -> void:
	var lv: int = Global.get_skill_level("bash")
	if lv <= 0 or _player.bash_scene == null:
		return
	var forward: Vector2 = _player._last_input_dir
	if forward.length_squared() < 0.01:
		forward = _player._get_mouse_aim_direction()
	if forward.length_squared() < 0.01:
		forward = Vector2.RIGHT
	forward = forward.normalized()
	var count: int = _SwordScale.get_bash_hit_count(lv)
	var dmg: int = int(round(float(_player.get_scaled_skill_damage(_player.bash_base_damage)) * _SwordScale.get_bash_damage_mult(lv)))
	var stun: float = _SwordScale.get_bash_stun_chance(lv)
	for _i: int in count:
		_player._play_action_anim(&"attack")
		var arc: Node = _player.bash_scene.instantiate()
		if arc == null or not arc.has_method("setup_from_player"):
			return
		_player.get_main_scene().add_child(arc)
		arc.setup_from_player(
			_player.global_position,
			forward,
			dmg,
			_SwordScale.get_bash_radius(lv),
			_SwordScale.get_bash_arc_angle(lv),
			stun
		)
