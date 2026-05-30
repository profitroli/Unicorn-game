# scripts/minigame_find_portal.gd
extends Control
class_name MinigameFindPortal

## completed(is_success, magic_remaining)
signal completed(is_success: bool, magic_remaining: int)

# ─── Конфигурация ───────────────────────────────────────────────────────────
var _particle_count: int   = 6
var _trap_count:     int   = 5
var _magic_max:      int   = 5
var _speed_px:       float = 200.0
var _unicorn_texture: Texture2D

# ─── Состояние ────────────────────────────────────────────────────────────────
var _particles:   Array[Vector2i] = []   # позиции несобранных частиц
var _traps:       Array[Vector2i] = []   # позиции ловушек
var _used_traps:  Array[Vector2i] = []   # уже сработавшие ловушки
var _collected:   int  = 0
var _magic:       int  = 5
var _unicorn_cell: Vector2i = Vector2i(2, 2)
var _is_busy:     bool = false
var _font:        Font

# Данные для динамических эффектов
var _collected_points: Array[Vector2] = [] # Координаты (px) уже собранных нитей
var _effect_time:      float = 0.0
var _unicorn_trail:    Array[Dictionary] = [] # Хранит позиции для шлейфа искрами

# ─── UI-ссылки ────────────────────────────────────────────────────────────────
var _dim_node:       ColorRect
var _effects_layer:  Control   # Слой кастомной магии поверх сетки
var _unicorn_ctrl:   Control
var _particle_nodes: Dictionary = {}    # Vector2i → Control
var _trap_nodes:     Dictionary = {}    # Vector2i → Panel
var _cell_btns:      Dictionary = {}    # Vector2i → Button
var _magic_icons:    Array[Panel] = []
var _counter_lbl:    Label
var _grid_origin:    Vector2 = Vector2.ZERO
var _grid_total_w:   float   = 0.0
var _grid_total_h:   float   = 0.0
var _grid_center_px: Vector2 = Vector2.ZERO
var _instruction_lbl: Label  # Ссылка на центральную надпись
# ─── Размеры и Сетка ─────────────────────────────────────────────────────────
const COLS:       int   = 6
const ROWS:       int   = 6
const CELL:       float = 118.0
const GAP:        float = 12.0
const UNICORN_SZ: float = 110.0
const PARTICLE_R: float = 28.0
const GLOW_R:     float = 48.0
const TRAP_SZ:    float = 64.0

# ─── Цветовая Палитра ────────────────────────────────────────────────────────
const C_DIM        := Color(0.00, 0.00, 0.00, 0.45)
const C_CELL_EMPTY := Color(0.992, 0.788, 0.8, 0.773)
const C_CELL_BOR   := Color(0.89, 0.267, 0.553, 0.714)
const C_CELL_HOV   := Color(0.25, 0.18, 0.10, 0.80)
const C_CELL_HVBOR := Color(0.85, 0.65, 0.25, 1.00)
const C_UI_BG      := Color(0.14, 0.09, 0.04, 0.95)
const C_UI_BOR     := Color(0.68, 0.48, 0.18, 1.00)
const C_UI_BOR2    := Color(0.85, 0.65, 0.30, 1.00)
const C_UI_TXT     := Color(0.98, 0.878, 0.498, 1.0)

const C_MAGIC_ON   := Color(0.809, 0.001, 0.88, 1.0)
const C_MAGIC_OFF  := Color(0.25, 0.15, 0.08, 0.80)
const C_TRAP       := Color(0.371, 0.085, 0.089, 0.898)
const C_TRAP_BOR   := Color(0.359, 0.143, 0.146, 1.0)
const C_TRAP_HIT   := Color(0.80, 0.20, 0.10, 0.95)

const C_LEY_LINE   := Color(0.98, 0.80, 0.30, 0.40)
const C_LEY_CORE   := Color(1.00, 0.95, 0.70, 0.95)
const C_PORTAL_GLOW:= Color(0.95, 0.70, 0.20, 0.30)

# ─── Публичный API ───────────────────────────────────────────────────────────

