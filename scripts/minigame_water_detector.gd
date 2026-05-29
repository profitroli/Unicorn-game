# scripts/minigame_water_detector.gd
extends Control
class_name MinigameWaterDetector

## Эмитируется при завершении (победе или поражении).
signal completed(is_success: bool, attempts_used: int)

# ─── Конфигурация ───────────────────────────────────────────────────────────
var _grid_cols:    int   = 6
var _grid_rows:    int   = 6
var _water_count:  int   = 2
var _max_attempts: int   = 8
var _signal_levels: Array[Dictionary] = []

# ─── Состояние ──────────────────────────────────────────────────────────────
var _water_positions: Array[Vector2i] = []
var _cell_states:     Dictionary = {}      
var _found_count:     int = 0
var _attempts_used:   int = 0
var _unicorn_cell:    Vector2i = Vector2i(2, 2)
var _is_animating:    bool = false

var _font:            Font
var _unicorn_texture: Texture2D

# ─── UI-ссылки ──────────────────────────────────────────────────────────────
var _dim_node:       ColorRect
var _unicorn_ctrl:   Control
var _unicorn_sprite: TextureRect
var _cell_panels:    Dictionary = {}
var _cell_btns:      Dictionary = {}
var _marker_nodes:   Dictionary = {}
var _water_sprites:  Dictionary = {}
var _bar_segments:   Array[Panel] = []
var _signal_lbl:     Label
var _attempts_lbl:   Label
var _found_lbl:      Label

# ─── Константы ──────────────────────────────────────────────────────────────
const CELL_SIZE:    float = 118.0   # ← сильно увеличил
const CELL_GAP:     float = 12.0
const UNICORN_SZ:   float = 110.0
const MARKER_SZ:    float = 68.0
const WATER_SZ:     float = 88.0

const BAR_W:        float = 44.0
const BAR_H:        float = 44.0
const BAR_GAP:      float = 5.0
const BAR_SEGS:     int   = 8

const GRID_OFFSET_Y: float = 280.0

# ─── Палитра ────────────────────────────────────────────────────────────────
const C_DIM        := Color(0.00, 0.00, 0.00, 0.45)
const C_CELL_EMPTY := Color(0.92, 0.82, 0.54, 1.00)
const C_CELL_BOR   := Color(0.72, 0.60, 0.36, 1.00)
const C_CELL_HOV   := Color(0.99, 0.94, 0.72, 1.00)
const C_CELL_HVBOR := Color(0.94, 0.80, 0.40, 1.00)
const C_UI_BG      := Color(0.16, 0.10, 0.03, 0.95)
const C_UI_BOR     := Color(0.68, 0.48, 0.18, 1.00)
const C_UI_BOR2    := Color(0.85, 0.65, 0.30, 1.00)
const C_UI_TXT     := Color(0.98, 0.88, 0.50, 1.00)
const C_BAR_OFF    := Color(0.10, 0.06, 0.02, 1.00)

const MARKER_COLORS: Array[Color] = [
    Color(0.28, 0.66, 0.98, 1.00),
    Color(0.98, 0.50, 0.10, 1.00),
    Color(0.98, 0.84, 0.18, 1.00),
    Color(0.50, 0.76, 0.96, 1.00),
    Color(0.55, 0.55, 0.58, 0.90),
]

const MARKER_ICONS: Array[String] = ["✓", "!", "~", "·", "·"]
const BAR_FILL:     Array[int]    = [8, 7, 5, 3, 0]
const BAR_COLORS:   Array[Color]  = [
    Color(0.96, 0.96, 1.00, 1.00),
    Color(0.98, 0.50, 0.10, 1.00),
    Color(0.98, 0.84, 0.18, 1.00),
    Color(0.44, 0.72, 0.96, 1.00),
    Color(0.12, 0.07, 0.02, 1.00),
]

const SIGNAL_TEXTS: Array[String] = ["ВОДА!", "ГОРЯЧО!", "ТЕПЛО", "ПРОХЛАДНО", "НИЧЕГО"]
const SIGNAL_COLORS: Array[Color] = [
    Color(0.60, 0.90, 1.00, 1.00),
    Color(0.98, 0.62, 0.14, 1.00),
    Color(0.98, 0.90, 0.30, 1.00),
    Color(0.60, 0.82, 0.98, 1.00),
    Color(0.66, 0.62, 0.56, 1.00),
]

var _grid_origin: Vector2 = Vector2.ZERO

