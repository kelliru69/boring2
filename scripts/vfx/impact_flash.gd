## Destello breve suave (Sprite2D radial) — evita el recuadro de 1 frame de PointLight2D.
extends RefCounted
class_name ImpactFlash

const _Budget = preload("res://scripts/vfx/combat_vfx_budget.gd")


static func spawn(
	parent: Node,
	world_pos: Vector2,
	color: Color = Color(0.85, 0.92, 1.0, 1.0),
	energy: float = 1.2,
	duration: float = 0.08,
	texture_scale: float = 2.4
) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	if not _Budget.allow_impact_flash(world_pos):
		return
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = VfxTextureFactory.get_soft_radial(VfxTextureFactory.RadialProfile.GLOW_ORB)
	sprite.centered = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.modulate = Color(color.r, color.g, color.b, 0.0)
	sprite.scale = Vector2.ZERO
	sprite.top_level = true
	sprite.visible = false
	sprite.z_index = 20
	sprite.z_as_relative = false
	CombatVfxPalette.apply_soft_blend(sprite)
	parent.add_child(sprite)
	sprite.set_deferred("global_position", world_pos)
	sprite.call_deferred("set_visible", true)
	var peak_scale: float = texture_scale * 0.16 * energy
	var tw: Tween = sprite.create_tween()
	tw.set_parallel(true)
	tw.tween_property(sprite, "scale", Vector2(peak_scale, peak_scale), 0.035).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(sprite, "modulate:a", color.a * 0.45, 0.035)
	tw.chain().tween_property(sprite, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tw.tween_callback(sprite.queue_free)
