## Drop de soporte raro: cruz verde con curación instantánea y bufos temporales.
class_name HealBuffDrop
extends Area2D

const GROUP: String = "HealBuffDrop"
const HEAL_MAX_HP_RATIO: float = 0.20
const CROSS_TEXTURE_SIZE: int = 36

var _collected: bool = false
var _pulse_time: float = 0.0

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	z_index = 64
	z_as_relative = false
	add_to_group(GROUP)
	body_entered.connect(_on_body_entered)
	collision_layer = 8
	collision_mask = 1
	monitoring = true
	if _sprite:
		_sprite.texture = _create_cross_texture(CROSS_TEXTURE_SIZE)
		_sprite.centered = true


func _process(delta: float) -> void:
	if _collected or _sprite == null:
		return
	_pulse_time += delta
	var pulse: float = 1.0 + 0.1 * sin(_pulse_time * 5.0)
	_sprite.scale = Vector2(pulse, pulse)


func _on_body_entered(body: Node2D) -> void:
	if _collected or not body.is_in_group("Jugador"):
		return
	var player: Player = body as Player
	if player == null:
		return
	_collected = true
	player.apply_heal_buff_pickup(HEAL_MAX_HP_RATIO)
	queue_free()


static func _create_cross_texture(size: int) -> ImageTexture:
	var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	var fill: Color = Color(0.22, 0.95, 0.38, 1.0)
	var outline: Color = Color(0.05, 0.35, 0.12, 1.0)
	var arm: int = maxi(int(size / 5.0), 3)
	var center: int = int(float(size) / 2.0)
	for y: int in size:
		for x: int in size:
			var on_vertical: bool = absi(x - center) < arm and absi(y - center) < int(size * 0.42)
			var on_horizontal: bool = absi(y - center) < arm and absi(x - center) < int(size * 0.42)
			if not on_vertical and not on_horizontal:
				continue
			var edge: bool = absi(x - center) >= arm - 1 or absi(y - center) >= arm - 1
			image.set_pixel(x, y, outline if edge else fill)
	return ImageTexture.create_from_image(image)
