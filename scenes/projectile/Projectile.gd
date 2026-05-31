## Projectile.gd — Fire Bolt: proyectil dirigido con colisión y autodestrucción.
class_name Projectile
extends Area2D

@export var speed: float = 500.0
@export var damage: int = 25
@export var max_travel_distance: float = 1200.0
@export var lifetime_seconds: float = 3.0

var _target: Node2D = null
var _direction: Vector2 = Vector2.RIGHT
var _spawn_position: Vector2 = Vector2.ZERO
var _alive: bool = true

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	_spawn_position = global_position
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	var life_timer: Timer = Timer.new()
	life_timer.one_shot = true
	life_timer.wait_time = lifetime_seconds
	add_child(life_timer)
	life_timer.timeout.connect(_destroy)
	life_timer.start()


func setup(target: Node2D, bolt_damage: int = -1) -> void:
	_target = target
	if bolt_damage > 0:
		damage = bolt_damage
	_update_direction()


func _physics_process(delta: float) -> void:
	if not _alive:
		return
	if _target != null and is_instance_valid(_target):
		_direction = (_target.global_position - global_position).normalized()
	elif _direction.length_squared() < 0.001:
		_destroy()
		return
	global_position += _direction * speed * delta
	rotation = _direction.angle()
	if global_position.distance_squared_to(_spawn_position) >= max_travel_distance * max_travel_distance:
		_destroy()
	if not _is_on_screen():
		_destroy()


func _update_direction() -> void:
	if _target != null and is_instance_valid(_target):
		_direction = (_target.global_position - global_position).normalized()
	else:
		_direction = Vector2.RIGHT


func _on_body_entered(body: Node2D) -> void:
	_try_hit_enemy(body)


func _on_area_entered(area: Area2D) -> void:
	if area.get_parent() is Node2D:
		_try_hit_enemy(area.get_parent() as Node2D)


func _try_hit_enemy(body: Node2D) -> void:
	if not _alive:
		return
	if not body.is_in_group("Enemigos"):
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
		Audio.play_sfx("hit", randf_range(0.95, 1.12))
		_hit_feedback()
		_destroy()


func _hit_feedback() -> void:
	if sprite:
		sprite.modulate = Color(1.0, 0.9, 0.3, 1.0)
		var tween: Tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 0.08)


func _is_on_screen() -> bool:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		return true
	var rect: Rect2 = get_viewport().get_visible_rect()
	var half: Vector2 = rect.size * 0.5
	var center: Vector2 = camera.get_screen_center_position()
	var world_rect: Rect2 = Rect2(center - half, rect.size)
	return world_rect.has_point(global_position)


func _destroy() -> void:
	if not _alive:
		return
	_alive = false
	set_physics_process(false)
	queue_free()
