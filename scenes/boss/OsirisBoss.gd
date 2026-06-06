## Escena legada (no usada en run). Jefe de Payon: MoonlightFlowerBoss.
class_name OsirisBoss
extends Enemy

signal defeated
signal boss_health_changed(current_hp: int, max_hp: int)

const _MapConfig = preload("res://data/map_config.gd")

@export var aoe_interval: float = 4.5
@export var aoe_radius: float = 95.0
@export var aoe_damage: int = 38
@export var visual_scale: float = 3.0

@export var aoe_telegraph_scene: PackedScene

var _aoe_cooldown: float = 2.0

@onready var hp_bar: ProgressBar = $UI/HPBar


func _ready() -> void:
	enemy_type = "osiris"
	super._ready()
	dies_on_player_contact = false
	max_hp = 2000
	current_hp = max_hp
	move_speed = 130.0
	_base_move_speed = move_speed
	contact_damage = int(round(22.0 * RunBalance.MOB_CONTACT_DAMAGE_MULTIPLIER))
	aoe_damage = int(round(float(aoe_damage) * RunBalance.MOB_CONTACT_DAMAGE_MULTIPLIER))
	zeny_reward = 250
	xp_reward = 600
	_display_name = "Osiris"
	if visual_root:
		visual_root.scale = Vector2(visual_scale, visual_scale)
		_set_visual_modulate(Color(0.55, 0.85, 0.35))
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = current_hp


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_aoe_cooldown -= delta
	if _aoe_cooldown <= 0.0:
		_cast_area_burst()
		_aoe_cooldown = aoe_interval


func _cast_area_burst() -> void:
	if _player == null or not is_instance_valid(_player):
		_find_player()
		return
	if aoe_telegraph_scene == null:
		if _player.has_method("take_damage"):
			if _player.global_position.distance_to(global_position) <= aoe_radius + 40.0:
				_player.take_damage(aoe_damage)
		return
	var telegraph: Node2D = aoe_telegraph_scene.instantiate() as Node2D
	if telegraph == null:
		return
	get_tree().current_scene.add_child(telegraph)
	telegraph.global_position = _player.global_position
	if telegraph.has_method("configure"):
		telegraph.configure(aoe_radius, 1.6, aoe_damage)


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
	Audio.play_sfx("enemy_death", randf_range(0.8, 1.0))
	_try_drop_card()
	_spawn_loot_drops()
	Loot.vacuum_all_on_map(get_tree())
	defeated.emit()
	queue_free()
