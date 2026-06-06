## Timers y ejecución de habilidades automáticas / autónomas del Mage.
class_name MageCombatController
extends Node

const _MageScale = preload("res://data/mage_skill_scaling.gd")
const _SkillDefs = preload("res://data/skill_definitions.gd")
const _Vfx = preload("res://scripts/vfx/elemental_vfx_spawner.gd")
const _VfxSpawn = preload("res://scripts/vfx/vfx_spawn_helper.gd")

var _player: Node2D = null
var _timers: Dictionary = {}
var _busy: Dictionary = {}


func setup(player: Node2D) -> void:
	_player = player
	_ensure_timers()
	refresh_all()


func refresh_all() -> void:
	_stop_all()
	if _player == null or not _player.is_mage():
		return
	_bind_sight()
	if Global.get_skill_level("soul_strike") > 0 and not Global.is_skill_disabled_for_combat("soul_strike"):
		_start_timer("soul_strike", _MageScale.get_soul_strike_burst_interval(Global.get_skill_level("soul_strike")))
	if Global.get_skill_level("cold_bolt") > 0 and not Global.is_skill_disabled_for_combat("cold_bolt"):
		_start_timer("cold_bolt", _MageScale.get_cold_bolt_interval())
	if Global.get_skill_level("fire_bolt") > 0 and not Global.is_skill_disabled_for_combat("fire_bolt"):
		_start_timer("fire_bolt", _MageScale.get_fire_bolt_interval())
	if Global.get_skill_level("lightning_bolt") > 0 and not Global.is_skill_disabled_for_combat("lightning_bolt"):
		_start_timer("lightning_bolt", _MageScale.get_lightning_interval())
	if Global.get_skill_level("firewall") > 0 and not Global.is_skill_disabled_for_combat("firewall"):
		_start_timer("firewall", _MageScale.get_firewall_interval())


func _ensure_timers() -> void:
	var ids: Array[String] = ["soul_strike", "cold_bolt", "fire_bolt", "lightning_bolt", "firewall"]
	for skill_id: String in ids:
		if _timers.has(skill_id):
			continue
		var timer: Timer = Timer.new()
		timer.name = "Timer_%s" % skill_id
		timer.process_callback = Timer.TIMER_PROCESS_IDLE
		add_child(timer)
		timer.timeout.connect(_on_timer_timeout.bind(skill_id))
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
	_busy.clear()


func _on_timer_timeout(skill_id: String) -> void:
	if _player == null or not _player.is_alive():
		return
	if _busy.get(skill_id, false):
		return
	match skill_id:
		"soul_strike":
			_cast_soul_strike()
		"cold_bolt":
			_cast_cold_bolt()
		"fire_bolt":
			_cast_fire_bolt()
		"lightning_bolt":
			_cast_lightning_bolt()
		"firewall":
			_cast_firewall()


func _bind_sight() -> void:
	if _player.sight_orb == null:
		return
	var lv: int = Global.get_skill_level("sight")
	if _player.sight_orb.has_method("bind_player"):
		_player.sight_orb.bind_player(_player)
	if _player.sight_orb.has_method("set_active"):
		_player.sight_orb.set_active(lv > 0)
	if lv > 0 and _player.sight_orb.has_method("apply_mage_level"):
		_player.sight_orb.apply_mage_level(lv, _player.get_scaled_skill_damage(_player.sight_tick_damage))


func _cast_soul_strike() -> void:
	var lv: int = Global.get_skill_level("soul_strike")
	if lv <= 0 or _player.fire_bolt_scene == null:
		return
	_busy["soul_strike"] = true
	_player._play_action_anim(&"attack")
	var direction: Vector2 = _player._get_mouse_aim_direction()
	var count: int = _MageScale.get_soul_strike_spirit_count(lv)
	var stagger: float = _MageScale.get_soul_strike_stagger(lv)
	var dmg: int = int(round(float(_player.get_scaled_skill_damage(_player.fire_bolt_damage)) * _MageScale.get_soul_strike_damage_mult(lv)))
	for i: int in count:
		if _player._is_dead:
			break
		_spawn_fire_bolt(direction, dmg, _Vfx.TRAIL_PRESET_SOUL)
		if i < count - 1 and stagger > 0.0:
			await get_tree().create_timer(stagger).timeout
	_busy["soul_strike"] = false


func _cast_cold_bolt() -> void:
	var lv: int = Global.get_skill_level("cold_bolt")
	if lv <= 0 or _player.cold_bolt_scene == null:
		return
	_busy["cold_bolt"] = true
	var count: int = _MageScale.get_cold_bolt_hit_count(lv)
	var slow: float = _MageScale.get_cold_bolt_slow_ratio(lv)
	var dmg: int = int(round(float(_player.get_scaled_skill_damage(_player.cold_bolt_damage)) * _MageScale.get_cold_bolt_damage_mult(lv)))
	for _i: int in count:
		var target: Node2D = _pick_random_enemy()
		if target == null:
			break
		var bolt: Node = _player.cold_bolt_scene.instantiate()
		if bolt == null:
			continue
		_VfxSpawn.add_child_at_world(_player.get_main_scene(), bolt as Node2D, _player.global_position)
		if bolt.has_method("setup_target"):
			bolt.setup_target(target, dmg)
		if bolt.has_method("set_slow_ratio"):
			bolt.set_slow_ratio(slow)
		elif bolt.get("freeze_slow_ratio") != null:
			bolt.freeze_slow_ratio = slow
		_player.try_fusion_autocast_duplicate_bolt(Vector2.ZERO, dmg, _Vfx.TRAIL_PRESET_ICE, "cold")
		await get_tree().create_timer(0.1).timeout
	_busy["cold_bolt"] = false