# ─── Публичный API ───────────────────────────────────────────────────────────
func setup(
    config: Dictionary,
    signal_levels: Array[Dictionary],
    unicorn_texture: Texture2D = null
) -> void:
    _grid_cols     = config.get("grid_cols", 6)
    _grid_rows     = config.get("grid_rows", 6)
    _water_count   = config.get("water_cell_count", 2)
    _max_attempts  = config.get("max_attempts", 8)
    _signal_levels = signal_levels
    _unicorn_texture = unicorn_texture

    _found_count   = 0
    _attempts_used = 0
    _is_animating  = false

    var gw := float(_grid_cols) * CELL_SIZE + float(_grid_cols - 1) * CELL_GAP
    _grid_origin = Vector2((1920.0 - gw) * 0.5, GRID_OFFSET_Y)

    _unicorn_cell = Vector2i(_grid_cols / 2 - 1, _grid_rows / 2 - 1)
    _place_water_randomly()

    for c in get_children():
        c.queue_free()
    
    _bar_segments.clear()
    _cell_panels.clear()
    _cell_btns.clear()
    _marker_nodes.clear()
    _water_sprites.clear()
    _cell_states.clear()

    if is_inside_tree():
        _build_ui()


func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE

    const FP := "res://assets/text/ArcadeJeu-Regular.otf"
    _font = load(FP) if ResourceLoader.exists(FP) else ThemeDB.fallback_font

func _place_water_randomly() -> void:
    _water_positions.clear()
    var pool: Array[Vector2i] = []
    for r in _grid_rows:
        for c in _grid_cols:
            pool.append(Vector2i(c, r))
    pool.shuffle()
    for i in min(_water_count, pool.size()):
        _water_positions.append(pool[i])
# ─── Построение UI ───────────────────────────────────────────────────────────
func _build_ui() -> void:
    _dim_node = ColorRect.new()
    _dim_node.color = Color(0.0, 0.0, 0.0, 0.88)
    _dim_node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _dim_node.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(_dim_node)

    # === Большая рамка "устройства" как в первой игре ===
    var device := Panel.new()
    device.position = Vector2(140, 120)
    device.size = Vector2(1640, 920)
    var ds := StyleBoxFlat.new()
    ds.bg_color = Color(0.12, 0.09, 0.06, 1.0)
    ds.set_corner_radius_all(12)
    # Исправлено:
    ds.border_width_top = 8
    ds.border_width_bottom = 8
    ds.border_width_left = 8
    ds.border_width_right = 8
    ds.border_color = Color(0.65, 0.52, 0.32, 1.0)
    device.add_theme_stylebox_override("panel", ds)
    _dim_node.add_child(device)

    # Заголовок
    var title := _lbl("МИНИ-ИГРА 4: ДЕТЕКТОР ВОДЫ", 58, Color(0.98, 0.88, 0.48))
    title.position = Vector2(0, 40)
    title.size = Vector2(1920, 90)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    if _font:
        title.add_theme_font_override("font", _font)
    _dim_node.add_child(title)

    var subtitle := _lbl("НАЙДИ ДВА ПОДЗЕМНЫХ ИСТОЧНИКА", 32, Color(0.85, 0.72, 0.42))
    subtitle.position = Vector2(0, 115)
    subtitle.size = Vector2(1920, 50)
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _dim_node.add_child(subtitle)

    _build_hud()
    _build_grid_cells()
    _build_unicorn()

    _update_hud_labels()
    _refresh_bar(-1)

func _build_unicorn() -> void:
    _unicorn_ctrl = Control.new()
    _unicorn_ctrl.size = Vector2(UNICORN_SZ, UNICORN_SZ)
    _unicorn_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _unicorn_ctrl.position = _unicorn_center_pos(_unicorn_cell)
    _dim_node.add_child(_unicorn_ctrl)

    _unicorn_sprite = TextureRect.new()
    _unicorn_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _unicorn_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    _unicorn_sprite.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _unicorn_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE

    if _unicorn_texture and _unicorn_texture.get_width() > 0:
        _unicorn_sprite.texture = _unicorn_texture
    else:
        # Заглушка
        var ph := Panel.new()
        ph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        var ps := StyleBoxFlat.new()
        ps.bg_color = Color(0.86, 0.86, 0.96, 0.9)
        ph.add_theme_stylebox_override("panel", ps)
        _unicorn_ctrl.add_child(ph)

        var ul := _lbl("U", 48, Color(0.38, 0.34, 0.72))
        ul.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        ul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        ul.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        _unicorn_ctrl.add_child(ul)
        return

    _unicorn_ctrl.add_child(_unicorn_sprite)


