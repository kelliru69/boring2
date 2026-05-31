## Cielo claro estilo RO — gradiente suave detrás del mapa.
extends CanvasLayer

@export var sky_top_color: Color = Color(0.55, 0.78, 0.95, 1.0)
@export var sky_bottom_color: Color = Color(0.72, 0.88, 0.98, 1.0)


func _ready() -> void:
	layer = -200
	var sky: TextureRect = TextureRect.new()
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	var gradient: Gradient = Gradient.new()
	gradient.set_color(0, sky_top_color)
	gradient.set_color(1, sky_bottom_color)
	var tex: GradientTexture2D = GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill_from = Vector2(0.5, 0.0)
	tex.fill_to = Vector2(0.5, 1.0)
	tex.width = 4
	tex.height = 256
	sky.texture = tex
	add_child(sky)