func _cast_fire_bolt() -> void:
	var lv: int = Global.get_skill_level("fire_bolt")
	if lv <= 0 or _player.fire_bolt_scene == null:
		return
	_busy["fire_bolt"] = true
	var target: Node2D = _player._find_nearest_enemy_in_range()
	if target == null:
		_busy["fire_bolt"] = false
		return
	var direction: Vector2 = (target.global_position - _player.global_position).normalized()
	var count: int = _MageScale.get_fire_bolt_hit_count(lv)
	var dmg: int = int(round(float(_player.get_scaled_skill_damage(_player.fire_bolt_damage)) * _MageScale.get_fire_bolt_damage_mult(lv)))
	for i: int in count:
		_spawn_fire_bolt(direction, dmg, _Vfx.TRAIL_PRESET_FIRE)
		if i < count - 1:
			await get_tree().create_timer(_MageScale.get_fire_bolt_stagger()).timeout
	_busy["fire_bolt"] = false


func _cast_lightning_bolt() -> void:
	var lv: int = Global.get_skill_level("lightning_bolt")
	if lv <= 0:
		return
	var scene: PackedScene = _player.lightning_bolt_scene
	if scene == null:
		return
	_busy["lightning_bolt"] = true
	var count: int = _MageScale.get_lightning_projectile_count(lv)
	var spread: float = _MageScale.get_lightning_angle_spread(count)
	var base_dir: Vector2 = Vector2.from_angle(randf() * TAU)
	var dmg: int = int(round(float(_player.get_scaled_skill_damage(_player.fire_bolt_damage)) * _MageScale.get_lightning_damage_mult(lv)))
	var dist: float = _MageScale.get_lightning_travel_distance(lv)
	for i: int in count:
		var angle_off: float = 0.0
		if count > 1:
			angle_off = lerpf(-spread, spread, float(i) / float(count - 1))
		var dir: Vector2 = base_dir.rotated(angle_off)
		var bolt: Node = scene.instantiate()
		if bolt == null:
			continue
		_VfxSpawn.add_child_at_world(_player.get_main_scene(), bolt as Node2D, _player.global_position)
		if bolt.has_method("setup_boomerang"):
			bolt.setup_boomerang(dir, dmg, dist)
		_player.try_fusion_autocast_duplicate_bolt(dir, dmg, _Vfx.TRAIL_PRESET_LIGHTNING, "lightning")
		await get_tree().create_timer(0.06).timeout
	_busy["lightning_bolt"] = false


func _cast_firewall() -> void:
	var lv: int = Global.get_skill_level("firewall")
	if lv <= 0 or _player.firewall_scene == null:
		return
	var count: int = _MageScale.get_firewall_barrier_count(lv)
	var offset: float = _MageScale.get_firewall_offset_distance(lv)
	var dmg: int = int(round(float(_player.get_scaled_skill_damage(18)) * _MageScale.get_firewall_damage_mult(lv)))
	var kb: float = _MageScale.get_firewall_knockback(lv)
	var tile_count: int = _MageScale.get_firewall_tile_count(lv)
	var tile_px: float = 32.0
	if _player.has_method("get_depth_tile_size_px"):
		tile_px = float(_player.call("get_depth_tile_size_px"))
	var life: float = _MageScale.get_firewall_duration()
	var sides: Array[Vector2] = [Vector2.LEFT]
	if count >= 2:
		sides.append(Vector2.RIGHT)
	for side: Vector2 in sides:
		var raw_pos: Vector2 = _player.global_position + side * offset
		var pos: Vector2 = _MageScale.snap_wall_anchor(raw_pos, tile_px)
		var wall: Node = _player.firewall_scene.instantiate()
		if wall == null:
			continue
		_VfxSpawn.add_child_at_world(_player.get_main_scene(), wall as Node2D, pos)
		if wall.has_method("setup_barrier"):
			wall.setup_barrier(pos, tile_count, tile_px, dmg, kb, life, side)


func _spawn_fire_bolt(direction: Vector2, dmg: int, trail_preset: StringName = _Vfx.TRAIL_PRESET_FIRE) -> void:
	var bolt: Node = _player.fire_bolt_scene.instantiate()
	if bolt == null:
		return
	if bolt.has_method("set_trail_preset"):
		bolt.set_trail_preset(trail_preset)
	_VfxSpawn.add_child_at_world(_player.get_main_scene(), bolt as Node2D, _player.global_position)
	if bolt.has_method("setup_direction"):
		bolt.setup_direction(direction, dmg)
	_player.try_fusion_autocast_duplicate_bolt(direction, dmg, trail_preset, "fire")


func _pick_random_enemy() -> Node2D:
	var in_range: Array[Node2D] = []
	for node: Node in _player.get_tree().get_nodes_in_group(_SkillDefs.GROUP_ENEMIES):
		if node is Node2D and _player.global_position.distance_squared_to((node as Node2D).global_position) <= _player.skill_range * _player.skill_range:
			in_range.append(node as Node2D)
	if in_range.is_empty():
		return null
	return in_range[randi() % in_range.size()]
