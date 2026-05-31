## Hub de preparación — pestañas con tema moderno.
extends Control

enum Tab { SHOP, CARDS, RUN }

const _Theme = preload("res://scripts/ui/modern_ui_theme.gd")
const BACKGROUND_PATH: String = "res://art/background.png"

@onready var background: TextureRect = $Background
@onready var top_bar_panel: PanelContainer = $TopBarPanel
@onready var zeny_shop: Control = $Panels/ZenyShopPanel
@onready var card_album: Control = $Panels/CardAlbumPanel
@onready var run_setup: Control = $Panels/RunSetupPanel
@onready var shop_tab: Button = $TopBarPanel/Margin/TopBar/ShopTab
@onready var cards_tab: Button = $TopBarPanel/Margin/TopBar/CardsTab
@onready var run_tab: Button = $TopBarPanel/Margin/TopBar/RunTab
@onready var back_button: Button = $TopBarPanel/Margin/TopBar/BackButton


func _ready() -> void:
	if ResourceLoader.exists(BACKGROUND_PATH):
		background.texture = load(BACKGROUND_PATH) as Texture2D
	_Theme.apply_panel(top_bar_panel)
	for btn: Button in [back_button, shop_tab, cards_tab, run_tab]:
		_Theme.apply_button(btn, 36.0)
	shop_tab.pressed.connect(_show_tab.bind(Tab.SHOP))
	cards_tab.pressed.connect(_show_tab.bind(Tab.CARDS))
	run_tab.pressed.connect(_show_tab.bind(Tab.RUN))
	back_button.pressed.connect(_on_back)
	_show_tab(Tab.RUN)


func _show_tab(tab: Tab) -> void:
	Audio.play_ui_click()
	if zeny_shop.has_method("hide_panel"):
		zeny_shop.hide_panel()
	if card_album.has_method("hide_panel"):
		card_album.hide_panel()
	if run_setup.has_method("hide_panel"):
		run_setup.hide_panel()
	match tab:
		Tab.SHOP:
			if zeny_shop.has_method("show_panel"):
				zeny_shop.show_panel()
		Tab.CARDS:
			if card_album.has_method("show_panel"):
				card_album.show_panel()
		Tab.RUN:
			if run_setup.has_method("show_panel"):
				run_setup.show_panel()


func _on_back() -> void:
	Audio.play_ui_click()
	Game.go_to_title()
