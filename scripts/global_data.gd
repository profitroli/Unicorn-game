extends Node
class_name GlobalDataManager

signal unicorn_updated

# Путь к файлу сохранения на диске
const SAVE_PATH := "user://unicorn_save.json"

# Пути текстур
var temp_griva_path: String = "res://assets/group/Group 129(4).png"
var temp_hvost_path: String = "res://assets/group/Group 129(5).png"
var temp_rog_path:   String = "res://assets/group/Group 129(6).png"
var temp_aks_path:   String = ""

# Цвета (WHITE = без изменений)
var color_griva: Color = Color.WHITE
var color_hvost: Color = Color.WHITE
var color_rog:   Color = Color.WHITE
var color_aks:   Color = Color.WHITE


func _ready() -> void:
	# Загружаем сохранение сразу при старте игры
	load_from_disk()


# ─── СОХРАНЕНИЕ НА ДИСК ───────────────────────────────────────────────────────

func save_unicorn_with_colors(
		griva:   String,
		hvost:   String,
		rog:     String,
		aks:     String,
		c_griva: Color,
		c_hvost: Color,
		c_rog:   Color,
		c_aks:   Color
) -> void:
	temp_griva_path = griva
	temp_hvost_path = hvost
	temp_rog_path   = rog
	temp_aks_path   = aks
	color_griva     = c_griva
	color_hvost     = c_hvost
	color_rog       = c_rog
	color_aks       = c_aks

	save_to_disk()
	unicorn_updated.emit()


func save_unicorn(griva: String, hvost: String, rog: String, aks: String) -> void:
	temp_griva_path = griva
	temp_hvost_path = hvost
	temp_rog_path   = rog
	temp_aks_path   = aks

	save_to_disk()
	unicorn_updated.emit()


# ─── ЗАПИСЬ В ФАЙЛ ────────────────────────────────────────────────────────────

func save_to_disk() -> void:
	# Собираем всё в словарь — Color сериализуем как строку "#rrggbbaa"
	var data := {
		"griva_path": temp_griva_path,
		"hvost_path": temp_hvost_path,
		"rog_path":   temp_rog_path,
		"aks_path":   temp_aks_path,
		"color_griva": color_griva.to_html(true),
		"color_hvost": color_hvost.to_html(true),
		"color_rog":   color_rog.to_html(true),
		"color_aks":   color_aks.to_html(true),
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("[GlobalData] Не удалось открыть файл для записи: %s" % SAVE_PATH)
		return

	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	print("[GlobalData] Сохранено в ", SAVE_PATH)


# ─── ЧТЕНИЕ ИЗ ФАЙЛА ──────────────────────────────────────────────────────────

func load_from_disk() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		print("[GlobalData] Файл сохранения не найден — используются значения по умолчанию.")
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("[GlobalData] Не удалось открыть файл для чтения: %s" % SAVE_PATH)
		return

	var raw := file.get_as_text()
	file.close()

	var json := JSON.new()
	var err := json.parse(raw)
	if err != OK:
		push_error("[GlobalData] Ошибка парсинга JSON: %s" % json.get_error_message())
		return

	var data: Dictionary = json.get_data()

	# Восстанавливаем пути
	temp_griva_path = data.get("griva_path", temp_griva_path)
	temp_hvost_path = data.get("hvost_path", temp_hvost_path)
	temp_rog_path   = data.get("rog_path",   temp_rog_path)
	temp_aks_path   = data.get("aks_path",   temp_aks_path)

	# Восстанавливаем цвета из hex-строк
	color_griva = Color.from_string(data.get("color_griva", "ffffffff"), Color.WHITE)
	color_hvost = Color.from_string(data.get("color_hvost", "ffffffff"), Color.WHITE)
	color_rog   = Color.from_string(data.get("color_rog",   "ffffffff"), Color.WHITE)
	color_aks   = Color.from_string(data.get("color_aks",   "ffffffff"), Color.WHITE)

	print("[GlobalData] Загружено из ", SAVE_PATH)
