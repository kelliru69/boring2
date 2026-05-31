## Player.gd — Mage y Swordman: habilidades, meta-progresión y cartas equipadas.
class_name Player
extends CharacterBody2D

const _ShapeFactory = preload("res://scripts/util/shape_texture_factory.gd")
const _SpriteLoader = preload("res://scripts/visual/sprite_asset_loader.gd")
const _AnimLoader = preload("res://scripts/visual/sprite_animation_loader.gd")
const _PlayerVisuals = preload("res://data/player_visual_catalog.gd")
const _SkillDefs = preload("res://data/skill_definitions.gd")
const _SkillScaling = preload("res://data/skill_scaling.gd")
const _MageScale = preload("res://data/mage_skill_scaling.gd")
const _SwordmanScaling = preload("res://data/swordman_scaling.gd")
const _MageCombatScript = preload("res://scripts/combat/mage_combat_controller.gd")
const _SwordCombatScript = preload("res://scripts/combat/swordman_combat_controller.gd")
const _HpBarScript = preload("res://scenes/player/PlayerHpBar.gd")
const _DamageNumber = preload("res://scenes/ui/DamageNumber.gd")

signal health_changed(current_hp: int, max_hp: int)
signal player_died

@export_group("Visual")
@export var sprite_height: float = 52.0
@export var procedural_fallback_color: Color = Color(0.35, 0.55, 1.0, 1.0)
@export var aim_indicator_length: float = 40.0

@export_group("Estadísticas")
@export var max_hp: int = 100
@export var move_speed: float = 225.0
@export var cooldown_reduction: float = 0.0
@export var skill_range: float = 400.0

@export_group("Fire Bolt (Mage)")
@export var fire_bolt_damage: int = 25
@export var fire_bolt_interval: float = 0.9
@export var fire_bolt_burst_delay: float = 0.07
@export var fire_bolt_scene: PackedScene

@export_group("Cold Bolt (Mage)")
@export var cold_bolt_damage: int = 18
@export var cold_bolt_interval: float = 2.5
@export var cold_bolt_scene: PackedScene

@export_group("Thunderstorm (Mage)")
@export var thunderstorm_interval: float = 4.0
@export var thunderstorm_scene: PackedScene

@export_group("Lightning / Fire Wall (Mage)")
@export var lightning_bolt_scene: PackedScene = preload("res://scenes/skills/LightningBolt.tscn")
@export var firewall_scene: PackedScene = preload("res://scenes/skills/FireWall.tscn")

@export_group("Sight (Mage)")
@export var sight_tick_damage: int = 6

@export_group("Swordman")
@export var bash_base_damage: int = 22
@export var bash_interval: float = 0.85
@export var bash_scene: PackedScene
@export var magnum_interval: float = 5.0
@export var magnum_base_damage: int = 28
@export var magnum_scene: PackedScene
@export var endure_duration: float = 4.0
@export var endure_defense_bonus: float = 0.5

@export_group("Loot")
@export var loot_magnet_radius: float = 96.0

var class_id: String = "mage"
var current_hp: int = 100
var fire_bolt_level: int = 1
var cold_bolt_level: int = 1
var thunderstorm_level: int = 1
var sight_level: int = 1
var bash_level: int = 1
var magnum_level: int = 1
var magnum_unlocked: bool = false
var cold_bolt_unlocked: bool = false
var thunderstorm_unlocked: bool = false
var sight_unlocked: bool = false

var attack_multiplier: float = 1.0
var defense_multiplier: float = 1.0
var crit_chance: float = 0.0
var _meta_regen_hp: int = 0
var _meta_regen_accum: float = 0.0
var _base_loot_magnet_radius: float = 96.0
var fire_damage_bonus: float = 0.0
var _fire_buff_timer: float = 0.0
var _endure_active: bool = false
var _endure_timer: float = 0.0
var _endure_cooldown: float = 0.0

var _is_dead: bool = false
var _hurt_sfx_cooldown: float = 0.0
var _uses_animation: bool = false
var _action_anim_lock: bool = false
var _last_input_dir: Vector2 = Vector2.ZERO
var _base_modulate: Color = Color.WHITE
var _aim_direction: Vector2 = Vector2.RIGHT
var _burst_in_progress: bool = false
var _cold_burst_in_progress: bool = false
var _damage_invuln_timer: float = 0.0
var _last_aim_draw_dir: Vector2 = Vector2.RIGHT

const DAMAGE_INVULN_SECONDS: float = 0.45

