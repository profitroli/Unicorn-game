# scripts/minigame_profile_questionnaire.gd
extends Control
class_name MinigameProfileQuestionnaire

## Эмитируется после ответа на все вопросы.
## score: количество правильных ответов (0–4)
signal completed(score: int)

# ─── Данные ──────────────────────────────────────────────────────────────────
var _questions_data:   Array[Dictionary] = []
var _current_idx:      int  = 0
var _score:            int  = 0
var _answered:         bool = false

var _portrait_neutral: Texture2D
var _portrait_happy:   Texture2D
var _portrait_sad:     Texture2D

# ─── UI-ссылки ───────────────────────────────────────────────────────────────
var _avatar_tex:     TextureRect
var _progress_lbl:   Label
var _question_lbl:   Label
var _option_panels:  Array[Panel]  = []
var _option_lbls:    Array[Label]  = []
var _option_btns:    Array[Button] = []
var _reaction_lbl:   Label
var _next_btn:       Button
var _font:           Font

# ─── Пастельная палитра SoulMatch ────────────────────────────────────────────
const C_DIM      := Color(0.0, 0.0, 0.0, 0.0)
const C_PHONE    := Color(0.99, 0.97, 1.00, 1.00)
const C_PBORD    := Color(0.58, 0.48, 0.74, 1.00)
const C_HEADER   := Color(0.91, 0.86, 0.97, 1.00)
const C_AVATAR   := Color(0.88, 0.80, 0.96, 1.00)
const C_QBKG     := Color(0.75, 0.63, 0.92, 1.00)
const C_OPT      := Color(0.99, 0.96, 0.92, 1.00)
const C_OPTBOR   := Color(0.84, 0.78, 0.92, 1.00)
const C_OPTHOV   := Color(0.94, 0.88, 1.00, 1.00)
const C_CORRECT  := Color(0.72, 0.96, 0.72, 1.00)
const C_WRONG    := Color(1.00, 0.72, 0.72, 1.00)
const C_NAV      := Color(0.84, 0.78, 0.96, 1.00)
const C_TXT      := Color(0.16, 0.10, 0.24, 1.00)
const C_TXTG     := Color(0.44, 0.38, 0.58, 1.00)
const C_WHITE    := Color(1.00, 1.00, 1.00, 1.00)
const C_SAVEBG   := Color(0.722, 0.62, 0.922, 0.0)
const C_ROK      := Color(0.12, 0.54, 0.22, 1.00)
const C_RERR     := Color(0.76, 0.16, 0.16, 1.00)

const PHONE_W: float = 463.0
const PHONE_H: float = 1007.0
const OPT_H:   float = 120.0
const OPT_GAP: float = 8.0
const LETTERS: Array  = ["A", "B", "C"]

# ─── Публичный API ───────────────────────────────────────────────────────────

## Вызывать ПОСЛЕ add_child. Инициализирует данные и строит интерфейс.
func setup(
        questions:        Array[Dictionary],
        portrait_neutral: Texture2D,
        portrait_happy:   Texture2D = null,
        portrait_sad:     Texture2D = null
) -> void:
    _questions_data   = questions
    _portrait_neutral = portrait_neutral
    _portrait_happy   = portrait_happy if portrait_happy  else portrait_neutral
    _portrait_sad     = portrait_sad   if portrait_sad    else portrait_neutral
    _current_idx = 0
    _score       = 0
    _answered    = false

    for c in get_children():
        c.queue_free()
    _option_panels.clear()
    _option_lbls.clear()
    _option_btns.clear()

    if is_inside_tree():
        _build_ui()
        _show_question(0)

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    const FP := "res://assets/text/ArcadeJeu-Regular.otf"
    _font = load(FP) if ResourceLoader.exists(FP) else ThemeDB.fallback_font

# ─── Построение интерфейса ────────────────────────────────────────────────────

