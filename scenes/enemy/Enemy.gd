## Enemy.gd — Monstruos RO: persecución, loot, sprite animado o estático.
class_name Enemy
extends CharacterBody2D

const _ShapeFactory = preload("res://scripts/util/shape_texture_factory.gd")
const _SpriteLoader = preload("res://scripts/visual/sprite_asset_loader.gd")
const _AnimLoader = preload("res://scripts/visual/sprite_animation_loader.gd")
const CARD_DROP_CHANCE: float = 0.0005  # 0.05% base


## Probabilidad efectiva de carta con suerte comercial:
## chance_final = CARD_DROP_CHANCE * (1 + bonus_luck)
## Ejemplo nv.5 (+25%): 0.0005 * 1.25 = 0.000625 → 0.0625%
static func get_card_drop_chance() -> float:
	if Global.debug_card_drop_chance >= 0.0:
		return Global.debug_card_drop_chance
	# base 0.05% multiplicado por suerte comercial: chance_final = 0.0005 * (1 + bonus)
	return Global.compute_card_drop_chance(CARD_DROP_CHANCE)
const _DamageNumber = preload("res://scenes/ui/DamageNumber.gd")
const _EnemyCatalog = preload("res://data/enemy_catalog.gd")
const _CollisionLayers = preload("res://scripts/combat/collision_layers.gd")
const _BodySeparation = preload("res://scripts/combat/body_separation.gd")
const _TileDepthSort = preload("res://scripts/visual/tile_depth_sort.gd")
const _Manifest = preload("res://data/monster_visual_manifest.gd")
const _HitFlash = preload("res://scripts/vfx/enemy_hit_flash.gd")

@export_group("Tipo")
@export var enemy_type: String = "poring"

@export_group("Estadísticas")
@export var max_hp: int = 30
@export var move_speed: float = 80.0
@export var contact_damage: int = 10
@export var zeny_reward: int = 5
@export var xp_reward: int = 10

@export_group("Animación")
@export var bob_amount: float = 3.0
@export var bob_speed: float = 10.0

@export_group("Loot")
@export var loot_scene: PackedScene
@export var card_drop_scene: PackedScene
@export var spawn_card_on_ground: bool = true

@export_group("Comportamiento")
## Si es true, el enemigo muere al infligir daño por contacto (legado kamikaze; desactivado por defecto con body block).
@export var dies_on_player_contact: bool = false

var current_hp: int = 30
var _card_id: String = "carta_poring"
var _card_name: String = "Carta Poring"
var _display_name: String = "Poring"
var _player: Node2D = null
var _enemy_visual_def: Dictionary = {}
var _bob_phase: float = 0.0
var _uses_animation: bool = false
var _base_modulate: Color = Color.WHITE
var _base_move_speed: float = 80.0
var _knockback_velocity: Vector2 = Vector2.ZERO
var _bowling_chain_damage: int = 0
var _bowling_chain_timer: float = 0.0
var _bowling_chain_consumed: bool = false
var size_tier: String = "medium"
var _freeze_timer: Timer = null
var _stun_timer: Timer = null
var _is_stunned: bool = false
var movement_mode: String = "chase"
var linear_velocity: Vector2 = Vector2.ZERO
var _auto_despawn_outside: bool = false
## Margen extra sobre la suma de radios para daño por contacto (alineado al body block).
const CONTACT_STANDOFF_EXTRA: float = 2.0

@onready var contact_timer: Timer = $ContactDamageTimer
@onready var visual_root: Node2D = $VisualRoot
@onready var animated_visual: AnimatedSprite2D = $VisualRoot/AnimatedSprite2D
@onready var static_visual: Sprite2D = $VisualRoot/Sprite2D
@onready var hit_sound_player: HitSoundPlayer = $HitSoundPlayer


func _ready() -> void:
	add_to_group("Enemigos")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_apply_body_collision_layers()
	_freeze_timer = Timer.new()
	_freeze_timer.one_shot = true
	add_child(_freeze_timer)
	_freeze_timer.timeout.connect(_on_freeze_expired)
	_stun_timer = Timer.new()
	_stun_timer.one_shot = true
	add_child(_stun_timer)
	_stun_timer.timeout.connect(_on_stun_expired)
	apply_type(enemy_type)
	if contact_timer:
		if not contact_timer.timeout.is_connected(_on_contact_damage_tick):
			contact_timer.timeout.connect(_on_contact_damage_tick)


