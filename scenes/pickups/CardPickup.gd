## CardPickup.gd — Coleccionable visual de carta en el suelo.
class_name CardPickup
extends Area2D

const _CardVisuals = preload("res://data/card_visual_catalog.gd")
const _SpriteLoader = preload("res://scripts/visual/sprite_asset_loader.gd")
const _ShapeFactory = preload("res://scripts/util/shape_texture_factory.gd")

var card_id: String = ""
var card_data: Dictionary = {}

@export var collect_radius: float = 20.0
@export var card_sprite_height: float = 22.0

var _player: Node2D = null
var _collected: bool = false

@onready var visual: Sprite2D = $Sprite2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_find_player()


func configure(id: String, data: Dictionary) -> void:
	card_id = id
	card_data = data
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


func _physics_process(_delta: float) -> void:
	if _collected:
		return
	if _player == null or not is_instance_valid(_player):
		_find_player()
		return
	var dist: float = global_position.distance_to(_player.global_position)
	if dist <= collect_radius:
		_collect()


func _find_player() -> void:
	var players: Array[Node] = get_tree().get_nodes_in_group("Jugador")
	if players.size() > 0 and players[0] is Node2D:
		_player = players[0] as Node2D


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Jugador"):
		_player = body
		_collect()


func _collect() -> void:
	if _collected or card_id.is_empty():
		return
	_collected = true
	if Arena.is_ready():
		global_position = Arena.clamp_to_playable(global_position, 4.0)
	Global.unlock_card(card_id, card_data)
	queue_free()
