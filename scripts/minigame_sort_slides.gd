# scripts/minigame_sort_slides.gd
extends Control
class_name MinigameSortSlides

## Эмитируется когда игрок завершает игру.
## is_success = true если порядок верный и таймер не истёк
signal completed(is_success: bool)

# ─── Данные ──────────────────────────────────────────────────────────────────
var _slides_data:     Array[Dictionary] = []
var _current_order:   Array[int]        = []  # [display_pos] → data_idx
var _timer_duration:  float = 60.0
var _time_left:       float = 60.0
var _ticking:         bool  = false
var _result_shown:    bool  = false

# ─── Drag-состояние ──────────────────────────────────────────────────────────
var _drag_active:       bool  = false
var _drag_from_pos:     int   = -1
var _drag_ghost:        Panel = null
var _drag_mouse_off_y:  float = 0.0  # смещение от верха строки до мыши

# ─── UI-ссылки ───────────────────────────────────────────────────────────────
var _row_panels:   Array[Panel] = []  # в порядке _current_order
var _screen_panel: Panel        = null
var _list_vbox:    VBoxContainer = null
var _timer_lbl:    Label         = null
var _submit_btn:   Button        = null
var _font:         Font

# ─── Стилевые константы ──────────────────────────────────────────────────────
const C_BG        := Color(0.00, 0.00, 0.00, 0.80)
const C_SCREEN    := Color(0.96, 0.96, 0.97, 1.00)
const C_HEADER    := Color(0.88, 0.88, 0.92, 1.00)
const C_BORDER    := Color(0.74, 0.74, 0.80, 1.00)
const C_ROW       := Color(1.00, 1.00, 1.00, 1.00)
const C_ROW_DRAG  := Color(0.88, 0.92, 1.00, 1.00)
const C_ROW_BOR   := Color(0.76, 0.76, 0.84, 1.00)
const C_TEXT      := Color(0.10, 0.10, 0.14, 1.00)
const C_NUM       := Color(0.50, 0.50, 0.58, 1.00)
const C_HANDLE    := Color(0.55, 0.55, 0.64, 1.00)
const C_BTN       := Color(0.72, 0.76, 0.90, 1.00)
const C_BTN_HOV   := Color(0.62, 0.66, 0.84, 1.00)
const C_BTN_BOR   := Color(0.56, 0.60, 0.76, 1.00)
const C_TIMER     := Color(0.12, 0.12, 0.16, 1.00)
const C_TIMER_W   := Color(0.88, 0.14, 0.14, 1.00)
const C_GREEN     := Color(0.30, 0.78, 0.38, 1.00)
const C_RED       := Color(0.84, 0.22, 0.22, 1.00)
const C_GHOST_BOR := Color(0.40, 0.55, 0.90, 1.00)

const SCREEN_W := 680.0
const SCREEN_H := 520.0
const ROW_H    := 130
const ROW_SEP  :=  5.0

# ─── Публичный API ───────────────────────────────────────────────────────────

func setup(slides: Array[Dictionary], timer_sec: int) -> void:
    _slides_data    = slides
    _timer_duration = float(timer_sec)
    _time_left      = _timer_duration
    _result_shown   = false
    _drag_active    = false
    _drag_from_pos  = -1

    _current_order.clear()
    for i in slides.size():
        _current_order.append(i)
    _current_order.shuffle()

    # Чистим старый UI если был
    for c in get_children():
        c.queue_free()
    _row_panels.clear()

    if is_inside_tree():
        _build_ui()
        _ticking = true


func _ready() -> void:
    const FP := "res://assets/text/ArcadeJeu-Regular.otf"
    if ResourceLoader.exists(FP):
        _font = load(FP)

# ─── _process: таймер + обновление ghost ─────────────────────────────────────

