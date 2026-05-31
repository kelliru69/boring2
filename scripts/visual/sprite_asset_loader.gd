## Carga texturas PNG/SVG desde assets/ con escala uniforme.
class_name SpriteAssetLoader
extends RefCounted

static func try_apply(sprite: Sprite2D, asset_path: String, target_height: float = 32.0) -> bool:
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
	sprite.scale = Vector2(scale_factor, scale_factor)
	sprite.centered = true
	sprite.modulate = Color.WHITE
	return true
