extends CanvasLayer
class_name HomeOverlay

signal saved_and_exited
signal exited_without_save

## Путь сцены, который будет записан в слот сохранения.
@export var current_scene_path: String = ""

# ── Пути к ресурсам ─────────────────────────────────────────────────────────
const HOME_BTN_TEXTURE_PATH   := "res://assets/icon/Max_a_Ты_гейм-дизайнер,_со (2) 1.png"
const CLOSE_BTN_TEXTURE_PATH  := "res://assets/icon/закрыть 2.png"
# Используем одну и ту же подложку для кнопок действий, текст наложим кодом
const ACTION_BTN_TEXTURE_PATH := "res://assets/icon/выход вопрос (1) 1.png" 
const PANEL_BG_TEXTURE_PATH   := "res://assets/foto/Group 136.png"
const FONT_PATH               := "res://assets/text/ArcadeJeu-Regular.otf"

# ── Внутренние ссылки ────────────────────────────────────────────────────────
var _home_btn:  Button
var _dim:       ColorRect    # затемнение и заглушка ввода
var _panel_bg:  TextureRect  # фон панели
var _save_btn:  Button       # Кнопка с текстом «Сохранить и выйти»
var _exit_btn:  Button       # Кнопка с текстом «Выйти без сохранения»
var _font:      FontFile

const _C_DIM := Color(0.0, 0.0, 0.0, 0.55)
const _C_DANGER := Color(0.82, 0.22, 0.18, 1.0)
const _C_TEXT_ON_BTN := Color.BLACK

# ── Ready ────────────────────────────────────────────────────────────────────
func _ready() -> void:
	layer = 200   # выше FadeLayer (100) и PlashkaLayer (50)
	_load_custom_font()
	_build_home_button()
	_build_dialog()
	_set_dialog_visible(false)

# ── Загрузка ресурсов ────────────────────────────────────────────────────────
func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	push_error("[HomeOverlay] Текстура не найдена: " + path)
	return null

func _load_custom_font() -> void:
	if ResourceLoader.exists(FONT_PATH):
		_font = load(FONT_PATH)
	else:
		push_error("[HomeOverlay] Шрифт не найден: " + FONT_PATH)
		# Фоллбэк на стандартный шрифт, чтобы текст хоть как-то отобразился
		_font = ThemeDB.fallback_font

# ── Кнопка «Домой» (в углу экрана) ──────────────────────────────────────────
func _build_home_button() -> void:
	_home_btn = Button.new()
	_home_btn.name = "HomeButton"
	_home_btn.flat = true
	_home_btn.position = Vector2(5.0, 5.0)
	_home_btn.custom_minimum_size = Vector2(220.0, 80.0)
	_home_btn.icon = _load_texture(HOME_BTN_TEXTURE_PATH)
	_home_btn.expand_icon = true
	# На эту кнопку текст не просили добавлять, оставляем как есть
	add_child(_home_btn)
	_home_btn.pressed.connect(_on_home_pressed)

# ── Диалог ───────────────────────────────────────────────────────────────────
func _build_dialog() -> void:
	# --- затемнение и ЗАГЛУШКА (Input Blocker) ---
	_dim = ColorRect.new()
	_dim.name    = "Dim"
	_dim.color   = _C_DIM
	_dim.position = Vector2.ZERO
	# Устанавливаем размер на весь экран (предполагаем 1920x1080)
	_dim.size    = Vector2(1920.0, 1080.0)
	
	# ВАЖНО: mouse_filter = STOP делает ColorRect преградой для кликов мыши.
	# Кнопки позади него (в "мире") перестанут нажиматься.
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_dim)

	# --- фон панели (картинка) ---
	_panel_bg = TextureRect.new()
	_panel_bg.name = "PanelBG"
	_panel_bg.texture = _load_texture(PANEL_BG_TEXTURE_PATH)
	_panel_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_panel_bg.position = Vector2(0, 0)
	_panel_bg.size = Vector2(1920, 1080)
	# Панель должна пропускать клики мимо себя, чтобы они ловились _dim, 
	# если кликнули не по кнопке на панели.
	_panel_bg.mouse_filter = Control.MOUSE_FILTER_PASS 
	_dim.add_child(_panel_bg)

	# --- кнопка закрытия (крестик) ---
	var x_btn := _make_texture_button(CLOSE_BTN_TEXTURE_PATH, Vector2(70.0, 70.0), Vector2(1275.0, 382.0))
	x_btn.pressed.connect(_on_close_pressed)
	_panel_bg.add_child(x_btn)
