# scripts/minigame_first_message.gd
extends Control
class_name MinigameFirstMessage

signal completed()

var _messages_data: Array[Dictionary] = []
var _can_select: bool = true
var _font: Font

var _chat_vbox: VBoxContainer
var _no_msg_lbl: Label
var _typing_lbl: Label
var _reaction_lbl: Label
var _option_btns: Array[Button] = []

const PHONE_W: float = 463.0
const PHONE_H: float = 1007.0
const CHAT_H:  float = 300.0
const OPT_H:   float = 86.0
const OPT_GAP: float = 40.0
const BUBBLE_W: float = 300.0

# ─── Пастельная палитра SoulMatch ────────────────────────────────────────────
const C_DIM       := Color(0.0, 0.0, 0.0, 0.0)
const C_PHONE     := Color(0.99, 0.97, 1.00, 1.00)
const C_PBORD     := Color(0.58, 0.48, 0.74, 1.00)
const C_HEADER    := Color(0.99, 0.99, 1.00, 1.00)
const C_CHAT_BG   := Color(0.97, 0.92, 0.97, 1.00)
const C_OPT_AREA  := Color(0.88, 0.82, 0.97, 1.00)
const C_OPT_BTN   := Color(0.99, 0.96, 0.92, 1.00)
const C_OPT_BORD  := Color(0.84, 0.78, 0.92, 1.00)
const C_OPT_HOV   := Color(0.92, 0.86, 1.00, 1.00)
const C_OPT_DIS   := Color(0.92, 0.90, 0.94, 1.00)
const C_MSG_SENT  := Color(0.74, 0.62, 0.92, 1.00)   # фиолетовый — наш пузырь
const C_MSG_RECV  := Color(0.99, 0.99, 0.99, 1.00)   # белый — пузырь Арсения
const C_MSG_BORD  := Color(0.80, 0.74, 0.90, 1.00)
const C_NAV       := Color(0.84, 0.78, 0.96, 1.00)
const C_TXT       := Color(0.16, 0.10, 0.24, 1.00)
const C_TXTG      := Color(0.44, 0.38, 0.58, 1.00)
const C_WHITE     := Color(1.00, 1.00, 1.00, 1.00)
const C_TYPING    := Color(0.60, 0.52, 0.74, 1.00)
const C_LOGO      := Color(0.70, 0.62, 0.88, 0.55)
const C_NOMSG     := Color(0.56, 0.50, 0.66, 0.75)
const C_ROK       := Color(0.12, 0.54, 0.22, 1.00)
const C_RERR      := Color(0.76, 0.16, 0.16, 1.00)


# ─── Публичный API ───────────────────────────────────────────────────────────

## Вызывать ПОСЛЕ add_child. Строит UI и готовит данные.
func setup(messages: Array[Dictionary], _profile_texture: Texture2D = null) -> void:
    _messages_data = messages
    _can_select = true

    for c in get_children():
        c.queue_free()
    _option_btns.clear()

    _build_ui()


func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE

    const FP := "res://assets/text/ArcadeJeu-Regular.otf"
    if ResourceLoader.exists(FP):
        _font = load(FP)
    else:
        _font = ThemeDB.fallback_font

# ─── Построение интерфейса ────────────────────────────────────────────────────