func _process(delta: float) -> void:
    # Таймер
    if _ticking:
        _time_left = maxf(_time_left - delta, 0.0)
        _refresh_timer()
        if _time_left <= 0.0:
            _ticking = false
            _on_timeout()

    # Ghost следует за мышью
    if _drag_active and is_instance_valid(_drag_ghost) and _screen_panel:
        var mouse_y_in_screen: float = \
                get_global_mouse_position().y - _screen_panel.global_position.y
        var new_ghost_y := mouse_y_in_screen - _drag_mouse_off_y
        var min_y := _list_vbox.position.y
        var max_y := _list_vbox.position.y + \
                float(_current_order.size() - 1) * (ROW_H + ROW_SEP)
        _drag_ghost.position.y = clampf(new_ghost_y, min_y, max_y)

# ─── Глобальный ввод – отпускание кнопки мыши ─────────────────────────────

func _input(event: InputEvent) -> void:
    if _drag_active and event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
            _end_drag()
            get_viewport().set_input_as_handled()

# ─── Построение UI ───────────────────────────────────────────────────────────

func _build_ui() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    
    var dim := ColorRect.new()
    dim.color = Color(0.0, 0.0, 0.0, 0.82)
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    dim.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(dim)

    _screen_panel = Panel.new()
    _screen_panel.size = Vector2(680, 520)
    _screen_panel.position = Vector2((1920 - 680)*0.5, (1080 - 520)*0.5)
    _screen_panel.mouse_filter = Control.MOUSE_FILTER_PASS
    dim.add_child(_screen_panel)

    # Шапка
    var header := Panel.new()
    header.position = Vector2(-350, -250)
    header.size     = Vector2(1600, 100)
    _mk_panel(header, C_HEADER, C_BORDER, 1, 0)
    # Скруглим только верхние углы шапки
    var hs := header.get_theme_stylebox("panel") as StyleBoxFlat
    if hs:
        hs.corner_radius_top_left  = 6
        hs.corner_radius_top_right = 6
    _screen_panel.add_child(header)

    # === ТАЙМЕР БЕЗ СТИКЕРА ===
    _timer_lbl = _lbl("Таймер: 00:00", 35, C_TIMER)
    _timer_lbl.position = Vector2(1300, 22)
    _timer_lbl.size     = Vector2(300, 40)
    _timer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _timer_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    header.add_child(_timer_lbl)

    # Заголовок «ПРЕЗЕНТАЦИЯ»
    var title := _lbl("МИНИ-ИГРА 2: СОБЕРИ ПРЕЗЕНТАЦИЮ", 40, C_TEXT)
    title.position = Vector2(70, 30)
    title.size     = Vector2(SCREEN_W, 28)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    header.add_child(title)

    # VBox строк
    _list_vbox = VBoxContainer.new()
    _list_vbox.position = Vector2(-350, -144)
    _list_vbox.size     = Vector2(1600, 800)
    _list_vbox.add_theme_constant_override("separation", int(ROW_SEP))
    _screen_panel.add_child(_list_vbox)

    _rebuild_rows()
    
    # Кнопка «ГОТОВО К ЗАЩИТЕ!»
    _submit_btn = Button.new()
    _submit_btn.text      = " ГОТОВО К ЗАЩИТЕ!"
    _submit_btn.position  = Vector2(160, 700)
    _submit_btn.size      = Vector2(320, 70)
    _submit_btn.focus_mode = Control.FOCUS_NONE
    if _font:
        _submit_btn.add_theme_font_override("font", _font)
    _submit_btn.add_theme_font_size_override("font_size", 40)
    _submit_btn.add_theme_color_override("font_color", C_TEXT)

    var ss := _mk_style(C_BTN, C_BTN_BOR, 2, 6)
    var sh := _mk_style(C_BTN_HOV, C_BTN_BOR, 2, 6)
    _submit_btn.add_theme_stylebox_override("normal",  ss)
    _submit_btn.add_theme_stylebox_override("hover",   sh)
    _submit_btn.add_theme_stylebox_override("pressed", _mk_style(
            Color(0.54, 0.58, 0.76, 1.0), C_BTN_BOR, 2, 6))
    _submit_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
    _submit_btn.pressed.connect(_on_submit)
    _screen_panel.add_child(_submit_btn)