func setup(config: Dictionary, unicorn_texture: Texture2D = null) -> void:
    _particle_count  = config.get("particle_count",   6)
    _trap_count      = config.get("trap_stone_count", 5)
    _magic_max       = config.get("magic_points_max", 5)
    _speed_px        = float(config.get("unicorn_speed_px", 200))
    _unicorn_texture = unicorn_texture
    _collected       = 0
    _magic           = _magic_max
    _is_busy         = false
    _unicorn_cell    = Vector2i(COLS / 2 - 1, ROWS / 2 - 1)
    
    _collected_points.clear()
    _unicorn_trail.clear()

    _grid_total_w = float(COLS) * CELL + float(COLS - 1) * GAP
    _grid_total_h = float(ROWS) * CELL + float(ROWS - 1) * GAP
    _grid_origin  = Vector2((1920.0 - _grid_total_w) * 0.5, 260.0)
    _grid_center_px = _grid_origin + Vector2(_grid_total_w * 0.5, _grid_total_h * 0.5)

    _place_game_elements()

    for c in get_children():
        c.queue_free()
    _particle_nodes.clear()
    _trap_nodes.clear()
    _cell_btns.clear()
    _magic_icons.clear()
    _used_traps.clear()

    if is_inside_tree():
        _build_ui()

    if is_instance_valid(_instruction_lbl):
     _instruction_lbl.text = "Собери все частицы ✨"
    
    
func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    const FP := "res://assets/text/ArcadeJeu-Regular.otf"
    _font = load(FP) if ResourceLoader.exists(FP) else ThemeDB.fallback_font

func _process(delta: float) -> void:
    _effect_time += delta
    
    if _is_busy and _unicorn_ctrl:
        _unicorn_trail.append({
            "pos": _unicorn_ctrl.position + Vector2(UNICORN_SZ*0.5, UNICORN_SZ*0.5),
            "alpha": 1.0,
            "size": randf_range(4.0, 8.0)
        })
    
    var i := 0
    while i < _unicorn_trail.size():
        _unicorn_trail[i]["alpha"] -= delta * 2.5
        if _unicorn_trail[i]["alpha"] <= 0:
            _unicorn_trail.remove_at(i)
        else:
            i += 1
            
    if _effects_layer:
        _effects_layer.queue_redraw()

# ─── Расстановка элементов ────────────────────────────────────────────────────

func _place_game_elements() -> void:
    _particles.clear()
    _traps.clear()

    var all_cells: Array[Vector2i] = []
    for r in ROWS:
        for c2 in COLS:
            var cell := Vector2i(c2, r)
            if cell != _unicorn_cell:
                all_cells.append(cell)

    all_cells.shuffle()

    for i in min(_particle_count, all_cells.size()):
        _particles.append(all_cells[i])
    for i in range(_particle_count, min(_particle_count + _trap_count, all_cells.size())):
        _traps.append(all_cells[i])

# ─── Построение UI ───────────────────────────────────────────────────────────

func _build_ui() -> void:
    _dim_node = ColorRect.new()
    _dim_node.color = Color(0.05, 0.03, 0.02, 0.65)
    _dim_node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _dim_node.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(_dim_node)

    var device := Panel.new()
    device.position = Vector2(120, 110)
    device.size = Vector2(1680, 940)
    var ds := StyleBoxFlat.new()
    ds.bg_color = Color(0.0, 0.0, 0.0, 0.576)
    ds.set_corner_radius_all(12)
    ds.border_width_top = 8; ds.border_width_bottom = 8
    ds.border_width_left = 8; ds.border_width_right = 8
    ds.border_color = Color(0.65, 0.50, 0.25, 0.9)
    device.add_theme_stylebox_override("panel", ds)
    _dim_node.add_child(device)

    var title := _lbl("МИНИ-ИГРА 5: НАЙДИ ПОРТАЛ", 56, C_UI_TXT)
    title.position = Vector2(0, 40)
    title.size = Vector2(1920, 80)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _dim_node.add_child(title)


    _build_hud()
    _build_grid()
    
    _effects_layer = Control.new()
    _effects_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _effects_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _effects_layer.draw.connect(_draw_magical_effects)
    _dim_node.add_child(_effects_layer)
    
    _build_particles()
    _build_traps()
    _build_unicorn()
    _update_hud()

