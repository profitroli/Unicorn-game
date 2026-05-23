extends Control

@onready var panels = [
	$TextureRect/ContentPanel/GrivaPanel, 
	$TextureRect/ContentPanel/HvostPanel, 
	$TextureRect/ContentPanel/RogPanel, 
	$TextureRect/ContentPanel/TeloPanel
]

# Ссылки на слои-картинки, которые наложены друг на друга
var griva_layer: TextureRect
var hvost_layer: TextureRect
var rog_layer: TextureRect
var aks_layer: TextureRect

# Переменные, где будут храниться пути выбранных картинок (это и есть наша группа)
var temp_griva_path: String = ""
var temp_hvost_path: String = ""
var temp_rog_path: String = ""
var temp_aks_path: String = ""

# --- НОВЫЕ ПЕРЕМЕННЫЕ ДЛЯ ЦВЕТОВ ---
# Храним текущие цвета элементов (по умолчанию белый — без изменений)
var color_griva: Color = Color.WHITE
var color_hvost: Color = Color.WHITE
var color_rog: Color = Color.WHITE
var color_aks: Color = Color.WHITE

# Переменная для отслеживания текущего выбранного типа элемента (0 - грива, 1 - хвост, 2 - рог, 3 - тело)
var current_type_index: int = 0

func _ready():
	# Кнопка назад в меню
	$TextureRect/MenuButton.pressed.connect(_on_back_pressed)

	# Переключение вкладок
	show_panel(0)
	$TextureRect/TabContainer/GrivaButton.pressed.connect(func(): show_panel(0))
	$TextureRect/TabContainer/HvostButton.pressed.connect(func(): show_panel(1))
	$TextureRect/TabContainer/RogButton.pressed.connect(func(): show_panel(2))
	$TextureRect/TabContainer/TeloButton.pressed.connect(func(): show_panel(3))
	
	# Кнопка сброса аксессуаров
	if $"TextureRect/ContentPanel/TeloPanel".has_node("ResetButton"):
		$"TextureRect/ContentPanel/TeloPanel/ResetButton".pressed.connect(_on_reset_aks_pressed)
	
	# Создаем слои с правильным распределением (за конем и перед конем)
	_prepare_unicorn_layers()
	
	# ==========================================
	# РУЧНЫЕ ПУТИ ДЛЯ КАЖДОЙ КНОПКИ
	# ==========================================
	
	# --- Панель ГРИВА ---
	$"TextureRect/ContentPanel/GrivaPanel/1".pressed.connect(func(): _apply_element("griva", "res://assets/group/Group 129(4).png"))
	$"TextureRect/ContentPanel/GrivaPanel/2".pressed.connect(func(): _apply_element("griva", "res://assets/group/Group 129(1).png"))
	$"TextureRect/ContentPanel/GrivaPanel/3".pressed.connect(func(): _apply_element("griva", "res://assets/group/Group 129(7).png"))
	$"TextureRect/ContentPanel/GrivaPanel/4".pressed.connect(func(): _apply_element("griva", "res://assets/group/Group 129(11).png"))
	
	# --- Панель ХВОСТ ---
	$"TextureRect/ContentPanel/HvostPanel/1".pressed.connect(func(): _apply_element("hvost", "res://assets/group/Group 129(5).png"))
	$"TextureRect/ContentPanel/HvostPanel/2".pressed.connect(func(): _apply_element("hvost", "res://assets/group/Group 129(2).png"))
	$"TextureRect/ContentPanel/HvostPanel/3".pressed.connect(func(): _apply_element("hvost", "res://assets/group/Group 129(8).png"))
	$"TextureRect/ContentPanel/HvostPanel/4".pressed.connect(func(): _apply_element("hvost", "res://assets/group/Group 129(10).png"))
	
	# --- Панель РОГ ---
	$"TextureRect/ContentPanel/RogPanel/1".pressed.connect(func(): _apply_element("rog", "res://assets/group/Group 129(6).png"))
	$"TextureRect/ContentPanel/RogPanel/2".pressed.connect(func(): _apply_element("rog", "res://assets/group/Group 129(3).png"))
	$"TextureRect/ContentPanel/RogPanel/3".pressed.connect(func(): _apply_element("rog", "res://assets/group/Group 129(9).png"))
	$"TextureRect/ContentPanel/RogPanel/4".pressed.connect(func(): _apply_element("rog", "res://assets/group/Group 129(12).png"))
	
	# --- Панель ТЕЛО (АКСЕССУАРЫ) ---
	$"TextureRect/ContentPanel/TeloPanel/1".pressed.connect(func(): _apply_element("aks", "res://assets/group/Group 129(13).png"))
	$"TextureRect/ContentPanel/TeloPanel/2".pressed.connect(func(): _apply_element("aks", "res://assets/group/Group 129(15).png"))
	$"TextureRect/ContentPanel/TeloPanel/3".pressed.connect(func(): _apply_element("aks", "res://assets/group/Group 129(14).png"))
	$"TextureRect/ContentPanel/TeloPanel/4".pressed.connect(func(): _apply_element("aks", "res://assets/group/Group 129(16).png"))

	# ==========================================
	# НАСТРОЙКА КНОПОК ЦВЕТА (НОВОЕ)
	# ==========================================
	_setup_color_buttons()