# ─── Строки ──────────────────────────────────────────────────────────────────

func _rebuild_rows() -> void:
    for c in _list_vbox.get_children():
        c.free()   # немедленное освобождение чтобы VBox был чист
    _row_panels.clear()

    for disp_pos in _current_order.size():
        var data_idx: int = _current_order[disp_pos]
        var row := _create_row(disp_pos, data_idx)
        _list_vbox.add_child(row)
        _row_panels.append(row)


func _create_row(disp_pos: int, data_idx: int) -> Panel:
    var row := Panel.new()
    row.name = "SlideRow_%d" % disp_pos
    row.custom_minimum_size = Vector2(0, ROW_H)
    _mk_panel(row, C_ROW, C_ROW_BOR, 1, 4)
    row.set_meta("data_idx", data_idx)

    # Номер строки
    var num := _lbl("%d." % (disp_pos + 1), 35, C_NUM)
    num.name     = "NumLabel"
    num.position = Vector2(10, 0)
    num.size     = Vector2(30, ROW_H)
    num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    row.add_child(num)

    # Текст слайда
    var title := _lbl(_slides_data[data_idx].get("title", "?"), 35, C_TEXT)
    title.position = Vector2(80, 0)
    title.size     = Vector2(SCREEN_W - 112, ROW_H)
    title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    row.add_child(title)

    # Ручка перетаскивания ↕
    var handle := _lbl("↕", 45, C_HANDLE)
    handle.position = Vector2(1500, 0)
    handle.size     = Vector2(42, ROW_H)
    handle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    handle.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
    handle.mouse_filter = Control.MOUSE_FILTER_IGNORE
    row.add_child(handle)

    # Захватываем ссылку на саму строку (не индекс!) чтобы избежать stale closure
    row.gui_input.connect(func(ev: InputEvent): _on_row_input(ev, row))
    return row

# ─── Drag-логика ─────────────────────────────────────────────────────────────

func _on_row_input(event: InputEvent, row: Panel) -> void:
    if _result_shown or _drag_active:
        return
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            var pos := _row_panels.find(row)
            if pos == -1:
                return
            _start_drag(pos)
            get_viewport().set_input_as_handled()


func _start_drag(from_pos: int) -> void:
    _drag_active   = true
    _drag_from_pos = from_pos

    var row: Panel = _row_panels[from_pos]

    # Смещение мыши от верха строки в экранных координатах
    _drag_mouse_off_y = get_global_mouse_position().y - row.global_position.y

    # Создаём ghost (floating copy) в координатах _screen_panel
    _drag_ghost = Panel.new()
    _drag_ghost.size = Vector2(_list_vbox.size.x, ROW_H)
    # Начальная Y-позиция ghost = Y строки в координатах _screen_panel
    var row_y_in_screen := row.global_position.y - _screen_panel.global_position.y
    _drag_ghost.position = Vector2(_list_vbox.position.x, row_y_in_screen)
    _drag_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _mk_panel(_drag_ghost, C_ROW_DRAG, C_GHOST_BOR, 2, 4)

    # Иконка + текст на ghost
    var data_idx: int = _current_order[from_pos]
    var gtitle := _lbl(_slides_data[data_idx].get("title", "?"), 35, C_TEXT)
    gtitle.position = Vector2(80, 0)
    gtitle.size     = Vector2(SCREEN_W - 112, ROW_H)
    gtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    gtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _drag_ghost.add_child(gtitle)
    var ghandle := _lbl("↕", 45, C_GHOST_BOR)
    ghandle.position = Vector2(1500, 0)
    ghandle.size     = Vector2(42, ROW_H)
    ghandle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    ghandle.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
    ghandle.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _drag_ghost.add_child(ghandle)

    # Добавляем ghost поверх списка (в _screen_panel, над VBox)
    _screen_panel.add_child(_drag_ghost)

    # Оригинальную строку делаем полупрозрачной
    row.modulate = Color(1, 1, 1, 0.30)