# ── HUD ─────────────────────────────────────────────────────────────────────

func _build_hud() -> void:
    var lp := _mk_ui_panel(Vector2(150, 150), Vector2(400, 95))
    _counter_lbl = _lbl("Частицы: 0 / %d" % _particle_count, 25, C_UI_TXT)
    _counter_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _counter_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _counter_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    lp.add_child(_counter_lbl)
    
# [НОВАЯ ФИЧА] Центральная надпись-инструкция ровно посередине верхних панелей
    _instruction_lbl = _lbl("Собери все частицы✨", 40, Color(0.98, 0.878, 0.498, 1.0)) 
    _instruction_lbl.position = Vector2(550, 150) 
    _instruction_lbl.size = Vector2(1367 - 550, 95) 
    _instruction_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _instruction_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _dim_node.add_child(_instruction_lbl)
    
    var rp := _mk_ui_panel(Vector2(1367, 150), Vector2(400, 95))
    var iw: float = 34.0
    var igap: float = 12.0
    var total_w = float(_magic_max) * iw + float(_magic_max - 1) * igap
    var start_x = (400.0 - total_w) * 0.5
    
    for i in _magic_max:
        var mg := Panel.new()
        mg.position = Vector2(start_x + float(i) * (iw + igap), (95.0 - iw) * 0.5)
        mg.size     = Vector2(iw, iw)
        _style_circle(mg, C_MAGIC_ON, C_UI_BOR)
        rp.add_child(mg)
        _magic_icons.append(mg)

# ── Сетка ────────────────────────────────────────────────────────────────────

func _build_grid() -> void:
    for r in ROWS:
        for c2 in COLS:
            var cell := Vector2i(c2, r)
            var pos  := _cell_to_px(cell)

            var cp := Panel.new()
            cp.position = pos
            cp.size     = Vector2(CELL, CELL)
            cp.mouse_filter = Control.MOUSE_FILTER_IGNORE # Панели фона не должны мешать клику
            var cs := StyleBoxFlat.new()
            cs.bg_color = C_CELL_EMPTY
            cs.set_corner_radius_all(4)
            cs.border_width_top = 2; cs.border_width_bottom = 2
            cs.border_width_left = 2; cs.border_width_right = 2
            cs.border_color = C_CELL_BOR
            cp.add_theme_stylebox_override("panel", cs)
            _dim_node.add_child(cp)

            var btn := Button.new()
            btn.position = pos
            btn.size     = Vector2(CELL, CELL)
            btn.flat     = true
            btn.focus_mode = Control.FOCUS_NONE
            btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
            for sn in ["normal", "focus"]:
                btn.add_theme_stylebox_override(sn, StyleBoxEmpty.new())
            
            var hs := StyleBoxFlat.new()
            hs.bg_color = C_CELL_HOV
            hs.set_corner_radius_all(4)
            hs.border_width_top = 2; hs.border_width_bottom = 2
            hs.border_width_left = 2; hs.border_width_right = 2
            hs.border_color = C_CELL_HVBOR
            btn.add_theme_stylebox_override("hover", hs)
            btn.add_theme_stylebox_override("pressed", hs)
            
            var cc := cell
            btn.pressed.connect(func(): _on_cell_tapped(cc))
            _dim_node.add_child(btn)
            _cell_btns[cell] = btn

# ── Кастомная Отрисовка Эффектов ──────────────────────────────────────────────

func _draw_magical_effects() -> void:
    if not _effects_layer: return
    
    for spark in _unicorn_trail:
        var col := Color(C_MAGIC_ON, spark["alpha"] * 0.7)
        _effects_layer.draw_circle(spark["pos"], spark["size"], col)
        
    var progress := float(_collected) / float(_particle_count)
    var base_radius := 10.0 + progress * 40.0
    var pulse := sin(_effect_time * 5.0) * 4.0
    var current_r := base_radius + pulse
    
    if _collected > 0 and _collected < _particle_count:
        _effects_layer.draw_circle(_grid_center_px, current_r + 15.0, Color(C_PORTAL_GLOW, 0.15))
        _effects_layer.draw_circle(_grid_center_px, current_r, Color(C_MAGIC_ON, 0.4))
        _effects_layer.draw_circle(_grid_center_px, current_r * 0.4, Color.WHITE)
        
    for pt in _collected_points:
        var wave := sin(_effect_time * 8.0 + pt.x) * 1.5
        _effects_layer.draw_line(pt, _grid_center_px, Color(C_LEY_LINE, 0.3), 6.0 + wave, true)
        _effects_layer.draw_line(pt, _grid_center_px, C_LEY_CORE, 1.5, true)
        _effects_layer.draw_circle(pt, 5.0 + wave*0.5, C_MAGIC_ON)