func _build_hud() -> void:
    # Левая панель
    var lp := _mk_panel(Vector2(180, 780), Vector2(520, 90))
    _found_lbl = _lbl("НАЙДЕНО: 0 / 2", 32, C_UI_TXT)
    _found_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _found_lbl.offset_left = 30
    _found_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _found_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    lp.add_child(_found_lbl)

    # Правая панель
    var rp := _mk_panel(Vector2(1220, 780), Vector2(520, 90))
    _attempts_lbl = _lbl("ПОПЫТКИ: 0 / 8", 32, C_UI_TXT)
    _attempts_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _attempts_lbl.offset_left = 30
    _attempts_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _attempts_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    rp.add_child(_attempts_lbl)

    # Сигнал
    _signal_lbl = _lbl("", 42, C_UI_TXT)
    _signal_lbl.position = Vector2(0, 660)
    _signal_lbl.size = Vector2(1920, 70)
    _signal_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _dim_node.add_child(_signal_lbl)

    _build_bar()


func _build_bar() -> void:
    var total_w := float(BAR_SEGS) * BAR_W + float(BAR_SEGS - 1) * BAR_GAP
    var bx := (1920.0 - total_w) * 0.5 - 4.0
    const BY: float = 720.0

    var bg_p := Panel.new()
    bg_p.position = Vector2(bx - 15, BY - 12)
    bg_p.size = Vector2(total_w + 54, BAR_H + 30)
    bg_p.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var bgs := StyleBoxFlat.new()
    bgs.bg_color = C_UI_BG
    bgs.set_corner_radius_all(12)
    # Исправлено:
    bgs.border_width_top = 4
    bgs.border_width_bottom = 4
    bgs.border_width_left = 4
    bgs.border_width_right = 4
    bgs.border_color = C_UI_BOR
    bg_p.add_theme_stylebox_override("panel", bgs)
    _dim_node.add_child(bg_p)

    # Стрелки
    var al := _lbl("◀", 36, C_UI_BOR2)
    al.position = Vector2(bx - 38, BY - 8)
    al.size = Vector2(32, BAR_H + 12)
    al.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _dim_node.add_child(al)

    var ar := _lbl("▶", 36, C_UI_BOR2)
    ar.position = Vector2(bx + total_w + 18, BY - 8)
    ar.size = Vector2(32, BAR_H + 12)
    ar.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _dim_node.add_child(ar)

    for i in BAR_SEGS:
        var seg := Panel.new()
        seg.position = Vector2(bx + float(i) * (BAR_W + BAR_GAP), BY)
        seg.size = Vector2(BAR_W, BAR_H)
        seg.mouse_filter = Control.MOUSE_FILTER_IGNORE
        var ss := StyleBoxFlat.new()
        ss.bg_color = C_BAR_OFF
        ss.set_corner_radius_all(6)
        seg.add_theme_stylebox_override("panel", ss)
        _dim_node.add_child(seg)
        _bar_segments.append(seg)

func _refresh_bar(level: int) -> void:
    for seg in _bar_segments:
        var s := seg.get_theme_stylebox("panel") as StyleBoxFlat
        if s:
            s.bg_color = C_BAR_OFF
    
    if _signal_lbl:
        _signal_lbl.text = ""
        
func _build_grid_cells() -> void:
    for r in _grid_rows:
        for c in _grid_cols:
            var cell := Vector2i(c, r)
            var pos := _cell_to_px(cell)

            var cp := Panel.new()
            cp.position = pos
            cp.size = Vector2(CELL_SIZE, CELL_SIZE)
            cp.mouse_filter = Control.MOUSE_FILTER_IGNORE
            var cs := StyleBoxFlat.new()
            cs.bg_color = C_CELL_EMPTY
            cs.set_corner_radius_all(5)
            cs.border_width_top = 2
            cs.border_width_bottom = 2
            cs.border_width_left = 2
            cs.border_width_right = 2
            cs.border_color = C_CELL_BOR
            cp.add_theme_stylebox_override("panel", cs)
            _dim_node.add_child(cp)
            _cell_panels[cell] = cp

            var btn := Button.new()
            btn.position = pos
            btn.size = Vector2(CELL_SIZE, CELL_SIZE)
            btn.flat = true
            btn.focus_mode = Control.FOCUS_NONE
            btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
            for sn in ["normal", "focus"]:
                btn.add_theme_stylebox_override(sn, StyleBoxEmpty.new())
            var hs := StyleBoxFlat.new()
            hs.bg_color = C_CELL_HOV
            hs.set_corner_radius_all(5)
            hs.border_width_top = 2
            hs.border_width_bottom = 2
            hs.border_width_left = 2
            hs.border_width_right = 2
            hs.border_color = C_CELL_HVBOR
            btn.add_theme_stylebox_override("hover", hs)
            btn.add_theme_stylebox_override("pressed", hs)

            var cc := cell
            btn.pressed.connect(func(): _on_cell_clicked(cc))
            _dim_node.add_child(btn)
            _cell_btns[cell] = btn


