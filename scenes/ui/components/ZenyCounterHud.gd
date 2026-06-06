## Contador de Zeny con icono de moneda y outline (esquina superior derecha).
class_name ZenyCounterHud
extends Control

const _HudIcons = preload("res://data/hud_icon_registry.gd")
const _MapConfig = preload("res://data/map_config.gd")

@onready var _coin: TextureRect = $HBox/CoinIcon
@onready var _amount: Label = $HBox/AmountLabel


func _ready() -> void:
	anchors_preset = Control.PRESET_TOP_RIGHT
	offset_left = -240.0
	offset_top = 12.0
	offset_right = -14.0
	offset_bottom = 48.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _amount:
		_amount.add_theme_color_override(&"font_color", Color(1.0, 0.92, 0.35, 1.0))
		_amount.add_theme_color_override(&"font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
		_amount.add_theme_constant_override(&"outline_size", 5)
		_amount.add_theme_font_size_override(&"font_size", 20)
	var tex: Texture2D = _HudIcons.get_zeny_coin_icon()
	if tex and _coin:
		_coin.texture = tex
	refresh()


func refresh() -> void:
	if _amount == null:
		return
	if _MapConfig.is_campaign_tier_map(Game.selected_map_id):
		_amount.text = "%d Z⚔" % Global.campaign_zeny
	else:
		_amount.text = "%s" % _format_zeny(Global.total_zeny)


static func _format_zeny(value: int) -> String:
	var s: String = str(maxi(value, 0))
	if s.length() <= 3:
		return s
	var parts: PackedStringArray = PackedStringArray()
	while s.length() > 3:
		parts.insert(0, s.substr(s.length() - 3, 3))
		s = s.substr(0, s.length() - 3)
	if not s.is_empty():
		parts.insert(0, s)
	return ",".join(parts)