# ── Остальные элементы игры ───────────────────────────────────────────────────

func _build_particles() -> void:
    for cell in _particles:
        var center := _cell_center(cell)
        var container := Control.new()
        container.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _dim_node.add_child(container)

        var glow := Panel.new()
        glow.mouse_filter = Control.MOUSE_FILTER_IGNORE # ИСПРАВЛЕНО: Свечение больше не крадет клики
        glow.size = Vector2(GLOW_R * 2, GLOW_R * 2)
        glow.position = center - Vector2(GLOW_R, GLOW_R)
        _style_circle(glow, Color(C_MAGIC_ON, 0.25), Color(0,0,0,0))
        container.add_child(glow)

        var gt := glow.create_tween().set_loops()
        gt.tween_property(glow, "modulate:a", 0.3, 0.8)
        gt.tween_property(glow, "modulate:a", 1.0, 0.8)

        var core := Panel.new()
        core.mouse_filter = Control.MOUSE_FILTER_IGNORE # ИСПРАВЛЕНО: Ядро частицы свободно пропускает клики
        core.size = Vector2(PARTICLE_R * 2, PARTICLE_R * 2)
        core.position = center - Vector2(PARTICLE_R, PARTICLE_R)
        _style_circle(core, Color.WHITE, C_MAGIC_ON)
        container.add_child(core)

        _particle_nodes[cell] = container

func _build_traps() -> void:
    for cell in _traps:
        var center := _cell_center(cell)
        var tp := Panel.new()
        tp.mouse_filter = Control.MOUSE_FILTER_IGNORE # ИСПРАВЛЕНО: Сама панель ловушки игнорирует клики
        tp.size = Vector2(TRAP_SZ, TRAP_SZ)
        tp.position = center - Vector2(TRAP_SZ * 0.5, TRAP_SZ * 0.5)
        var ts := StyleBoxFlat.new()
        ts.bg_color = C_TRAP
        ts.set_corner_radius_all(6)
        ts.border_width_top = 2; ts.border_width_bottom = 2
        ts.border_width_left = 2; ts.border_width_right = 2
        ts.border_color = C_TRAP_BOR
        tp.add_theme_stylebox_override("panel", ts)
        _dim_node.add_child(tp)
        
        var crack := _lbl("✦", 16, Color(0.15, 0.08, 0.04, 0.5))
        crack.mouse_filter = Control.MOUSE_FILTER_IGNORE # ИСПРАВЛЕНО: Символ на ловушке прозрачен для мыши
        crack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        crack.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        crack.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        tp.add_child(crack)
        _trap_nodes[cell] = tp

func _build_unicorn() -> void:
    _unicorn_ctrl = Control.new()
    _unicorn_ctrl.size = Vector2(UNICORN_SZ, UNICORN_SZ)
    _unicorn_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE

    if _unicorn_texture:
        var tex := TextureRect.new()
        tex.mouse_filter = Control.MOUSE_FILTER_IGNORE # ИСПРАВЛЕНО: Текстура персонажа не задерживает клики
        tex.texture = _unicorn_texture
        tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        _unicorn_ctrl.add_child(tex)
    else:
        var ph := Panel.new()
        ph.mouse_filter = Control.MOUSE_FILTER_IGNORE # ИСПРАВЛЕНО: Плейсхолдер персонажа прозрачен для мыши
        ph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        var ps := StyleBoxFlat.new()
        ps.bg_color = Color(0.9, 0.9, 0.98, 0.95)
        ps.set_corner_radius_all(8)
        ps.border_width_top = 2; ps.border_width_bottom = 2
        ps.border_color = Color(0.5, 0.45, 0.75, 1.0)
        ph.add_theme_stylebox_override("panel", ps)
        _unicorn_ctrl.add_child(ph)

    _unicorn_ctrl.position = _unicorn_visual_pos(_unicorn_cell)
    _dim_node.add_child(_unicorn_ctrl)