# Функция настройки кнопок цвета и их палитры
func _setup_color_buttons():
	# Связываем кнопки из сцены с конкретными HEX-цветами
	_connect_color_button("TextureRect/Color/Blue", Color.from_string("87cefa", Color.BLUE))
	_connect_color_button("TextureRect/Color/Green", Color.from_string("90ee90", Color.GREEN)) #ccffcc
	_connect_color_button("TextureRect/Color/DarkBlue", Color.from_string("3333cc", Color.DARK_BLUE))
	_connect_color_button("TextureRect/Color/Purple", Color.from_string("ff00ff", Color.PURPLE))
	_connect_color_button("TextureRect/Color/Pink", Color.from_string("ff69b4", Color.PINK)) #ffccff
	_connect_color_button("TextureRect/Color/Red", Color.from_string("ff0000", Color.RED))
	_connect_color_button("TextureRect/Color/Yellow", Color.from_string("feff03", Color.YELLOW))
	_connect_color_button("TextureRect/Color/Orange", Color.from_string("d2691e", Color.ORANGE))
	_connect_color_button("TextureRect/Color/White", Color.WHITE)
	_connect_color_button("TextureRect/Color/Black", Color.from_string("000000", Color.BLACK))

# Помощник для подключения кнопки цвета
func _connect_color_button(button_path: String, color: Color):
	if has_node(button_path):
		var btn = get_node(button_path) as Button
		# Красим саму кнопку в редакторе, так как сейчас они прозрачные
		btn.modulate = color 
		# Подключаем клик
		btn.pressed.connect(func(): _apply_color_to_current_layer(color))

# Функция применения цвета к текущему активному слою
func _apply_color_to_current_layer(color: Color):
	match current_type_index:
		0:
			griva_layer.modulate = color
			color_griva = color
		1:
			hvost_layer.modulate = color
			color_hvost = color
		2:
			rog_layer.modulate = color
			color_rog = color
		3:
			aks_layer.modulate = color
			color_aks = color

# Функция создания слоев с учетом правильной sorting видимости
func _prepare_unicorn_layers():
	var main_rect = $TextureRect
	var base_unicorn = $TextureRect/Unicorn
	
	base_unicorn.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	base_unicorn.stretch_mode = TextureRect.STRETCH_SCALE
	base_unicorn.size = Vector2(1028, 791)
	
	# Создаем Хвост и Гриву как дочерние элементы TextureRect (родителя коня)
	hvost_layer = _create_layer(main_rect, "HvostLayer", base_unicorn.position, base_unicorn.size)
	griva_layer = _create_layer(main_rect, "GrivaLayer", base_unicorn.position, base_unicorn.size)
	
	# Принудительно сдвигаем Хвост и Гриву в самый верх дерева под TextureRect, чтобы они ушли ЗА коня
	main_rect.move_child(hvost_layer, 0)
	main_rect.move_child(griva_layer, 1)
	
	# Создаем Рог и Аксессуары внутри Unicorn, чтобы они гарантированно были ПЕРЕД конём
	rog_layer = _create_layer(base_unicorn, "RogLayer", Vector2.ZERO, base_unicorn.size)
	aks_layer = _create_layer(base_unicorn, "AksLayer", Vector2.ZERO, base_unicorn.size)

func _create_layer(parent: Control, layer_name: String, layer_pos: Vector2, layer_size: Vector2) -> TextureRect:
	var layer: TextureRect
	if parent.has_node(layer_name):
		layer = parent.get_node(layer_name)
	else:
		layer = TextureRect.new()
		layer.name = layer_name
		parent.add_child(layer)
	
	layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	layer.stretch_mode = TextureRect.STRETCH_SCALE
	layer.position = layer_pos
	layer.size = layer_size
	return layer

# Простое применение текстуры при клике
func _apply_element(type: String, img_path: String):
	if not ResourceLoader.exists(img_path):
		print("Файл не найден: ", img_path)
		return
		
	var texture_obj = load(img_path)
	
	match type:
		"griva":
			griva_layer.texture = texture_obj
			temp_griva_path = img_path
		"hvost":
			hvost_layer.texture = texture_obj
			temp_hvost_path = img_path
		"rog":
			rog_layer.texture = texture_obj
			temp_rog_path = img_path
		"aks":
			aks_layer.texture = texture_obj
			temp_aks_path = img_path

func _on_reset_aks_pressed():
	aks_layer.texture = null
	temp_aks_path = ""
	aks_layer.modulate = Color.WHITE
	color_aks = Color.WHITE

func show_panel(index: int):
	current_type_index = index # Запоминаем вкладку (0, 1, 2 или 3)
	for i in range(panels.size()):
		panels[i].visible = (i == index)

func _on_back_pressed():
	# Сохраняем всю группу путей И ЦВЕТА в глобальный скрипт GlobalData
	if has_node("/root/GlobalData"):
		var global = get_node("/root/GlobalData")
		
		# Проверяем, умеет ли твой GlobalData принимать еще и цвета.
		# Если метод save_unicorn принимает только 4 аргумента, добавь в него переменные для цветов 
		# или создай там новый метод, например: global.save_unicorn_colors(color_griva, color_hvost, color_rog, color_aks)
		if global.has_method("save_unicorn_with_colors"):
			global.save_unicorn_with_colors(temp_griva_path, temp_hvost_path, temp_rog_path, temp_aks_path, color_griva, color_hvost, color_rog, color_aks)
		else:
			global.save_unicorn(temp_griva_path, temp_hvost_path, temp_rog_path, temp_aks_path)
			
	get_tree().change_scene_to_file("res://scenes/mainmenu.tscn")