func apply_type(type_id: String) -> void:
	enemy_type = type_id
	var def: Dictionary = _EnemyCatalog.get_definition(type_id)
	_enemy_visual_def = def
	max_hp = int(def.get("max_hp", max_hp))
	current_hp = max_hp
	move_speed = float(def.get("move_speed", move_speed))
	_base_move_speed = move_speed
	contact_damage = int(round(
		float(def.get("contact_damage", contact_damage)) * RunBalance.MOB_CONTACT_DAMAGE_MULTIPLIER
	))
	zeny_reward = int(def.get("zeny_reward", zeny_reward))
	xp_reward = int(def.get("xp_reward", xp_reward))
	_card_id = String(def.get("card_id", _card_id))
	_card_name = String(def.get("card_name", _card_name))
	_display_name = String(def.get("display_name", _display_name))
	size_tier = _resolve_size_tier(def)
	dies_on_player_contact = bool(def.get("dies_on_player_contact", false))
	_apply_collision_from_definition(def)
	_apply_visual(Color(def.get("color", Color.WHITE)))


func _apply_visual(fallback_color: Color) -> void:
	_uses_animation = false
	if animated_visual:
		animated_visual.visible = false
	if static_visual:
		static_visual.visible = true
	if _AnimLoader.try_setup_animated(animated_visual, static_visual, _enemy_visual_def):
		_uses_animation = true
		_base_modulate = Color.WHITE
		_set_visual_modulate(Color.WHITE)
		return
	var sprite_path: String = String(_enemy_visual_def.get("sprite_path", ""))
	if sprite_path.is_empty() or not ResourceLoader.exists(sprite_path):
		sprite_path = _Manifest.get_static_sprite_path(enemy_type)
	var sprite_height: float = float(_enemy_visual_def.get("sprite_height", 30.0))
	var width_scale: float = float(_enemy_visual_def.get("sprite_width_scale", 1.0))
	if static_visual and _SpriteLoader.try_apply(static_visual, sprite_path, sprite_height, width_scale):
		_base_modulate = Color.WHITE
		_set_visual_modulate(Color.WHITE)
		return
	_base_modulate = fallback_color
	if static_visual and static_visual.has_method("apply_visual"):
		static_visual.apply_visual(_ShapeFactory.Shape.SQUARE, fallback_color)
	_set_visual_modulate(fallback_color)


func _set_visual_modulate(color: Color) -> void:
	if animated_visual and animated_visual.visible:
		animated_visual.modulate = color
	if static_visual and static_visual.visible:
		static_visual.modulate = color


func _apply_body_collision_layers() -> void:
	collision_layer = _CollisionLayers.LAYER_ENEMIES
	collision_mask = _CollisionLayers.MASK_ENEMY_BODY


func _apply_collision_from_definition(def: Dictionary) -> void:
	var shape_node: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null or not (shape_node.shape is CircleShape2D):
		return
	var radius: float = float(def.get("collision_radius", 12.0))
	(shape_node.shape as CircleShape2D).radius = maxf(radius, 4.0)


func _get_flash_target() -> CanvasItem:
	if _uses_animation and animated_visual:
		return animated_visual
	return static_visual


func _find_player() -> void:
	var players: Array[Node] = get_tree().get_nodes_in_group("Jugador")
	if players.size() > 0 and players[0] is Node2D:
		_player = players[0] as Node2D


func apply_map_modifiers(hp_multiplier: float, damage_multiplier: float) -> void:
	max_hp = int(round(float(max_hp) * hp_multiplier))
	current_hp = max_hp
	contact_damage = int(round(float(contact_damage) * damage_multiplier))
	var ranged_val: Variant = get("ranged_damage")
	if ranged_val != null:
		set(
			"ranged_damage",
			maxi(int(round(float(ranged_val) * damage_multiplier)), 1)
		)


func is_linear_wave_mob() -> bool:
	return movement_mode == "linear"


func set_linear_movement(move_velocity: Vector2, auto_despawn: bool = true) -> void:
	movement_mode = "linear"
	linear_velocity = move_velocity
	_auto_despawn_outside = auto_despawn
	collision_mask = _CollisionLayers.MASK_ENEMY_LINEAR_WAVE
	if visual_root and move_velocity.x != 0.0:
		var flip: bool = move_velocity.x < 0.0
		if animated_visual and animated_visual.visible:
			animated_visual.flip_h = flip
		if static_visual and static_visual.visible:
			static_visual.flip_h = flip


func reset_chase_movement() -> void:
	movement_mode = "chase"
	linear_velocity = Vector2.ZERO
	_auto_despawn_outside = false
	collision_mask = _CollisionLayers.MASK_ENEMY_BODY


