## Lluvia de meteoros — proyectiles visibles + daño por tic (fusión Wizard).
extends Node2D

const _AreaHitHelper = preload("res://scripts/combat/area_hit_helper.gd")
const _HitFlash = preload("res://scripts/vfx/enemy_hit_flash.gd")
const _Vfx = preload("res://scripts/vfx/elemental_vfx_spawner.gd")

var _center: Vector2 = Vector2.ZERO
var _radius: float = 160.0
var _tick_damage: int = 18
var _duration: float = 4.5
var tick_interval: float = 0.32
var _elapsed: float = 0.0
var _tick_accum: float = 0.0

var _zone_indicator: Node2D = null
var _meteor_texture: Texture2D = null


func setup(
	world_center: Vector2,
	radius: float,
	tick_damage: int,
	duration: float = 4.5,
	strike_interval: float = 0.32
) -> void:
	global_position = world_center
	_center = world_center
	_radius = maxf(radius, 40.0)
	_tick_damage = maxi(tick_damage, 1)
	_duration = maxf(duration, 1.0)
	tick_interval = maxf(strike_interval, 0.08)
	_meteor_texture = _create_meteor_texture()
	_spawn_zone_indicator()


func _process(delta: float) -> void:
	_elapsed += delta
	_tick_accum += delta
	if _zone_indicator:
		var pulse: float = 0.55 + 0.45 * sin(_elapsed * 4.0)
		_zone_indicator.modulate.a = pulse
	if _elapsed >= _duration:
		if _zone_indicator:
			_zone_indicator.queue_free()
		queue_free()
		return
	if _tick_accum >= tick_interval:
		_tick_accum = 0.0
		_strike_random_meteor()


func _spawn_zone_indicator() -> void:
	_zone_indicator = Node2D.new()
	_zone_indicator.z_index = 8
	add_child(_zone_indicator)
	var ring := _create_ring_sprite(_radius)
	_zone_indicator.add_child(ring)


func _strike_random_meteor() -> void:
	var angle: float = randf() * TAU
	var dist: float = randf() * _radius
	var hit_pos: Vector2 = _center + Vector2.from_angle(angle) * dist
	_spawn_falling_meteor(hit_pos)


func _spawn_falling_meteor(target: Vector2) -> void:
	var parent: Node = get_parent()
	if parent == null:
		return
	var meteor := Sprite2D.new()
	meteor.texture = _meteor_texture
	meteor.z_index = 48
	meteor.scale = Vector2(1.4, 1.4)
	meteor.global_position = target + Vector2(randf_range(-24.0, 24.0), -300.0)
	parent.add_child(meteor)
	var tw: Tween = create_tween()
	tw.tween_property(meteor, "global_position", target, randf_range(0.28, 0.42)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		_Vfx.spawn_fire_impact(parent, target)
		_apply_hit_at(target)
		meteor.queue_free()
	)


func _apply_hit_at(hit_pos: Vector2) -> void:
	var world: World2D = get_world_2d()
	if world == null:
		return
	_AreaHitHelper.for_each_enemy_body_in_circle(hit_pos, _radius * 0.28, world, _on_hit)


func _on_hit(body: Node2D) -> void:
	if body and body.has_method("take_damage"):
		body.take_damage(_tick_damage, _HitFlash.ELEMENT_FIRE)


static func _create_meteor_texture() -> Texture2D:
	var size: int = 28
	var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	var core: Color = Color(1.0, 0.45, 0.12, 1.0)
	var tail: Color = Color(0.85, 0.22, 0.05, 0.9)
	var cx: int = int(size / 2)
	for y: int in size:
		for x: int in size:
			var dx: float = float(x - cx)
			var dy: float = float(y - cx)
			var dist: float = sqrt(dx * dx + dy * dy)
			if dist <= 5.0:
				image.set_pixel(x, y, core)
			elif dy > 0.0 and absf(dx) < 4.0 and dy < 12.0:
				image.set_pixel(x, y, tail)
	return ImageTexture.create_from_image(image)


static func _create_ring_sprite(radius: float) -> Sprite2D:
	var diameter: int = maxi(int(radius * 2.0), 64)
	var image: Image = Image.create(diameter, diameter, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	var center: int = int(diameter / 2)
	var ring_r: float = float(center) - 2.0
	for y: int in diameter:
		for x: int in diameter:
			var d: float = Vector2(float(x - center), float(y - center)).length()
			if d >= ring_r - 2.0 and d <= ring_r:
				image.set_pixel(x, y, Color(1.0, 0.35, 0.1, 0.55))
	var sprite := Sprite2D.new()
	sprite.texture = ImageTexture.create_from_image(image)
	sprite.centered = true
	return sprite