func _end_drag() -> void:
    if not _drag_active:
        return
    _drag_active = false

    if not is_instance_valid(_drag_ghost):
        _drag_from_pos = -1
        return

    # Определяем целевую позицию по центру ghost
    var ghost_center_y := _drag_ghost.position.y + ROW_H * 0.5
    var to_pos := _compute_target_pos(ghost_center_y)

    _drag_ghost.free()
    _drag_ghost = null

    # Обновляем порядок
    if to_pos != _drag_from_pos:
        var moved: int = _current_order[_drag_from_pos]
        _current_order.remove_at(_drag_from_pos)
        _current_order.insert(to_pos, moved)

    _drag_from_pos = -1

    # Перестраиваем строки с новым порядком
    _rebuild_rows()


func _compute_target_pos(ghost_center_y_in_screen: float) -> int:
    # ghost_center_y в координатах _screen_panel
    # _list_vbox.position.y – верх списка в тех же координатах
    var local_y := ghost_center_y_in_screen - _list_vbox.position.y
    var idx     := int(local_y / (ROW_H + ROW_SEP))
    return clampi(idx, 0, _current_order.size() - 1)

# ─── Submit ──────────────────────────────────────────────────────────────────

func _on_submit() -> void:
    if _result_shown:
        return
    _result_shown = true
    _ticking = false
    _submit_btn.disabled = true
    _check_result()


func _on_timeout() -> void:
    if _result_shown:
        return
    _result_shown = true
    completed.emit(false)


func _check_result() -> void:
    var correct := true
    for disp_pos in _current_order.size():
        var data_idx: int = _current_order[disp_pos]
        var expected: int = _slides_data[data_idx].get("correct_position", -1)
        if expected != disp_pos:
            correct = false
            break

    if correct:
        # Все слайды верно → анимация зеленым
        for i in _row_panels.size():
            var tween := create_tween()
            tween.tween_callback(func():
                var st := _row_panels[i].get_theme_stylebox("panel") as StyleBoxFlat
                if st:
                    st.bg_color = C_GREEN
            ).set_delay(float(i) * 0.12)
        await get_tree().create_timer(float(_row_panels.size()) * 0.12 + 2).timeout
    else:
        # Неверные позиции → красный
        for i in _row_panels.size():
            var data_idx: int = _current_order[i]
            var expected: int = _slides_data[data_idx].get("correct_position", -1)
            if expected != i:
                var st := _row_panels[i].get_theme_stylebox("panel") as StyleBoxFlat
                if st:
                    st.bg_color = C_RED
        await get_tree().create_timer(4).timeout

    completed.emit(correct)

# ─── Таймер ──────────────────────────────────────────────────────────────────

func _refresh_timer() -> void:
    if not _timer_lbl:
        return
    _timer_lbl.text = "ТАЙМЕР\n" + _fmt(ceili(_time_left))
    _timer_lbl.add_theme_color_override("font_color",
            C_TIMER_W if _time_left <= 10.0 else C_TIMER)


func _fmt(s: int) -> String:
    return "%02d:%02d" % [s / 60, s % 60]

# ─── Фабрики ─────────────────────────────────────────────────────────────────

func _lbl(text: String, size: int, color: Color) -> Label:
    var l := Label.new()
    l.text = text
    if _font:
        l.add_theme_font_override("font", _font)
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", color)
    return l


func _mk_panel(p: Panel, bg: Color, border: Color, bw: int, r: int) -> void:
    var s := StyleBoxFlat.new()
    s.bg_color = bg
    s.set_corner_radius_all(r)
    s.border_width_top    = bw; s.border_width_bottom = bw
    s.border_width_left   = bw; s.border_width_right  = bw
    s.border_color        = border
    p.add_theme_stylebox_override("panel", s)


func _mk_style(bg: Color, border: Color, bw: int, r: int) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = bg
    s.set_corner_radius_all(r)
    s.border_width_top    = bw; s.border_width_bottom = bw
    s.border_width_left   = bw; s.border_width_right  = bw
    s.border_color        = border
    return s