@onready var visual_root: Node2D = $VisualRoot
@onready var animated_visual: AnimatedSprite2D = $VisualRoot/AnimatedSprite2D
@onready var static_visual: Sprite2D = $VisualRoot/Sprite2D
@onready var sight_orb: Node = $Sight
@onready var loot_collector: Area2D = $LootCollector
@onready var fire_bolt_timer: Timer = $SkillTimers/FireBoltTimer
@onready var cold_bolt_timer: Timer = $SkillTimers/ColdBoltTimer
@onready var thunderstorm_timer: Timer = $SkillTimers/ThunderstormTimer
@onready var bash_timer: Timer = $SkillTimers/BashTimer
@onready var magnum_timer: Timer = $SkillTimers/MagnumTimer
@onready var regen_timer: Timer = $SkillTimers/RegenTimer
@onready var floating_hp_bar: ProgressBar = $FloatingHPBar
@onready var hit_sound_player: HitSoundPlayer = $HitSoundPlayer
@onready var active_skills: ActiveSkillController = $ActiveSkills

var _mage_combat: Node = null
var _sword_combat: Node = null
var _base_max_hp: int = 100
var _base_move_speed: float = 225.0
var _firewall_timer: Timer = null


func _ready() -> void:
	class_id = Game.selected_class_id
	add_to_group("Jugador")
	_configure_class_base_stats()
	_base_max_hp = max_hp
	_base_move_speed = move_speed
	_base_loot_magnet_radius = loot_magnet_radius
	Global.apply_run_bonuses_to_player(self)
	current_hp = max_hp
	_apply_player_visual()
	if animated_visual and not animated_visual.animation_finished.is_connected(_on_sprite_animation_finished):
		animated_visual.animation_finished.connect(_on_sprite_animation_finished)
	_setup_combat_controllers()
	_setup_class_skills()
	_setup_floating_hp_bar()
	sync_from_skill_tree()
	if active_skills:
		active_skills.bind_player(self)
	health_changed.emit(current_hp, max_hp)


func _configure_class_base_stats() -> void:
	if class_id == Game.CLASS_SWORDMAN:
		max_hp = 140
		move_speed = 205.0
		procedural_fallback_color = Color(0.85, 0.35, 0.3, 1.0)
	else:
		class_id = Game.CLASS_MAGE


func _setup_combat_controllers() -> void:
	if _mage_combat == null:
		_mage_combat = _MageCombatScript.new()
		_mage_combat.name = "MageCombat"
		add_child(_mage_combat)
	if _sword_combat == null:
		_sword_combat = _SwordCombatScript.new()
		_sword_combat.name = "SwordCombat"
		add_child(_sword_combat)
	if _mage_combat.has_method("setup"):
		_mage_combat.setup(self)
	if _sword_combat.has_method("setup"):
		_sword_combat.setup(self)


func _setup_class_skills() -> void:
	_stop_combat_skill_timers()
	if _mage_combat != null and _mage_combat.has_method("refresh_all"):
		_mage_combat.refresh_all()
	if _sword_combat != null and _sword_combat.has_method("refresh_all"):
		_sword_combat.refresh_all()


func _stop_combat_skill_timers() -> void:
	if fire_bolt_timer:
		fire_bolt_timer.stop()
	if cold_bolt_timer:
		cold_bolt_timer.stop()
	if thunderstorm_timer:
		thunderstorm_timer.stop()
	if bash_timer:
		bash_timer.stop()
	if magnum_timer:
		magnum_timer.stop()
	if _firewall_timer:
		_firewall_timer.stop()


func _ensure_firewall_timer() -> Timer:
	if _firewall_timer == null:
		_firewall_timer = Timer.new()
		_firewall_timer.name = "FirewallTimer"
		var host: Node = get_node_or_null("SkillTimers")
		if host:
			host.add_child(_firewall_timer)
		else:
			add_child(_firewall_timer)
	return _firewall_timer


func _setup_floating_hp_bar() -> void:
	if floating_hp_bar == null:
		return
	floating_hp_bar.set_script(_HpBarScript)
	if floating_hp_bar.has_method("bind_player"):
		floating_hp_bar.bind_player(self)


