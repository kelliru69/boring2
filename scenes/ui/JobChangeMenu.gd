## Menú de Job Change — tras vencer el jefe del Mapa 2.
extends CanvasLayer

signal job_selected(job_id: String)

const _Theme = preload("res://scripts/ui/modern_ui_theme.gd")
const _Fusion = preload("res://data/job_fusion_catalog.gd")

@onready var dimmer: ColorRect = $Dimmer
@onready var panel: PanelContainer = $PanelContainer
@onready var title_label: Label = $PanelContainer/Margin/VBox/TitleLabel
@onready var subtitle_label: Label = $PanelContainer/Margin/VBox/SubtitleLabel
@onready var choices_row: HBoxContainer = $PanelContainer/Margin/VBox/ChoicesRow
@onready var fusion_label: Label = $PanelContainer/Margin/VBox/FusionLabel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_Theme.apply_panel(panel)
	_Theme.style_title(title_label, 22)
	_Theme.style_subtitle(subtitle_label, 13)


func show_menu() -> void:
	title_label.text = "Job Change"
	subtitle_label.text = (
		"Elige tu evolución antes de avanzar a Orc Village.\n\n"
		+ "Las fusiones sin ingredientes en Nv.5 se desbloquearán solas cuando completes "
		+ "los requisitos durante la partida (los ingredientes se consumen al fusionar)."
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
		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(220.0, 120.0)
		btn.text = "%s\n%s" % [_Fusion.get_job_display_name(job_id), _Fusion.get_job_description(job_id)]
		_Theme.apply_button(btn, 120.0)
		btn.pressed.connect(_on_job_pressed.bind(job_id))
		choices_row.add_child(btn)


func _update_fusion_preview() -> void:
	var lines: PackedStringArray = PackedStringArray()
	for job_id: String in Global.get_campaign_job_options():
		lines.append("[%s]" % _Fusion.get_job_display_name(job_id))
		for recipe: Dictionary in _Fusion.get_fusion_recipes_for_job(job_id):
			lines.append("  • " + _Fusion.describe_recipe_for_job_change(recipe))
	if lines.is_empty():
		fusion_label.text = "Sin fusiones disponibles para tu clase."
	else:
		fusion_label.text = "Fusiones por clase:\n" + "\n".join(lines)


func _on_job_pressed(job_id: String) -> void:
	Audio.play_ui_click()
	if Global.apply_campaign_job_change(job_id):
		job_selected.emit(job_id)
		hide_menu()
