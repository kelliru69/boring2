## Sight — orbes orbitales; daño por contacto permisivo + pulsos de área.
class_name Sight
extends Area2D

const _MageScale = preload("res://data/mage_skill_scaling.gd")
const _SkillDefs = preload("res://data/skill_definitions.gd")
const _AreaHitHelper = preload("res://scripts/combat/area_hit_helper.gd")
const _MageVfx = preload("res://scripts/vfx/mage_skill_vfx.gd")
const _Palette = preload("res://scripts/vfx/combat_vfx_palette.gd")
const _SkillVisual = preload("res://scripts/skills/skill_visual_service.gd")
const _ProjectileBase = preload("res://scripts/skills/projectile_skill_base.gd")

@export var orbit_radius: float = 52.0
@export var orbit_speed: float = 2.8
@export var tick_damage: int = 6
@export var tick_interval: float = 0.35

var _angle: float = 0.0
var _tick_accum: float = 0.0
var _player: Node2D = null
var _enabled: bool = false
var _skill_level: int = 1
var _secondary_area: Area2D = null
var _secondary_shape: CollisionShape2D = null
var _secondary_visual: Sprite2D = null
var _hit_radius: float = 30.0
var _hit_cooldowns: Dictionary = {}
var _knockback_force: float = 0.0
var _secondary_radius: float = 26.0
const HIT_COOLDOWN_SEC: float = 0.18

var _vfx_time: float = 0.0
var _wisp_attached: bool = false

@onready var visual: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	visible = false
	monitoring = false
	body_entered.connect(_on_body_entered)
	_apply_collision_radius()
	if visual:
		_SkillVisual.apply_sight_aura(self, visual)


func bind_player(player: Node2D) -> void:
	_player = player


func setup_level(level: int, base_damage: int = 6) -> void:
	apply_mage_level(level, base_damage)


func apply_mage_level(level: int, base_damage: int) -> void:
	_skill_level = _MageScale.clamp_level(level)
	_hit_radius = _MageScale.get_sight_hit_radius(_skill_level)
	_secondary_radius = _MageScale.get_sight_secondary_radius(_skill_level)
	orbit_radius = _MageScale.get_sight_orbit_radius(_skill_level)
	orbit_speed = _MageScale.get_sight_orbit_speed(_skill_level)
	tick_damage = int(round(float(base_damage) * _MageScale.get_sight_damage_mult(_skill_level)))
	_knockback_force = _MageScale.get_sight_knockback_force(_skill_level)
	_apply_collision_radius()
	_set_secondary_orb(_MageScale.get_sight_orb_count(_skill_level) >= 2)


func set_active(active: bool) -> void:
	_enabled = active
	visible = active
	monitoring = active
	if active:
		_hit_cooldowns.clear()
		_attach_orb_wisps()
	if _secondary_area:
		_secondary_area.monitoring = active
		if active and not _secondary_area.body_entered.is_connected(_on_secondary_body_entered):
			_secondary_area.body_entered.connect(_on_secondary_body_entered)


func _apply_collision_radius() -> void:
	if collision_shape and collision_shape.shape is CircleShape2D:
		(collision_shape.shape as CircleShape2D).radius = _hit_radius * 0.55
	if _secondary_shape and _secondary_shape.shape is CircleShape2D:
		(_secondary_shape.shape as CircleShape2D).radius = _secondary_radius * 0.55


func _attach_orb_wisps() -> void:
	if _wisp_attached or not _SkillVisual.USE_SIGHT_WISP_PARTICLES:
		return
	_MageVfx.attach_sight_wisp(self)
	if _secondary_area:
		_MageVfx.attach_sight_wisp(_secondary_area)
	_wisp_attached = true