# --- кнопки действий с текстом НА них ---
	_save_btn = _make_action_button("Сохранить и выйти", Vector2(350.0, 130.0))
	_exit_btn = _make_action_button("Выйти без сохранения", Vector2(350.0, 130.0))

	var hbox := HBoxContainer.new()
	hbox.position = Vector2(588.0, 608.0)
	hbox.add_theme_constant_override("separation", 40)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	# Чтобы HBox не сжимал кнопки, задаем ему размер
	hbox.custom_minimum_size = Vector2(740, 130) 
	hbox.add_child(_save_btn)
	hbox.add_child(_exit_btn)
	_panel_bg.add_child(hbox)

	# --- предупреждение о заполненных слотах ---
	var warn := Label.new()
	warn.name = "WarnLabel"
	warn.text = "⚠️ Все 3 слота заполнены.\nУдалите сохранение в главном меню."
	
	# Настройка шрифта для варнинга (тоже используем аркадный)
	if _font:
		warn.add_theme_font_override("font", _font)
	warn.add_theme_font_size_override("font_size", 22)
	warn.add_theme_color_override("font_color", _C_DANGER)
	
	warn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Позиционирование относительно hbox
	warn.position = Vector2(588.0, 750.0) 
	warn.size = Vector2(740.0, 80.0)
	warn.visible = false
	_panel_bg.add_child(warn)

	_save_btn.pressed.connect(_on_save_and_exit)
	_exit_btn.pressed.connect(_on_exit_without_save)

# ── Создание кнопок действий с наложением текста ─────────────────────────────
func _make_action_button(text: String, size: Vector2) -> Button:
	# Создаем базовую кнопку с иконкой-подложкой
	var btn := Button.new()
	btn.flat = true
	btn.icon = _load_texture(ACTION_BTN_TEXTURE_PATH)
	btn.expand_icon = true
	btn.custom_minimum_size = size
	# Важно для правильного mouse_over эффекта стандартной кнопки
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	# Создаем Label для текста НА кнопке
	var lbl := Label.new()
	lbl.name = "TextOver"
	lbl.text = text
	
	# Настройка стилей текста (Чёрный, Шрифт из файла)
	lbl.add_theme_color_override("font_color", _C_TEXT_ON_BTN)
	if _font:
		lbl.add_theme_font_override("font", _font)
	lbl.add_theme_font_size_override("font_size", 24) # Подберите размер под шрифт
	
	# Выравнивание текста по центру Label
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# Разрешаем перенос текста, если фраза длинная ("Выйти без сохранения")
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	# Растягиваем Label на всю площадь кнопки
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Добавляем небольшие отступы, чтобы текст не прилипал к краям картинки
	lbl.offset_left = 15
	lbl.offset_right = -15
	lbl.offset_top = 10
	lbl.offset_bottom = -10
	
	# Label должен пропускать клики мыши сквозь себя, чтобы нажималась сама Button
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	btn.add_child(lbl)
	return btn

# ── Простой строитель кнопок (для крестика) ──────────────────────────────
func _make_texture_button(texture_path: String, size: Vector2, position: Vector2) -> Button:
	var btn := Button.new()
	btn.flat = true
	btn.icon = _load_texture(texture_path)
	btn.expand_icon = true
	btn.custom_minimum_size = size
	btn.position = position
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return btn

# ── Показ / скрытие диалога ───────────────────────────────────────────────────
func _set_dialog_visible(v: bool) -> void:
	if _dim:
		_dim.visible = v
		# Если диалог скрыт, он не должен блокировать мышь
		_dim.mouse_filter = Control.MOUSE_FILTER_STOP if v else Control.MOUSE_FILTER_IGNORE
	
	# Скрываем кнопку "Домой", когда открыт диалог
	if _home_btn:
		_home_btn.visible = not v
# ── Обработчики ───────────────────────────────────────────────────────────────
func _on_home_pressed() -> void:
	# Обновляем состояние кнопки «Сохранить» перед показом диалога
	var sys: SaveSystemManager = _get_save_system()
	if sys and _save_btn:
		var can: bool = sys.can_add()
		_save_btn.disabled = not can
		
		# Делаем текст на выключенной кнопке полупрозрачным
		var lbl = _save_btn.get_node_or_null("TextOver") as Label
		if lbl:
			lbl.modulate.a = 0.5 if not can else 1.0
			
		var warn := _panel_bg.get_node_or_null("WarnLabel") as Label
		if warn:
			warn.visible = not can
	_set_dialog_visible(true)

func _on_close_pressed() -> void:
	_set_dialog_visible(false)

func _on_save_and_exit() -> void:
	_set_dialog_visible(false)
	var sys: SaveSystemManager = _get_save_system()
	if sys and current_scene_path != "":
		sys.create_save(current_scene_path)
	_store_last_scene()
	saved_and_exited.emit()
	get_tree().change_scene_to_file("res://scenes/mainmenu.tscn")

func _on_exit_without_save() -> void:
	_set_dialog_visible(false)
	_store_last_scene()
	exited_without_save.emit()
	get_tree().change_scene_to_file("res://scenes/mainmenu.tscn")

# ── Утилиты ───────────────────────────────────────────────────────────────────
func _store_last_scene() -> void:
	var g: GlobalDataManager = get_node_or_null("/root/GlobalData")
	if g and current_scene_path != "":
		g.last_played_scene = current_scene_path

func _get_save_system() -> SaveSystemManager:
	var sys := get_node_or_null("/root/SaveSystem") as SaveSystemManager
	if not sys:
		push_error("[HomeOverlay] Autoload 'SaveSystem' не найден!")
	return sys
