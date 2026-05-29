extends Control

@onready var white_screen = $FadeLayer/WhiteScreen

func _ready():
    white_screen.modulate.a = 0.0 
    
    $VideoStreamPlayer.play()
    $VideoStreamPlayer.finished.connect(_on_video_finished)

func _on_video_finished():
    var tween = create_tween()
    tween.tween_property(white_screen, "modulate:a", 1.0, 1.0)
    
    await tween.finished
    get_tree().change_scene_to_file("res://scenes/prologue.tscn")
