## Thunderstorm — AoE circular: pulsos de daño Viento + knockback.
class_name Thunderstorm
extends Area2D

const _SkillDefs = preload("res://data/skill_definitions.gd")
const _MageScale = preload("res://data/mage_skill_scaling.gd")
const _AreaHitHelper = preload("res://scripts/combat/area_hit_helper.gd")

@export var radius: float = 72.0
@export var pulse_damage: int = 12
@export var duration: float = 1.5
@export var pulse_interval: float = 0.5
@export var knockback_force: float = 140.0

var _elapsed: float = 0.0
var _pulse_accum: float = 0.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual: Sprite2D = $Sprite2D


func setup_level(level: int, base_damage: int = 12) -> void:
	var lv: int = _MageScale.clamp_level(level)
	radius = _MageScale.get_thunderstorm_radius(lv)
	pulse_damage = base_damage
	duration = _MageScale.get_thunderstorm_duration()
	pulse_interval = _MageScale.get_thunderstorm_pulse_interval()
	_apply_radius_visual()
	_pulse_accum = 0.0
	call_deferred("_apply_pulse")


func set_radius_override(new_radius: float) -> void:
	radius = new_radius
	_apply_radius_visual()


func _ready() -> void:
	_apply_radius_visual()
	_pulse_accum = pulse_interval


func _apply_radius_visual() -> void:
	if collision_shape and collision_shape.shape is CircleShape2D:
		(collision_shape.shape as CircleShape2D).radius = radius
	if visual:
		visual.scale = Vector2(radius / 16.0, radius / 16.0)


func _process(delta: float) -> void:
	_elapsed += delta
	_pulse_accum += delta
	if _elapsed >= duration:
		queue_free()
		return
	if _pulse_accum >= pulse_interval:
		_pulse_accum -= pulse_interval
		_apply_pulse()
	if visual:
		var alpha: float = 0.35 + sin(_elapsed * 12.0) * 0.15
		visual.modulate = Color(0.7, 0.85, 1.0, alpha)


func _apply_pulse() -> void:
	_AreaHitHelper.for_each_enemy_body_in_circle(
		global_position, radius, get_world_2d(), _on_enemy_pulse_hit
	)


func _on_enemy_pulse_hit(body: Node2D) -> void:
	if not body.is_in_group(_SkillDefs.GROUP_ENEMIES):
		return
	if body.has_method("take_damage"):
		body.take_damage(pulse_damage)
	var away: Vector2 = (body.global_position - global_position).normalized()
	if away.length_squared() < 0.001:
		away = Vector2.RIGHT
	if body.has_method("apply_knockback"):
		body.apply_knockback(away * knockback_force)


static func spawn_at(world_pos: Vector2, scene: PackedScene, parent: Node) -> void:
	if scene == null or parent == null:
		return
	var storm: Thunderstorm = scene.instantiate() as Thunderstorm
	if storm == null:
		return
	parent.add_child(storm)
	storm.global_position = world_pos
