extends Control

const SLOT_TEXTURE = preload("res://assets/icon/Group 113.png")

@onready var saves_list = $TextureRect/Controlsave/SavesList 
var save_counter = 1

func _ready():
	$TextureRect/PlayButton.pressed.connect(_on_play_pressed) 
	$TextureRect/SaveButton.pressed.connect(_on_save_pressed) 
	$TextureRect/CustomizationButton.pressed.connect(_on_customization_pressed) 
	$TextureRect/SettingsButton.pressed.connect(_on_settings_pressed)
	$TextureRect/ExitButton.pressed.connect(_on_exit_pressed)
	
	$TextureRect/Controlvixod/yes.pressed.connect(_on_confirm_exit) 
	$TextureRect/Controlvixod/no.pressed.connect(_on_cancel_exit) 
	$TextureRect/Controlvixod/krest.pressed.connect(_on_cancel_exit)
	
	$TextureRect/Controlset/vixod.pressed.connect(_on_close_settings_pressed)
	
	$TextureRect/Controlsave/vixod.pressed.connect(_on_close_save_pressed)
	
	$TextureRect/Controlsave/add.pressed.connect(_on_add_save_button_pressed)
	$TextureRect/Controlsave/delete.pressed.connect(_on_delete_save_button_pressed)
	
	$TextureRect/Controlvixod.visible = false 
	$TextureRect/Controlset.visible = false
	$TextureRect/Controlsave.visible = false
	
	var custom_font = load("res://assets/text/PixelifySans-VariableFont_wght.ttf")

	var fps_button = $"TextureRect/Controlset/FPSButton"

	var popup = fps_button.get_popup()

	var new_style = StyleBoxFlat.new()
	new_style.bg_color = Color("d0cde6") 
	new_style.set_corner_radius_all(8)  

	new_style.content_margin_left = 15
	new_style.content_margin_right = 15
	new_style.content_margin_top = 10
	new_style.content_margin_bottom = 10
	
	popup.add_theme_stylebox_override("panel", new_style)

	if custom_font:
		popup.add_theme_font_override("font", custom_font)
	popup.add_theme_font_size_override("font_size", 35)

	popup.add_theme_color_override("font_color", Color.BLACK)        
	popup.add_theme_color_override("font_hover_color", Color.BLACK)

func _on_play_pressed():
	get_tree().change_scene_to_file("res://scenes/intro.tscn")

func _on_exit_pressed():
	$TextureRect/Controlvixod.visible = true

func _on_confirm_exit():
	get_tree().quit()

func _on_cancel_exit():
	$TextureRect/Controlvixod.visible = false 

func _on_save_pressed():
	$TextureRect/Controlsave.visible = true

func _on_customization_pressed():
	get_tree().change_scene_to_file("res://scenes/customization.tscn")

func _on_settings_pressed():
	$TextureRect/Controlset.visible = true

func _on_close_settings_pressed():
	$TextureRect/Controlset.visible = false

func _on_close_save_pressed():
	$TextureRect/Controlsave.visible = false

func _on_add_save_button_pressed():
	if saves_list.get_child_count() >= 3:
		print("Достигнут максимум сохранений!")
		return
	
	var new_slot = TextureRect.new()
	new_slot.texture = SLOT_TEXTURE
	
	var custom_font = load("res://assets/text/PixelifySans-VariableFont_wght.ttf")
	
	var name_label = Label.new()
	name_label.text = "СОХРАНЕНИЕ\nмиссия 1-" + str(save_counter)
	name_label.position = Vector2(140, 20) 
	name_label.add_theme_color_override("font_color", Color.BLACK)
	if custom_font:
		name_label.add_theme_font_override("font", custom_font)
		name_label.add_theme_font_size_override("font_size", 28) 

	var date_label = Label.new()
	date_label.text = "18:24\n19.05.2026" 
	date_label.position = Vector2(800, 20) 
	date_label.add_theme_color_override("font_color", Color.BLACK)
	if custom_font:
		date_label.add_theme_font_override("font", custom_font)
		date_label.add_theme_font_size_override("font_size", 24) 
	
	new_slot.add_child(name_label)
	new_slot.add_child(date_label)

	saves_list.add_child(new_slot)
	
	save_counter += 1

func _on_delete_save_button_pressed():
	if saves_list.get_child_count() == 0:
		return

	var last_slot = saves_list.get_child(saves_list.get_child_count() - 1)

	last_slot.queue_free()

	if save_counter > 1:
		save_counter -= 1

func _on_volume_slider_value_changed(value: float) -> void:
	var bus_index = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus_index, value)
	if value <= -30:
		AudioServer.set_bus_mute(bus_index, true)
	else:
		AudioServer.set_bus_mute(bus_index, false)

func _on_fps_button_item_selected(index: int) -> void:
	if index == 0:
		Engine.max_fps = 30
		print("Включен режим 30 FPS")
	elif index == 1:
		Engine.max_fps = 60
		print("Включен режим 60 FPS")

func _on_anti_aliasing_button_toggled(toggled_on: bool) -> void:
	var viewport_rid = get_viewport().get_viewport_rid()
	if toggled_on == true:
		RenderingServer.viewport_set_msaa_2d(viewport_rid, RenderingServer.VIEWPORT_MSAA_2X)
		print("Сглаживание графики ВКЛЮЧЕНО")
	else:
		RenderingServer.viewport_set_msaa_2d(viewport_rid, RenderingServer.VIEWPORT_MSAA_DISABLED)
		print("Сглаживание графики ВЫКЛЮЧЕНО")
