## Cold Bolt — homing al enemigo con mayor HP máximo en rango; aplica Freeze.
class_name ColdBolt
extends Area2D

const _SkillDefs = preload("res://data/skill_definitions.gd")

@export var speed: float = 420.0
@export var damage: int = 18
@export var freeze_duration: float = 3.0
@export var freeze_slow_ratio: float = 0.5
@export var max_travel_distance: float = 1200.0
@export var lifetime_seconds: float = 4.0

var _target: Node2D = null
var _direction: Vector2 = Vector2.RIGHT
var _spawn_position: Vector2 = Vector2.ZERO
var _alive: bool = true

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	_spawn_position = global_position
	body_entered.connect(_on_body_entered)
	var life_timer: Timer = Timer.new()
	life_timer.one_shot = true
	life_timer.wait_time = lifetime_seconds
	add_child(life_timer)
	life_timer.timeout.connect(_destroy)
	life_timer.start()


func setup_target(target: Node2D, bolt_damage: int = -1) -> void:
	_target = target
	if bolt_damage > 0:
		damage = bolt_damage
	_update_direction()


## Ralentización (Cold Bolt): ratio 0.2–0.5 según nivel, sin stun completo.
func set_slow_ratio(ratio: float) -> void:
	freeze_slow_ratio = clampf(ratio, 0.05, 0.95)
	freeze_duration = 1.4


func _physics_process(delta: float) -> void:
	if not _alive:
		return
	if _target != null and is_instance_valid(_target):
		_direction = (_target.global_position - global_position).normalized()
	global_position += _direction * speed * delta
	rotation = _direction.angle()
	if global_position.distance_squared_to(_spawn_position) >= max_travel_distance * max_travel_distance:
		_destroy()
	elif Arena.is_ready() and not Arena.is_inside_playable(global_position, 0.0):
		_destroy()


func _update_direction() -> void:
	if _target != null and is_instance_valid(_target):
		_direction = (_target.global_position - global_position).normalized()


func _on_body_entered(body: Node2D) -> void:
	if not _alive or not body.is_in_group(_SkillDefs.GROUP_ENEMIES):
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
	if body.has_method("apply_freeze"):
		body.apply_freeze(freeze_duration, freeze_slow_ratio)
	Audio.play_sfx("hit", randf_range(0.9, 1.05))
	_destroy()


func _destroy() -> void:
	if not _alive:
		return
	_alive = false
	set_physics_process(false)
	queue_free()
