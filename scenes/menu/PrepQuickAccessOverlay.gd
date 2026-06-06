## Overlay universal de cartas + tienda (sin bloqueo de mapa 1).
extends CanvasLayer

const _Theme = preload("res://scripts/ui/modern_ui_theme.gd")

@onready var _dimmer: ColorRect = $Dimmer
@onready var _panel: PanelContainer = $Panel
@onready var _shop_btn: Button = $Panel/Margin/VBox/ShopBtn
@onready var _album_btn: Button = $Panel/Margin/VBox/AlbumBtn
@onready var _close_btn: Button = $Panel/Margin/VBox/CloseBtn
@onready var _shop_panel: Control = $ZenyShopPanel
@onready var _album_panel: Control = $CardAlbumPanel


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_Theme.apply_panel(_panel)
	for btn: Button in [_shop_btn, _album_btn, _close_btn]:
		_Theme.apply_button(btn, 42.0)
	_shop_btn.pressed.connect(_open_shop)
	_album_btn.pressed.connect(_open_album)
	_close_btn.pressed.connect(close)


func open() -> void:
	visible = true
	_panel.visible = true
	if _shop_panel:
		_shop_panel.visible = false
	if _album_panel:
		_album_panel.visible = false


func close() -> void:
	visible = false
	if _shop_panel and _shop_panel.has_method("hide_panel"):
		_shop_panel.hide_panel()
	if _album_panel and _album_panel.has_method("hide_panel"):
		_album_panel.hide_panel()


func _open_shop() -> void:
	Audio.play_ui_click()
	_panel.visible = false
	if _shop_panel and _shop_panel.has_method("show_panel"):
		_shop_panel.show_panel()


func _open_album() -> void:
	Audio.play_ui_click()
	_panel.visible = false
	if _album_panel and _album_panel.has_method("show_panel"):
		_album_panel.show_panel()
