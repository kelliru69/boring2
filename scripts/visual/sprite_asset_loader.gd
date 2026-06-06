## Carga texturas PNG/SVG desde assets/ con escala configurable.
class_name SpriteAssetLoader
extends RefCounted

static func try_apply(
	sprite: Sprite2D,
	asset_path: String,
	target_height: float = 32.0,
	width_scale: float = 1.0
) -> bool:
	if asset_path.is_empty():
		return false
	if not ResourceLoader.exists(asset_path):
		return false
	var texture: Texture2D = load(asset_path) as Texture2D
	if texture == null:
		return false
	sprite.texture = texture
	var tex_height: float = maxf(float(texture.get_height()), 1.0)
	var scale_factor: float = target_height / tex_height
	var sx: float = scale_factor * maxf(width_scale, 0.05)
	sprite.scale = Vector2(sx, scale_factor)
	sprite.centered = true
	sprite.modulate = Color.WHITE
	return true
