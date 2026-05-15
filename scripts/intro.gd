extends Control

@onready var white_screen = $FadeLayer/WhiteScreen

func _ready():
	# Изначально экран полностью прозрачный
	white_screen.modulate.a = 0.0 
	
	$VideoStreamPlayer.play()
	$VideoStreamPlayer.finished.connect(_on_video_finished)

func _on_video_finished():
	var tween = create_tween()
	# Плавно делаем белым (альфа от 0 до 1)
	tween.tween_property(white_screen, "modulate:a", 1.0, 1.0)
	
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/mission_1.tscn")