func apply_meta_bonuses(bonuses: Dictionary) -> void:
	var hp_mult: float = float(bonuses.get("max_hp_mult", 1.0))
	var atk_mult: float = float(bonuses.get("attack_mult", 1.0))
	var move_mult: float = float(bonuses.get("move_speed_mult", 1.0))
	var card_stats: Dictionary = bonuses.get("card_stats", {})
	max_hp = int(round(float(max_hp) * hp_mult))
	max_hp += int(card_stats.get("max_hp_flat", 0))
	max_hp = int(round(float(max_hp) * (1.0 + float(card_stats.get("max_hp_pct", 0.0)))))
	attack_multiplier = atk_mult * (1.0 + float(card_stats.get("attack_pct", 0.0)))
	defense_multiplier = 1.0 + float(bonuses.get("defense_pct", 0.0)) + float(card_stats.get("defense_pct", 0.0))
	move_speed *= move_mult * (1.0 + float(card_stats.get("move_speed_pct", 0.0)))
	cooldown_reduction = clampf(cooldown_reduction + float(card_stats.get("cooldown_pct", 0.0)), -0.5, 0.9)
	crit_chance = clampf(float(bonuses.get("crit_chance", 0.0)), 0.0, 0.95)
	_meta_regen_hp = maxi(int(bonuses.get("regen_hp_per_tick", 0)), 0)
	_meta_regen_accum = 0.0
	var pickup_mult: float = float(bonuses.get("pickup_range_mult", 1.0))
	loot_magnet_radius = _base_loot_magnet_radius * pickup_mult
	current_hp = max_hp


func is_mage() -> bool:
	return class_id == Game.CLASS_MAGE or class_id in [Game.JOB_WIZARD, Game.JOB_SAGE]


func is_swordman() -> bool:
	return class_id == Game.CLASS_SWORDMAN or class_id in [Game.JOB_KNIGHT, Game.JOB_CRUSADER]


func is_alive() -> bool:
	return not _is_dead


func sync_from_skill_tree() -> void:
	class_id = Global.current_class if not Global.current_class.is_empty() else Game.selected_class_id
	fire_bolt_level = maxi(Global.get_skill_level("fire_bolt"), 1)
	cold_bolt_unlocked = Global.get_skill_level("cold_bolt") > 0
	cold_bolt_level = maxi(Global.get_skill_level("cold_bolt"), 1) if cold_bolt_unlocked else 1
	thunderstorm_unlocked = Global.get_skill_level("thunderstorm") > 0
	thunderstorm_level = maxi(Global.get_skill_level("thunderstorm"), 1) if thunderstorm_unlocked else 1
	sight_unlocked = Global.get_skill_level("sight") > 0
	sight_level = maxi(Global.get_skill_level("sight"), 1) if sight_unlocked else 1
	bash_level = maxi(Global.get_skill_level("bash"), 1)
	magnum_unlocked = Global.get_skill_level("magnum_break") > 0
	magnum_level = maxi(Global.get_skill_level("magnum_break"), 1) if magnum_unlocked else 1
	var mastery: int = Global.get_skill_level("sword_mastery")
	if mastery > 0:
		attack_multiplier = maxf(attack_multiplier, 1.0 + _SwordmanScaling.get_sword_mastery_attack_bonus(mastery))
	apply_run_stat_bonuses()
	_setup_class_skills()


func apply_run_stat_bonuses() -> void:
	move_speed = _base_move_speed * Global.get_move_speed_multiplier()


func apply_max_hp_percent_bonus(percent: float) -> void:
	var bonus_hp: int = int(round(float(_base_max_hp) * percent))
	if bonus_hp <= 0:
		return
	max_hp += bonus_hp
	current_hp = mini(current_hp + bonus_hp, max_hp)
	health_changed.emit(current_hp, max_hp)


func get_main_scene() -> Node:
	return get_tree().current_scene


func get_scaled_skill_damage(base: int) -> int:
	var dmg: int = _get_scaled_damage(base)
	if crit_chance > 0.0 and randf() < crit_chance:
		dmg = int(round(float(dmg) * MetaShop.CRIT_DAMAGE_MULT))
	return dmg


func get_auto_skill_interval(base_interval: float) -> float:
	var mult: float = Global.get_attack_speed_multiplier()
	return maxf(base_interval / mult, 0.12)


func get_effective_skill_cooldown(skill_id: String) -> float:
	var base: float = Global.get_skill_cooldown(skill_id)
	if skill_id == "frost_dive":
		base = _MageScale.get_frost_dive_cooldown()
	elif skill_id == "thunderstorm":
		base = _MageScale.get_thunderstorm_cooldown()
	elif skill_id == "magnum_break":
		base = _SwordmanScaling.get_magnum_cooldown()
	elif skill_id == "provoke":
		base = _SwordmanScaling.get_provoke_cooldown()
	return maxf(base * Global.get_active_cooldown_multiplier(), 0.25)


