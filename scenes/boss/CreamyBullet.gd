## Proyectil recto de Creamy — daña al jugador.
class_name CreamyBullet
extends Area2D

@export var speed: float = 250.0
@export var damage: int = 37
@export var max_travel_distance: float = 1600.0
@export var lifetime_seconds: float = 4.0

var _direction: Vector2 = Vector2.RIGHT
var _spawn_position: Vector2 = Vector2.ZERO
var _alive: bool = true

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	_spawn_position = global_position
	body_entered.connect(_on_body_entered)
	var life_timer: Timer = Timer.new()
	life_timer.one_shot = true
	life_timer.wait_time = lifetime_seconds
	add_child(life_timer)
	life_timer.timeout.connect(_destroy)
	life_timer.start()


func apply_visual_scale(scale_factor: float) -> void:
	var s: float = maxf(scale_factor, 0.5)
	if sprite:
		sprite.scale = Vector2(s, s)
	if collision_shape and collision_shape.shape is CircleShape2D:
		var base_radius: float = 11.0
		(collision_shape.shape as CircleShape2D).radius = base_radius * s


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


func _on_body_entered(body: Node2D) -> void:
	if not _alive or not body.is_in_group("Jugador"):
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
	_destroy()


func _destroy() -> void:
	if not _alive:
		return
	_alive = false
	set_physics_process(false)
	queue_free()
