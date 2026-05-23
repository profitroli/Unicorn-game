extends Node

# Задай здесь пути к твоим начальным картинкам по умолчанию, чтобы лошадь не была «лысой»
var temp_griva_path: String = "res://assets/group/Group 129(4).png"
var temp_hvost_path: String = "res://assets/group/Group 129(5).png"
var temp_rog_path: String = "res://assets/group/Group 129(6).png"
var temp_aks_path: String = "" # Если аксессуаров изначально нет, оставляем пустым

# Цвета по умолчанию (белый цвет означает «без изменений»)
var color_griva: Color = Color.WHITE
var color_hvost: Color = Color.WHITE
var color_rog: Color = Color.WHITE
var color_aks: Color = Color.WHITE

func save_unicorn_with_colors(griva, hvost, rog, aks, c_griva, c_hvost, c_rog, c_aks):
	temp_griva_path = griva
	temp_hvost_path = hvost
	temp_rog_path = rog
	temp_aks_path = aks
	
	color_griva = c_griva
	color_hvost = c_hvost
	color_rog = c_rog
	color_aks = c_aks
	print("Данные единорога успешно сохранены!")

func save_unicorn(griva, hvost, rog, aks):
	temp_griva_path = griva
	temp_hvost_path = hvost
	temp_rog_path = rog
	temp_aks_path = aks