func cast_skill_by_id(skill_id: String) -> bool:
	if _is_dead:
		return false
	match skill_id:
		"frost_dive":
			return _cast_frost_dive()
		"thunderstorm":
			return _cast_thunderstorm_manual()
		"magnum_break":
			return _cast_magnum_manual()
		"provoke":
			return _cast_provoke()
		_:
			return false


func _cast_thunderstorm_manual() -> bool:
	if not is_mage() or thunderstorm_scene == null or Global.get_skill_level("thunderstorm") <= 0:
		return false
	var lv: int = Global.get_skill_level("thunderstorm")
	var target_pos: Vector2 = get_global_mouse_position()
	_cast_thunderstorm_at_delayed(target_pos, lv)
	return true


func _cast_thunderstorm_at_delayed(world_pos: Vector2, lv: int) -> void:
	var delay: float = _MageScale.get_thunderstorm_cast_delay()
	await get_tree().create_timer(delay).timeout
	if _is_dead or not is_instance_valid(self):
		return
	_spawn_thunderstorm_at(world_pos, get_main_scene(), lv)


func _cast_magnum_manual() -> bool:
	if not is_swordman() or magnum_scene == null or Global.get_skill_level("magnum_break") <= 0:
		return false
	var lv: int = Global.get_skill_level("magnum_break")
	_play_action_anim(&"attack")
	var burst: Node = magnum_scene.instantiate()
	if burst == null or not burst.has_method("setup_at_center"):
		return false
	get_main_scene().add_child(burst)
	var dmg: int = int(round(float(get_scaled_skill_damage(magnum_base_damage)) * _SwordmanScaling.get_magnum_damage_mult(lv)))
	burst.setup_at_center(
		global_position,
		_SwordmanScaling.get_magnum_radius(lv),
		dmg
	)
	if burst.has_method("set_knockback_force"):
		burst.knockback_force = _SwordmanScaling.get_magnum_knockback(lv)
	fire_damage_bonus = _SwordmanScaling.get_magnum_fire_buff(lv)
	_fire_buff_timer = 3.0
	return true


func _cast_provoke() -> bool:
	if not is_swordman() or Global.get_skill_level("provoke") <= 0:
		return false
	var lv: int = Global.get_skill_level("provoke")
	var radius: float = _SwordmanScaling.get_provoke_radius(lv)
	var slow: float = _SwordmanScaling.get_provoke_slow_ratio(lv)
	for node: Node in get_tree().get_nodes_in_group(_SkillDefs.GROUP_ENEMIES):
		if not node is CharacterBody2D:
			continue
		var enemy: CharacterBody2D = node as CharacterBody2D
		if global_position.distance_to(enemy.global_position) > radius:
			continue
		if enemy.has_method("apply_freeze"):
			enemy.apply_freeze(_SwordmanScaling.get_provoke_duration(lv), slow)
	return true


func _ensure_timer_connected(timer: Timer, callback: Callable) -> void:
	if timer == null:
		return
	if not timer.timeout.is_connected(callback):
		timer.timeout.connect(callback)


func _connect_timer(timer: Timer, callback: Callable, interval: float) -> void:
	if timer == null:
		return
	_ensure_timer_connected(timer, callback)
	timer.wait_time = _apply_cooldown(interval)
	timer.start()


func _apply_cooldown(base_interval: float) -> float:
	var reduction: float = clampf(cooldown_reduction, 0.0, 0.9)
	return maxf(base_interval * (1.0 - reduction), 0.15)


func _process(delta: float) -> void:
	if _is_dead:
		return
	_aim_direction = _get_mouse_aim_direction()
	if _fire_buff_timer > 0.0:
		_fire_buff_timer = maxf(_fire_buff_timer - delta, 0.0)
		if _fire_buff_timer <= 0.0:
			fire_damage_bonus = 0.0
	if _endure_active:
		_endure_timer = maxf(_endure_timer - delta, 0.0)
		if _endure_timer <= 0.0:
			_endure_active = false
	if _endure_cooldown > 0.0:
		_endure_cooldown = maxf(_endure_cooldown - delta, 0.0)
	if _aim_direction.distance_squared_to(_last_aim_draw_dir) > 0.02:
		_last_aim_draw_dir = _aim_direction
		queue_redraw()
	if _meta_regen_hp > 0:
		_meta_regen_accum += delta
		if _meta_regen_accum >= MetaShop.REGEN_INTERVAL_SEC:
			_meta_regen_accum = 0.0
			heal(_meta_regen_hp)