func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_find_player()
		return
	if _is_stunned:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if movement_mode == "linear":
		_process_linear_movement(delta)
		return
	velocity = _compute_chase_velocity()
	move_and_slide()
	_enforce_standoff_from_player()
	_process_bowling_chain(delta)
	_knockback_velocity = _knockback_velocity.lerp(Vector2.ZERO, delta * 10.0)
	if Arena.is_ready() and Arena.is_inside_playable(global_position, 0.0):
		global_position = Arena.clamp_to_playable(global_position, 8.0)
	var face_dir: Vector2 = velocity
	if face_dir.length_squared() < 0.01 and _player != null:
		face_dir = _get_player_hurt_position() - global_position
	_update_motion_visuals(face_dir, delta)
	_update_tile_depth_sort()
	if (Engine.get_physics_frames() & 1) == 0:
		_process_contact_damage()


func _process_linear_movement(delta: float) -> void:
	velocity = linear_velocity + _knockback_velocity
	move_and_slide()
	_knockback_velocity = _knockback_velocity.lerp(Vector2.ZERO, delta * 10.0)
	_process_bowling_chain(delta)
	_update_motion_visuals(linear_velocity.normalized() if linear_velocity.length_squared() > 0.001 else Vector2.RIGHT, delta)
	# Sin body block (mask 0); el daño por contacto usa distancia, igual que los mobs que persiguen.
	if (Engine.get_physics_frames() & 1) == 0:
		_process_contact_damage()
	if _auto_despawn_outside and Arena.is_ready() and Arena.is_past_despawn_margin(global_position, 110.0):
		queue_free()
	_update_tile_depth_sort()


func get_depth_sort_y() -> float:
	return global_position.y + _get_collision_radius() * 0.35


func _get_player_depth_tile_row() -> int:
	if _player != null and _player.has_method("get_depth_tile_row"):
		return int(_player.call("get_depth_tile_row"))
	if _player == null:
		return 0
	return _TileDepthSort.get_tile_row(_player.global_position.y, _TileDepthSort.DEFAULT_TILE_SIZE_PX)


func _get_depth_tile_size_px() -> float:
	if _player != null and _player.has_method("get_depth_tile_size_px"):
		return float(_player.call("get_depth_tile_size_px"))
	return _TileDepthSort.DEFAULT_TILE_SIZE_PX


func _update_tile_depth_sort() -> void:
	var tile_px: float = _get_depth_tile_size_px()
	var enemy_row: int = _TileDepthSort.get_tile_row(get_depth_sort_y(), tile_px)
	var player_row: int = _get_player_depth_tile_row()
	z_as_relative = false
	z_index = _TileDepthSort.compute_enemy_z_index(enemy_row, player_row)


func _update_motion_visuals(direction: Vector2, delta: float) -> void:
	if direction.x != 0.0:
		var flip: bool = direction.x < 0.0
		if animated_visual and animated_visual.visible:
			animated_visual.flip_h = flip
		if static_visual and static_visual.visible:
			static_visual.flip_h = flip
	var moving: bool = velocity.length_squared() > 4.0
	if visual_root and bob_amount > 0.0:
		if moving:
			_bob_phase += delta * bob_speed
			visual_root.position.y = sin(_bob_phase) * bob_amount
		else:
			visual_root.position.y = 0.0
	if _uses_animation and animated_visual and moving:
		if not animated_visual.is_playing():
			animated_visual.play()
	elif _uses_animation and animated_visual and animated_visual.is_playing():
		animated_visual.stop()


func get_body_radius() -> float:
	return _get_collision_radius()


func _get_collision_radius() -> float:
	var shape_node: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node and shape_node.shape is CircleShape2D:
		return (shape_node.shape as CircleShape2D).radius
	return 12.0


func _get_player_body_radius() -> float:
	if _player != null and _player.has_method("get_contact_radius"):
		return float(_player.call("get_contact_radius"))
	return 9.0


func _get_standoff_distance() -> float:
	return _BodySeparation.standoff_distance(
		_get_collision_radius(), _get_player_body_radius(), CONTACT_STANDOFF_EXTRA
	)


func _compute_chase_velocity() -> Vector2:
	if _player == null or not is_instance_valid(_player):
		return Vector2.ZERO
	var anchor: Vector2 = _get_player_hurt_position()
	return _BodySeparation.clip_chase_velocity(
		global_position,
		anchor,
		move_speed,
		_get_collision_radius(),
		_get_player_body_radius(),
		_knockback_velocity,
		CONTACT_STANDOFF_EXTRA,
	)


