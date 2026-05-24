extends Control
class_name UnicornDisplay

# ─── Ссылки на слои (назначаются при инициализации) ───────────────────────────
# Структура узлов в unicorn_display.tscn:
# UnicornDisplay (Control)  ← этот скрипт
#   └── UnicornContainer (TextureRect)
#         ├── HvostLayer   (TextureRect)
#         ├── GrivaLayer   (TextureRect)
#         ├── BaseUnicorn  (TextureRect) ← тело единорога
#         ├── RogLayer     (TextureRect)
#         └── AksLayer     (TextureRect)

@onready var _hvost_layer:    TextureRect = $UnicornContainer/HvostLayer
@onready var _griva_layer:    TextureRect = $UnicornContainer/GrivaLayer
@onready var _base_unicorn:   TextureRect = $UnicornContainer/BaseUnicorn
@onready var _rog_layer:      TextureRect = $UnicornContainer/RogLayer
@onready var _aks_layer:      TextureRect = $UnicornContainer/AksLayer


func _ready() -> void:
	# ─── БАГ #1 ИСПРАВЛЕН: сигнал теперь существует в GlobalData ─────────────
	if not has_node("/root/GlobalData"):
		push_error("[UnicornDisplay] GlobalData не зарегистрирован в Autoload!")
		return

	var g: GlobalDataManager = get_node("/root/GlobalData")

	# Подписываемся на обновления кастомизации
	g.unicorn_updated.connect(_on_unicorn_updated)

	# Применяем текущие данные сразу при загрузке сцены
	_apply_from_global()


## Вызывается сигналом unicorn_updated из GlobalData.
func _on_unicorn_updated() -> void:
	_apply_from_global()


## Читает данные из GlobalData и обновляет все слои единорога.
func _apply_from_global() -> void:
	if not has_node("/root/GlobalData"):
		return

	var g: GlobalDataManager = get_node("/root/GlobalData")

	_set_texture(_griva_layer, g.temp_griva_path)
	_set_texture(_hvost_layer, g.temp_hvost_path)
	_set_texture(_rog_layer,   g.temp_rog_path)
	_set_texture(_aks_layer,   g.temp_aks_path)

	_griva_layer.modulate = g.color_griva
	_hvost_layer.modulate = g.color_hvost
	_rog_layer.modulate   = g.color_rog
	_aks_layer.modulate   = g.color_aks

	# Показываем слой только если для него задана текстура
	_hvost_layer.visible = (_hvost_layer.texture != null)
	_griva_layer.visible = (_griva_layer.texture != null)
	_rog_layer.visible   = (_rog_layer.texture   != null)
	_aks_layer.visible   = (_aks_layer.texture   != null)


func _set_texture(layer: TextureRect, path: String) -> void:
	if not is_instance_valid(layer):
		return
	if path != "" and ResourceLoader.exists(path):
		layer.texture = load(path)
	else:
		layer.texture = null