func _draw() -> void:
	if _is_dead:
		return
	var end: Vector2 = _aim_direction * aim_indicator_length
	var line_color: Color = Color(1.0, 0.55, 0.15, 0.65) if is_mage() else Color(0.95, 0.75, 0.45, 0.7)
	draw_line(Vector2.ZERO, end, line_color, 2.0)


func _physics_process(delta: float) -> void:
	_hurt_sfx_cooldown = maxf(_hurt_sfx_cooldown - delta, 0.0)
	_damage_invuln_timer = maxf(_damage_invuln_timer - delta, 0.0)
	if _is_dead:
		return
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_dir.length_squared() > 0.0001:
		_last_input_dir = input_dir
	velocity = input_dir * move_speed
	move_and_slide()
	if Arena.is_ready():
		_constrain_to_playable()
	_update_facing(input_dir)
	_update_locomotion_anim(input_dir)


func _unhandled_input(event: InputEvent) -> void:
	if active_skills and active_skills.try_handle_input(event):
		get_viewport().set_input_as_handled()


func get_contact_radius() -> float:
	var shape_node: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node and shape_node.shape is CircleShape2D:
		return (shape_node.shape as CircleShape2D).radius * maxf(scale.x, scale.y)
	return 14.0


func _constrain_to_playable() -> void:
	global_position = Arena.clamp_to_playable(global_position, get_contact_radius())


func _get_mouse_aim_direction() -> Vector2:
	var dir: Vector2 = get_global_mouse_position() - global_position
	if dir.length_squared() < 0.001:
		return _aim_direction if _aim_direction.length_squared() > 0.001 else Vector2.RIGHT
	return dir.normalized()


func _get_scaled_damage(base: int) -> int:
	return int(round(float(base) * attack_multiplier))


# --- Mage (legacy timers desactivados; lógica en MageCombatController) ---
func _start_fire_bolt_burst() -> void:
	_burst_in_progress = true
	var direction: Vector2 = _get_mouse_aim_direction()
	for i: int in clampi(fire_bolt_level, 1, SkillTreeCatalog.MAX_SKILL_LEVEL):
		if _is_dead:
			break
		_spawn_fire_bolt(direction)
		if i < fire_bolt_level - 1:
			await get_tree().create_timer(fire_bolt_burst_delay).timeout
	_burst_in_progress = false


func _spawn_fire_bolt(direction: Vector2) -> void:
	var bolt: Node = fire_bolt_scene.instantiate()
	if bolt == null or not bolt.has_method("setup_direction"):
		return
	var parent: Node = get_tree().current_scene
	parent.add_child(bolt)
	if bolt is Node2D:
		(bolt as Node2D).global_position = global_position
	var dmg: int = _get_scaled_damage(fire_bolt_damage)
	dmg = int(round(float(dmg) * (1.0 + fire_damage_bonus)))
	bolt.setup_direction(direction, dmg)
	Audio.play_sfx("fire_bolt", randf_range(0.92, 1.05))


func _on_cold_bolt_timer_timeout() -> void:
	if _is_dead or not is_mage() or not cold_bolt_unlocked or cold_bolt_scene == null or _cold_burst_in_progress:
		return
	_cold_burst_in_progress = true
	await _fire_cold_bolt_burst()
	_cold_burst_in_progress = false


func _fire_cold_bolt_burst() -> void:
	for i: int in _SkillScaling.get_cold_bolt_burst_count(cold_bolt_level):
		if _is_dead:
			return
		var target: Node2D = _find_highest_max_hp_enemy_in_range()
		if target == null:
			return
		var bolt: Node = cold_bolt_scene.instantiate()
		if bolt == null:
			return
		get_tree().current_scene.add_child(bolt)
		if bolt is Node2D:
			(bolt as Node2D).global_position = global_position
		bolt.setup_target(target, _get_scaled_damage(cold_bolt_damage))
		if i < _SkillScaling.get_cold_bolt_burst_count(cold_bolt_level) - 1:
			await get_tree().create_timer(0.12).timeout


func _on_thunderstorm_timer_timeout() -> void:
	if _is_dead or not is_mage() or not thunderstorm_unlocked or thunderstorm_scene == null:
		return
	var enemies: Array[Node] = get_tree().get_nodes_in_group(_SkillDefs.GROUP_ENEMIES)
	if enemies.is_empty():
		return
	var pick: Node2D = enemies[randi() % enemies.size()] as Node2D
	if pick:
		_spawn_thunderstorm_at(pick.global_position, get_tree().current_scene)


