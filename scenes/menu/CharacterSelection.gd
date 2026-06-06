## Selección de clase y skin antes del hub de preparación.

extends Control



const _Theme = preload("res://scripts/ui/modern_ui_theme.gd")

const _MenuEsc = preload("res://scripts/ui/menu_esc_handler.gd")

const _ClassCatalog = preload("res://data/menu_class_catalog.gd")

const _SkinCatalog = preload("res://data/player_skin_catalog.gd")

const _CardScene: PackedScene = preload("res://scenes/ui/components/ClassSelectCard.tscn")

const BACKGROUND_PATH: String = "res://art/background.png"



@onready var background: TextureRect = $Background

@onready var title_label: Label = $RootMargin/RootVBox/Header/TitleLabel

@onready var skin_title_label: Label = $RootMargin/RootVBox/SkinSection/SkinTitleLabel

@onready var skin_row: HBoxContainer = $RootMargin/RootVBox/SkinSection/SkinRow

@onready var cards_row: HBoxContainer = $RootMargin/RootVBox/CardsRow

@onready var back_button: Button = $RootMargin/RootVBox/Footer/BackButton



var _selected_skin_id: String = _SkinCatalog.SKIN_BLUE_CAT

var _skin_panels: Dictionary = {}





func _ready() -> void:

	if ResourceLoader.exists(BACKGROUND_PATH):

		background.texture = load(BACKGROUND_PATH) as Texture2D

	_Theme.style_title(title_label, 26)

	title_label.text = "Elige tu clase"

	_Theme.style_subtitle(skin_title_label, 15)

	skin_title_label.text = "Apariencia del personaje"

	_selected_skin_id = Game.selected_player_skin_id

	if not _SkinCatalog.is_valid(_selected_skin_id):

		_selected_skin_id = Global.player_skin_id

	_Theme.apply_button(back_button, 40.0)

	back_button.pressed.connect(_on_back_pressed)

	_build_skin_picker()

	_build_cards()





func _build_skin_picker() -> void:

	for child: Node in skin_row.get_children():

		child.queue_free()

	_skin_panels.clear()

	for skin_def: Dictionary in _SkinCatalog.get_all_skins():

		var skin_id: String = String(skin_def.get("id", ""))

		var panel: PanelContainer = PanelContainer.new()

		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		panel.add_theme_stylebox_override(&"panel", _Theme.make_card_style(skin_id == _selected_skin_id))

		panel.mouse_filter = Control.MOUSE_FILTER_STOP

		panel.gui_input.connect(_on_skin_panel_input.bind(skin_id, panel))

		panel.mouse_entered.connect(_on_skin_hover.bind(panel, true))

		panel.mouse_exited.connect(_on_skin_hover.bind(panel, false))

		var margin := MarginContainer.new()

		margin.add_theme_constant_override(&"margin_left", 12)

		margin.add_theme_constant_override(&"margin_top", 10)

		margin.add_theme_constant_override(&"margin_right", 12)

		margin.add_theme_constant_override(&"margin_bottom", 10)

		panel.add_child(margin)

		var vbox := VBoxContainer.new()

		vbox.add_theme_constant_override(&"separation", 8)

		vbox.alignment = BoxContainer.ALIGNMENT_CENTER

		margin.add_child(vbox)

		var portrait_frame := PanelContainer.new()

		portrait_frame.custom_minimum_size = Vector2(72, 72)

		portrait_frame.add_theme_stylebox_override(&"panel", _Theme.make_panel_style())

		var portrait := TextureRect.new()

		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE

		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

		portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

		portrait.custom_minimum_size = Vector2(64, 64)

		portrait.texture = _get_skin_preview_texture(skin_def)

		portrait_frame.add_child(portrait)

		vbox.add_child(portrait_frame)

		var name_lbl := Label.new()

		name_lbl.text = String(skin_def.get("display_name", skin_id))

		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		_Theme.style_title(name_lbl, 16)

		vbox.add_child(name_lbl)

		var desc_lbl := Label.new()

		desc_lbl.text = String(skin_def.get("description", ""))

		desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

		_Theme.style_body(desc_lbl, 11)

		vbox.add_child(desc_lbl)

		skin_row.add_child(panel)

		_skin_panels[skin_id] = panel

	_refresh_skin_highlight()





func _on_skin_panel_input(event: InputEvent, skin_id: String, _panel: PanelContainer) -> void:

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:

		Audio.play_ui_click()

		_select_skin(skin_id)





func _on_skin_hover(panel: PanelContainer, hovered: bool) -> void:

	if String(panel.get_meta("skin_id", "")) == _selected_skin_id:

		return

	panel.add_theme_stylebox_override(&"panel", _Theme.make_card_style(hovered))





func _select_skin(skin_id: String) -> void:

	if not _SkinCatalog.is_valid(skin_id):

		return

	_selected_skin_id = skin_id

	_refresh_skin_highlight()





func _refresh_skin_highlight() -> void:

	for skin_id: String in _skin_panels:

		var panel: PanelContainer = _skin_panels[skin_id] as PanelContainer

		if panel == null:

			continue

		panel.set_meta("skin_id", skin_id)

		panel.add_theme_stylebox_override(&"panel", _Theme.make_card_style(skin_id == _selected_skin_id))





func _build_cards() -> void:

	for child: Node in cards_row.get_children():

		child.queue_free()

	var entries: Array[Dictionary] = [_ClassCatalog.get_mage_entry(), _ClassCatalog.get_swordman_entry()]

	for entry: Dictionary in entries:

		var card: ClassSelectCard = _CardScene.instantiate() as ClassSelectCard

		cards_row.add_child(card)

		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		card.setup(entry)

		if card.has_signal("class_chosen"):

			card.class_chosen.connect(_on_class_chosen)





func _on_class_chosen(class_id: String) -> void:

	if class_id != Game.CLASS_MAGE and class_id != Game.CLASS_SWORDMAN:

		return

	Global.select_class_for_run(class_id, _selected_skin_id)

	Game.go_to_preparation()





func _unhandled_input(event: InputEvent) -> void:

	if _MenuEsc.is_back_pressed(event):

		_on_back_pressed()

		_MenuEsc.mark_input_handled(self)





func _on_back_pressed() -> void:

	Audio.play_ui_click()

	Game.go_to_title()


func _get_skin_preview_texture(skin_def: Dictionary) -> Texture2D:
	var tex: Texture2D = PlayerDirectionalSpriteFrames.get_preview_texture(skin_def)
	if tex != null:
		return tex
	if not bool(skin_def.get("use_scene_default", false)):
		return null
	var player_packed: PackedScene = load("res://scenes/player/Player.tscn") as PackedScene
	if player_packed == null:
		return null
	var temp: Node = player_packed.instantiate()
	var anim: AnimatedSprite2D = temp.get_node_or_null("VisualRoot/AnimatedSprite2D") as AnimatedSprite2D
	if anim and anim.sprite_frames and anim.sprite_frames.has_animation(&"idle_down"):
		tex = anim.sprite_frames.get_frame_texture(&"idle_down", 0)
	temp.queue_free()
	return tex