# ─── Игровая Логика ──────────────────────────────────────────────────────────

func _on_cell_tapped(cell: Vector2i) -> void:
    if _is_busy or cell == _unicorn_cell:
        return
    _is_busy = true
    _set_grid_clickable(false)
    _do_move(cell)

func _do_move(target: Vector2i) -> void:
    await _anim_unicorn_move(target)

    if target in _particles:
        _particles.erase(target)
        _collected += 1
        _collected_points.append(_cell_center(target))
        
        await _anim_collect_particle(target)
        _update_hud()

        if _collected >= _particle_count:
            await _anim_portal_open()
            completed.emit(true, _magic)
            return

    elif target in _traps and target not in _used_traps:
        _used_traps.append(target)
        _magic -= 1
        await _anim_trap_hit(target)
        _update_magic_icons()

        if _magic <= 0:
            await get_tree().create_timer(0.6).timeout
            completed.emit(false, 0)
            return

    _is_busy = false
    _set_grid_clickable(true)

# ─── Анимации ────────────────────────────────────────────────────────────────

func _anim_unicorn_move(target: Vector2i) -> void:
    var from_px := _unicorn_visual_pos(_unicorn_cell)
    var to_px   := _unicorn_visual_pos(target)
    var dist    := (to_px - from_px).length()
    var dur     := maxf(dist / _speed_px, 0.18)

    var tw := create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
    tw.tween_property(_unicorn_ctrl, "position", to_px, dur)
    await tw.finished
    _unicorn_cell = target

func _anim_collect_particle(cell: Vector2i) -> void:
    var node: Control = _particle_nodes.get(cell, null)
    if not is_instance_valid(node): return

    var tw := create_tween().set_parallel(true)
    tw.tween_property(node, "scale", Vector2(0.1, 0.1), 0.25).set_trans(Tween.TRANS_BACK)
    tw.tween_property(node, "position", _grid_center_px - node.size*0.5, 0.25).set_trans(Tween.TRANS_QUAD)
    await tw.finished
    node.queue_free()
    _particle_nodes.erase(cell)

func _anim_trap_hit(cell: Vector2i) -> void:
    var tp: Panel = _trap_nodes.get(cell, null)
    if is_instance_valid(tp):
        var ts := tp.get_theme_stylebox("panel") as StyleBoxFlat
        if ts:
            var tw2 := create_tween()
            tw2.tween_property(ts, "bg_color", C_TRAP_HIT, 0.1)
            tw2.tween_property(ts, "bg_color", Color(C_TRAP_HIT, 0.3), 0.4)

    var orig_pos := _unicorn_ctrl.position
    var shake_tw := create_tween()
    for _s in 3:
        shake_tw.tween_property(_unicorn_ctrl, "position", orig_pos + Vector2(randf_range(-6, 6), randf_range(-5, 5)), 0.05)
    shake_tw.tween_property(_unicorn_ctrl, "position", orig_pos, 0.05)
    await shake_tw.finished