func _cast_frost_dive() -> bool:
	if not is_mage() or Global.get_skill_level("frost_dive") <= 0:
		return false
	var lv: int = Global.get_skill_level("frost_dive")
	var center: Vector2 = get_global_mouse_position()
	var radius: float = _MageScale.get_frost_dive_radius(lv)
	var dmg: int = int(round(float(_get_scaled_damage(cold_bolt_damage)) * _MageScale.get_frost_dive_damage_mult(lv)))
	var stun: float = _MageScale.get_frost_dive_stun_duration(lv)
	_damage_enemies_in_circle(center, radius, dmg, stun)
	var line_len: float = _MageScale.get_frost_dive_line_length(lv)
	if line_len > 0.0:
		var dir: Vector2 = _get_mouse_aim_direction()
		var steps: int = 4
		for i: int in steps:
			var t: float = float(i + 1) / float(steps)
			var point: Vector2 = global_position + dir * line_len * t
			_damage_enemies_in_circle(point, radius * 0.65, dmg, stun)
	return true


func _damage_enemies_in_circle(center: Vector2, radius: float, damage: int, stun_sec: float) -> void:
	for node: Node in get_tree().get_nodes_in_group(_SkillDefs.GROUP_ENEMIES):
		if not node is Node2D:
			continue
		var enemy: Node2D = node as Node2D
		if center.distance_to(enemy.global_position) > radius:
			continue
		if enemy.has_method("take_damage"):
			enemy.take_damage(damage)
		if enemy.has_method("apply_freeze"):
			enemy.apply_freeze(stun_sec, 0.0)


func _spawn_thunderstorm_at(world_pos: Vector2, parent: Node, lv: int = 1) -> void:
	var storm: Node = thunderstorm_scene.instantiate()
	if storm == null:
		return
	parent.add_child(storm)
	if storm is Node2D:
		(storm as Node2D).global_position = world_pos
	if storm.has_method("setup_level"):
		var base_dmg: int = int(round(float(get_scaled_skill_damage(12)) * _MageScale.get_thunderstorm_damage_mult(lv)))
		storm.setup_level(lv, base_dmg)
		if storm.has_method("set_radius_override"):
			storm.set_radius_override(_MageScale.get_thunderstorm_radius(lv))


# --- Swordman ---
func _on_regen_timer_timeout() -> void:
	if _is_dead or not is_swordman():
		return
	heal(1)


func _on_magnum_timer_timeout() -> void:
	if _is_dead or not is_swordman() or not magnum_unlocked or magnum_scene == null:
		return
	_play_action_anim(&"attack")
	var burst: Node = magnum_scene.instantiate()
	if burst == null or not burst.has_method("setup_at_center"):
		return
	get_tree().current_scene.add_child(burst)
	var lv: int = magnum_level
	var dmg: int = int(round(float(get_scaled_skill_damage(magnum_base_damage)) * _SwordmanScaling.get_magnum_damage_mult(lv)))
	burst.setup_at_center(
		global_position,
		_SwordmanScaling.get_magnum_radius(lv),
		dmg
	)
	var buff: float = _SwordmanScaling.get_magnum_fire_buff(lv)
	fire_damage_bonus = buff
	_fire_buff_timer = 3.0


func _activate_endure() -> void:
	_endure_active = true
	_endure_timer = endure_duration
	_endure_cooldown = endure_duration + 2.0


func _find_nearest_enemy_in_range() -> Node2D:
	var best: Node2D = null
	var best_dist_sq: float = INF
	var range_sq: float = skill_range * skill_range
	for node: Node in get_tree().get_nodes_in_group(_SkillDefs.GROUP_ENEMIES):
		if not node is Node2D:
			continue
		var enemy: Node2D = node as Node2D
		var dist_sq: float = global_position.distance_squared_to(enemy.global_position)
		if dist_sq > range_sq:
			continue
		if dist_sq < best_dist_sq:
			best_dist_sq = dist_sq
			best = enemy
	return best


func _find_highest_max_hp_enemy_in_range() -> Node2D:
	var best: Node2D = null
	var best_hp: int = -1
	var range_sq: float = skill_range * skill_range
	for node: Node in get_tree().get_nodes_in_group(_SkillDefs.GROUP_ENEMIES):
		if not node is Node2D:
			continue
		var enemy: Node2D = node as Node2D
		if global_position.distance_squared_to(enemy.global_position) > range_sq:
			continue
		var ehp: int = int(enemy.max_hp) if enemy.get("max_hp") != null else 0
		if ehp > best_hp:
			best_hp = ehp
			best = enemy
	return best


