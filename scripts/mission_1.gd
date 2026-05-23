extends Node2D # (или Control, смотря какой у тебя корень)

@onready var black_screen = $FadeLayer/BlackScreen

func _ready():
	black_screen.modulate.a = 1.0
	
	var tween = create_tween()
	tween.tween_property(black_screen, "modulate:a", 0.0, 1.0)
	
	await tween.finished
	black_screen.visible = false 