func _enforce_standoff_from_player() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var anchor: Vector2 = _get_player_hurt_position()
	global_position = _BodySeparation.resolve_position(
		global_position,
		anchor,
		_get_collision_radius(),
		_get_player_body_radius(),
		CONTACT_STANDOFF_EXTRA,
	)


func _get_player_hurt_position() -> Vector2:
	if _player == null or not is_instance_valid(_player):
		return Vector2.ZERO
	if _player.has_method("get_hurt_world_position"):
		return _player.get_hurt_world_position() as Vector2
	return _player.global_position


func _get_touch_distance() -> float:
	return _get_standoff_distance()


func _is_touching_player() -> bool:
	if _player == null or not is_instance_valid(_player):
		return false
	var reach: float = _get_touch_distance()
	var hurt_pos: Vector2 = _get_player_hurt_position()
	return global_position.distance_squared_to(hurt_pos) <= reach * reach


func _process_contact_damage() -> void:
	if _player == null or not is_instance_valid(_player):
		_find_player()
	if not _is_touching_player():
		return
	if dies_on_player_contact:
		_deal_contact_damage()
		return
	if contact_timer == null or not contact_timer.is_stopped():
		return
	_deal_contact_damage()
	contact_timer.start()


func _on_contact_damage_tick() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if not _is_touching_player():
		return
	if dies_on_player_contact:
		_deal_contact_damage()
		return
	if contact_timer == null or not contact_timer.is_stopped():
		return
	_deal_contact_damage()
	contact_timer.start()


func _deal_contact_damage() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if not _player.has_method("take_contact_damage"):
		return
	var dealt: bool = _player.take_contact_damage(contact_damage, self)
	if dies_on_player_contact and dealt:
		die()


func apply_stun(duration: float) -> void:
	if duration <= 0.0:
		return
	_is_stunned = true
	move_speed = 0.0
	if _freeze_timer and not _freeze_timer.is_stopped():
		_freeze_timer.stop()
	if visual_root:
		visual_root.modulate = Color(0.9, 0.9, 0.5)
	if _stun_timer:
		_stun_timer.start(duration)


func _on_stun_expired() -> void:
	_is_stunned = false
	move_speed = _base_move_speed
	if visual_root:
		visual_root.modulate = Color.WHITE


func take_damage(amount: int, _hit_element: StringName = _HitFlash.ELEMENT_DEFAULT) -> void:
	if amount <= 0:
		return
	if Arena.is_ready() and not Arena.can_damage_enemy_at(global_position):
		return
	Global.record_damage_dealt(amount)
	if _is_damage_number_visible():
		var parent: Node = get_tree().current_scene
		if parent:
			_DamageNumber.spawn(global_position, amount, parent)
	current_hp = maxi(current_hp - amount, 0)
	if hit_sound_player:
		hit_sound_player.play_hit(global_position)
	if current_hp <= 0:
		die()


## Congelado: reduce velocidad un [slow_ratio] (0.5 = 50%) durante [duration] s.
func apply_freeze(duration: float, slow_ratio: float = 0.5) -> void:
	move_speed = _base_move_speed * clampf(slow_ratio, 0.05, 1.0)
	if _freeze_timer:
		_freeze_timer.start(duration)
	if visual_root:
		visual_root.modulate = Color(0.75, 0.9, 1.0)


func _on_freeze_expired() -> void:
	move_speed = _base_move_speed
	if visual_root:
		visual_root.modulate = Color.WHITE


func apply_knockback(force: Vector2) -> void:
	_knockback_velocity += force


func get_pierce_hit_count() -> int:
	match size_tier:
		"small":
			return 1
		"large":
			return 3
		_:
			return 2


func mark_bowling_chain(base_damage: int, track_sec: float = 0.85) -> void:
	_bowling_chain_damage = maxi(base_damage, 1)
	_bowling_chain_timer = track_sec
	_bowling_chain_consumed = false


func clear_bowling_chain() -> void:
	_bowling_chain_damage = 0
	_bowling_chain_timer = 0.0
	_bowling_chain_consumed = true


func _process_bowling_chain(delta: float) -> void:
	if _bowling_chain_timer <= 0.0 or _bowling_chain_consumed or _bowling_chain_damage <= 0:
		return
	_bowling_chain_timer = maxf(_bowling_chain_timer - delta, 0.0)
	if _knockback_velocity.length() < 40.0:
		return
	var my_radius: float = _get_collision_radius()
	for node: Node in get_tree().get_nodes_in_group("Enemigos"):
		if node == self or not node is Enemy:
			continue
		var other: Enemy = node as Enemy
		var touch_dist: float = my_radius + other._get_collision_radius() + 4.0
		if global_position.distance_to(other.global_position) > touch_dist:
			continue
		var chain_dmg: int = _bowling_chain_damage * 2
		take_damage(chain_dmg)
		other.take_damage(chain_dmg)
		_bowling_chain_consumed = true
		_bowling_chain_timer = 0.0
		other.clear_bowling_chain()
		break


