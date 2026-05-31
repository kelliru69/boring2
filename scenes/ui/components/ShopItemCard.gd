## Tarjeta de artículo en la tienda de Zeny.
extends PanelContainer

signal buy_pressed(upgrade_id: String)
signal minus_pressed(upgrade_id: String)

const _Theme = preload("res://scripts/ui/modern_ui_theme.gd")

var _upgrade_id: String = ""

@onready var _icon_frame: PanelContainer = $Margin/HBox/IconFrame
@onready var _icon: TextureRect = $Margin/HBox/IconFrame/Icon
@onready var _title: Label = $Margin/HBox/Info/Title
@onready var _desc: Label = $Margin/HBox/Info/Desc
@onready var _level: Label = $Margin/HBox/Info/Level
@onready var _price: Label = $Margin/HBox/Actions/Price
@onready var _minus_btn: Button = $Margin/HBox/Actions/MinusBtn
@onready var _buy_btn: Button = $Margin/HBox/Actions/BuyBtn


func _ready() -> void:
	add_theme_stylebox_override(&"panel", _Theme.make_card_style())
	if _icon_frame:
		_icon_frame.add_theme_stylebox_override(&"panel", _Theme.make_panel_style(_Theme.CARD_FILL, _Theme.PANEL_BORDER, 10, false))
	_Theme.wire_card_hover(self)
	_Theme.apply_button(_minus_btn, 36.0)
	_Theme.apply_button(_buy_btn, 40.0)
	_minus_btn.pressed.connect(func() -> void: minus_pressed.emit(_upgrade_id))
	_buy_btn.pressed.connect(func() -> void: buy_pressed.emit(_upgrade_id))


func setup(
	upgrade_id: String,
	def: Dictionary,
	level: int,
	max_level: int,
	cost: int,
	can_buy: bool,
	icon_tex: Texture2D = null
) -> void:
	_upgrade_id = upgrade_id
	_title.text = String(def.get("title", upgrade_id))
	_desc.text = String(def.get("description", ""))
	_level.text = "Nivel %d / %d" % [level, max_level]
	_Theme.style_title(_title, 16)
	_Theme.style_subtitle(_desc, 12)
	_Theme.style_accent(_level, 12)
	if icon_tex:
		_icon.texture = icon_tex
		_icon.modulate = Color.WHITE
	else:
		_icon.texture = null
		_icon.modulate = _Theme.ACCENT * Color(1, 1, 1, 0.35)
	if cost < 0:
		_price.text = "MAX"
		_Theme.style_subtitle(_price, 14)
	else:
		_price.text = "%d Z" % cost
		_Theme.style_zeny(_price, 17)
	_buy_btn.text = "Comprar" if cost >= 0 else "Completo"
	_buy_btn.disabled = not can_buy or cost < 0
	_minus_btn.disabled = level <= 0
