# scripts/minigame_sort_cards.gd
extends Control
class_name MinigameSortCards

## Эмитируется когда игрок завершает проверку.
## correct_count = количество карточек на правильных позициях (0–5)
signal completed(correct_count: int)

# ─── Данные (передаются через setup) ────────────────────────────────────────
var _cards_data:    Array[Dictionary] = []
var _slots_count:   int   = 5
var _initial_time:  float = 60.0

# ─── Состояние ───────────────────────────────────────────────────────────────
var _slot_content:   Array[int] = []  # [slot_idx]  → card_idx, -1 = пусто
var _card_in_slot:   Array[int] = []  # [card_idx]  → slot_idx, -1 = в пуле
var _selected_card:  int   = -1
var _time_left:      float = 60.0
var _ticking:        bool  = false
var _result_shown:   bool  = false

@onready var _minigame_root: Control = self

# ─── UI-ссылки ───────────────────────────────────────────────────────────────
var _slot_panels:   Array[Panel]  = []
var _slot_text:     Array[Label]  = []
var _slot_numeral:  Array[Label]  = []
var _card_buttons:  Array[Button] = []
var _timer_label:   Label
var _check_button:  Button
var _hint_label:    Label

var _font: Font

# ─── Константы оформления ────────────────────────────────────────────────────
const NUMERALS := ["I", "II", "III", "IV", "V"]

const C_PHONE_BG     := Color(0.14, 0.11, 0.09, 1.00)
const C_PHONE_BORDER := Color(0.48, 0.40, 0.28, 1.00)
const C_NOTES_BG     := Color(0.97, 0.92, 0.78, 1.00)
const C_NOTES_BAR    := Color(0.87, 0.81, 0.64, 1.00)
const C_SLOT_EMPTY   := Color(0.91, 0.85, 0.68, 1.00)
const C_SLOT_FILLED  := Color(0.98, 0.93, 0.78, 1.00)
const C_SLOT_BORDER  := Color(0.60, 0.52, 0.36, 1.00)
const C_CARD         := Color(0.96, 0.90, 0.72, 1.00)
const C_CARD_HOVER   := Color(0.99, 0.95, 0.82, 1.00)
const C_CARD_SEL     := Color(1.00, 0.88, 0.28, 1.00)
const C_CARD_PLACED  := Color(0.78, 0.73, 0.58, 1.00)
const C_CARD_BORDER  := Color(0.58, 0.50, 0.34, 1.00)
const C_CORRECT      := Color(0.28, 0.76, 0.36, 1.00)
const C_WRONG        := Color(0.84, 0.22, 0.22, 1.00)
const C_TEXT         := Color(0.16, 0.10, 0.04, 1.00)
const C_HINT         := Color(0.65, 0.58, 0.42, 1.00)
const C_TIMER_OK     := Color(0.55, 0.95, 0.60, 1.00)
const C_TIMER_WARN   := Color(0.95, 0.22, 0.22, 1.00)
const C_BTN_OFF      := Color(0.32, 0.30, 0.26, 1.00)
const C_BTN_ON       := Color(0.52, 0.44, 0.30, 1.00)
const C_BTN_HOVER    := Color(0.64, 0.56, 0.40, 1.00)

const PHONE_W := 1800.0
const PHONE_H := 1000.0

# ─── Публичный API ───────────────────────────────────────────────────────────

## Вызывать ПОСЛЕ add_child(). Инициализирует данные и строит UI.
func setup(cards: Array[Dictionary], slots: int, timer_sec: int) -> void:
    _cards_data = cards
    _slots_count = slots
    _initial_time = float(timer_sec)
    _time_left = _initial_time

    _slot_content.clear()
    _card_in_slot.clear()
    for _i in slots: _slot_content.append(-1)
    for _i in cards.size(): _card_in_slot.append(-1)

    _selected_card = -1
    _result_shown = false
    _ticking = true

    for c in get_children():
        c.queue_free()

    _build_ui()


func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    
    const FONT_PATH = "res://assets/text/ArcadeJeu-Regular.otf"
    if ResourceLoader.exists(FONT_PATH):
        _font = load(FONT_PATH)
    else:
        push_warning("Шрифт не найден: " + FONT_PATH)
    
    if not _font:
        _font = ThemeDB.fallback_font


func _process(delta: float) -> void:
    if not _ticking:
        return
    _time_left = maxf(_time_left - delta, 0.0)
    _refresh_timer()
    if _time_left <= 0.0:
        _ticking = false
        _on_timeout()

# ─── Построение UI ───────────────────────────────────────────────────────────

