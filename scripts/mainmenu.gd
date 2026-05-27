extends Control

const SLOT_TEXTURE := preload("res://assets/icon/Group 113.png")

# Цвета состояний слота
const COLOR_NORMAL   := Color(1.0,  1.0,  1.0,  1.0)
const COLOR_SELECTED := Color(0.85, 0.78, 1.0,  1.0)  # мягкий фиолетовый оттенок
const COLOR_HINT     := Color(0.7,  0.95, 0.7,  1.0)  # зелёный hint «нажми ещё раз»

@onready var saves_list: VBoxContainer = $TextureRect/Controlsave/SavesList

## Индекс выбранного слота (−1 = ничего не выбрано).
var _selected_index: int = -1
var _custom_font: Font
var _custom_font1: Font

## Ссылки на кнопки слотов для управления подсветкой без перестройки списка.
var _slot_buttons: Array[Button] = []

func _ready() -> void:
  _custom_font = load("res://assets/text/PixelifySans-VariableFont_wght.ttf")
  _custom_font1 = load("res://assets/text/ArcadeJeu-Regular.otf")

  # ── Кнопки главного меню ────────────────────────────────────
  $TextureRect/PlayButton.pressed.connect(_on_play_pressed)
  $TextureRect/SaveButton.pressed.connect(_on_save_pressed)
  $TextureRect/CustomizationButton.pressed.connect(_on_customization_pressed)
  $TextureRect/SettingsButton.pressed.connect(_on_settings_pressed)
  $TextureRect/ExitButton.pressed.connect(_on_exit_pressed)

  # ── Диалог выхода ───────────────────────────────────────────
  $TextureRect/Controlvixod/yes.pressed.connect(_on_confirm_exit)
  $TextureRect/Controlvixod/no.pressed.connect(_on_cancel_exit)
  $TextureRect/Controlvixod/krest.pressed.connect(_on_cancel_exit)

  # ── Настройки ───────────────────────────────────────────────
  $TextureRect/Controlset/vixod.pressed.connect(_on_close_settings_pressed)

  # ── Панель сохранений ───────────────────────────────────────
  $TextureRect/Controlsave/vixod.pressed.connect(_on_close_save_pressed)
  $TextureRect/Controlsave/add.pressed.connect(_on_add_save_pressed)
  $TextureRect/Controlsave/delete.pressed.connect(_on_delete_save_pressed)

  $TextureRect/Controlvixod.visible = false
  $TextureRect/Controlset.visible   = false
  $TextureRect/Controlsave.visible  = false

  _setup_fps_popup()

  var sys: SaveSystemManager = _get_save_system()
  if sys:
    sys.saves_updated.connect(_refresh_saves_list)

  _refresh_saves_list()

# ────────────────────────────────────────────────────────────────
# ГЛАВНОЕ МЕНЮ
# ────────────────────────────────────────────────────────────────

func _on_play_pressed() -> void:
  get_tree().change_scene_to_file("res://scenes/intro.tscn")

func _on_exit_pressed() -> void:
  $TextureRect/Controlvixod.visible = true

func _on_confirm_exit() -> void:
  get_tree().quit()

func _on_cancel_exit() -> void:
  $TextureRect/Controlvixod.visible = false

func _on_customization_pressed() -> void:
  get_tree().change_scene_to_file("res://scenes/customization.tscn")

func _on_settings_pressed() -> void:
  $TextureRect/Controlset.visible = true

func _on_close_settings_pressed() -> void:
  $TextureRect/Controlset.visible = false

func _on_save_pressed() -> void:
  _selected_index = -1
  $TextureRect/Controlsave.visible = true
  _refresh_saves_list()

func _on_close_save_pressed() -> void:
  $TextureRect/Controlsave.visible = false
  _selected_index = -1

# ────────────────────────────────────────────────────────────────
# СОХРАНЕНИЯ
# ────────────────────────────────────────────────────────────────

func _on_add_save_pressed() -> void:
  var sys: SaveSystemManager = _get_save_system()
  if not sys:
    return

  if not sys.can_add():
    _flash_button($TextureRect/Controlsave/add, Color.RED)
    return

  var g: GlobalDataManager = get_node_or_null("/root/GlobalData")
  var scene: String = g.last_played_scene if g else ""

  if scene == "":
    _flash_button($TextureRect/Controlsave/add, Color.RED)
    return

  if sys.create_save(scene):
    _flash_button($TextureRect/Controlsave/add, Color.GREEN)
  # _refresh_saves_list вызовется автоматически через saves_updated

