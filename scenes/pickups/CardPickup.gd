## CardPickup.gd — Coleccionable visual de carta en el suelo.
class_name CardPickup
extends Area2D

const _CardVisuals = preload("res://data/card_visual_catalog.gd")
const _SpriteLoader = preload("res://scripts/visual/sprite_asset_loader.gd")
const _ShapeFactory = preload("res://scripts/util/shape_texture_factory.gd")

var card_id: String = ""
var card_data: Dictionary = {}

const GROUP_CARD_PICKUP: String = "CardPickup"
const SLEEP_DISTANCE: float = 720.0

@export var magnet_speed: float = 14.0
@export var collect_distance: float = 14.0
@export var card_sprite_height: float = 22.0
## Evita recoger la carta al spawnear encima del jugador (p. ej. al morir el jefe).
@export var pickup_grace_time: float = 0.45

var _player: Node2D = null
var _collected: bool = false
var _pickup_grace_left: float = 0.0

@onready var visual: Sprite2D = $Sprite2D


func _ready() -> void:
	z_index = 64
	z_as_relative = false
	add_to_group(GROUP_CARD_PICKUP)
	body_entered.connect(_on_body_entered)
	collision_layer = 8
	collision_mask = 1
	monitoring = true
	monitorable = true
	_pickup_grace_left = pickup_grace_time
	set_physics_process(true)
	_find_player()


func configure(id: String, data: Dictionary) -> void:
	card_id = id
	card_data = data
	_pickup_grace_left = pickup_grace_time
	_apply_card_visual()


func _apply_card_visual() -> void:
	if visual == null:
		return
	var custom_path: String = String(card_data.get("sprite_path", ""))
	if custom_path != "" and _SpriteLoader.try_apply(visual, custom_path, card_sprite_height):
		return
	for path: String in _CardVisuals.get_pickup_sprite_paths(card_id):
		if _SpriteLoader.try_apply(visual, path, card_sprite_height):
			return
	if visual.has_method("apply_visual"):
		visual.apply_visual(_ShapeFactory.Shape.SQUARE, Color(0.95, 0.85, 0.2, 1.0))


func _physics_process(delta: float) -> void:
	if _collected:
		return
	if _pickup_grace_left > 0.0:
		_pickup_grace_left = maxf(_pickup_grace_left - delta, 0.0)
		return
	if _player == null or not is_instance_valid(_player):
		_find_player()
	if _player == null:
		return
	for body: Node2D in get_overlapping_bodies():
		if body.is_in_group("Jugador"):
			_player = body
			_collect()
			return
	var touch_range: float = _get_touch_collect_range()
	if global_position.distance_to(_player.global_position) <= touch_range:
		_collect()
		return
	if global_position.distance_squared_to(_player.global_position) > SLEEP_DISTANCE * SLEEP_DISTANCE:
		return
	if not _is_player_in_collect_range():
		return
	global_position = global_position.lerp(
		_player.global_position, clampf(magnet_speed * delta, 0.0, 1.0)
	)
	if global_position.distance_to(_player.global_position) <= collect_distance:
		_collect()


func try_collect_by(player: Node2D) -> void:
	if player == null or not player.is_in_group("Jugador"):
		return
	_player = player
	_collect()


func _get_pickup_radius() -> float:
	var shape_node: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node and shape_node.shape is CircleShape2D:
		return (shape_node.shape as CircleShape2D).radius
	return 10.0


func _get_touch_collect_range() -> float:
	var player_radius: float = 14.0
	if _player.has_method("get_contact_radius"):
		player_radius = float(_player.call("get_contact_radius"))
	return _get_pickup_radius() + player_radius + 2.0


func _find_player() -> void:
	var players: Array[Node] = get_tree().get_nodes_in_group("Jugador")
	if players.size() > 0 and players[0] is Node2D:
		_player = players[0] as Node2D


func _on_body_entered(body: Node2D) -> void:
	if _pickup_grace_left > 0.0:
		return
	if body.is_in_group("Jugador"):
		_player = body
		_collect()


func _is_player_in_collect_range() -> bool:
	if _player == null:
		return false
	if _player.has_method("is_loot_in_magnet_range"):
		return _player.is_loot_in_magnet_range(global_position)
	return _player.global_position.distance_to(global_position) <= 120.0


func _can_pickup() -> bool:
	return not _collected and _pickup_grace_left <= 0.0 and not card_id.is_empty()


func _collect() -> void:
	if not _can_pickup():
		return
	_collected = true
	if Arena.is_ready():
		global_position = Arena.clamp_to_playable(global_position, 4.0)
	Global.unlock_card(card_id, card_data)
	queue_free()
