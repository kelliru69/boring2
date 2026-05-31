## Menú principal: selección de clase/mapa e inicio de partida.
extends Control

@onready var class_option: OptionButton = $Panel/Margin/VBox/ClassRow/ClassOption
@onready var map_option: OptionButton = $Panel/Margin/VBox/MapRow/MapOption
@onready var start_button: Button = $Panel/Margin/VBox/StartButton


func _ready() -> void:
	_setup_selectors()
	start_button.pressed.connect(_on_start_pressed)


func _setup_selectors() -> void:
	class_option.clear()
	class_option.add_item("Mage", 0)
	class_option.selected = 0
	class_option.disabled = false
	map_option.clear()
	map_option.add_item("Prontera Fields", 0)
	map_option.selected = 0
	map_option.disabled = false


func _on_start_pressed() -> void:
	Audio.play_ui_click()
	Game.selected_class_id = "mage"
	Game.selected_map_id = "prontera_fields"
	Game.start_new_run()