func _build_ui() -> void:
    var full_bg := TextureRect.new()
    full_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    full_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    full_bg.stretch_mode = TextureRect.STRETCH_SCALE
    full_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE

    const BG_PATH = "res://assets/alisa/Профиль алисы-Photoroom 1.png"
    if ResourceLoader.exists(BG_PATH):
        full_bg.texture = load(BG_PATH)
    else:
        push_warning("Не найдена фоновая картинка: " + BG_PATH)
        full_bg.modulate = Color(0.3, 0.3, 0.3)  # тёмный фон на случай ошибки

    add_child(full_bg)
    # Затемнение фона
    var dim := ColorRect.new()
    dim.color = C_DIM
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    dim.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(dim)

    var px := (1920.0 - PHONE_W) * 0.5
    var py := (1080.0 - PHONE_H) * 0.5


    # ── Корпус телефона ──────────────────────────────────────────────
    var phone := Panel.new()
    phone.position     = Vector2(px, py)
    phone.size         = Vector2(PHONE_W, PHONE_H)
    phone.mouse_filter = Control.MOUSE_FILTER_PASS
    _mk_panel(phone, C_PHONE, C_PBORD, 3, 70)
    dim.add_child(phone)
    

    # ── Шапка: «Редактирование профиля» ─────────────────────────────
    var hdr := Panel.new()
    hdr.size = Vector2(PHONE_W, 56)
    _mk_panel(hdr, C_HEADER, C_PBORD, 0, 0)
    var hs := hdr.get_theme_stylebox("panel") as StyleBoxFlat
    if hs:
        hs.corner_radius_top_left  = 70
        hs.corner_radius_top_right = 70
    phone.add_child(hdr)

    var x_lbl := _lbl("+", 50, C_TXTG)
    x_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    x_lbl.position = Vector2(285, 80)
    x_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    hdr.add_child(x_lbl)

    var title_lbl := _lbl("Редактирование профиля", 20, C_TXT)
    title_lbl.position = Vector2(35, 10)
    title_lbl.size     = Vector2(PHONE_W - 118, 44)
    title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
    hdr.add_child(title_lbl)

    var save_p := Panel.new()
    save_p.position = Vector2(PHONE_W - 70, 12)
    save_p.size     = Vector2(56, 30)
    _mk_panel(save_p, C_SAVEBG, Color(0,0,0,0), 0, 8)
    var save_l := _lbl("", 16, C_WHITE)
    save_l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    save_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    save_l.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
    save_p.add_child(save_l)
    hdr.add_child(save_p)

    # ── Аватар Алисы ─────────────────────────────────────────────────
    const AV: float = 96.0
    var av_bg := Panel.new()
    av_bg.position = Vector2((PHONE_W - AV) * 0.5, 64.0)
    av_bg.size     = Vector2(AV, AV)
    _mk_panel(av_bg, C_AVATAR, C_PBORD, 2, AV * 0.5)
    phone.add_child(av_bg)

    var name_lbl := _lbl("Алиса", 24, C_TXT)
    name_lbl.position = Vector2(0, 168.0)
    name_lbl.size     = Vector2(PHONE_W, 28)
    name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    phone.add_child(name_lbl)

    # ── Панель вопроса ────────────────────────────────────────────────
    var q_bg := Panel.new()
    q_bg.position = Vector2(16, 204.0)
    q_bg.size     = Vector2(PHONE_W - 32, 120.0)
    _mk_panel(q_bg, C_QBKG, Color(0,0,0,0), 0, 12)
    phone.add_child(q_bg)

    _question_lbl = _lbl("", 28, C_WHITE)
    _question_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _question_lbl.offset_left   = 12;  _question_lbl.offset_right  = -12
    _question_lbl.offset_top    =  4;  _question_lbl.offset_bottom = -4
    _question_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _question_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
    _question_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    q_bg.add_child(_question_lbl)

    # ── Три варианта ответа ───────────────────────────────────────────
    const OPTS_Y: float = 340.0
    for i in 3:
        var op := Panel.new()
        op.position = Vector2(16, OPTS_Y + float(i) * (OPT_H + OPT_GAP))
        op.size     = Vector2(PHONE_W - 32, OPT_H)
        _mk_panel(op, C_OPT, C_OPTBOR, 1, 10)
        phone.add_child(op)
        _option_panels.append(op)

        # Буква варианта
        var let_l := _lbl(LETTERS[i], 30, C_TXTG)
        let_l.position = Vector2(14, 0)
        let_l.size     = Vector2(28, OPT_H)
        let_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        op.add_child(let_l)

        # Вертикальный разделитель
        var sep := ColorRect.new()
        sep.color    = C_OPTBOR
        sep.position = Vector2(46, 14)
        sep.size     = Vector2(1, OPT_H - 28)
        op.add_child(sep)

        # Текст варианта
        var opt_l := _lbl("", 25, C_TXT)
        opt_l.position = Vector2(56, 4)
        opt_l.size     = Vector2(PHONE_W - 32 - 70, OPT_H - 8)
        opt_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        opt_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        op.add_child(opt_l)
        _option_lbls.append(opt_l)

        # Невидимая кнопка-оверлей поверх всей карточки
        var obtn := Button.new()
        obtn.flat       = true
        obtn.focus_mode = Control.FOCUS_NONE
        obtn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        
        # ←←← ЭТО ДОЛЖНО БЫТЬ ←←←
        obtn.mouse_filter = Control.MOUSE_FILTER_STOP
        
        obtn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
        for sn in ["normal", "hover", "pressed", "focus", "disabled"]:
            obtn.add_theme_stylebox_override(sn, StyleBoxEmpty.new())
        var ci := i
        obtn.pressed.connect(func(): _on_option_pressed(ci))
        op.add_child(obtn)
        _option_btns.append(obtn)

    # ── Реакция Алисы ─────────────────────────────────────────────────
    var rx_y: float = OPTS_Y + 3.0 * (OPT_H + OPT_GAP) + 10.0
    _reaction_lbl = _lbl("", 20, C_RERR)
    _reaction_lbl.position = Vector2(16, rx_y)
    _reaction_lbl.size     = Vector2(PHONE_W - 32, 52)
    _reaction_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _reaction_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
    _reaction_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _reaction_lbl.visible = false
    phone.add_child(_reaction_lbl)

    # ── Прогресс «Вопрос X / 4» ──────────────────────────────────────
    _progress_lbl = _lbl("Вопрос 1 / 4", 24, C_TXTG)
    _progress_lbl.position = Vector2(0, rx_y + 70.0)
    _progress_lbl.size     = Vector2(PHONE_W, 22)
    _progress_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    phone.add_child(_progress_lbl)

    # ── Кнопка «Далее» ────────────────────────────────────────────────
    _next_btn = Button.new()
    _next_btn.text     = "Далее ▶"
    _next_btn.position = Vector2((PHONE_W - 200.0) * 0.5, rx_y + 100.0)
    _next_btn.size     = Vector2(200, 60)
    _next_btn.visible  = false
    _next_btn.focus_mode = Control.FOCUS_NONE
    _next_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    if _font:
        _next_btn.add_theme_font_override("font", _font)
    _next_btn.add_theme_font_size_override("font_size", 30)
    _next_btn.add_theme_color_override("font_color", C_WHITE)
    _next_btn.add_theme_stylebox_override("normal",  _mk_style(C_TXTG , Color(0,0,0,0), 0, 10))
    _next_btn.add_theme_stylebox_override("hover",   _mk_style(Color(0.60, 0.50, 0.82, 1.0), Color(0,0,0,0), 0, 10))
    _next_btn.add_theme_stylebox_override("pressed", _mk_style(Color(0.52, 0.42, 0.74, 1.0), Color(0,0,0,0), 0, 10))
    _next_btn.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())
    _next_btn.pressed.connect(_on_next_pressed)
    phone.add_child(_next_btn)

    # ── Нижняя навигационная панель ───────────────────────────────────
    var nav := Panel.new()
    nav.position = Vector2(0, PHONE_H - 74.0)
    nav.size     = Vector2(PHONE_W, 74)
    _mk_panel(nav, C_NAV, C_PBORD, 0, 0)
    var ns := nav.get_theme_stylebox("panel") as StyleBoxFlat
    if ns:
        ns.corner_radius_bottom_left  = 56
        ns.corner_radius_bottom_right = 56
    phone.add_child(nav)

    var nav_icons := ["", "", "", ""]
    for i2 in 4:
        var ico := _lbl(nav_icons[i2], 18, C_TXTG)
        ico.position = Vector2(float(i2) * (PHONE_W / 4.0) + 8, 8)
        ico.size     = Vector2(PHONE_W / 4.0 - 16, 26)
        ico.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        nav.add_child(ico)

    var sm_l := _lbl("SoulMatch", 40, C_TXTG)
    sm_l.position = Vector2(PHONE_W / 4.0 - 38, 10)
    sm_l.size     = Vector2(76, 18)
    sm_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    nav.add_child(sm_l)

