extends Control

var base_unicorn: TextureRect
var griva_layer: TextureRect
var hvost_layer: TextureRect
var rog_layer: TextureRect
var aks_layer: TextureRect

func _ready():
	# Создаём всё программно
	_setup_unicorn_layers()
	# Подписываемся на сигнал обновления
	if has_node("/root/GlobalData"):
		get_node("/root/GlobalData").unicorn_updated.connect(_on_unicorn_updated)
	# Загружаем текущие данные
	load_unicorn_data()

func _setup_unicorn_layers():
	# Очищаем старые дети, если есть
	for child in get_children():
		if child is TextureRect:
			child.queue_free()
	
	# Создаём контейнер
	var container = TextureRect.new()
	container.name = "UnicornContainer"
	container.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	container.stretch_mode = TextureRect.STRETCH_SCALE
	container.size = Vector2(1028, 791)
	add_child(container)
	
	# 1. Хвост (будет ЗА конём)
	hvost_layer = TextureRect.new()
	hvost_layer.name = "HvostLayer"
	hvost_layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hvost_layer.stretch_mode = TextureRect.STRETCH_SCALE
	hvost_layer.size = Vector2(1028, 791)
	container.add_child(hvost_layer)
	
	# 2. Грива (будет ЗА конём)
	griva_layer = TextureRect.new()
	griva_layer.name = "GrivaLayer"
	griva_layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	griva_layer.stretch_mode = TextureRect.STRETCH_SCALE
	griva_layer.size = Vector2(1028, 791)
	container.add_child(griva_layer)
	
	# 3. Базовый конь
	base_unicorn = TextureRect.new()
	base_unicorn.name = "UnicornBase"
	base_unicorn.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	base_unicorn.stretch_mode = TextureRect.STRETCH_SCALE
	base_unicorn.size = Vector2(1028, 791)
	# Загрузи сюда свою базовую картинку коня!
	base_unicorn.texture = load("res://assets/group/Group 129.png")
	container.add_child(base_unicorn)
	
	# 4. Рог (ПЕРЕД конём)
	rog_layer = TextureRect.new()
	rog_layer.name = "RogLayer"
	rog_layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rog_layer.stretch_mode = TextureRect.STRETCH_SCALE
	rog_layer.size = Vector2(1028, 791)
	container.add_child(rog_layer)
	
	# 5. Аксессуары (ПЕРЕД конём)
	aks_layer = TextureRect.new()
	aks_layer.name = "AksLayer"
	aks_layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	aks_layer.stretch_mode = TextureRect.STRETCH_SCALE
	aks_layer.size = Vector2(1028, 791)
	container.add_child(aks_layer)
	
	print("Слои созданы!")

func load_unicorn_data():
	if not has_node("/root/GlobalData"):
		print("НЕТ GLOBALDATA!")
		return
	
	var global = get_node("/root/GlobalData")
	
	print("ЗАГРУЖАЮ данные:")
	print("Грива путь: ", global.temp_griva_path)
	print("Хвост путь: ", global.temp_hvost_path)
	
	# Загружаем текстуры
	_set_layer_texture(griva_layer, global.temp_griva_path)
	_set_layer_texture(hvost_layer, global.temp_hvost_path)
	_set_layer_texture(rog_layer, global.temp_rog_path)
	_set_layer_texture(aks_layer, global.temp_aks_path)
	
	# Применяем цвета
	griva_layer.modulate = global.color_griva
	hvost_layer.modulate = global.color_hvost
	rog_layer.modulate = global.color_rog
	aks_layer.modulate = global.color_aks

func _set_layer_texture(layer: TextureRect, path: String):
	if layer:
		if path and path != "" and ResourceLoader.exists(path):
			layer.texture = load(path)
			print("✓ Загружено: ", path)
		else:
			layer.texture = null
			print("✗ Не загружено: ", path)

func _on_unicorn_updated():
	print("Получен сигнал обновления!")
	load_unicorn_data()