func _build_ui() -> void:
    var dim := ColorRect.new()
    dim.name = "Dim"
    dim.color = Color(0.0, 0.0, 0.0, 0.82)
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    dim.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(dim)

    var phone := Panel.new()
    phone.size = Vector2(840, 620)
    phone.position = Vector2(50, 70)
    phone.mouse_filter = Control.MOUSE_FILTER_PASS
    dim.add_child(phone)

    # Декоративная линия под шапкой
    var sep := ColorRect.new()
    sep.color    = Color(C_PHONE_BORDER, 0.35)
    sep.position = Vector2(24, 56)
    sep.size     = Vector2(PHONE_W - 48, 1)
    phone.add_child(sep)

    # ── Заголовок ────────────────────────────────────────────────
    var title := _lbl("МИНИ-ИГРА 1: СОБЕРИ РЕФЕРАТ", 50,
            Color(0.90, 0.84, 0.64, 1.0))
    title.position = Vector2(14, -20)
    title.size     = Vector2(PHONE_W , 500)
    title.add_theme_font_override("font", _font)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    phone.add_child(title)

    # ── Таймер ───────────────────────────────────────────────────
    var tbg := Panel.new()
    tbg.position = Vector2(PHONE_W- 218, -40)
    tbg.size     = Vector2(200, 100)
    _mk_panel(tbg, Color(0.04, 0.04, 0.04, 1.0), Color(0.32, 0.32, 0.32, 1.0), 2, 6)
    phone.add_child(tbg)

    var tcap := _lbl("ТАЙМЕР", 35, Color(0.52, 0.52, 0.52, 1.0))
    tcap.position = Vector2(5, 15)
    tcap.size     = Vector2(122, 18)
    tcap.add_theme_font_override("font", _font)
    tcap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    tcap.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    tbg.add_child(tcap)

    _timer_label = _lbl(_fmt_time(_time_left), 35, C_TIMER_OK)
    _timer_label.position = Vector2(22, 55)
    _timer_label.size     = Vector2(122, 29)
    _timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    tbg.add_child(_timer_label)

    # ── Notes-панель (слоты) ─────────────────────────────────────
    var notes := Panel.new()
    notes.position = Vector2(14, 62)
    notes.size     = Vector2(PHONE_W, 700)
    _mk_panel(notes, C_NOTES_BG, Color(0.68, 0.60, 0.44, 1.0), 2, 8)
    phone.add_child(notes)

    # Шапка Notes
    var nbar := ColorRect.new()
    nbar.color    = C_NOTES_BAR
    nbar.position = Vector2(0, 0)
    nbar.size     = Vector2(notes.size.x, 40)
    notes.add_child(nbar)
    var nlbl := _lbl("Блокнот", 26, C_TEXT)
    nlbl.position = Vector2(10, 10)
    nlbl.size     = Vector2(220, 22)
    nbar.add_child(nlbl)

    # Создаём слоты
    var avail_w : float = notes.size.x - 16.0
    var slot_w  : float = (avail_w - float(_slots_count - 1) * 6.0) / float(_slots_count)
    var slot_h  : float = 250

    for i in _slots_count:
        var sp := Panel.new()
        sp.position = Vector2(8.0 + float(i) * (slot_w + 6.0), 45.0)
        sp.size     = Vector2(slot_w, slot_h)
        _mk_panel(sp, C_SLOT_EMPTY, C_SLOT_BORDER, 2, 5)
        notes.add_child(sp)
        _slot_panels.append(sp)

        # Римская цифра (видна когда слот пуст)
        var num := _lbl(NUMERALS[i], 100, Color(0.50, 0.38, 0.20, 0.50))
        num.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        num.offset_bottom = 20
        num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        num.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
        sp.add_child(num)
        _slot_numeral.append(num)

        # Текст карточки в слоте
        var txt := _lbl("", 30, C_TEXT)
        txt.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        txt.offset_left = 4; txt.offset_right  = -4
        txt.offset_top  = 4; txt.offset_bottom = -4
        txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        txt.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
        txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        sp.add_child(txt)
        _slot_text.append(txt)

        # Невидимая кнопка-оверлей для клика по слоту
        var sbtn := Button.new()
        sbtn.flat = true
        sbtn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        for sn in ["normal", "hover", "pressed", "focus", "disabled"]:
            sbtn.add_theme_stylebox_override(sn, StyleBoxEmpty.new())
        sbtn.focus_mode = Control.FOCUS_NONE
        var ci := i
        sbtn.pressed.connect(func(): _on_slot_clicked(ci))
        sp.add_child(sbtn)

    # ── Сетка карточек ───────────────────────────────────────────
    var grid := GridContainer.new()
    grid.columns  = 4
    grid.position = Vector2(20, 363)
    grid.size     = Vector2(1000, 500)
    grid.add_theme_constant_override("h_separation", 6)
    grid.add_theme_constant_override("v_separation", 6)
    phone.add_child(grid)

    # Перемешиваем порядок отображения карточек
    var order: Array[int] = []
    for i in _cards_data.size():
        order.append(i)
    order.shuffle()

    _card_buttons.resize(_cards_data.size())

    for di in order.size():
        var ci: int    = order[di]
        var ctxt: String = _cards_data[ci].get("text", "")

        var btn := Button.new()
        btn.custom_minimum_size = Vector2(442, 190)
        btn.text          = ctxt
        btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        btn.focus_mode    = Control.FOCUS_NONE
        if _font:
            btn.add_theme_font_override("font", _font)
        btn.add_theme_font_size_override("font_size", 27)
        for col_name in ["font_color", "font_hover_color", "font_pressed_color"]:
            btn.add_theme_color_override(col_name, C_TEXT)
        btn.add_theme_color_override("font_disabled_color",
                Color(C_TEXT.r, C_TEXT.g, C_TEXT.b, 0.50))

        # Normal
        var sn := _card_style(C_CARD, C_CARD_BORDER, 2)
        btn.add_theme_stylebox_override("normal", sn)
        # Hover
        var sh := _card_style(C_CARD_HOVER, C_CARD_BORDER, 2)
        btn.add_theme_stylebox_override("hover", sh)
        # Disabled (размещена)
        var sd := _card_style(C_CARD_PLACED, Color(0.42, 0.38, 0.28, 1.0), 1)
        btn.add_theme_stylebox_override("disabled", sd)
        # Focus – убираем рамку
        btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

        grid.add_child(btn)
        _card_buttons[ci] = btn

        var cap_ci := ci
        btn.pressed.connect(func(): _on_card_clicked(cap_ci))

    # ── Подсказка ────────────────────────────────────────────────
    _hint_label = _lbl(
            "ЗАПОЛНИТЕ ВСЕ %d СЛОТОВ, ЧТОБЫ ПРОВЕРИТЬ" % _slots_count,
            35, C_HINT)
    _hint_label.position = Vector2(14, PHONE_H - 200)
    _hint_label.size     = Vector2(PHONE_W - 28, 26)
    _hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    phone.add_child(_hint_label)

    # ── Кнопка ПРОВЕРИТЬ ─────────────────────────────────────────
    _check_button = Button.new()
    _check_button.text      = "ПРОВЕРИТЬ"
    _check_button.position  = Vector2(730, PHONE_H - 130)
    _check_button.size      = Vector2(300, 100)
    _check_button.disabled  = true
    _check_button.focus_mode = Control.FOCUS_NONE
    if _font:
        _check_button.add_theme_font_override("font", _font)
    _check_button.add_theme_font_size_override("font_size", 25)
    _check_button.add_theme_color_override("font_color",         Color(0.88, 0.80, 0.58, 1.0))
    _check_button.add_theme_color_override("font_disabled_color", Color(0.46, 0.44, 0.38, 1.0))

    _check_button.add_theme_stylebox_override("normal",   _btn_style(C_BTN_OFF))
    _check_button.add_theme_stylebox_override("disabled", _btn_style(C_BTN_OFF))
    _check_button.add_theme_stylebox_override("hover",    _btn_style(C_BTN_HOVER))
    _check_button.add_theme_stylebox_override("pressed",  _btn_style(C_BTN_ON))
    _check_button.add_theme_stylebox_override("focus",    StyleBoxEmpty.new())
    _check_button.pressed.connect(_on_check_pressed)
    phone.add_child(_check_button)


