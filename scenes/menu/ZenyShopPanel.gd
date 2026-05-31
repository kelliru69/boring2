## Sub-menú: tienda persistente de Zeny — tarjetas premium por artículo.
extends Control

const _MetaShop = preload("res://data/meta_shop.gd")
const _Theme = preload("res://scripts/ui/modern_ui_theme.gd")
const _CardScene: PackedScene = preload("res://scenes/ui/components/ShopItemCard.tscn")
const _DefaultIcon: Texture2D = preload("res://icon.svg")

@onready var zeny_label: Label = $Margin/VBox/Header/ZenyLabel
@onready var hint_label: Label = $Margin/VBox/HintLabel
@onready var list: VBoxContainer = $Margin/VBox/Scroll/List

var _cards: Dictionary = {}


func _ready() -> void:
	visible = false
	if hint_label:
		hint_label.text = "Balance ~%d Z/run en Prontera. «−» baja nivel (pruebas, sin reembolso)." % _MetaShop.ESTIMATED_PRONTERA_RUN_ZENY
		_Theme.style_subtitle(hint_label, 12)
	_Theme.style_title($Margin/VBox/Header/ShopTitle, 22)
	Global.shop_updated.connect(_refresh)
	Global.zeny_gained.connect(_on_zeny_changed)
	_build_cards()
	_refresh()


func show_panel() -> void:
	visible = true
	_refresh()


func hide_panel() -> void:
	visible = false


func _on_zeny_changed(_amount: int, _total: int) -> void:
	_refresh()


func _build_cards() -> void:
	for child: Node in list.get_children():
		child.queue_free()
	_cards.clear()
	_add_section_header("Desbloqueos")
	for upgrade_id: String in _MetaShop.UNLOCK_IDS:
		_add_shop_card(upgrade_id)
	_add_section_header("Aumentos")
	for upgrade_id: String in _MetaShop.STAT_IDS:
		_add_shop_card(upgrade_id)


func _add_section_header(title: String) -> void:
	var lbl := Label.new()
	lbl.text = title
	_Theme.style_accent(lbl, 16)
	list.add_child(lbl)


func _add_shop_card(upgrade_id: String) -> void:
	var card: PanelContainer = _CardScene.instantiate() as PanelContainer
	card.name = upgrade_id
	list.add_child(card)
	_cards[upgrade_id] = card
	if card.has_signal("buy_pressed"):
		card.buy_pressed.connect(_on_buy_pressed)
	if card.has_signal("minus_pressed"):
		card.minus_pressed.connect(_on_minus_pressed)


func _on_buy_pressed(upgrade_id: String) -> void:
	Audio.play_ui_click()
	if Global.purchase_shop_upgrade(upgrade_id):
		_refresh()


func _on_minus_pressed(upgrade_id: String) -> void:
	Audio.play_ui_click()
	if Global.decrease_shop_upgrade(upgrade_id):
		_refresh()


func _refresh() -> void:
	_Theme.style_zeny(zeny_label, 20)
	zeny_label.text = "Zeny disponible: %d" % Global.total_zeny
	for upgrade_id: String in _cards:
		var card: Node = _cards[upgrade_id]
		if not card.has_method("setup"):
			continue
		var def: Dictionary = _MetaShop.get_definition(upgrade_id)
		var level: int = Global.get_shop_purchase_count(upgrade_id)
		var max_lv: int = _MetaShop.get_max_level(upgrade_id)
		var cost: int = Global.get_shop_cost(upgrade_id)
		card.setup(
			upgrade_id,
			def,
			level,
			max_lv,
			cost,
			Global.can_purchase_shop(upgrade_id),
			_DefaultIcon
		)