func _build_ui() -> void:
    # Большой фон на всю мини-игру (1920x1080)
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
        
    # Затемнение
    var dim := ColorRect.new()
    dim.color = C_DIM
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    dim.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(dim)

    var phone := Panel.new()
    phone.position = Vector2((1920 - PHONE_W) * 0.5, (1080 - PHONE_H) * 0.5)
    phone.size = Vector2(PHONE_W, PHONE_H)
    phone.mouse_filter = Control.MOUSE_FILTER_PASS
    _mk_panel(phone, C_PHONE, C_PBORD, 4, 70)
    dim.add_child(phone)

    # Шапка
    var hdr := Panel.new()
    hdr.size = Vector2(PHONE_W, 56)
    _mk_panel(hdr, C_HEADER, C_PBORD, 0, 0)
    var hs := hdr.get_theme_stylebox("panel") as StyleBoxFlat
    if hs:
        hs.corner_radius_top_left  = 70
        hs.corner_radius_top_right = 70
    phone.add_child(hdr)

    var hdr_lbl := _lbl("ЧАТ С АРСЕНИЕМ", 26, C_TXT)
    hdr_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    hdr_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hdr_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    hdr.add_child(hdr_lbl)

    # Зона чата
    var chat_bg := Panel.new()
    chat_bg.position = Vector2(0, 56)
    chat_bg.size = Vector2(PHONE_W, CHAT_H)
    _mk_panel(chat_bg, C_CHAT_BG, Color(0,0,0,0), 0, 0)
    phone.add_child(chat_bg)

    _chat_vbox = VBoxContainer.new()
    _chat_vbox.position = Vector2(8, 8)
    _chat_vbox.size = Vector2(PHONE_W - 16, CHAT_H - 40)
    _chat_vbox.add_theme_constant_override("separation", 8)
    chat_bg.add_child(_chat_vbox)

    # Логотип SoulMatch (декоративный, показывается когда нет сообщений)
    var logo_lbl := _lbl("", 40, C_LOGO)
    logo_lbl.position = Vector2(0, CHAT_H * 0.22)
    logo_lbl.size     = Vector2(PHONE_W, 36)
    logo_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    chat_bg.add_child(logo_lbl)

    # «Сообщений нет. Начните беседу!»
    _no_msg_lbl = _lbl("Сообщений нет.\nНачните беседу!", 25, Color(0.56, 0.50, 0.66, 0.75))
    _no_msg_lbl.position = Vector2(0, CHAT_H * 0.4)
    _no_msg_lbl.size = Vector2(PHONE_W, 50)
    _no_msg_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    chat_bg.add_child(_no_msg_lbl)

    _typing_lbl = _lbl("Арсений пишет...", 20, Color(0.60, 0.52, 0.74))
    _typing_lbl.position = Vector2(12, CHAT_H - 28)
    _typing_lbl.size = Vector2(PHONE_W - 24, 22)
    _typing_lbl.visible = false
    chat_bg.add_child(_typing_lbl)

    _reaction_lbl = _lbl("", 18, Color(0.76, 0.16, 0.16))
    _reaction_lbl.position = Vector2(8, 60 + CHAT_H + 4)
    _reaction_lbl.size = Vector2(PHONE_W - 16, 44)
    _reaction_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _reaction_lbl.visible = false
    phone.add_child(_reaction_lbl)

    # ── Метка реакции Алисы (между чатом и вариантами) ──────────────
    _reaction_lbl = _lbl("", 18, C_RERR)
    _reaction_lbl.position = Vector2(8, 60 + CHAT_H + 4)
    _reaction_lbl.size     = Vector2(PHONE_W - 16, 44)
    _reaction_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _reaction_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
    _reaction_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _reaction_lbl.visible = false
    phone.add_child(_reaction_lbl)

    # ── Разделительная линия ────────────────────────────────────────
    var sep := ColorRect.new()
    sep.color    = C_PBORD
    sep.position = Vector2(0, 60 + CHAT_H + 70)
    sep.size     = Vector2(PHONE_W, 1)
    phone.add_child(sep)

    # ── Кнопки-варианты сообщений ────────────────────────────────────
    var opts_container := VBoxContainer.new()
    opts_container.position = Vector2(12, 60 + CHAT_H + 90)
    opts_container.size = Vector2(PHONE_W - 24, 300)
    opts_container.add_theme_constant_override("separation", 20)
    phone.add_child(opts_container)

    for i in _messages_data.size():
        var obtn := Button.new()
        obtn.text = _messages_data[i].get("message", "")
        obtn.custom_minimum_size = Vector2(0, 120)
        obtn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        obtn.focus_mode = Control.FOCUS_NONE
        obtn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        obtn.mouse_filter = Control.MOUSE_FILTER_STOP
        obtn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

        # ─── КРАСИМ КНОПКИ (Добавленный блок) ──────────────────────────────────
        # Создаем стили на основе констант: (цвет_фона, цвет_рамки, толщина_рамки, скругление)
        var style_normal   := _mk_style(C_OPT_BTN, C_OPT_BORD, 2, 20)
        var style_hover    := _mk_style(C_OPT_HOV, C_OPT_BORD, 2, 20)
        var style_pressed  := _mk_style(C_OPT_HOV, C_OPT_BORD, 2, 20)
        var style_disabled := _mk_style(C_OPT_DIS, C_OPT_BORD, 2, 20)

        # Переопределяем стили состояний кнопки
        obtn.add_theme_stylebox_override("normal", style_normal)
        obtn.add_theme_stylebox_override("hover", style_hover)
        obtn.add_theme_stylebox_override("pressed", style_pressed)
        obtn.add_theme_stylebox_override("disabled", style_disabled)

        # Настраиваем цвет текста для каждого состояния
        obtn.add_theme_color_override("font_color", C_TXT)
        obtn.add_theme_color_override("font_hover_color", C_TXT)
        obtn.add_theme_color_override("font_pressed_color", C_TXT)
        obtn.add_theme_color_override("font_disabled_color", C_TXTG)
        # ──────────────────────────────────────────────────────────────────────

        if _font:
            obtn.add_theme_font_override("font", _font)
        obtn.add_theme_font_size_override("font_size", 24)

        obtn.pressed.connect(func(): _on_option_pressed(i))
        opts_container.add_child(obtn)
        _option_btns.append(obtn)


    # ── Нижняя навигационная панель ───────────────────────────────────
    var nav := Panel.new()
    nav.position = Vector2(0, PHONE_H - 74.0)
    nav.size     = Vector2(PHONE_W, 74)
    _mk_panel(nav, C_NAV, C_PBORD, 0, 0)
    var ns := nav.get_theme_stylebox("panel") as StyleBoxFlat
    if ns:
        ns.corner_radius_bottom_left  = 26
        ns.corner_radius_bottom_right = 26
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

