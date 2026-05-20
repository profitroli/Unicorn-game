extends Control

@onready var panels = [
	$TextureRect/ContentPanel/GrivaPanel, 
	$TextureRect/ContentPanel/HvostPanel, 
	$TextureRect/ContentPanel/RogPanel, 
	$TextureRect/ContentPanel/TeloPanel
]

# Ссылки на автоматические слои
var griva_layer: TextureRect
var hvost_layer: TextureRect
var rog_layer: TextureRect
var aks_layer: TextureRect

# ВРЕМЕННЫЕ переменные для примерки внутри сцены кастомизации
var temp_griva_path: String = ""
var temp_hvost_path: String = ""
var temp_rog_path: String = ""
var temp_aks_path: String = ""

func _ready():
	$TextureRect/MenuButton.pressed.connect(_on_back_pressed)

	show_panel(0)
	
	$TextureRect/TabContainer/GrivaButton.pressed.connect(func(): show_panel(0))
	$TextureRect/TabContainer/HvostButton.pressed.connect(func(): show_panel(1))
	$TextureRect/TabContainer/RogButton.pressed.connect(func(): show_panel(2))
	$TextureRect/TabContainer/TeloButton.pressed.connect(func(): show_panel(3))
	
	# Подключаем кнопку СБРОСА аксессуаров
	if $"TextureRect/ContentPanel/TeloPanel".has_node("ResetButton"):
		$"TextureRect/ContentPanel/TeloPanel/ResetButton".pressed.connect(_on_reset_aks_pressed)
	
	# Создаем слои с правильным порядком отрисовки
	_prepare_unicorn_layers()
	
	# 1. Кнопки на панели ГРИВА
	$"TextureRect/ContentPanel/GrivaPanel/1".pressed.connect(func(): _apply_element("griva", "1", $"TextureRect/ContentPanel/GrivaPanel/1"))
	$"TextureRect/ContentPanel/GrivaPanel/2".pressed.connect(func(): _apply_element("griva", "2", $"TextureRect/ContentPanel/GrivaPanel/2"))
	$"TextureRect/ContentPanel/GrivaPanel/3".pressed.connect(func(): _apply_element("griva", "3", $"TextureRect/ContentPanel/GrivaPanel/3"))
	$"TextureRect/ContentPanel/GrivaPanel/4".pressed.connect(func(): _apply_element("griva", "4", $"TextureRect/ContentPanel/GrivaPanel/4"))
	
	# 2. Кнопки на панели ХВОСТ
	$"TextureRect/ContentPanel/HvostPanel/1".pressed.connect(func(): _apply_element("hvost", "1", $"TextureRect/ContentPanel/HvostPanel/1"))
	$"TextureRect/ContentPanel/HvostPanel/2".pressed.connect(func(): _apply_element("hvost", "2", $"TextureRect/ContentPanel/HvostPanel/2"))
	$"TextureRect/ContentPanel/HvostPanel/3".pressed.connect(func(): _apply_element("hvost", "3", $"TextureRect/ContentPanel/HvostPanel/3"))
	$"TextureRect/ContentPanel/HvostPanel/4".pressed.connect(func(): _apply_element("hvost", "4", $"TextureRect/ContentPanel/HvostPanel/4"))
	
	# 3. Кнопки на панели РОГ
	$"TextureRect/ContentPanel/RogPanel/1".pressed.connect(func(): _apply_element("rog", "1", $"TextureRect/ContentPanel/RogPanel/1"))
	$"TextureRect/ContentPanel/RogPanel/2".pressed.connect(func(): _apply_element("rog", "2", $"TextureRect/ContentPanel/RogPanel/2"))
	$"TextureRect/ContentPanel/RogPanel/3".pressed.connect(func(): _apply_element("rog", "3", $"TextureRect/ContentPanel/RogPanel/3"))
	$"TextureRect/ContentPanel/RogPanel/4".pressed.connect(func(): _apply_element("rog", "4", $"TextureRect/ContentPanel/RogPanel/4"))
	
	# 4. Кнопки на панели ТЕЛО (Аксессуары)
	$"TextureRect/ContentPanel/TeloPanel/1".pressed.connect(func(): _apply_element("aks", "1", $"TextureRect/ContentPanel/TeloPanel/1"))
	$"TextureRect/ContentPanel/TeloPanel/2".pressed.connect(func(): _apply_element("aks", "2", $"TextureRect/ContentPanel/TeloPanel/2"))
	$"TextureRect/ContentPanel/TeloPanel/3".pressed.connect(func(): _apply_element("aks", "3", $"TextureRect/ContentPanel/TeloPanel/3"))
	$"TextureRect/ContentPanel/TeloPanel/4".pressed.connect(func(): _apply_element("aks", "4", $"TextureRect/ContentPanel/TeloPanel/4"))