func _apply_player_visual() -> void:
	_uses_animation = false
	if animated_visual:
		animated_visual.visible = false
	if static_visual:
		static_visual.visible = true
	var debug_color: Color = Color(0.35, 0.55, 1.0, 1.0)
	if static_visual and static_visual.has_method("apply_visual"):
		static_visual.apply_visual(_ShapeFactory.Shape.SQUARE, debug_color)
	_set_visual_modulate(debug_color)


func _set_visual_modulate(color: Color) -> void:
	if animated_visual and animated_visual.visible:
		animated_visual.modulate = color
	if static_visual and static_visual.visible:
		static_visual.modulate = color


func _get_visual_target() -> CanvasItem:
	if _uses_animation and animated_visual:
		return animated_visual
	return static_visual


func _update_facing(input_dir: Vector2) -> void:
	if input_dir.x == 0.0:
		return
	var flip: bool = input_dir.x < 0.0
	if animated_visual and animated_visual.visible:
		animated_visual.flip_h = flip
	elif static_visual:
		static_visual.flip_h = flip


func _update_locomotion_anim(input_dir: Vector2) -> void:
	if not _uses_animation or animated_visual == null or _is_dead or _action_anim_lock:
		return
	var moving: bool = input_dir.length_squared() > 0.0001
	var target: StringName = &"walk" if moving else &"idle"
	if animated_visual.animation != target:
		animated_visual.play(target)
	elif not animated_visual.is_playing():
		animated_visual.play(target)


func _play_action_anim(anim_name: StringName) -> void:
	if not _uses_animation or animated_visual == null or animated_visual.sprite_frames == null:
		return
	if not animated_visual.sprite_frames.has_animation(anim_name):
		return
	_action_anim_lock = true
	animated_visual.play(anim_name)


func _on_sprite_animation_finished() -> void:
	if not _uses_animation or animated_visual == null:
		return
	var finished: StringName = animated_visual.animation
	if finished == &"hurt" or finished == &"attack":
		_action_anim_lock = false
		if not _is_dead:
			_update_locomotion_anim(_last_input_dir)


func is_loot_in_magnet_range(world_pos: Vector2) -> bool:
	return global_position.distance_to(world_pos) <= loot_magnet_radius


func _refresh_cold_bolt_timer() -> void:
	if cold_bolt_timer == null or not is_mage():
		return
	_ensure_timer_connected(cold_bolt_timer, _on_cold_bolt_timer_timeout)
	cold_bolt_timer.stop()
	if cold_bolt_unlocked:
		var mult: float = _SkillScaling.get_cold_bolt_cooldown_multiplier(cold_bolt_level)
		cold_bolt_timer.wait_time = _apply_cooldown(cold_bolt_interval * mult)
		cold_bolt_timer.start()


func _refresh_thunderstorm_timer() -> void:
	if thunderstorm_timer == null or not is_mage():
		return
	_ensure_timer_connected(thunderstorm_timer, _on_thunderstorm_timer_timeout)
	thunderstorm_timer.stop()
	if thunderstorm_unlocked:
		thunderstorm_timer.wait_time = _apply_cooldown(thunderstorm_interval)
		thunderstorm_timer.start()


func take_damage(amount: int) -> void:
	if _is_dead or amount <= 0 or _damage_invuln_timer > 0.0:
		return
	var mitigated: int = amount
	var endure_lv: int = Global.get_skill_level("endure")
	if endure_lv > 0:
		var reduction: float = _SwordmanScaling.get_endure_damage_reduction(endure_lv)
		mitigated = int(round(float(amount) * (1.0 - reduction)))
	if _endure_active:
		mitigated = int(round(float(mitigated) * (1.0 - endure_defense_bonus)))
	mitigated = int(round(float(mitigated) / maxf(defense_multiplier, 0.1)))
	current_hp = maxi(current_hp - mitigated, 0)
	_damage_invuln_timer = DAMAGE_INVULN_SECONDS
	if mitigated > 0:
		_show_hurt_damage_number(mitigated)
	if _hurt_sfx_cooldown <= 0.0:
		if hit_sound_player:
			hit_sound_player.play_hit(global_position, randf_range(0.92, 1.05))
		else:
			Audio.play_sfx("player_hurt")
		_hurt_sfx_cooldown = 0.4
	_flash_hurt()
	health_changed.emit(current_hp, max_hp)
	if current_hp <= 0:
		_die()


