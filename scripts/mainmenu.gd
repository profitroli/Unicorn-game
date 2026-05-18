extends Control

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
	
	$TextureRect/Controlvixod.visible = false 
	$TextureRect/Controlset.visible = false
	$TextureRect/Controlsave.visible = false

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

func _on_volume_slider_value_changed(value: float) -> void:
	var bus_index = AudioServer.get_bus_index("Master")

	AudioServer.set_bus_volume_db(bus_index, value)

	if value <= -30:
		AudioServer.set_bus_mute(bus_index, true)
	else:
		AudioServer.set_bus_mute(bus_index, false)
