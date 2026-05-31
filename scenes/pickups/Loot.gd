## Loot físico: XP, Zeny y consumibles de curación (manzana/zanahoria).
class_name Loot
extends Area2D

enum LootType { XP, ZENY, HEAL_APPLE, HEAL_CARROT }

const GROUP_LOOT: String = "Loot"
const HEAL_APPLE_RATIO: float = 0.10
const HEAL_CARROT_RATIO: float = 0.15
const MAX_ACTIVE_LOOT: int = 70
const LOOT_SLEEP_DISTANCE: float = 720.0

static var _active_loot_count: int = 0

@export var loot_type: LootType = LootType.XP
@export var amount: int = 5
@export var magnet_speed: float = 14.0
@export var collect_distance: float = 14.0
@export var draw_radius: float = 6.0
## Segundos antes de poder recoger (evita absorción instantánea al spawnear sobre el jugador).
@export var pickup_grace_time: float = 0.45

var _magnet_forced: bool = false
var _collected: bool = false
var _pickup_grace_left: float = 0.0
var _player: Node2D = null


func _ready() -> void:
	add_to_group(GROUP_LOOT)
	body_entered.connect(_on_body_entered)
	collision_layer = 8
	collision_mask = 1
	monitoring = true
	_pickup_grace_left = pickup_grace_time
	set_physics_process(true)


func configure(type: LootType, value: int) -> void:
	loot_type = type
	amount = maxi(value, 1)
	queue_redraw()


func activate_vacuum_magnet() -> void:
	_magnet_forced = true


static func spawn_pickup(
	scene: PackedScene,
	type: LootType,
	value: int,
	world_pos: Vector2,
	parent: Node
) -> Loot:
	if scene == null or parent == null:
		return null
	if _active_loot_count >= MAX_ACTIVE_LOOT:
		_grant_loot_direct(parent, type, value)
		return null
	var pickup: Loot = scene.instantiate() as Loot
	if pickup == null:
		return null
	parent.add_child(pickup)
	pickup.global_position = _resolve_spawn_position(world_pos, parent)
	pickup.configure(type, value)
	pickup._pickup_grace_left = pickup.pickup_grace_time
	_active_loot_count += 1
	return pickup


static func _grant_loot_direct(parent: Node, type: LootType, value: int) -> void:
	var grant_amount: int = maxi(value, 1)
	match type:
		LootType.XP:
			Global.add_experience(grant_amount)
		LootType.ZENY:
			Global.add_zeny(grant_amount)
		LootType.HEAL_APPLE, LootType.HEAL_CARROT:
			if parent == null:
				return
			var players: Array[Node] = parent.get_tree().get_nodes_in_group("Jugador")
			if players.is_empty() or not players[0].has_method("heal_percent_of_max"):
				return
			var ratio: float = HEAL_APPLE_RATIO if type == LootType.HEAL_APPLE else HEAL_CARROT_RATIO
			players[0].heal_percent_of_max(ratio)


static func _resolve_spawn_position(world_pos: Vector2, parent: Node) -> Vector2:
	var pos: Vector2 = world_pos
	var players: Array[Node] = parent.get_tree().get_nodes_in_group("Jugador")
	if players.is_empty() or not players[0] is Node2D:
		return pos
	var player: Node2D = players[0] as Node2D
	var min_dist: float = 36.0
	if pos.distance_to(player.global_position) < min_dist:
		var away: Vector2 = pos - player.global_position
		if away.length_squared() < 1.0:
			away = Vector2.from_angle(randf() * TAU)
		pos = player.global_position + away.normalized() * min_dist
	return pos


static func vacuum_all_on_map(tree: SceneTree = null) -> void:
	var scene_tree: SceneTree = tree
	if scene_tree == null:
		var main_loop: MainLoop = Engine.get_main_loop()
		if main_loop is SceneTree:
			scene_tree = main_loop as SceneTree
	if scene_tree == null:
		return
	for node: Node in scene_tree.get_nodes_in_group(GROUP_LOOT):
		if node is Loot:
			(node as Loot).activate_vacuum_magnet()


func _physics_process(delta: float) -> void:
	if _collected:
		return
	if _pickup_grace_left > 0.0:
		_pickup_grace_left = maxf(_pickup_grace_left - delta, 0.0)
		return
	if _player == null or not is_instance_valid(_player):
		_find_player()
	if _player != null and not _magnet_forced:
		if global_position.distance_squared_to(_player.global_position) > LOOT_SLEEP_DISTANCE * LOOT_SLEEP_DISTANCE:
			return
	var should_magnet: bool = _magnet_forced or _is_player_in_collect_range()
	if should_magnet and _player != null:
		global_position = global_position.lerp(_player.global_position, clampf(magnet_speed * delta, 0.0, 1.0))
		if global_position.distance_to(_player.global_position) <= collect_distance:
			_collect()


func _is_player_in_collect_range() -> bool:
	if _player == null:
		return false
	if _player.has_method("is_loot_in_magnet_range"):
		return _player.is_loot_in_magnet_range(global_position)
	return _player.global_position.distance_to(global_position) <= 120.0


func _find_player() -> void:
	var players: Array[Node] = get_tree().get_nodes_in_group("Jugador")
	if not players.is_empty() and players[0] is Node2D:
		_player = players[0] as Node2D


func _on_body_entered(body: Node2D) -> void:
	if _pickup_grace_left > 0.0:
		return
	if body.is_in_group("Jugador"):
		_player = body
		_collect()


func _can_pickup() -> bool:
	return not _collected and _pickup_grace_left <= 0.0


func _collect() -> void:
	if not _can_pickup():
		return
	_collected = true
	match loot_type:
		LootType.XP:
			Global.add_experience(amount)
		LootType.ZENY:
			Global.add_zeny(amount)
		LootType.HEAL_APPLE:
			_apply_heal_to_player(HEAL_APPLE_RATIO)
		LootType.HEAL_CARROT:
			_apply_heal_to_player(HEAL_CARROT_RATIO)
	Audio.play_sfx("zeny", randf_range(0.95, 1.05))
	queue_free()


func _exit_tree() -> void:
	_active_loot_count = maxi(_active_loot_count - 1, 0)


func _apply_heal_to_player(ratio: float) -> void:
	if _player and _player.has_method("heal_percent_of_max"):
		_player.heal_percent_of_max(ratio)


func _draw() -> void:
	var color: Color
	match loot_type:
		LootType.XP:
			color = Color(0.72, 0.35, 0.95, 0.95)
		LootType.ZENY:
			color = Color(1.0, 0.88, 0.2, 0.95)
		LootType.HEAL_APPLE:
			color = Color(0.95, 0.25, 0.25, 0.95)
			draw_radius = 7.0
		LootType.HEAL_CARROT:
			color = Color(1.0, 0.55, 0.15, 0.95)
			draw_radius = 7.0
		_:
			color = Color.WHITE
	draw_circle(Vector2.ZERO, draw_radius, color)
	draw_arc(Vector2.ZERO, draw_radius + 2.0, 0.0, TAU, 12, Color(color, 0.35), 1.5)