# ─── Основная логика выбора и анимации ───────────────────────────────────────

func _on_option_pressed(idx: int) -> void:
    if not _can_select: return
    _can_select = false
    for b in _option_btns: b.disabled = true
    _handle_choice(idx)


func _handle_choice(idx: int) -> void:
    var data: Dictionary = _messages_data[idx]

    # ── 1. Показываем отправленное сообщение (наш пузырь справа) ────
    _no_msg_lbl.visible = false
    _add_message(data.get("message", ""), true)

    await get_tree().create_timer(0.8).timeout

    # ── 2. Индикатор «Арсений пишет...» ─────────────────────────────
    _typing_lbl.visible = true
    await get_tree().create_timer(1.5).timeout
    _typing_lbl.visible = false

    # ── 3. Ответ Арсения (его пузырь слева) ─────────────────────────
    var response: String = data.get("response_text", "")
    if response != "":
        _add_message(response, false)

    await get_tree().create_timer(3.0).timeout

    # ── 4. Развязка ──────────────────────────────────────────────────
    if data.get("is_correct", false):
        # Победа — сразу сообщаем миссии
        await get_tree().create_timer(1.0).timeout
        completed.emit()
        return

    # Неверный выбор — показываем реакцию и сбрасываем интерфейс
    var alisa_react: String   = data.get("alisa_reaction", "")
    var unicorn_cmt: String   = data.get("unicorn_comment", "")

    if alisa_react != "":
        _show_reaction("АЛИСА: " + alisa_react, C_RERR)
        await get_tree().create_timer(3.5).timeout

    if unicorn_cmt != "":
        _show_reaction("ЕДИНОРОГ: " + unicorn_cmt, C_TYPING)
        await get_tree().create_timer(3.5).timeout

    _show_reaction("АЛИСА: Нет, давай переделаем.", C_RERR)
    await get_tree().create_timer(3.5).timeout

    _reset_chat()


# ─── Вспомогательные методы ──────────────────────────────────────────────────

func _add_message(text: String, is_sent: bool) -> void:
    var row := HBoxContainer.new()
    # Высоту (Y) ставим 0 — контейнер сам растянется по вертикали
    row.custom_minimum_size = Vector2(PHONE_W - 16.0, 0)
    row.add_theme_constant_override("separation", 0)
    _chat_vbox.add_child(row)

    if is_sent:
        # Пружина слева, прижимает наш пузырь вправо
        var sp := Control.new()
        sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(sp)

    # PanelContainer АВТОМАТИЧЕСКИ подстраивается под размер дочерних элементов (Label)
    var bubble := PanelContainer.new()
    # Фиксируем только ширину. Высота (0) подстроится под количество строк текста.
    bubble.custom_minimum_size = Vector2(BUBBLE_W, 0)

    # Настраиваем стиль фона пузырька и ВНУТРЕННИЕ ОТСТУПЫ
    var style := StyleBoxFlat.new()
    style.bg_color = C_MSG_SENT if is_sent else C_MSG_RECV
    style.border_color = C_MSG_BORD
    style.border_width_top = 1; style.border_width_bottom = 1
    style.border_width_left = 1; style.border_width_right = 1
    style.set_corner_radius_all(10)
    
    # Вот эта магия не даст тексту прилипать к краям пузыря
    style.content_margin_left = 12.0
    style.content_margin_right = 12.0
    style.content_margin_top = 12.0
    style.content_margin_bottom = 12.0

    bubble.add_theme_stylebox_override("panel", style)
    row.add_child(bubble)

    var lbl := _lbl(text, 20, C_TXT)
    lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    
    # Мы БОЛЬШЕ НЕ задаём position и size для Label! 
    # PanelContainer сам поставит его ровно по центру с учетом отступов.
    bubble.add_child(lbl)

    if not is_sent:
        # Пружина справа, прижимает пузырь Арсения влево
        var sp := Control.new()
        sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(sp)
        
func _estimate_bubble_height(text: String) -> float:
    # Используем динамический расчет высоты на основе шрифта и ширины
    var font: Font = _font if _font else ThemeDB.fallback_font
    var text_size: Vector2 = font.get_multiline_string_size(
        text, HORIZONTAL_ALIGNMENT_LEFT, BUBBLE_W - 20, 15
    )
    return text_size.y + 24 # 24 — это отступы сверху и снизу


func _show_reaction(text: String, color: Color) -> void:
    _reaction_lbl.text = text
    _reaction_lbl.add_theme_color_override("font_color", color)
    _reaction_lbl.visible = true


func _reset_chat() -> void:
    # Удаляем все пузыри из VBox
    for c in _chat_vbox.get_children():
        c.queue_free()
    # Сбрасываем вспомогательные элементы
    _reaction_lbl.visible = false
    _typing_lbl.visible   = false
    _no_msg_lbl.visible   = true
    # Разблокируем варианты для повторного выбора
    for btn in _option_btns:
        btn.disabled = false
    _can_select = true

# ─── Стилевые утилиты ────────────────────────────────────────────────────────

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
