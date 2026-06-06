## Shield Boomerang — proyectil de ida y vuelta con daño en área.
extends Area2D

const _SkillDefs = preload("res://data/skill_definitions.gd")
const _HitFlash = preload("res://scripts/vfx/enemy_hit_flash.gd")

@export var speed: float = 420.0
@export var max_travel: float = 300.0
@export var hit_radius: float = 44.0
@export var damage: int = 40

var _direction: Vector2 = Vector2.RIGHT
var _origin: Vector2 = Vector2.ZERO
var _traveled: float = 0.0
var _returning: bool = false
var _player: Player = null
var _hit_ids: Dictionary = {}


func setup(player: Player, direction: Vector2, bolt_damage: int) -> void:
	_player = player
	if direction.length_squared() < 0.001:
		direction = Vector2.RIGHT
	_direction = direction.normalized()
	_origin = player.global_position
	global_position = _origin
	damage = maxi(bolt_damage, 1)
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = hit_radius
	var col: CollisionShape2D = CollisionShape2D.new()
	col.shape = shape
	add_child(col)
	body_entered.connect(_on_body_entered)
	collision_layer = 0
	collision_mask = 2


func _physics_process(delta: float) -> void:
	var step: float = speed * delta
	global_position += _direction * step
	_traveled += step
	if _player and is_instance_valid(_player):
		if _returning:
			_direction = (_player.global_position - global_position).normalized()
			if _direction.length_squared() < 0.001:
				_direction = Vector2.RIGHT
		if not _returning and _traveled >= max_travel:
			_returning = true
			_traveled = 0.0
			_hit_ids.clear()
		elif _returning and global_position.distance_to(_player.global_position) <= 28.0:
			queue_free()
			return
	elif _traveled >= max_travel * 2.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body == null or not body.is_in_group(_SkillDefs.GROUP_ENEMIES):
		return
	var id: int = body.get_instance_id()
	if _hit_ids.has(id):
		return
	_hit_ids[id] = true
	if body.has_method("take_damage"):
		body.take_damage(damage, _HitFlash.ELEMENT_SOUL)