# ─── Основная логика ────────────────────────────────────────────────────────
func _on_cell_clicked(cell: Vector2i) -> void:
    if _is_animating or _cell_states.has(cell):
        return
    _is_animating = true
    _set_cells_interactive(false)
    _run_turn(cell)

func _animate_bar(level: int) -> void:
    var fill_n: int   = BAR_FILL[min(level, BAR_FILL.size() - 1)]
    var bcolor: Color = BAR_COLORS[min(level, BAR_COLORS.size() - 1)]

    # Сбрасываем все сегменты в тёмный
    for seg in _bar_segments:
        var s := seg.get_theme_stylebox("panel") as StyleBoxFlat
        if s:
            s.bg_color = C_BAR_OFF

    # Обновляем текст сигнала
    if _signal_lbl:
        _signal_lbl.text = SIGNAL_TEXTS[min(level, SIGNAL_TEXTS.size() - 1)]
        _signal_lbl.add_theme_color_override(
            "font_color", SIGNAL_COLORS[min(level, SIGNAL_COLORS.size() - 1)]
        )

    # Заполняем сегменты по одному
    for i in fill_n:
        var s := _bar_segments[i].get_theme_stylebox("panel") as StyleBoxFlat
        if s:
            s.bg_color = bcolor
        await get_tree().create_timer(0.055).timeout

    # Двойное мигание при нахождении воды
    if level == 0:
        for _f in 2:
            for seg in _bar_segments:
                var s := seg.get_theme_stylebox("panel") as StyleBoxFlat
                if s:
                    s.bg_color = C_BAR_OFF
            await get_tree().create_timer(0.14).timeout
            
            for seg in _bar_segments:
                var s := seg.get_theme_stylebox("panel") as StyleBoxFlat
                if s:
                    s.bg_color = bcolor
            await get_tree().create_timer(0.14).timeout
func _run_turn(cell: Vector2i) -> void:
    await _move_unicorn(cell)

    _attempts_used += 1
    var dist: float = _min_distance(cell)
    var level: int = _dist_to_level(dist)
    _cell_states[cell] = level

    await _animate_bar(level)
    _place_marker(cell, level)

    if level == 0:
        _found_count += 1

    _update_hud_labels()

    if _found_count >= _water_count:
        await get_tree().create_timer(0.9).timeout
        _is_animating = false
        completed.emit(true, _attempts_used)
        return

    if _attempts_used >= _max_attempts:
        _signal_lbl.text = "ПОПРОБУЕМ ЕЩЁ РАЗ..."
        _signal_lbl.add_theme_color_override("font_color", Color(0.96, 0.40, 0.22))
        await get_tree().create_timer(1.2).timeout
        _is_animating = false
        completed.emit(false, _attempts_used)
        return

    _is_animating = false
    _set_cells_interactive(true)


func _move_unicorn(target_cell: Vector2i) -> void:
    var target_pos := _unicorn_center_pos(target_cell)
    var tw := create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
    tw.tween_property(_unicorn_ctrl, "position", target_pos, 0.42)
    await tw.finished
    _unicorn_cell = target_cell