# ─── Логика вопросов ─────────────────────────────────────────────────────────

func _show_question(idx: int) -> void:
    # Все вопросы отвечены — завершаем
    if idx >= _questions_data.size():
        completed.emit(_score)
        return

    _answered = false
    var q: Dictionary = _questions_data[idx]

    _question_lbl.text = q.get("question", "")
    _progress_lbl.text = "Вопрос %d / %d" % [idx + 1, _questions_data.size()]
    _reaction_lbl.visible = false
    _next_btn.visible     = false

    if _avatar_tex and _portrait_neutral:
        _avatar_tex.texture = _portrait_neutral

    var opts: Array = q.get("options", [])
    for i in _option_panels.size():
        if i < opts.size():
            _option_lbls[i].text    = opts[i]
            _option_panels[i].visible = true
            _option_btns[i].disabled  = false
            _reset_opt_color(i)
        else:
            _option_panels[i].visible = false


func _on_option_pressed(idx: int) -> void:
    if _answered:
        return
    _answered = true

    # Блокируем все варианты
    for btn in _option_btns:
        btn.disabled = true

    var q:           Dictionary = _questions_data[_current_idx]
    var correct_idx: int        = q.get("correct_index", 0)
    var reactions:   Array      = q.get("reactions", [])
    var is_ok:       bool       = (idx == correct_idx)

    if is_ok:
        _score += 1
        _set_opt_color(idx, C_CORRECT)
        if _avatar_tex and _portrait_happy:
            _avatar_tex.texture = _portrait_happy
    else:
        _set_opt_color(idx, C_WRONG)
        _set_opt_color(correct_idx, C_CORRECT)  # подсвечиваем правильный
        if _avatar_tex and _portrait_sad:
            _avatar_tex.texture = _portrait_sad

    # Реакция Алисы
    if reactions.size() > idx:
        _reaction_lbl.text = reactions[idx]
        _reaction_lbl.add_theme_color_override("font_color", C_ROK if is_ok else C_RERR)
        _reaction_lbl.visible = true

    _next_btn.visible = true


