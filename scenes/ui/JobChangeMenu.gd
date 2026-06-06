## Menú de Job Change — scroll suave + ilustración de fondo por clase.
extends CanvasLayer

signal job_selected(job_id: String)

const _Theme = preload("res://scripts/ui/modern_ui_theme.gd")
const _Fusion = preload("res://data/job_fusion_catalog.gd")
const _ClassCatalog = preload("res://data/class_select_catalog.gd")

@onready var dimmer: ColorRect = $Dimmer
@onready var panel: PanelContainer = $PanelContainer
@onready var title_label: Label = $PanelContainer/Margin/VBox/TitleLabel
@onready var subtitle_label: Label = $PanelContainer/Margin/VBox/SubtitleLabel
@onready var job_bg: TextureRect = $PanelContainer/Margin/VBox/Body/JobBackground
@onready var job_bg_fade: ColorRect = $PanelContainer/Margin/VBox/Body/JobBackgroundFade
@onready var scroll: ScrollContainer = $PanelContainer/Margin/VBox/Body/ScrollRow/Scroll
@onready var choices_row: HBoxContainer = $PanelContainer/Margin/VBox/Body/ScrollRow/Scroll/ChoicesRow
@onready var fusion_scroll: ScrollContainer = $PanelContainer/Margin/VBox/FusionScroll
@onready var fusion_label: Label = $PanelContainer/Margin/VBox/FusionScroll/FusionLabel

var _bg_tween: Tween = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_Theme.apply_panel(panel)
	_Theme.style_title(title_label, 22)
	_Theme.style_subtitle(subtitle_label, 13)
	job_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED


func show_menu() -> void:
	title_label.text = "Job Change"
	subtitle_label.text = (
		"Elige tu evolución. Los ingredientes fusionados conservan Nv.5 para requisitos futuros."
	)
	_rebuild_choices()
	_update_fusion_preview()
	get_tree().paused = true
	visible = true


func hide_menu() -> void:
	visible = false
	get_tree().paused = false


func _rebuild_choices() -> void:
	for child: Node in choices_row.get_children():
		child.queue_free()
	var jobs: Array[String] = Global.get_campaign_job_options()
	for job_id: String in jobs:
		var card := _make_job_card(job_id)
		choices_row.add_child(card)
	if not jobs.is_empty():
		_update_job_background(jobs[0], false)


func _make_job_card(job_id: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(240.0, 140.0)
	card.add_theme_stylebox_override(&"panel", _Theme.make_card_style())
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margin)
	var vbox := VBoxContainer.new()
	margin.add_child(vbox)
	var name_lbl := Label.new()
	name_lbl.text = _Fusion.get_job_display_name(job_id)
	_Theme.style_title(name_lbl, 18)
	var desc_lbl := Label.new()
	desc_lbl.text = _Fusion.get_job_description(job_id)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_Theme.style_body(desc_lbl, 12)
	var btn := Button.new()
	btn.text = "Elegir %s" % _Fusion.get_job_display_name(job_id)
	_Theme.apply_button(btn, 38.0)
	btn.pressed.connect(_on_job_pressed.bind(job_id))
	btn.mouse_entered.connect(func() -> void: _update_job_background(job_id, true))
	vbox.add_child(name_lbl)
	vbox.add_child(desc_lbl)
	vbox.add_child(btn)
	return card


func _update_job_background(job_id: String, animate: bool) -> void:
	var tex: Texture2D = _resolve_job_art(job_id)
	if tex:
		job_bg.texture = tex
	if not animate:
		job_bg_fade.modulate.a = 0.0
		return
	if _bg_tween != null and _bg_tween.is_valid():
		_bg_tween.kill()
	job_bg_fade.modulate.a = 1.0
	_bg_tween = create_tween()
	_bg_tween.tween_property(job_bg_fade, "modulate:a", 0.0, 0.3)


func _resolve_job_art(job_id: String) -> Texture2D:
	var class_data: ClassData = _ClassCatalog.get_class_by_id(job_id)
	if class_data != null and class_data.class_background != null:
		return class_data.class_background
	return null


func _update_fusion_preview() -> void:
	var lines: PackedStringArray = PackedStringArray()
	for job_id: String in Global.get_campaign_job_options():
		lines.append("[%s]" % _Fusion.get_job_display_name(job_id))
		for recipe: Dictionary in _Fusion.get_fusion_recipes_for_job(job_id):
			lines.append("  • " + _Fusion.describe_recipe_for_job_change(recipe))
	if lines.is_empty():
		fusion_label.text = "Sin fusiones disponibles para tu clase."
	else:
		fusion_label.text = "Requisitos de fusión:\n" + "\n".join(lines)


func _on_job_pressed(job_id: String) -> void:
	Audio.play_ui_click()
	if Global.apply_campaign_job_change(job_id):
		job_selected.emit(job_id)
		hide_menu()