func _show_hurt_damage_number(amount: int) -> void:
	var parent: Node = get_tree().current_scene
	if parent == null:
		return
	var hurt_color: Color = Color(1.0, 0.22, 0.22)
	_DamageNumber.spawn(global_position + Vector2(0.0, -18.0), amount, parent, hurt_color)


func _flash_hurt() -> void:
	if _uses_animation and animated_visual:
		_play_action_anim(&"hurt")
	var target: CanvasItem = _get_visual_target()
	if target == null:
		return
	target.modulate = Color(1.4, 0.5, 0.5)
	var tween: Tween = create_tween()
	tween.tween_property(target, "modulate", _base_modulate, 0.15)


func heal(amount: int) -> void:
	if _is_dead or amount <= 0:
		return
	current_hp = mini(current_hp + amount, max_hp)
	health_changed.emit(current_hp, max_hp)


func heal_percent_of_max(ratio: float) -> void:
	heal(int(round(float(max_hp) * clampf(ratio, 0.0, 1.0))))


func increase_max_hp(amount: int) -> void:
	max_hp += amount
	current_hp = mini(current_hp + amount, max_hp)
	health_changed.emit(current_hp, max_hp)


func increase_move_speed(percent: float) -> void:
	move_speed *= 1.0 + percent


func increase_fire_damage(amount: int) -> void:
	fire_bolt_damage += amount
	bash_base_damage += amount


func increase_skill_range(amount: float) -> void:
	skill_range += amount


func upgrade_fire_bolt_level() -> void:
	fire_bolt_level = mini(fire_bolt_level + 1, 3)


func unlock_cold_bolt() -> void:
	cold_bolt_unlocked = true
	_refresh_cold_bolt_timer()


func unlock_thunderstorm() -> void:
	thunderstorm_unlocked = true
	_refresh_thunderstorm_timer()


func unlock_sight() -> void:
	sight_unlocked = true
	if sight_orb and sight_orb.has_method("set_active"):
		sight_orb.set_active(true)


func upgrade_cold_bolt_level() -> void:
	if not cold_bolt_unlocked:
		unlock_cold_bolt()
	cold_bolt_level = mini(cold_bolt_level + 1, _SkillScaling.MAX_SKILL_LEVEL)
	_refresh_cold_bolt_timer()


func upgrade_thunderstorm_level() -> void:
	if not thunderstorm_unlocked:
		unlock_thunderstorm()
	thunderstorm_level = mini(thunderstorm_level + 1, _SkillScaling.MAX_SKILL_LEVEL)


func upgrade_sight_level() -> void:
	if not sight_unlocked:
		unlock_sight()
	sight_level = mini(sight_level + 1, _SkillScaling.MAX_SKILL_LEVEL)


func upgrade_bash_level() -> void:
	bash_level = mini(bash_level + 1, _SwordmanScaling.MAX_LEVEL)


func unlock_magnum_break() -> void:
	magnum_unlocked = true
	magnum_level = maxi(magnum_level, 1)
	_refresh_magnum_timer()


func upgrade_magnum_level() -> void:
	if not magnum_unlocked:
		unlock_magnum_break()
		return
	magnum_level = mini(magnum_level + 1, _SwordmanScaling.MAX_LEVEL)


func _refresh_magnum_timer() -> void:
	if magnum_timer == null or not is_swordman():
		return
	_ensure_timer_connected(magnum_timer, _on_magnum_timer_timeout)
	magnum_timer.stop()
	if magnum_unlocked:
		magnum_timer.wait_time = _apply_cooldown(magnum_interval)
		magnum_timer.start()


func apply_cooldown_reduction(bonus: float) -> void:
	cooldown_reduction = clampf(cooldown_reduction + bonus, 0.0, 0.9)
	_setup_class_skills()
	_refresh_magnum_timer()


func _die() -> void:
	_is_dead = true
	if _uses_animation and animated_visual:
		_action_anim_lock = true
		animated_visual.play(&"death")
	for t: Timer in [fire_bolt_timer, cold_bolt_timer, thunderstorm_timer, bash_timer, magnum_timer, regen_timer]:
		if t:
			t.stop()
	if sight_orb and sight_orb.has_method("set_active"):
		sight_orb.set_active(false)
	player_died.emit()
	set_physics_process(false)
	set_process(false)
