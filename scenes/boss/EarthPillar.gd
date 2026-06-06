## Pilar de tierra — obstáculo temporal que bloquea movimiento y proyectiles.
extends StaticBody2D
class_name EarthPillar

const GROUP: StringName = &"earth_pillar"
const LIFETIME_SEC: float = 6.0

@export var pillar_radius: float = 28.0

var _lifetime_left: float = LIFETIME_SEC


func _ready() -> void:
	add_to_group(GROUP)
	collision_layer = CollisionLayers.LAYER_ENEMIES
	collision_mask = CollisionLayers.LAYER_PLAYER | CollisionLayers.LAYER_PROJECTILES
	_build_shapes()
	_build_visual()
	set_process(true)


func _build_shapes() -> void:
	var body_shape: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = pillar_radius
	body_shape.shape = circle
	add_child(body_shape)
	var projectile_blocker: Area2D = Area2D.new()
	projectile_blocker.collision_layer = 0
	projectile_blocker.collision_mask = CollisionLayers.LAYER_PROJECTILES
	var area_shape: CollisionShape2D = CollisionShape2D.new()
	var area_circle: CircleShape2D = CircleShape2D.new()
	area_circle.radius = pillar_radius * 1.05
	area_shape.shape = area_circle
	projectile_blocker.add_child(area_shape)
	projectile_blocker.area_entered.connect(_on_projectile_entered)
	add_child(projectile_blocker)


func _build_visual() -> void:
	var sprite: Sprite2D = Sprite2D.new()
	var img: Image = Image.create(48, 56, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.42, 0.32, 0.18, 0.95))
	sprite.texture = ImageTexture.create_from_image(img)
	sprite.position = Vector2(0.0, -8.0)
	add_child(sprite)
	z_index = 6


func _process(delta: float) -> void:
	_lifetime_left -= delta
	modulate.a = clampf(_lifetime_left / 1.2, 0.35, 1.0)
	if _lifetime_left <= 0.0:
		queue_free()


func _on_projectile_entered(area: Area2D) -> void:
	if is_instance_valid(area):
		area.queue_free()