func _on_next_pressed() -> void:
    _current_idx += 1
    _show_question(_current_idx)

# ─── Стилевые утилиты ────────────────────────────────────────────────────────

func _reset_opt_color(idx: int) -> void:
    var s := _option_panels[idx].get_theme_stylebox("panel") as StyleBoxFlat
    if s:
        s.bg_color     = C_OPT
        s.border_color = C_OPTBOR


func _set_opt_color(idx: int, color: Color) -> void:
    var s := _option_panels[idx].get_theme_stylebox("panel") as StyleBoxFlat
    if s:
        s.bg_color     = color
        s.border_color = color.darkened(0.12)


func _mk_panel(p: Panel, bg: Color, border: Color, bw: int, r: int) -> void:
    var s := StyleBoxFlat.new()
    s.bg_color = bg
    s.set_corner_radius_all(r)
    s.border_width_top    = bw;  s.border_width_bottom = bw
    s.border_width_left   = bw;  s.border_width_right  = bw
    s.border_color        = border
    p.add_theme_stylebox_override("panel", s)


func _mk_style(bg: Color, border: Color, bw: int, r: int) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = bg
    s.set_corner_radius_all(r)
    s.border_width_top    = bw;  s.border_width_bottom = bw
    s.border_width_left   = bw;  s.border_width_right  = bw
    s.border_color        = border
    return s


func _lbl(text: String, size: int, color: Color) -> Label:
    var l := Label.new()
    l.text = text
    if _font:
        l.add_theme_font_override("font", _font)
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", color)
    return l