func _resolve_size_tier(def: Dictionary) -> String:
	if def.has("size_tier"):
		return String(def.get("size_tier", "medium"))
	match enemy_type:
		"poring", "lunatic", "fabre", "orc_baby":
			return "small"
		"creamy", "osiris", "moonlight_flower":
			return "large"
		_:
			return "medium"


func _is_damage_number_visible() -> bool:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		return true
	var half: Vector2 = get_viewport().get_visible_rect().size * 0.5
	var center: Vector2 = camera.get_screen_center_position()
	var margin: float = 64.0
	var world_rect: Rect2 = Rect2(center - half - Vector2(margin, margin), half * 2.0 + Vector2(margin * 2.0, margin * 2.0))
	return world_rect.has_point(global_position)


## Desactivado temporalmente (flash en VisualRoot se veía como cuadro blanco).
func _flash_damage_feedback(_hit_element: StringName = _HitFlash.ELEMENT_DEFAULT) -> void:
	pass


func die() -> void:
	Audio.play_sfx("enemy_death", randf_range(0.9, 1.1))
	_try_drop_card()
	_try_drop_heal_item()
	_spawn_loot_drops()
	queue_free()


func _try_drop_heal_item() -> void:
	var drop_kind: String = String(_enemy_visual_def.get("heal_drop", ""))
	if drop_kind.is_empty() or loot_scene == null:
		return
	var chance: float = float(_enemy_visual_def.get("heal_drop_chance", _EnemyCatalog.HEAL_DROP_BASE_CHANCE))
	if chance <= 0.0:
		chance = _EnemyCatalog.HEAL_DROP_BASE_CHANCE
	chance = Global.compute_food_drop_chance(chance)
	if randf() > chance:
		return
	var parent: Node = get_tree().current_scene
	if parent == null:
		return
	var loot_type: Loot.LootType = Loot.LootType.HEAL_APPLE
	if drop_kind == "carrot":
		loot_type = Loot.LootType.HEAL_CARROT
	Loot.spawn_pickup(loot_scene, loot_type, 0, global_position, parent)


func _spawn_loot_drops() -> void:
	if loot_scene == null:
		return
	var parent: Node = get_tree().current_scene
	if parent == null:
		return
	Loot.spawn_pickup(loot_scene, Loot.LootType.XP, xp_reward, global_position + Vector2(-6.0, 0.0), parent)
	Loot.spawn_pickup(loot_scene, Loot.LootType.ZENY, zeny_reward, global_position + Vector2(6.0, 0.0), parent)


func _try_drop_card() -> void:
	if _card_id == "carta_orc_hero" and Global.run_orc_hero_card_dropped:
		return
	if randf() > get_card_drop_chance():
		return
	if _card_id == "carta_orc_hero":
		Global.run_orc_hero_card_dropped = true
	var card_data: Dictionary = {
		"id": _card_id,
		"name": _card_name,
		"monster": _display_name,
	}
	if spawn_card_on_ground and card_drop_scene != null:
		var pickup: Node2D = card_drop_scene.instantiate() as Node2D
		if pickup:
			var parent: Node = get_tree().current_scene
			if parent:
				parent.add_child(pickup)
				pickup.global_position = _resolve_card_spawn_position(global_position, parent)
				if pickup.has_method("configure"):
					pickup.configure(_card_id, card_data)
			return
	Global.unlock_card(_card_id, card_data)


func _resolve_card_spawn_position(world_pos: Vector2, parent: Node) -> Vector2:
	var pos: Vector2 = world_pos
	var tree: SceneTree = parent.get_tree()
	if tree == null:
		return pos
	var players: Array[Node] = tree.get_nodes_in_group("Jugador")
	if players.is_empty() or not players[0] is Node2D:
		return pos
	var player: Node2D = players[0] as Node2D
	if player == null or not is_instance_valid(player):
		return pos
	var min_dist: float = 36.0
	if pos.distance_to(player.global_position) < min_dist:
		var away: Vector2 = pos - player.global_position
		if away.length_squared() < 1.0:
			away = Vector2.from_angle(randf() * TAU)
		pos = player.global_position + away.normalized() * min_dist
	return pos
