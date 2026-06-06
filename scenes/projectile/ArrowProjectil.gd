## ArrowProjectil.gd — Proyectil enemigo: viaja en línea recta y daña al jugador.
extends Area2D
class_name ArrowProjectil

const _ThreatVfx = preload("res://scripts/vfx/enemy_threat_vfx.gd")
const _TileDepthSort = preload("res://scripts/visual/tile_depth_sort.gd")

@export var speed: float = 520.0
@export var damage: int = 100
@export var max_travel_distance: float = 1400.0
@export var lifetime_seconds: float = 3.5

var _direction: Vector2 = Vector2.RIGHT
var _spawn_position: Vector2 = Vector2.ZERO
var _alive: bool = true
var _owner: Node = null

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	_spawn_position = global_position
	z_as_relative = false
	if sprite:
		_ThreatVfx.setup_enemy_projectile_sprite(sprite)
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	var life_timer: Timer = Timer.new()
	life_timer.one_shot = true
	life_timer.wait_time = lifetime_seconds
	add_child(life_timer)
	life_timer.timeout.connect(_destroy)
	life_timer.start()


## target_world: posición del jugador al terminar la carga.
func setup(target_world: Vector2, arrow_damage: int = 100, arrow_speed: float = 520.0, owner: Node = null) -> void:
	_owner = owner
	damage = maxi(arrow_damage, 1)
	speed = maxf(arrow_speed, 1.0)
	var dir: Vector2 = target_world - global_position
	_direction = dir.normalized() if dir.length_squared() > 0.001 else Vector2.RIGHT
	rotation = _direction.angle()


func _physics_process(delta: float) -> void:
	if not _alive:
		return
	global_position += _direction * speed * delta
	z_index = _TileDepthSort.compute_ground_telegraph_z_index(global_position.y) + 1
	if global_position.distance_squared_to(_spawn_position) >= max_travel_distance * max_travel_distance:
		_destroy()
		return
	if not _is_on_screen():
		_destroy()


func _on_body_entered(body: Node2D) -> void:
	_try_hit_player(body)


func _on_area_entered(area: Area2D) -> void:
	if area.get_parent() is Node2D:
		_try_hit_player(area.get_parent() as Node2D)


func _try_hit_player(body: Node2D) -> void:
	if not _alive or body == null:
		return
	if not body.is_in_group("Jugador"):
		return
	if body.has_method("take_contact_damage"):
		body.call("take_contact_damage", damage, _owner if _owner != null else self)
		_hit_feedback()
		_destroy()


func _hit_feedback() -> void:
	if sprite:
		sprite.modulate = Color(1.0, 0.25, 0.15, 1.0)
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