func _physics_process(delta: float) -> void:
	if not _enabled or _player == null or not is_instance_valid(_player):
		return
	_vfx_time += delta
	if visual:
		var pulse: float = 0.84 + 0.16 * sin(_vfx_time * 7.0)
		var tint: Color = _Palette.player_sight_modulate(_vfx_time)
		tint.a = pulse * 0.9
		var sheet: AnimatedSprite2D = _ProjectileBase.get_sheet_visual(self)
		if sheet:
			sheet.modulate = Color.WHITE
		elif not _ProjectileBase.uses_skill_sheet(self):
			visual.modulate = tint
		elif visual.visible:
			visual.modulate = tint
	_angle += orbit_speed * delta
	global_position = _player.global_position + Vector2.from_angle(_angle) * orbit_radius
	rotation = _angle + PI * 0.5
	if _secondary_area:
		_secondary_area.global_position = _player.global_position + Vector2.from_angle(_angle + PI) * orbit_radius
		_secondary_area.rotation = _angle + PI + PI * 0.5
	_tick_accum += delta
	if _tick_accum >= tick_interval:
		_tick_accum = 0.0
		_apply_area_damage_at(global_position)
		if _secondary_area:
			_apply_area_damage_at(_secondary_area.global_position)
	_apply_overlap_damage_at(global_position)
	if _secondary_area:
		_apply_overlap_damage_at(_secondary_area.global_position)
	_decay_hit_cooldowns(delta)


func _set_secondary_orb(enabled: bool) -> void:
	if enabled and _secondary_area == null:
		_secondary_area = Area2D.new()
		_secondary_area.collision_layer = collision_layer
		_secondary_area.collision_mask = collision_mask
		_secondary_area.monitoring = _enabled
		_secondary_shape = CollisionShape2D.new()
		var circle: CircleShape2D = CircleShape2D.new()
		circle.radius = _secondary_radius * 0.55
		_secondary_shape.shape = circle
		_secondary_area.add_child(_secondary_shape)
		if visual:
			_secondary_visual = Sprite2D.new()
			_secondary_visual.texture = visual.texture
			_secondary_visual.scale = visual.scale
			_secondary_visual.modulate = visual.modulate
			_secondary_visual.texture_filter = visual.texture_filter
			_Palette.apply_soft_blend(_secondary_visual)
			_secondary_area.add_child(_secondary_visual)
		var host: Node = get_parent() if get_parent() else get_tree().current_scene
		if host:
			host.add_child(_secondary_area)
			if _player != null and is_instance_valid(_player):
				_secondary_area.global_position = _player.global_position + Vector2.from_angle(_angle + PI) * orbit_radius
		_secondary_area.body_entered.connect(_on_secondary_body_entered)
	elif not enabled and _secondary_area:
		_secondary_area.queue_free()
		_secondary_area = null
		_secondary_shape = null
		_secondary_visual = null


func _apply_area_damage_at(world_pos: Vector2) -> void:
	var world: World2D = get_world_2d()
	if world == null and _player != null:
		world = _player.get_world_2d()
	if world == null:
		return
	_AreaHitHelper.for_each_enemy_body_in_circle(
		world_pos, _hit_radius, world, _on_area_hit
	)


func _apply_overlap_damage_at(world_pos: Vector2) -> void:
	for body: Node2D in get_overlapping_bodies():
		_try_hit_body(body, world_pos)
	if _secondary_area:
		for body: Node2D in _secondary_area.get_overlapping_bodies():
			_try_hit_body(body, world_pos)


func _on_area_hit(body: Node2D) -> void:
	_try_hit_body(body, global_position)


func _try_hit_body(body: Node2D, at_pos: Vector2) -> void:
	if not _enabled or not body.is_in_group(_SkillDefs.GROUP_ENEMIES):
		return
	if body.global_position.distance_to(at_pos) > _hit_radius + 14.0:
		return
	var body_id: int = body.get_instance_id()
	if _hit_cooldowns.has(body_id):
		return
	if body.has_method("take_damage"):
		body.take_damage(tick_damage)
		_hit_cooldowns[body_id] = HIT_COOLDOWN_SEC
	if _knockback_force > 0.0 and body.has_method("apply_knockback"):
		var away: Vector2 = (body.global_position - at_pos).normalized()
		if away.length_squared() < 0.001:
			away = Vector2.RIGHT
		body.apply_knockback(away * _knockback_force)


func _decay_hit_cooldowns(delta: float) -> void:
	var expired: Array[int] = []
	for body_id: int in _hit_cooldowns:
		_hit_cooldowns[body_id] = float(_hit_cooldowns[body_id]) - delta
		if float(_hit_cooldowns[body_id]) <= 0.0:
			expired.append(body_id)
	for body_id: int in expired:
		_hit_cooldowns.erase(body_id)


func _on_body_entered(body: Node2D) -> void:
	_try_hit_body(body, global_position)


func _on_secondary_body_entered(body: Node2D) -> void:
	if _secondary_area:
		_try_hit_body(body, _secondary_area.global_position)
