## Hub de preparación — tienda, álbum y avance al selector de mapa.
extends Control

const _Theme = preload("res://scripts/ui/modern_ui_theme.gd")
const _MenuEsc = preload("res://scripts/ui/menu_esc_handler.gd")
const BACKGROUND_PATH: String = "res://art/background.png"

enum PanelMode { HUB, SHOP, ALBUM }

@onready var background: TextureRect = $Background
@onready var hub_panel: PanelContainer = $HubPanel
@onready var title_label: Label = $HubPanel/Margin/VBox/TitleLabel
@onready var subtitle_label: Label = $HubPanel/Margin/VBox/SubtitleLabel
@onready var zeny_label: Label = $HubPanel/Margin/VBox/ZenyLabel
@onready var shop_button: Button = $HubPanel/Margin/VBox/ActionsRow/ShopButton
@onready var cards_button: Button = $HubPanel/Margin/VBox/ActionsRow/CardsButton
@onready var back_button: Button = $HubPanel/Margin/VBox/Footer/BackButton
@onready var ready_button: Button = $HubPanel/Margin/VBox/Footer/ReadyButton
@onready var overlay_panels: Control = $OverlayPanels
@onready var zeny_shop: Control = $OverlayPanels/ZenyShopPanel
@onready var card_album: Control = $OverlayPanels/CardAlbumPanel
@onready var overlay_back_button: Button = $OverlayBackButton


func _ready() -> void:
	PrepAccessButton.attach_to(self)
	if ResourceLoader.exists(BACKGROUND_PATH):
		background.texture = load(BACKGROUND_PATH) as Texture2D
	_Theme.apply_panel(hub_panel)
	_Theme.style_title(title_label, 28)
	title_label.text = "Preparación"
	_Theme.style_subtitle(subtitle_label, 14)
	subtitle_label.text = "Mejora tu build antes de entrar al campo de batalla."
	_Theme.style_zeny(zeny_label, 18)
	for btn: Button in [shop_button, cards_button, back_button]:
		_Theme.apply_button(btn, 48.0)
	_Theme.apply_cta_button(ready_button, 54.0)
	ready_button.text = "¡LISTO! — Elegir mapa"
	shop_button.pressed.connect(_open_shop)
	cards_button.pressed.connect(_open_album)
	back_button.pressed.connect(_on_back)
	ready_button.pressed.connect(_on_ready)
	_Theme.apply_button(overlay_back_button, 40.0)
	overlay_back_button.text = "← Volver al hub"
	overlay_back_button.pressed.connect(_on_overlay_back)
	overlay_back_button.visible = false
	Global.zeny_gained.connect(_on_zeny_changed)
	Global.campaign_zeny_gained.connect(_on_zeny_changed)
	Global.profile_loaded.connect(_refresh_zeny)
	if Game.intermap_preparation_mode:
		_configure_intermap_mode()
	else:
		_show_mode(PanelMode.HUB)
	_refresh_zeny()


func _configure_intermap_mode() -> void:
	title_label.text = "Preparación — Siguiente mapa"
	var next_name: String = Game.get_continue_map_display_name(Game.selected_map_id)
	if next_name.is_empty():
		next_name = "siguiente mapa"
	subtitle_label.text = "Equipa las cartas que obtuviste en esta run antes de continuar a %s." % next_name
	ready_button.text = "Continuar a %s" % next_name
	back_button.text = "Menú principal"
	_show_mode(PanelMode.ALBUM)
	if card_album.has_method("show_panel"):
		card_album.show_panel()


func _refresh_zeny() -> void:
	if Global.campaign_zeny > 0 or Global.map_2_cleared:
		zeny_label.text = "Zeny: %d  ·  Campaña: %d Z⚔" % [Global.total_zeny, Global.campaign_zeny]
	else:
		zeny_label.text = "Zeny: %d" % Global.total_zeny


func _on_zeny_changed(_amount: int, _total: int) -> void:
	_refresh_zeny()


func _on_overlay_back() -> void:
	Audio.play_ui_click()
	_show_mode(PanelMode.HUB)


func _show_mode(mode: PanelMode) -> void:
	hub_panel.visible = mode == PanelMode.HUB
	overlay_back_button.visible = mode != PanelMode.HUB
	# OverlayPanels es fullscreen: sin IGNORE bloquea todos los clics del hub.
	if overlay_panels:
		overlay_panels.mouse_filter = Control.MOUSE_FILTER_IGNORE if mode == PanelMode.HUB else Control.MOUSE_FILTER_STOP
	if zeny_shop.has_method("hide_panel"):
		zeny_shop.hide_panel()
	if card_album.has_method("hide_panel"):
		card_album.hide_panel()
	match mode:
		PanelMode.SHOP:
			if zeny_shop.has_method("show_panel"):
				zeny_shop.show_panel()
		PanelMode.ALBUM:
			if card_album.has_method("show_panel"):
				card_album.show_panel()


func _open_shop() -> void:
	Audio.play_ui_click()
	_show_mode(PanelMode.SHOP)


func _open_album() -> void:
	Audio.play_ui_click()
	_show_mode(PanelMode.ALBUM)


func _unhandled_input(event: InputEvent) -> void:
	if not _MenuEsc.is_back_pressed(event):
		return
	if overlay_back_button.visible:
		_on_overlay_back()
	else:
		_on_back()
	_MenuEsc.mark_input_handled(self)


func _on_back() -> void:
	Audio.play_ui_click()
	if Game.intermap_preparation_mode and hub_panel.visible:
		Game.intermap_preparation_mode = false
		Game.go_to_title()
		return
	if hub_panel.visible:
		Game.go_to_character_selection()
	else:
		_show_mode(PanelMode.HUB)


func _on_ready() -> void:
	Audio.play_ui_click()
	if Game.intermap_preparation_mode:
		Game.intermap_preparation_mode = false
		Game.continue_to_next_map()
		return
	Game.go_to_map_selection()


func _exit_tree() -> void:
	if Global.zeny_gained.is_connected(_on_zeny_changed):
		Global.zeny_gained.disconnect(_on_zeny_changed)
	if Global.campaign_zeny_gained.is_connected(_on_zeny_changed):
		Global.campaign_zeny_gained.disconnect(_on_zeny_changed)
	if Global.profile_loaded.is_connected(_refresh_zeny):
		Global.profile_loaded.disconnect(_refresh_zeny)
