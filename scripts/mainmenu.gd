extends Control

func _ready():
	$TextureRect/PlayButton.pressed.connect(_on_play_pressed)
	$TextureRect/SaveButton.pressed.connect(_on_save_pressed)
	$TextureRect/CustomizationButton.pressed.connect(_on_customization_pressed)
	$TextureRect/SettingsButton.pressed.connect(_on_settings_pressed)
	$TextureRect/ExitButton.pressed.connect(_on_exit_pressed)
	
	$Control/TextureRect/Control/yes.pressed.connect(_on_confirm_exit)
	$Control/TextureRect/Control/no.pressed.connect(_on_cancel_exit)
	
	$Control.visible = false

func _on_play_pressed():
	get_tree().change_scene_to_file("res://scenes/intro.tscn")

func _on_exit_pressed():
	$Control.visible = true

func _on_confirm_exit():
	get_tree().quit()

func _on_cancel_exit():
	$Control.visible = false

func _on_save_pressed():
	print("Кнопка сохранения (пока не работает)")

func _on_customization_pressed():
	get_tree().change_scene_to_file("res://scenes/customization.tscn")

func _on_settings_pressed():
	get_tree().change_scene_to_file("res://scenes/hub.tscn")
