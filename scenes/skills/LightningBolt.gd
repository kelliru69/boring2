## Lightning Bolt — proyectil tipo boomerang (ida y vuelta).
class_name LightningBolt
extends Area2D

const _SkillDefs = preload("res://data/skill_definitions.gd")

@export var speed: float = 480.0
@export var damage: int = 20
@export var max_travel_distance: float = 200.0

var _direction: Vector2 = Vector2.RIGHT
var _spawn_position: Vector2 = Vector2.ZERO
var _traveled: float = 0.0
var _returning: bool = false
var _alive: bool = true
var _hit_ids: Dictionary = {}

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	_spawn_position = global_position
	body_entered.connect(_on_body_entered)


func setup_boomerang(direction: Vector2, bolt_damage: int, travel_distance: float) -> void:
	if direction.length_squared() < 0.001:
		direction = Vector2.RIGHT
	_direction = direction.normalized()
	damage = bolt_damage
	max_travel_distance = travel_distance
	rotation = _direction.angle()


func _physics_process(delta: float) -> void:
	if not _alive:
		return
	var step: float = speed * delta
	global_position += _direction * step
	_traveled += step
	rotation = _direction.angle()
	if Arena.is_ready() and not Arena.is_inside_playable(global_position, 0.0):
		_destroy()
		return
	if not _returning and _traveled >= max_travel_distance:
		_returning = true
		_direction = -_direction
		_traveled = 0.0
	elif _returning and _traveled >= max_travel_distance:
		_destroy()


func _on_body_entered(body: Node2D) -> void:
	if not _alive or not body.is_in_group(_SkillDefs.GROUP_ENEMIES):
		return
	var id: int = body.get_instance_id()
	if _hit_ids.has(id):
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
		_hit_ids[id] = true
		Audio.play_sfx("hit", randf_range(0.95, 1.1))


func _destroy() -> void:
	_alive = false
	set_physics_process(false)
	queue_free()