# ─── Обработчики взаимодействия ──────────────────────────────────────────────

func _on_card_clicked(card_idx: int) -> void:
    if _result_shown:
        return
    if _card_in_slot[card_idx] != -1:
        return  # карточка в слоте – клик обрабатывается через слот

    if _selected_card == card_idx:
        # Снять выделение
        _selected_card = -1
        _set_card_highlight(card_idx, false)
    else:
        if _selected_card != -1:
            _set_card_highlight(_selected_card, false)
        _selected_card = card_idx
        _set_card_highlight(card_idx, true)


func _on_slot_clicked(slot_idx: int) -> void:
    if _result_shown:
        return

    var occupant: int = _slot_content[slot_idx]

    if occupant != -1:
        # Слот занят → вернуть карточку в пул
        _return_card(slot_idx)
        if _selected_card != -1:
            _set_card_highlight(_selected_card, false)
            _selected_card = -1
    elif _selected_card != -1:
        # Поместить выбранную карточку в слот
        _place_card(_selected_card, slot_idx)
        _selected_card = -1

    _update_check_btn()


func _place_card(card_idx: int, slot_idx: int) -> void:
    _slot_content[slot_idx]  = card_idx
    _card_in_slot[card_idx]  = slot_idx

    _card_buttons[card_idx].disabled = true

    _slot_text[slot_idx].text          = _cards_data[card_idx].get("text", "")
    _slot_numeral[slot_idx].visible    = false

    var s := _slot_panels[slot_idx].get_theme_stylebox("panel") as StyleBoxFlat
    if s:
        s.bg_color     = C_SLOT_FILLED
        s.border_color = Color(0.50, 0.44, 0.28, 1.0)


