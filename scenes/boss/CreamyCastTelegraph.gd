## Telégrafo rojo: zona de impacto del casteo de Creamy (outline negro).
extends Area2D

const _ThreatVfx = preload("res://scripts/vfx/enemy_threat_vfx.gd")

@export var radius: float = 70.0
@export var cast_duration: float = 2.0
@export var impact_damage: int = 45

var _elapsed: float = 0.0
var _player: Node2D = null

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func configure(new_radius: float, duration: float, damage: int) -> void:
	radius = new_radius
	cast_duration = duration
	impact_damage = damage
	if collision_shape and collision_shape.shape is CircleShape2D:
		(collision_shape.shape as CircleShape2D).radius = radius
	queue_redraw()


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitoring = false
	if collision_shape.shape is CircleShape2D:
		(collision_shape.shape as CircleShape2D).radius = radius
	_ThreatVfx.apply_ground_layer_z(self, global_position.y)
	_find_player()
	queue_redraw()


func _process(delta: float) -> void:
	_elapsed += delta
	_ThreatVfx.apply_ground_layer_z(self, global_position.y)
	queue_redraw()
	if _elapsed >= cast_duration:
		_resolve_impact()
		queue_free()


func _resolve_impact() -> void:
	if _player == null:
		_find_player()
	if _player == null or not is_instance_valid(_player):
		return
	if global_position.distance_to(_player.global_position) <= radius + 8.0:
		if _player.has_method("take_damage"):
			_player.take_damage(impact_damage)


func _draw() -> void:
	_ThreatVfx.draw_ground_telegraph(self, Vector2.ZERO, radius, _elapsed, cast_duration)


func _find_player() -> void:
	var players: Array[Node] = get_tree().get_nodes_in_group("Jugador")
	if not players.is_empty() and players[0] is Node2D:
		_player = players[0] as Node2D