## Удаляет ВЫБРАННЫЙ слот.
## Если ничего не выбрано — подсвечивает кнопку красным как подсказку.
func _on_delete_save_pressed() -> void:
  var sys: SaveSystemManager = _get_save_system()
  if not sys or sys.get_count() == 0:
    _flash_button($TextureRect/Controlsave/delete, Color.RED)
    return

  if _selected_index < 0 or _selected_index >= sys.get_count():
    # Ничего не выбрано — намекаем игроку выбрать слот
    _flash_button($TextureRect/Controlsave/delete, Color.RED)
    _flash_saves_list_hint()
    return

  sys.delete_at(_selected_index)
  _selected_index = -1
  # _refresh_saves_list вызовется через saves_updated

## Перестраивает список слотов.
func _refresh_saves_list() -> void:
  _slot_buttons.clear()

  for child: Node in saves_list.get_children():
    child.queue_free()

  var sys: SaveSystemManager = _get_save_system()
  if not sys:
    return

  var slots := sys.get_slots()
  for i: int in slots.size():
    var btn: Button = _build_slot_button(slots[i], i)
    saves_list.add_child(btn)
    _slot_buttons.append(btn)

  # Восстанавливаем подсветку после перестройки
  _update_slot_highlights()

## Строит кнопку-слот.
func _build_slot_button(slot: Dictionary, index: int) -> Button:
  var btn := Button.new()
  btn.flat = true
  btn.focus_mode = Control.FOCUS_NONE
  btn.custom_minimum_size = Vector2(0.0, 150.0)

  # --- фоновая текстура ---
  if SLOT_TEXTURE:
    var bg := TextureRect.new()
    bg.texture      = SLOT_TEXTURE
    bg.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
    bg.stretch_mode = TextureRect.STRETCH_SCALE
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    btn.add_child(bg)

  var s_normal  := _make_slot_style(Color(0.0, 0.0, 0.0, 0.0))
  var s_hover   := _make_slot_style(Color(0.553, 0.459, 0.984, 0.15))
  var s_pressed := _make_slot_style(Color(0.553, 0.459, 0.984, 0.30))
  btn.add_theme_stylebox_override("normal",  s_normal)
  btn.add_theme_stylebox_override("hover",   s_hover)
  btn.add_theme_stylebox_override("pressed", s_pressed)

  # --- Номер сохранения (крупно, слева) ---
  var slot_number: int = slot.get("number", index + 1)

  var lbl_number := Label.new()
  lbl_number.text     = "%d" % slot_number
  lbl_number.position = Vector2(62.0, 62.0)
  lbl_number.add_theme_color_override("font_color", Color(0, 0, 0, 1.0))
  if _custom_font:
    lbl_number.add_theme_font_override("font", _custom_font1)
    lbl_number.add_theme_font_size_override("font_size", 42)
  btn.add_child(lbl_number)

  # --- Название миссии ---
  var lbl_name := Label.new()
  lbl_name.text     = slot.get("label", "?")
  lbl_name.position = Vector2(148.0, 40.0)
  lbl_name.add_theme_color_override("font_color", Color.BLACK)
  if _custom_font:
    lbl_name.add_theme_font_override("font", _custom_font1)
    lbl_name.add_theme_font_size_override("font_size", 35)
  btn.add_child(lbl_name)

  # --- Подсказка (появляется когда слот выбран) ---
  var lbl_hint := Label.new()
  lbl_hint.name     = "HintLabel"
  lbl_hint.text     = "▶ Нажми ещё раз для загрузки"
  lbl_hint.position = Vector2(120.0, 62.0)
  lbl_hint.visible  = false
  lbl_hint.add_theme_color_override("font_color", Color(0.618, 0.003, 0.88, 1.0))
  if _custom_font:
    lbl_hint.add_theme_font_override("font", _custom_font1)
    lbl_hint.add_theme_font_size_override("font_size", 30)
  btn.add_child(lbl_hint)

  # --- Дата и время (справа) ---
  var lbl_time := Label.new()
  lbl_time.text     = slot.get("time", "??:??") + "\n" + slot.get("date", "??.??.????")
  lbl_time.position = Vector2(966.0, 52.0)
  lbl_time.add_theme_color_override("font_color", Color.BLACK)
  if _custom_font:
    lbl_time.add_theme_font_override("font", _custom_font1)
    lbl_time.add_theme_font_size_override("font_size", 24)
  btn.add_child(lbl_time)

  btn.pressed.connect(func() -> void: _on_slot_pressed(index))
  return btn