func _prepare_unicorn_layers():
	var main_bg = $TextureRect
	var base_unicorn = $TextureRect/Unicorn
	
	# Грива
	if not main_bg.has_node("GrivaLayer"):
		griva_layer = TextureRect.new()
		griva_layer.name = "GrivaLayer"
		griva_layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		griva_layer.stretch_mode = TextureRect.STRETCH_SCALE
		main_bg.add_child(griva_layer)
		
		var unicorn_index = base_unicorn.get_index()
		main_bg.move_child(griva_layer, unicorn_index)
	else:
		griva_layer = main_bg.get_node("GrivaLayer")
		
	# Хвост
	if not base_unicorn.has_node("HvostLayer"):
		hvost_layer = TextureRect.new()
		hvost_layer.name = "HvostLayer"
		hvost_layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		hvost_layer.stretch_mode = TextureRect.STRETCH_SCALE
		base_unicorn.add_child(hvost_layer)
	else:
		hvost_layer = base_unicorn.get_node("HvostLayer")

	# Рог
	if not base_unicorn.has_node("RogLayer"):
		rog_layer = TextureRect.new()
		rog_layer.name = "RogLayer"
		rog_layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rog_layer.stretch_mode = TextureRect.STRETCH_SCALE
		base_unicorn.add_child(rog_layer)
	else:
		rog_layer = base_unicorn.get_node("RogLayer")

	# Аксессуары (Панель Тело)
	if not base_unicorn.has_node("AksLayer"):
		aks_layer = TextureRect.new()
		aks_layer.name = "AksLayer"
		aks_layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		aks_layer.stretch_mode = TextureRect.STRETCH_SCALE
		base_unicorn.add_child(aks_layer)
	else:
		aks_layer = base_unicorn.get_node("AksLayer")

func _apply_element(type: String, button_name: String, button: Button):
	var img_path = ""
	var texture_obj = null
	
	if "texture_normal" in button and button.texture_normal:
		texture_obj = button.texture_normal
	elif "icon" in button and button.icon:
		texture_obj = button.icon
		
	if texture_obj:
		img_path = texture_obj.resource_path
		
		if type == "griva":
			griva_layer.texture = texture_obj
			temp_griva_path = img_path
			
			if button_name == "1":
				griva_layer.position = Vector2($TextureRect/Unicorn.position.x + 240, $TextureRect/Unicorn.position.y - 15)
				griva_layer.size = Vector2(320, 320)
			elif button_name == "2":
				griva_layer.position = Vector2($TextureRect/Unicorn.position.x + 240, $TextureRect/Unicorn.position.y - 28)
				griva_layer.size = Vector2(330, 330)
			elif button_name == "3":
				griva_layer.position = Vector2($TextureRect/Unicorn.position.x + 300, $TextureRect/Unicorn.position.y - 10)
				griva_layer.size = Vector2(320, 320)
			elif button_name == "4":
				griva_layer.position = Vector2($TextureRect/Unicorn.position.x + 352, $TextureRect/Unicorn.position.y - 60)
				griva_layer.size = Vector2(300, 300)

		elif type == "hvost":
			hvost_layer.texture = texture_obj
			temp_hvost_path = img_path
			
			if button_name == "1":
				hvost_layer.position = Vector2(-183, 180)
				hvost_layer.size = Vector2(300, 350)
			elif button_name == "2":
				hvost_layer.position = Vector2(-190, 220)
				hvost_layer.size = Vector2(300, 350)
			elif button_name == "3":
				hvost_layer.position = Vector2(-180, 230)
				hvost_layer.size = Vector2(290, 340)
			elif button_name == "4":
				hvost_layer.position = Vector2(-180, 150)
				hvost_layer.size = Vector2(300, 350)

		elif type == "rog":
			rog_layer.texture = texture_obj
			temp_rog_path = img_path
			
			if button_name == "1":
				rog_layer.position = Vector2(590, -50)
				rog_layer.size = Vector2(120, 140)
			elif button_name == "2":
				rog_layer.position = Vector2(590, -50)
				rog_layer.size = Vector2(120, 140)
			elif button_name == "3":
				rog_layer.position = Vector2(580, -64)
				rog_layer.size = Vector2(140, 160)
			elif button_name == "4":
				rog_layer.position = Vector2(590, -50)
				rog_layer.size = Vector2(125, 145)

		elif type == "aks":
			aks_layer.texture = texture_obj
			temp_aks_path = img_path
			
			if button_name == "1":
				aks_layer.position = Vector2(500, 86)
				aks_layer.size = Vector2(187, 66)
			elif button_name == "2":
				aks_layer.position = Vector2(478, -40)
				aks_layer.size = Vector2(134, 114)
			elif button_name == "3":
				aks_layer.position = Vector2(490, -2)
				aks_layer.size = Vector2(119, 73)
			elif button_name == "4":
				aks_layer.position = Vector2(30, 220)
				aks_layer.size = Vector2(142, 75)

# ФУНКЦИЯ КНОПКИ «СБРОС»: Очищает аксессуары
func _on_reset_aks_pressed():
	aks_layer.texture = null
	temp_aks_path = ""

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/mainmenu.tscn")

func show_panel(index: int):
	for i in range(panels.size()):
		panels[i].visible = (i == index)