func _return_card(slot_idx: int) -> void:
    var card_idx: int = _slot_content[slot_idx]
    if card_idx == -1:
        return

    _slot_content[slot_idx] = -1
    _card_in_slot[card_idx] = -1

    _card_buttons[card_idx].disabled = false
    _set_card_highlight(card_idx, false)

    _slot_text[slot_idx].text       = ""
    _slot_numeral[slot_idx].visible = true

    var s := _slot_panels[slot_idx].get_theme_stylebox("panel") as StyleBoxFlat
    if s:
        s.bg_color     = C_SLOT_EMPTY
        s.border_color = C_SLOT_BORDER


func _on_check_pressed() -> void:
    if _result_shown:
        return
    _result_shown = true
    _ticking      = false
    _check_button.disabled = true
    _animate_results()


func _on_timeout() -> void:
    if _result_shown:
        return
    _result_shown = true
    completed.emit(0)

# ─── Анимация результата ─────────────────────────────────────────────────────

func _animate_results() -> void:
    var correct := 0

    for slot_idx in _slots_count:
        var card_idx: int = _slot_content[slot_idx]
        if card_idx == -1:
            continue
        var expected: int = _cards_data[card_idx].get("correct_position", -1)
        var ok: bool      = (expected == slot_idx)
        if ok:
            correct += 1

        var target_color := C_CORRECT if ok else C_WRONG
        var delay        := float(slot_idx) * 0.18

        # Анимация через tween с задержкой
        var tw := create_tween()
        tw.tween_callback(func():
            var st := _slot_panels[slot_idx].get_theme_stylebox("panel") as StyleBoxFlat
            if st:
                st.bg_color = target_color
        ).set_delay(delay)

    var wait := float(_slots_count) * 0.18 + 3
    await get_tree().create_timer(wait).timeout
    completed.emit(correct)

# ─── Визуальные хелперы ──────────────────────────────────────────────────────

func _set_card_highlight(card_idx: int, on: bool) -> void:
    if card_idx < 0 or card_idx >= _card_buttons.size():
        return
    var btn := _card_buttons[card_idx]
    if not is_instance_valid(btn):
        return
    var s := btn.get_theme_stylebox("normal") as StyleBoxFlat
    if not s:
        return
    if on:
        s.bg_color     = C_CARD_SEL
        s.border_color = Color(0.90, 0.70, 0.05, 1.0)
        s.border_width_top = 3; s.border_width_bottom = 3
        s.border_width_left = 3; s.border_width_right  = 3
    else:
        s.bg_color     = C_CARD
        s.border_color = C_CARD_BORDER
        s.border_width_top = 2; s.border_width_bottom = 2
        s.border_width_left = 2; s.border_width_right  = 2


func _update_check_btn() -> void:
    var full := true
    for c in _slot_content:
        if c == -1:
            full = false
            break
    _check_button.disabled = not full
    _check_button.add_theme_stylebox_override("normal",
            _btn_style(C_BTN_ON if full else C_BTN_OFF))


func _refresh_timer() -> void:
    if not _timer_label:
        return
    _timer_label.text = _fmt_time(_time_left)
    _timer_label.add_theme_color_override("font_color",
            C_TIMER_WARN if _time_left <= 10.0 else C_TIMER_OK)


func _fmt_time(t: float) -> String:
    var s := ceili(t)
    return "%02d:%02d" % [s / 60, s % 60]

# ─── Фабрики стилей / узлов ──────────────────────────────────────────────────

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


func _card_style(bg: Color, border: Color, bw: int) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = bg
    s.set_corner_radius_all(5)
    s.border_width_top    = bw; s.border_width_bottom = bw
    s.border_width_left   = bw; s.border_width_right  = bw
    s.border_color        = border
    return s


func _btn_style(bg: Color) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = bg
    s.set_corner_radius_all(8)
    s.border_width_top    = 2; s.border_width_bottom = 2
    s.border_width_left   = 2; s.border_width_right  = 2
    s.border_color        = Color(bg.r + 0.12, bg.g + 0.10, bg.b + 0.08, 1.0)
    return s
