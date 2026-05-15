extends Control

@onready var panels = [
	$TextureRect/ContentPanel/GrivaPanel, 
	$TextureRect/ContentPanel/HvostPanel, 
	$TextureRect/ContentPanel/RogPanel, 
	$TextureRect/ContentPanel/TeloPanel
]

func _ready():
	$TextureRect/MenuButton.pressed.connect(_on_back_pressed)

	show_panel(0)
	
	$TextureRect/TabContainer/GrivaButton.pressed.connect(func(): show_panel(0))
	$TextureRect/TabContainer/HvostButton.pressed.connect(func(): show_panel(1))
	$TextureRect/TabContainer/RogButton.pressed.connect(func(): show_panel(2))
	$TextureRect/TabContainer/TeloButton.pressed.connect(func(): show_panel(3))
	
func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/mainmenu.tscn")

func show_panel(index: int):
	for i in range(panels.size()):
		panels[i].visible = (i == index) 
