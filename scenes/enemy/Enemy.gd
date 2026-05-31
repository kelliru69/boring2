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
## Si es true, el enemigo muere al infligir daño por contacto (evita quedar pegado al jugador).
@export var dies_on_player_contact: bool = true

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
var _freeze_timer: Timer = null
var _stun_timer: Timer = null
var _is_stunned: bool = false
var _contact_dealt: bool = false
var movement_mode: String = "chase"
var linear_velocity: Vector2 = Vector2.ZERO
var _auto_despawn_outside: bool = false
const CONTACT_PADDING: float = 3.0

@onready var contact_timer: Timer = $ContactDamageTimer
@onready var visual_root: Node2D = $VisualRoot
@onready var animated_visual: AnimatedSprite2D = $VisualRoot/AnimatedSprite2D
@onready var static_visual: Sprite2D = $VisualRoot/Sprite2D
@onready var hit_sound_player: HitSoundPlayer = $HitSoundPlayer


func _ready() -> void:
	add_to_group("Enemigos")
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
	var sprite_height: float = float(_enemy_visual_def.get("sprite_height", 30.0))
	if static_visual and _SpriteLoader.try_apply(static_visual, sprite_path, sprite_height):
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


func set_linear_movement(move_velocity: Vector2, auto_despawn: bool = true) -> void:
	movement_mode = "linear"
	linear_velocity = move_velocity
	_auto_despawn_outside = auto_despawn
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
	var direction: Vector2 = (_player.global_position - global_position).normalized()
	velocity = direction * move_speed + _knockback_velocity
	move_and_slide()
	_knockback_velocity = _knockback_velocity.lerp(Vector2.ZERO, delta * 10.0)
	if Arena.is_ready() and Arena.is_inside_playable(global_position, 0.0):
		global_position = Arena.clamp_to_playable(global_position, 8.0)
	_update_motion_visuals(direction, delta)
	if (Engine.get_physics_frames() & 1) == 0:
		_process_contact_damage()


func _process_linear_movement(delta: float) -> void:
	velocity = linear_velocity + _knockback_velocity
	move_and_slide()
	_knockback_velocity = _knockback_velocity.lerp(Vector2.ZERO, delta * 10.0)
	_update_motion_visuals(linear_velocity.normalized() if linear_velocity.length_squared() > 0.001 else Vector2.RIGHT, delta)
	if _auto_despawn_outside and Arena.is_ready() and Arena.is_past_despawn_margin(global_position, 110.0):
		queue_free()


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


func _get_collision_radius() -> float:
	var shape_node: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node and shape_node.shape is CircleShape2D:
		return (shape_node.shape as CircleShape2D).radius
	return 12.0


func _get_touch_distance() -> float:
	var player_radius: float = 14.0
	if _player != null and _player.has_method("get_contact_radius"):
		player_radius = float(_player.call("get_contact_radius"))
	return _get_collision_radius() + player_radius + CONTACT_PADDING


func _is_touching_player() -> bool:
	if _player == null or not is_instance_valid(_player):
		return false
	var reach: float = _get_touch_distance()
	return global_position.distance_squared_to(_player.global_position) <= reach * reach


func _process_contact_damage() -> void:
	if _player == null or not is_instance_valid(_player):
		_find_player()
	if not _is_touching_player():
		_contact_dealt = false
		return
	if dies_on_player_contact:
		_deal_contact_damage()
		return
	if contact_timer == null or not contact_timer.is_stopped():
		return
	_deal_contact_damage()
	contact_timer.start()


func _on_contact_damage_tick() -> void:
	_contact_dealt = false
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
	if dies_on_player_contact and _contact_dealt:
		return
	if _player == null or not is_instance_valid(_player):
		return
	if not _player.has_method("take_damage"):
		return
	if dies_on_player_contact:
		_contact_dealt = true
	_player.take_damage(contact_damage)
	if dies_on_player_contact:
		die()
		return


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


func take_damage(amount: int) -> void:
	if amount <= 0:
		return
	if Arena.is_ready() and not Arena.can_damage_enemy_at(global_position):
		return
	if _is_damage_number_visible():
		var parent: Node = get_tree().current_scene
		if parent:
			_DamageNumber.spawn(global_position, amount, parent)
	current_hp = maxi(current_hp - amount, 0)
	_flash_damage_feedback()
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


func _is_damage_number_visible() -> bool:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		return true
	var half: Vector2 = get_viewport().get_visible_rect().size * 0.5
	var center: Vector2 = camera.get_screen_center_position()
	var margin: float = 64.0
	var world_rect: Rect2 = Rect2(center - half - Vector2(margin, margin), half * 2.0 + Vector2(margin * 2.0, margin * 2.0))
	return world_rect.has_point(global_position)


func _flash_damage_feedback() -> void:
	var target: CanvasItem = _get_flash_target()
	if target:
		target.modulate = Color(1.5, 0.6, 0.6)
		var tween: Tween = create_tween()
		tween.tween_property(target, "modulate", _base_modulate, 0.12)


func die() -> void:
	Audio.play_sfx("enemy_death", randf_range(0.9, 1.1))
	_try_drop_card()
	_try_drop_heal_item()
	_spawn_loot_drops()
	queue_free()


func _try_drop_heal_item() -> void:
	var drop_kind: String = String(_enemy_visual_def.get("heal_drop", ""))
	var chance: float = float(_enemy_visual_def.get("heal_drop_chance", 0.0))
	chance = Global.compute_food_drop_chance(chance)
	if drop_kind.is_empty() or loot_scene == null or randf() > chance:
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
	if randf() > get_card_drop_chance():
		return
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
				pickup.global_position = global_position
				if pickup.has_method("configure"):
					pickup.configure(_card_id, card_data)
			return
	Global.unlock_card(_card_id, card_data)
