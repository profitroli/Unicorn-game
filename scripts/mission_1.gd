extends Node2D # (или Control, смотря какой у тебя корень)

@onready var white_screen = $FadeLayer/WhiteScreen

func _ready():
	white_screen.modulate.a = 1.0
	
	var tween = create_tween()
	tween.tween_property(white_screen, "modulate:a", 0.0, 1.0)
	
	await tween.finished
	white_screen.visible = false 