func _anim_portal_open() -> void:
    _is_busy = true
    
    if is_instance_valid(_instruction_lbl):
     var text_tw := create_tween()
        # 1. Плавно гасим старый текст
     text_tw.tween_property(_instruction_lbl, "modulate:a", 0.0, 0.12)
        # 2. Меняем текст через встроенный метод set_text (БЕЗ эмодзи, чтобы не ломать шрифт)
     text_tw.tween_callback(_instruction_lbl.set_text.bind("Портал найден!"))
        # 3. Плавно зажигаем обратно
     text_tw.tween_property(_instruction_lbl, "modulate:a", 1.0, 0.12)
    
    var portal := Panel.new()
    portal.mouse_filter = Control.MOUSE_FILTER_IGNORE
    portal.size = Vector2(10, 10)
    portal.position = _grid_center_px - Vector2(5, 5)
    
    var ps := StyleBoxFlat.new()
    ps.bg_color = Color(1.0, 0.85, 0.4, 1.0)
    ps.set_corner_radius_all(5)
    ps.border_width_top = 4; ps.border_width_bottom = 4
    ps.border_width_left = 4; ps.border_width_right = 4
    ps.border_color = Color(0.9, 0.6, 0.1, 1.0)
    portal.add_theme_stylebox_override("panel", ps)
    _dim_node.add_child(portal)

    var tw1 := create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
    tw1.tween_property(portal, "size", Vector2(250, 250), 0.8)
    tw1.tween_property(portal, "position", _grid_center_px - Vector2(125, 125), 0.8)
    if ps:
        tw1.tween_property(ps, "set_corner_radius_all", 125, 0.8)
    await tw1.finished

    var portal_cell := _px_to_nearest_cell(_grid_center_px)
    await _anim_unicorn_move(portal_cell)

    var fade_tw := create_tween().set_parallel(true).set_ease(Tween.EASE_IN)
    fade_tw.tween_property(_unicorn_ctrl, "modulate:a", 0.0, 0.4)
    fade_tw.tween_property(_unicorn_ctrl, "scale", Vector2(0.0, 0.0), 0.4)
    fade_tw.tween_property(_unicorn_ctrl, "rotation", 5.0, 0.4)
    await fade_tw.finished
    await get_tree().create_timer(0.4).timeout

# ─── Вспомогательные методы ──────────────────────────────────────────────────

func _cell_to_px(cell: Vector2i) -> Vector2:
    return _grid_origin + Vector2(float(cell.x) * (CELL + GAP), float(cell.y) * (CELL + GAP))

func _cell_center(cell: Vector2i) -> Vector2:
    return _cell_to_px(cell) + Vector2(CELL * 0.5, CELL * 0.5)

func _unicorn_visual_pos(cell: Vector2i) -> Vector2:
    return _cell_to_px(cell) + Vector2((CELL - UNICORN_SZ) * 0.5, (CELL - UNICORN_SZ) * 0.5)

func _px_to_nearest_cell(px: Vector2) -> Vector2i:
    var local := px - _grid_origin
    var c2 := int(clampf(local.x / (CELL + GAP), 0, float(COLS - 1)))
    var r  := int(clampf(local.y / (CELL + GAP), 0, float(ROWS - 1)))
    return Vector2i(c2, r)

func _set_grid_clickable(enabled: bool) -> void:
    for btn: Button in _cell_btns.values():
        btn.disabled = not enabled

func _update_hud() -> void:
    if _counter_lbl:
        _counter_lbl.text = "Частицы: %d / %d" % [_collected, _particle_count]
    _update_magic_icons()

func _update_magic_icons() -> void:
    for i in _magic_icons.size():
        var ico := _magic_icons[i]
        var s := ico.get_theme_stylebox("panel") as StyleBoxFlat
        if s:
            s.bg_color = C_MAGIC_ON if i < _magic else C_MAGIC_OFF

# ─── Стилизация ──────────────────────────────────────────────────────────────

func _mk_ui_panel(pos: Vector2, size: Vector2) -> Panel:
    var p := Panel.new()
    p.position = pos
    p.size = size
    var s := StyleBoxFlat.new()
    s.bg_color = C_UI_BG
    s.set_corner_radius_all(6)
    s.border_width_top = 3; s.border_width_bottom = 3
    s.border_width_left = 3; s.border_width_right = 3
    s.border_color = C_UI_BOR
    s.shadow_color = C_UI_BOR2
    s.shadow_size = 3
    p.add_theme_stylebox_override("panel", s)
    p.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _dim_node.add_child(p)
    return p

func _style_circle(p: Panel, bg: Color, border: Color) -> void:
    var s := StyleBoxFlat.new()
    s.bg_color = bg
    s.set_corner_radius_all(int(min(p.size.x, p.size.y) * 0.5))
    s.border_width_top = 2; s.border_width_bottom = 2
    s.border_width_left = 2; s.border_width_right = 2
    s.border_color = border
    p.add_theme_stylebox_override("panel", s)

func _lbl(text: String, size: int, color: Color) -> Label:
    var l := Label.new()
    l.text = text
    if _font: l.add_theme_font_override("font", _font)
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", color)
    return l
