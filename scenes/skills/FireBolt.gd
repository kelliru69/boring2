## Fire Bolt — proyectil en línea recta (dirección fija, no homing).
class_name FireBolt
extends Area2D

const _SkillDefs = preload("res://data/skill_definitions.gd")

@export var speed: float = 520.0
@export var damage: int = 25
@export var max_travel_distance: float = 1400.0
@export var lifetime_seconds: float = 3.5

var _direction: Vector2 = Vector2.RIGHT
var _spawn_position: Vector2 = Vector2.ZERO
var _alive: bool = true
var _hit_enemy_ids: Dictionary = {}

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


## Dispara en [direction] normalizada desde la posición actual.
func setup_direction(direction: Vector2, bolt_damage: int = -1) -> void:
	if direction.length_squared() < 0.001:
		direction = Vector2.RIGHT
	_direction = direction.normalized()
	if bolt_damage > 0:
		damage = bolt_damage
	rotation = _direction.angle()


func _physics_process(delta: float) -> void:
	if not _alive:
		return
	global_position += _direction * speed * delta
	if global_position.distance_squared_to(_spawn_position) >= max_travel_distance * max_travel_distance:
		_destroy()
	elif Arena.is_ready() and not Arena.is_inside_playable(global_position, 0.0):
		_destroy()


func _on_body_entered(body: Node2D) -> void:
	_try_hit_enemy(body)


func _try_hit_enemy(body: Node2D) -> void:
	if not _alive or not body.is_in_group(_SkillDefs.GROUP_ENEMIES):
		return
	var enemy_id: int = body.get_instance_id()
	if _hit_enemy_ids.has(enemy_id):
		return
	if not body.has_method("take_damage"):
		return
	_hit_enemy_ids[enemy_id] = true
	body.take_damage(damage)
	Audio.play_sfx("hit", randf_range(0.95, 1.1))
	_hit_feedback()
	_destroy()


func _hit_feedback() -> void:
	if sprite:
		sprite.modulate = Color(1.0, 0.85, 0.25, 1.0)
		var tween: Tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 0.08)


func _destroy() -> void:
	if not _alive:
		return
	_alive = false
	set_physics_process(false)
	queue_free()