func _place_marker(cell: Vector2i, level: int) -> void:
    # Удаляем старый маркер
    if _marker_nodes.has(cell):
        _marker_nodes[cell].queue_free()
        _marker_nodes.erase(cell)

    var pos := _cell_to_px(cell)
    var col: Color = MARKER_COLORS[min(level, MARKER_COLORS.size() - 1)]

    # Маркер только если НЕ вода
    if level != 0:
        var off := (CELL_SIZE - MARKER_SZ) * 0.5
        var marker_pos := pos + Vector2(off, off)

        var mk := Panel.new()
        mk.position = marker_pos
        mk.size = Vector2(MARKER_SZ, MARKER_SZ)
        mk.mouse_filter = Control.MOUSE_FILTER_IGNORE

        var ms := StyleBoxFlat.new()
        ms.bg_color = col
        ms.set_corner_radius_all(int(MARKER_SZ * 0.5))
        # Исправлено:
        ms.border_width_top = 3
        ms.border_width_bottom = 3
        ms.border_width_left = 3
        ms.border_width_right = 3
        ms.border_color = col.darkened(0.3)
        mk.add_theme_stylebox_override("panel", ms)

        var icon := _lbl(MARKER_ICONS[min(level, MARKER_ICONS.size() - 1)], 28, Color.WHITE)
        icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        mk.add_child(icon)

        _dim_node.add_child(mk)
        _marker_nodes[cell] = mk

    # Вода
    if level == 0 and not _water_sprites.has(cell):
        var off := (CELL_SIZE - WATER_SZ) * 0.5
        var water_pos := pos + Vector2(off, off - 10)

        var water := TextureRect.new()
        water.texture = preload("res://assets/ui/Gemini_Generated_Image_oo0qv1oo0qv1oo0q-Photoroom 2.png")
        water.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        water.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        water.size = Vector2(WATER_SZ, WATER_SZ)
        water.position = water_pos
        _dim_node.add_child(water)
        _water_sprites[cell] = water

    # Затемнение ячейки
    var cp := _cell_panels.get(cell) as Panel
    if cp:
        var cs := cp.get_theme_stylebox("panel") as StyleBoxFlat
        if cs:
            cs.bg_color = Color(0.84, 0.74, 0.48, 1.0)
# ─── Вспомогательные ────────────────────────────────────────────────────────
func _cell_to_px(cell: Vector2i) -> Vector2:
    return _grid_origin + Vector2(
        float(cell.x) * (CELL_SIZE + CELL_GAP),
        float(cell.y) * (CELL_SIZE + CELL_GAP)
    )

func _unicorn_center_pos(cell: Vector2i) -> Vector2:
    return _cell_to_px(cell) + Vector2(
        (CELL_SIZE - UNICORN_SZ) * 0.5,
        (CELL_SIZE - UNICORN_SZ) * 0.5
    )

func _min_distance(cell: Vector2i) -> float:
    var min_d := INF
    for wp in _water_positions:
        var d := Vector2(float(cell.x - wp.x), float(cell.y - wp.y)).length()
        if d < min_d:
            min_d = d
    return min_d

func _dist_to_level(dist: float) -> int:
    for i in _signal_levels.size():
        var sl: Dictionary = _signal_levels[i]
        if dist <= float(sl.get("max_distance", 99)):
            return i
    return _signal_levels.size() - 1

func _set_cells_interactive(enabled: bool) -> void:
    for cell in _cell_btns:
        var btn := _cell_btns[cell] as Button
        if btn:
            btn.disabled = not enabled or _cell_states.has(cell)

func _update_hud_labels() -> void:
    if _attempts_lbl:
        _attempts_lbl.text = "ПОПЫТКИ: %d / %d" % [_attempts_used, _max_attempts]
    if _found_lbl:
        _found_lbl.text = "НАЙДЕНО: %d / %d" % [_found_count, _water_count] if _found_count > 0 else \
                          "НАЙДИ %d ИСТОЧНИКА ИЗ %d" % [_water_count, _water_count]

# ─── Фабрики ────────────────────────────────────────────────────────────────
func _mk_panel(pos: Vector2, size: Vector2) -> Panel:
    var p := Panel.new()
    p.position = pos
    p.size = size
    var s := StyleBoxFlat.new()
    s.bg_color = C_UI_BG
    s.set_corner_radius_all(6)
    s.border_width_top = 3
    s.border_width_bottom = 3
    s.border_width_left = 3
    s.border_width_right = 3
    s.border_color = C_UI_BOR
    s.shadow_color = C_UI_BOR2
    s.shadow_size = 3
    p.add_theme_stylebox_override("panel", s)
    p.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _dim_node.add_child(p)
    return p


func _lbl(text: String, size: int, color: Color) -> Label:
    var l := Label.new()
    l.text = text
    if _font:
        l.add_theme_font_override("font", _font)
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", color)
    return l