func _make_slot_style(tint: Color) -> StyleBoxFlat:
  var s := StyleBoxFlat.new()
  s.bg_color = tint
  s.set_corner_radius_all(8)
  return s

## Первый клик — выбор слота (подсветка).
## Второй клик по уже выбранному — загрузка сцены.
func _on_slot_pressed(index: int) -> void:
  if _selected_index == index:
    # Повторный клик = загрузка
    _load_save_at(index)
  else:
    # Первый клик = выбор
    _selected_index = index
    _update_slot_highlights()

## Загружает сцену из слота по индексу.
func _load_save_at(index: int) -> void:
  var sys: SaveSystemManager = _get_save_system()
  if not sys:
    return
  var path: String = sys.scene_at(index)
  if path != "" and ResourceLoader.exists(path):
    get_tree().change_scene_to_file(path)
  else:
    push_warning("[MainMenu] Путь сцены не найден: '%s'" % path)
    _flash_button(_slot_buttons[index], Color.RED)

## Обновляет внешний вид всех слотов в зависимости от выбранного.
func _update_slot_highlights() -> void:
  for i: int in _slot_buttons.size():
    var btn: Button = _slot_buttons[i]
    var hint: Label = btn.get_node_or_null("HintLabel")
    var is_selected: bool = (i == _selected_index)

    # Подсветка самой кнопки
    btn.modulate = COLOR_SELECTED if is_selected else COLOR_NORMAL

    # Показываем подсказку «нажми ещё раз» только у выбранного
    if hint:
      hint.visible = is_selected

## Мигает всеми слотами зелёным — подсказка «выбери слот для удаления».
func _flash_saves_list_hint() -> void:
  for btn: Button in _slot_buttons:
    var tw := btn.create_tween()
    tw.tween_property(btn, "modulate", Color(1.0, 0.404, 0.502, 1.0), 0.15)
    tw.tween_property(btn, "modulate", COLOR_NORMAL,                0.35)

# ────────────────────────────────────────────────────────────────
# НАСТРОЙКИ
# ────────────────────────────────────────────────────────────────

func _on_volume_slider_value_changed(value: float) -> void:
  var bus_index := AudioServer.get_bus_index("Master")
  AudioServer.set_bus_volume_db(bus_index, value)
  AudioServer.set_bus_mute(bus_index, value <= -30.0)

func _on_fps_button_item_selected(index: int) -> void:
  Engine.max_fps = 30 if index == 0 else 60

func _on_anti_aliasing_button_toggled(toggled_on: bool) -> void:
  var rid := get_viewport().get_viewport_rid()
  var msaa := RenderingServer.VIEWPORT_MSAA_2X if toggled_on \
        else RenderingServer.VIEWPORT_MSAA_DISABLED
  RenderingServer.viewport_set_msaa_2d(rid, msaa)

# ────────────────────────────────────────────────────────────────
# УТИЛИТЫ
# ────────────────────────────────────────────────────────────────

func _get_save_system() -> SaveSystemManager:
  var sys := get_node_or_null("/root/SaveSystem") as SaveSystemManager
  if not sys:
    push_error("[MainMenu] Autoload 'SaveSystem' не найден!")
  return sys

func _flash_button(btn: Button, color: Color) -> void:
  var tw := create_tween()
  tw.tween_property(btn, "modulate", color,       0.1)
  tw.tween_property(btn, "modulate", Color.WHITE, 0.4)

func _setup_fps_popup() -> void:
  var fps_button  := $"TextureRect/Controlset/FPSButton"
  var popup: PopupMenu = fps_button.get_popup()
  var new_style   := StyleBoxFlat.new()
  new_style.bg_color = Color("d0cde6")
  new_style.set_corner_radius_all(8)
  new_style.content_margin_left   = 15
  new_style.content_margin_right  = 15
  new_style.content_margin_top    = 10
  new_style.content_margin_bottom = 10
  popup.add_theme_stylebox_override("panel", new_style)
  if _custom_font:
    popup.add_theme_font_override("font", _custom_font)
  popup.add_theme_font_size_override("font_size", 35)
  popup.add_theme_color_override("font_color",       Color.BLACK)
  popup.add_theme_color_override("font_hover_color", Color.BLACK)
