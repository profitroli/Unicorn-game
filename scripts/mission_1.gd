class_name Mission1Script
extends Node2D
signal mission_completed

enum Phase {
    FADE_IN,
    DIALOGUE_INTRO,          # Коридор: знакомство → «Покажи гримуар»
    MINIGAME_1,              # «Собери реферат» (8 карточек, 5 слотов)
    DIALOGUE_POST_MG1,       # Коридор: после реферата → «профессор Всезнайкин»
    DIALOGUE_EXAM_BEFORE,    # Аудитория: «Три вопроса» → шёпот → конец сцены
    PLASHKA_15MIN,           # «15 МИНУТ СПУСТЯ...»
    DIALOGUE_EXAM_AFTER,     # Аудитория: профессор доволен → «Идите»
    DIALOGUE_GROUP_PROJECT,  # Переговорная: конфликт → Единорог → «Для этого я здесь»
    MINIGAME_2,              # «Собери презентацию» (6 слайдов)
    DIALOGUE_POST_MG2,       # Переговорная: примирение → профессор → «Идите сдавать»
    DIALOGUE_FINALE,         # Коридор: «Всё сдал» → портал → Алиса
    PLASHKA_FINALE,          # «ТЕМ ВРЕМЕНЕМ, В КАФЕ ЛУНА...»
    FADE_OUT
}

var _phase: Phase = Phase.FADE_IN

@export_category("Backgrounds")
## Университетский коридор — стенды с объявлениями, студенты с ноутбуками
@export var bg_university_corridor: Texture2D
## Аудитория — кафедра, доска, парты
@export var bg_classroom: Texture2D
## Переговорная комната — стол, закрытые ноутбуки, виноватые лица
@export var bg_meeting_room: Texture2D
## Задержка перед появлением текста плашки (сек)
@export var plashka_delay: float = 1.0

@export_category("Portraits — Макс")
## Макс измотан, не поднимает голову, листает конспекты
@export var portrait_max_tired: Texture2D
## Макс поднял взгляд, замер — увидел Единорога
@export var portrait_max_surprised: Texture2D
## Макс смотрит обречённо («Понедельник. Это точно понедельник.»)
@export var portrait_max_resigned: Texture2D
## Макс хватается за голову («ВСЁ горит!»)
@export var portrait_max_desperate: Texture2D
## Макс смеётся («Это хуже магии. Это Google Docs.»)
@export var portrait_max_laughing: Texture2D
## Макс шёпотом в аудитории
@export var portrait_max_whisper: Texture2D
## Макс краснеет («Новая лампа! Для чтения!»)
@export var portrait_max_embarrassed: Texture2D
## Макс счастливый — всё сдано, цель достигнута
@export var portrait_max_happy: Texture2D
## Макс закипает от злости — бросила группа
@export var portrait_max_angry: Texture2D

@export_category("Portraits — Единорог")
## Нейтральный / спокойный
@export var portrait_unicorn_neutral: Texture2D
## Любопытный / наклоняет голову (изучает телефон)
@export var portrait_unicorn_curious: Texture2D
## Мудрый / торжественный
@export var portrait_unicorn_wise: Texture2D
## Единорог шёпотом (прячется за Максом в аудитории)
@export var portrait_unicorn_whisper: Texture2D
## Единорог уверенно выходит вперёд (переговорная)
@export var portrait_unicorn_confident: Texture2D

@export_category("Portraits — Профессор Всезнайкин")
## Строгий, монотонный — экзаменует
@export var portrait_professor_strict: Texture2D
## Поднимает бровь — удивлён ответом Макса
@export var portrait_professor_raised_brow: Texture2D
## Щурится — замечает «гриву» за спиной Макса
@export var portrait_professor_squinting: Texture2D
## Нейтральный — вздыхает, закрывает тему
@export var portrait_professor_neutral: Texture2D

@export_category("Portraits — Группа")
## Кира — виноватая, отводит взгляд
@export var portrait_kira_guilty: Texture2D
## Дима — виноватый, пожимает плечами
@export var portrait_dima_guilty: Texture2D
## Юля — возмущённая («Почему сразу я?!»)
@export var portrait_yulia_indignant: Texture2D
## Юля — пристыженная («Мне стыдно.»)
@export var portrait_yulia_ashamed: Texture2D


@onready var black_screen: ColorRect          = $FadeLayer/BlackScreen
@onready var background: TextureRect          = $Background
@onready var dm: Node                         = $DialogueManager
@onready var dialogue_box: Control            = $DialogueBox
@onready var character_portrait_1: TextureRect = $CharacterPortrait1
@onready var character_portrait_2: TextureRect = $CharacterPortrait2
@onready var plashka_rect: ColorRect          = $PlashkaLayer/PlashkaRect
@onready var plashka_label: Label             = $PlashkaLayer/PlashkaLabel
@onready var minigame_layer: CanvasLayer      = $MinigameLayer

@export var finale_background_texture: Texture2D 
# ==============================================================
# ДАННЫЕ МИНИ-ИГРЫ 1 — «Собери реферат»
# Источник: ЕДИНОРОГ.docx → МИНИ-ИГРА 1
# 5 правильных тезисов + 3 ложных, перемешаны
# correct_position: порядковый номер в правильной цепочке (-1 = не входит)
# ==============================================================
const MINIGAME_1_CARDS: Array[Dictionary] = [
    {
        "text":             "Этика – это наука о морали и нравственности",
        "is_correct":       true,
        "correct_position": 0
    },
    {
        "text":             "Дилемма возникает при конфликте равнозначных ценностей",
        "is_correct":       true,
        "correct_position": 1
    },
    {
        "text":             "Кант предлагал категорический императив",
        "is_correct":       true,
        "correct_position": 2
    },
    {
        "text":             "Утилитаризм оценивает по последствиям",
        "is_correct":       true,
        "correct_position": 3
    },
    {
        "text":             "Современная этика учитывает культурный контекст",
        "is_correct":       true,
        "correct_position": 4
    },
    {
        "text":             "Этика была придумана драконами в третьем веке",
        "is_correct":       false,
        "correct_position": -1
    },
    {
        "text":             "Главное правило: всегда ешь пиццу ананасами вверх",
        "is_correct":       false,
        "correct_position": -1
    },
    {
        "text":             "Философы – это люди, которые не любят солнце",
        "is_correct":       false,
        "correct_position": -1
    }
]

const MINIGAME_1_SLOTS_COUNT: int       = 5   # Слотов для правильных карточек
const MINIGAME_1_TIMER_FIRST: int       = 60  # Первая попытка (сек)
const MINIGAME_1_TIMER_RETRY: int       = 45  # Пересдача при 3-4 верных (сек)

# ==============================================================
# ДАННЫЕ МИНИ-ИГРЫ 2 — «Собери презентацию»
# Источник: ЕДИНОРОГ.docx → МИНИ-ИГРА 2
# 6 слайдов, правильный порядок: проблема→данные→анализ→решения→план→выводы
# ==============================================================
const MINIGAME_2_SLIDES: Array[Dictionary] = [
    { "title": "Проблема: загрязнение кампуса",  "correct_position": 0 },
    { "title": "Данные опроса студентов",         "correct_position": 1 },
    { "title": "Графики и анализ",               "correct_position": 2 },
    { "title": "Предлагаемые решения",            "correct_position": 3 },
    { "title": "План внедрения",                  "correct_position": 4 },
    { "title": "Итоговые выводы",                 "correct_position": 5 }
]

const MINIGAME_2_TIMER_FIRST: int = 60

func _ready() -> void:
    _set_background(bg_university_corridor)

    if character_portrait_1: character_portrait_1.visible = false
    if character_portrait_2: character_portrait_2.visible = false

    plashka_label.modulate.a = 0.0
    plashka_rect.color       = Color(0, 0, 0, 0.0)
    minigame_layer.visible   = false

    if dm:
        if dm.has_signal("dialogue_finished"):
            dm.dialogue_finished.connect(_on_dialogue_finished)
        if dm.has_signal("line_changed"):
            dm.line_changed.connect(_on_dialogue_line_changed)
    _begin_fade_in()

    var _home := HomeOverlay.new()
    _home.current_scene_path = "res://scenes/mission_1.tscn"
    add_child(_home)

func _input(event: InputEvent) -> void:
    var is_dialogue_active: bool = (
        _phase == Phase.DIALOGUE_INTRO         or
        _phase == Phase.DIALOGUE_POST_MG1      or
        _phase == Phase.DIALOGUE_EXAM_BEFORE   or
        _phase == Phase.DIALOGUE_EXAM_AFTER    or
        _phase == Phase.DIALOGUE_GROUP_PROJECT or
        _phase == Phase.DIALOGUE_POST_MG2      or
        _phase == Phase.DIALOGUE_FINALE
    )
    if not is_dialogue_active:
        return

    var is_tap: bool = event is InputEventScreenTouch and event.pressed
    var is_click: bool = (
        event is InputEventMouseButton
        and event.pressed
        and event.button_index == MOUSE_BUTTON_LEFT
    )

    if (is_tap or is_click) and dm and dm.has_method("advance"):
        dm.advance()

func _set_background(texture: Texture2D) -> void:
    if background and texture:
        background.texture = texture

func _reset_plashka() -> void:
    plashka_label.modulate.a = 0.0
    plashka_rect.color       = Color(0, 0, 0, 0.0)

func _begin_fade_in() -> void:
    _phase = Phase.FADE_IN

    black_screen.modulate.a = 1.0
    black_screen.visible    = true

    var tween: Tween = create_tween()
    tween.tween_property(black_screen, "modulate:a", 0.0, 1.0)
    await tween.finished

    black_screen.visible = false
    _start_dialogue_intro()

func _start_dialogue_intro() -> void:
    _phase = Phase.DIALOGUE_INTRO
    _set_background(bg_university_corridor)

    if not dm or not dm.has_method("start"):
        push_warning("Mission1: DialogueManager не найден, пропускаем диалог.")
        _start_minigame_1()
        return

    var lines: Array[Dictionary] = [
        {
            "speaker":    "МАКС",
            "text":       "Так... реферат не готов, зачёт через десять минут, групповой проект горит, потому что все меня кинули... Идеальный день. Просто идеальный.",
            "portrait_1": portrait_max_tired,
            "pos_1":      Vector2(0, 0),
            "portrait_2": null,
            "pos_2":      Vector2.ZERO
        },
        # --- Единорог подходит, трогает копытом учебник ---
        {
            "speaker":    "ЕДИНОРОГ",
            "text":       "Прости, человек. Твоя аура... она серого цвета. У нас в лесу такая бывает только у зверей перед зимней спячкой. Ты умираешь?",
            "portrait_1": portrait_unicorn_curious,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_max_tired,
            "pos_2":      Vector2(0, 0)
        },
        # --- Макс поднимает взгляд, замирает ---
        {
            "speaker":    "МАКС",
            "text":       "...Так. Я сплю. Или переработал. Или это побочка от пятой чашки кофе.",
            "portrait_1": portrait_max_surprised,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_unicorn_curious,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "ЕДИНОРОГ",
            "text":       "Ты не спишь. Я Астерион. Из Волшебного леса. Портал, случайность, долгая история... Тебе нужна помощь – я чувствую это вот здесь.",
            "portrait_1": portrait_unicorn_neutral,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_max_surprised,
            "pos_2":      Vector2(0, 0)
        },
        # --- Макс смотрит в камеру обречённо ---
        {
            "speaker":    "МАКС",
            "text":       "Понедельник. Это точно понедельник.",
            "portrait_1": portrait_max_resigned,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_unicorn_neutral,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "МАКС",
            "text":       "Ладно, Астерион из Волшебного леса. Допустим, ты настоящий. Допустим, я не сошёл с ума. Ты реально можешь помочь?",
            "portrait_1": portrait_max_resigned,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_unicorn_neutral,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "ЕДИНОРОГ",
            "text":       "В моём мире я помогал лесу расти, а рекам – не пересыхать. Учебный день? Должен справиться. Что нужно?",
            "portrait_1": portrait_unicorn_wise,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_max_resigned,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "МАКС",
            "text":       "ВСЁ! Реферат по философии, зачёт по социологии, групповой проект, который я делаю один... Если я всё провалю – отец меня убьёт. Он говорит, я позор семьи, потому что ничего не довожу до конца.",
            "portrait_1": portrait_max_desperate,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_unicorn_wise,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "ЕДИНОРОГ",
            "text":       "Сурово. Но мы справимся. Показывай свой первый «гримуар».",
            "portrait_1": portrait_unicorn_wise,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_max_desperate,
            "pos_2":      Vector2(0, 0)
        },
        # --- Макс протягивает телефон с заметками ---
        {
            "speaker":    "ЕДИНОРОГ",
            "text":       "Текст, запертый в стеклянной пластине. Люди называют это магией?",
            "portrait_1": portrait_unicorn_curious,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_max_desperate,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "МАКС",
            "text":       "Это хуже магии. Это Google Docs. Мне надо написать реферат по философии на тему «Этические дилеммы в современном мире». У меня куча заметок, но я не могу собрать их в кучу.",
            "portrait_1": portrait_max_laughing,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_unicorn_curious,
            "pos_2":      Vector2(0, 0)
        },
        # --- Переход к мини-игре ---
        {
            "speaker":    "ЕДИНОРОГ",
            "text":       "Я помогу. В лесу я часто соединял разрозненные тропинки в одну. Давай посмотрим на эти… заметки.",
            "portrait_1": portrait_unicorn_wise,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_max_laughing,
            "pos_2":      Vector2(0, 0)
        }
    ]

    dm.start(lines)

func _on_dialogue_finished() -> void:
    if character_portrait_1: character_portrait_1.visible = false
    if character_portrait_2: character_portrait_2.visible = false

    match _phase:
        Phase.DIALOGUE_INTRO:
            _start_minigame_1()
        Phase.DIALOGUE_POST_MG1:
            _start_dialogue_exam_before()
        Phase.DIALOGUE_EXAM_BEFORE:
            _show_plashka_15min()
        Phase.DIALOGUE_EXAM_AFTER:
            _start_dialogue_group_project()
        Phase.DIALOGUE_GROUP_PROJECT:
            _start_minigame_2()
        Phase.DIALOGUE_POST_MG2:
            _start_dialogue_finale()
        Phase.DIALOGUE_FINALE:
            _show_plashka_finale()

func _on_dialogue_line_changed(line_data: Dictionary) -> void:
    if character_portrait_1:
        var tex_1: Texture2D = line_data.get("portrait_1", null)
        if tex_1 == null:
            character_portrait_1.visible = false
        else:
            character_portrait_1.texture        = tex_1
            character_portrait_1.visible        = true
            character_portrait_1.global_position = line_data.get("pos_1", Vector2.ZERO)

    if character_portrait_2:
        var tex_2: Texture2D = line_data.get("portrait_2", null)
        if tex_2 == null:
            character_portrait_2.visible = false
        else:
            character_portrait_2.texture        = tex_2
            character_portrait_2.visible        = true
            character_portrait_2.global_position = line_data.get("pos_2", Vector2.ZERO)

# ==============================================================
# ФАЗА 3 — МИНИ-ИГРА 1: «Собери реферат»
# Источник: ЕДИНОРОГ.docx → МИНИ-ИГРА 1
# Данные: MINIGAME_1_CARDS (8 карточек, 5 правильных)
# ==============================================================
func _start_minigame_1(timer: int = MINIGAME_1_TIMER_FIRST) -> void:
    _phase = Phase.MINIGAME_1
    minigame_layer.visible = true

    # TODO: инстанцируй сцену мини-игры и подключи сигнал.
    # var mg = preload("res://scenes/minigame_sort_cards.tscn").instantiate()
    # minigame_layer.add_child(mg)
    # mg.setup(MINIGAME_1_CARDS, MINIGAME_1_SLOTS_COUNT, timer)
    # mg.completed.connect(_on_minigame_1_completed)

    push_warning("Mission1: MINIGAME_1 — заглушка. Подключи реальный UI.")
    await get_tree().create_timer(0.1).timeout
    _on_minigame_1_completed(5)  # ЗАГЛУШКА: 5/5 правильных

## Вызывается мини-игрой по сигналу.
## correct_count: сколько карточек в правильных позициях (0–5).
func _on_minigame_1_completed(correct_count: int) -> void:
    if correct_count < 3:
        # Полный провал — Единорог помогает снова → полный перезапуск
        push_warning("Mission1: МГ1 провал (меньше 3 верных). Перезапуск с 60 сек.")
        minigame_layer.visible = false
        _start_minigame_1(MINIGAME_1_TIMER_FIRST)
        return

    if correct_count < 5:
        # 3–4 верных — «Почти! Попробуй ещё раз» → пересдача 45 сек
        push_warning("Mission1: МГ1 пересдача (3-4 верных). Таймер 45 сек.")
        minigame_layer.visible = false
        _start_minigame_1(MINIGAME_1_TIMER_RETRY)
        return

    # Победа! Все 5 карточек верно
    minigame_layer.visible = false
    _start_dialogue_post_mg1()

# ==============================================================
# ФАЗА 4 — ДИАЛОГ ПОСЛЕ МГ1 (коридор)
# Источник: ЕДИНОРОГ.docx → реплики после мини-игры 1
# Макс рад → «что такое зачёт?» → «Хуже. Профессор Всезнайкин!»
# ==============================================================
func _start_dialogue_post_mg1() -> void:
    _phase = Phase.DIALOGUE_POST_MG1
    _set_background(bg_university_corridor)

    if not dm or not dm.has_method("start"):
        push_warning("Mission1: DialogueManager не найден.")
        _start_dialogue_exam_before()
        return

    var lines: Array[Dictionary] = [
        {
            "speaker":    "МАКС",
            "text":       "Ого... Это реально похоже на связный реферат! Спасибо, Астерион! Осталось пережить зачёт и групповой проект...",
            "portrait_1": portrait_max_happy,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_unicorn_wise,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "ЕДИНОРОГ",
            "text":       "Веди меня. Только объясни, что такое «зачёт». Это битва с чудовищем?",
            "portrait_1": portrait_unicorn_curious,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_max_happy,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "МАКС",
            "text":       "Хуже. Это профессор Всезнайкин!",
            "portrait_1": portrait_max_resigned,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_unicorn_curious,
            "pos_2":      Vector2(0, 0)
        }
    ]

    dm.start(lines)

# ==============================================================
# ФАЗА 5 — ДИАЛОГ В АУДИТОРИИ (до зачёта)
# Источник: ЕДИНОРОГ.docx → «ПРОДОЛЖЕНИЕ МИССИИ 1» → аудитория
# Профессор: «Три вопроса» → шёпот Единорога → «надеюсь, не ржёт»
# ==============================================================
func _start_dialogue_exam_before() -> void:
    _phase = Phase.DIALOGUE_EXAM_BEFORE
    _set_background(bg_classroom)

    if not dm or not dm.has_method("start"):
        push_warning("Mission1: DialogueManager не найден.")
        _show_plashka_15min()
        return

    var lines: Array[Dictionary] = [
        {
            "speaker":    "ПРОФЕССОР ВСЕЗНАЙКИН",
            "text":       "Итак, Максим. Три вопроса. Без подготовки. Надеюсь, вы хоть что-то читали.",
            "portrait_1": portrait_professor_strict,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_max_whisper,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "МАКС",
            "text":       "Да, профессор. Я... готов.",
            "portrait_1": portrait_max_whisper,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_professor_strict,
            "pos_2":      Vector2(0, 0)
        },
        # --- Единорог тихо касается рогом плеча Макса (шёпот) ---
        {
            "speaker":    "ЕДИНОРОГ",
            "text":       "Я усилю твою память. Просто слушай свой внутренний голос.",
            "portrait_1": portrait_unicorn_whisper,
            "pos_1":      Vector2(0, 0),   # Прячется за Максом — ближе к центру
            "portrait_2": portrait_max_whisper,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "МАКС",
            "text":       "Надеюсь, он звучит не как ржущий конь...",
            "portrait_1": portrait_max_whisper,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_unicorn_whisper,
            "pos_2":      Vector2(0, 0)
        }
        # Завершение → _on_dialogue_finished → _show_plashka_15min
    ]

    dm.start(lines)

# ==============================================================
# ФАЗА 6 — ПЛАШКА «15 МИНУТ СПУСТЯ...»
# Источник: ЕДИНОРОГ.docx → [Затемнение. Плашка: «15 МИНУТ СПУСТЯ...»]
# Показывает плашку, затем скрывает и продолжает в аудитории
# ==============================================================
func _show_plashka_15min() -> void:
    _phase = Phase.PLASHKA_15MIN
    _reset_plashka()
    plashka_label.text = "15 МИНУТ СПУСТЯ..."

    # Задержка перед появлением текста
    await get_tree().create_timer(plashka_delay).timeout

    # Появление плашки
    var tw_in: Tween = create_tween()
    tw_in.tween_property(plashka_rect,  "color",         Color(0, 0, 0, 0.85), 0.5)
    tw_in.parallel().tween_property(plashka_label, "modulate:a", 1.0,         0.5)
    await tw_in.finished

    await get_tree().create_timer(1.5).timeout

    # Скрытие плашки перед следующим диалогом
    var tw_out: Tween = create_tween()
    tw_out.tween_property(plashka_rect,  "color",         Color(0, 0, 0, 0.0), 0.4)
    tw_out.parallel().tween_property(plashka_label, "modulate:a", 0.0,         0.4)
    await tw_out.finished

    _start_dialogue_exam_after()

# ==============================================================
# ФАЗА 7 — ДИАЛОГ В АУДИТОРИИ (после зачёта)
# Источник: ЕДИНОРОГ.docx → «[после третьего вопроса...]»
# Профессор доволен → замечает гриву → «фыркает» → уходят
# ==============================================================
func _start_dialogue_exam_after() -> void:
    _phase = Phase.DIALOGUE_EXAM_AFTER
    # Фон не меняется — всё ещё аудитория

    if not dm or not dm.has_method("start"):
        push_warning("Mission1: DialogueManager не найден.")
        _start_dialogue_group_project()
        return

    var lines: Array[Dictionary] = [
        {
            "speaker":    "ПРОФЕССОР ВСЕЗНАЙКИН",
            "text":       "Максим... это лучший ваш ответ за семестр. Вы, кажется, нашли вдохновение?",
            "portrait_1": portrait_professor_raised_brow,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_max_embarrassed,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "МАКС",
            "text":       "Просто... перечитал конспекты, профессор.",
            "portrait_1": portrait_max_embarrassed,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_professor_raised_brow,
            "pos_2":      Vector2(0, 0)
        },
        # --- Профессор замечает край сияющей гривы ---
        {
            "speaker":    "ПРОФЕССОР ВСЕЗНАЙКИН",
            "text":       "У вас там... грива?",
            "portrait_1": portrait_professor_squinting,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_max_embarrassed,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "МАКС",
            "text":       "Новая лампа! Для чтения! Очень яркая. Можно идти? У нас ещё проект...",
            "portrait_1": portrait_max_embarrassed,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_professor_squinting,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "ПРОФЕССОР ВСЕЗНАЙКИН",
            "text":       "Идите. И скажите вашей «лампе», что она подозрительно фыркает.",
            "portrait_1": portrait_professor_neutral,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_max_embarrassed,
            "pos_2":      Vector2(0, 0)
        }
        # Завершение → _on_dialogue_finished → _start_dialogue_group_project
    ]

    dm.start(lines)

# ==============================================================
# ФАЗА 8 — ДИАЛОГ: ГРУППОВОЙ ПРОЕКТ (переговорная)
# Источник: ЕДИНОРОГ.docx → «Переговорная комната»
# Конфликт группы → Единорог выходит вперёд → «Для этого я здесь»
# ==============================================================
func _start_dialogue_group_project() -> void:
    _phase = Phase.DIALOGUE_GROUP_PROJECT
    _set_background(bg_meeting_room)

    if not dm or not dm.has_method("start"):
        push_warning("Mission1: DialogueManager не найден.")
        _start_minigame_2()
        return

    var lines: Array[Dictionary] = [
        # --- Макс входит с Единорогом. Ноутбуки закрыты. Тишина. ---
        {
            "speaker":    "МАКС",
            "text":       "Ну и? Презентация?",
            "portrait_1": portrait_max_angry,
            "pos_1":      Vector2(0, 0),
            "portrait_2": null,
            "pos_2":      Vector2.ZERO
        },
        {
            "speaker":    "КИРА",
            "text":       "Макс, прости... У меня были дела...",
            "portrait_1": portrait_kira_guilty,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_max_angry,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "ДИМА",
            "text":       "А я думал, что Юля сделает...",
            "portrait_1": portrait_dima_guilty,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_max_angry,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "ЮЛЯ",
            "text":       "Почему сразу я?!",
            "portrait_1": portrait_yulia_indignant,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_max_angry,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "МАКС",
            "text":       "Вы серьёзно?! Через час сдача! Мы месяц готовились! Точнее, я готовился!",
            "portrait_1": portrait_max_angry,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_kira_guilty,
            "pos_2":      Vector2(0, 0)
        },
        # --- Единорог выходит вперёд. В комнате повисает тишина. ---
        {
            "speaker":    "КИРА",
            "text":       "Это... единорог?",
            "portrait_1": portrait_kira_guilty,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_unicorn_confident,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "ДИМА",
            "text":       "Макс, ты привёл коня? На проект?",
            "portrait_1": portrait_dima_guilty,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_unicorn_confident,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "ЕДИНОРОГ",
            "text":       "Я Астерион. Я здесь, чтобы помочь Максу. Потому что, судя по всему, вы этого делать не собирались.",
            "portrait_1": portrait_unicorn_confident,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_kira_guilty,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "ЮЛЯ",
            "text":       "Мне стыдно.",
            "portrait_1": portrait_yulia_ashamed,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_unicorn_confident,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "ЕДИНОРОГ",
            "text":       "Стыд – хорошее начало для исправления. Но сейчас нужны не извинения, а работа. Что у вас есть?",
            "portrait_1": portrait_unicorn_wise,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_yulia_ashamed,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "КИРА",
            "text":       "У меня... данные опроса. Я их собрала.",
            "portrait_1": portrait_kira_guilty,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_unicorn_wise,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "ДИМА",
            "text":       "А у меня графики.",
            "portrait_1": portrait_dima_guilty,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_unicorn_wise,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "ЮЛЯ",
            "text":       "Я расписала выводы. Просто не оформила...",
            "portrait_1": portrait_yulia_ashamed,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_unicorn_wise,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "МАКС",
            "text":       "Так у нас всё есть! Просто нужно собрать. Астерион, поможешь?",
            "portrait_1": portrait_max_surprised,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_unicorn_wise,
            "pos_2":      Vector2(0, 0)
        },
        # --- Последняя реплика перед мини-игрой ---
        {
            "speaker":    "ЕДИНОРОГ",
            "text":       "Для этого я здесь.",
            "portrait_1": portrait_unicorn_wise,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_max_surprised,
            "pos_2":      Vector2(0, 0)
        }
        # Завершение → _on_dialogue_finished → _start_minigame_2
    ]

    dm.start(lines)

# ==============================================================
# ФАЗА 9 — МИНИ-ИГРА 2: «Собери презентацию»
# Источник: ЕДИНОРОГ.docx → МИНИ-ИГРА 2
# Данные: MINIGAME_2_SLIDES (6 слайдов, перетаскивание)
# ==============================================================
func _start_minigame_2() -> void:
    _phase = Phase.MINIGAME_2
    minigame_layer.visible = true

    # TODO: инстанцируй сцену мини-игры и подключи сигнал.
    # var mg = preload("res://scenes/minigame_sort_slides.tscn").instantiate()
    # minigame_layer.add_child(mg)
    # mg.setup(MINIGAME_2_SLIDES, MINIGAME_2_TIMER_FIRST)
    # mg.completed.connect(_on_minigame_2_completed)

    push_warning("Mission1: MINIGAME_2 — заглушка. Подключи реальный UI.")
    await get_tree().create_timer(0.1).timeout
    _on_minigame_2_completed(true)  # ЗАГЛУШКА: победа

## Вызывается мини-игрой по сигналу.
## is_success: true = правильный порядок до истечения таймера.
func _on_minigame_2_completed(is_success: bool) -> void:
    if not is_success:
        # Таймер истёк или порядок неверный → перезапуск
        push_warning("Mission1: МГ2 провал. Перезапуск.")
        minigame_layer.visible = false
        _start_minigame_2()
        return

    minigame_layer.visible = false
    _start_dialogue_post_mg2()

# ==============================================================
# ФАЗА 10 — ДИАЛОГ ПОСЛЕ МГ2 (переговорная)
# Источник: ЕДИНОРОГ.docx → диалог после мини-игры 2
# Примирение команды → профессор заглядывает → «Идите сдавать»
# ==============================================================
func _start_dialogue_post_mg2() -> void:
    _phase = Phase.DIALOGUE_POST_MG2
    # Фон не меняется — всё ещё переговорная

    if not dm or not dm.has_method("start"):
        push_warning("Mission1: DialogueManager не найден.")
        _start_dialogue_finale()
        return

    var lines: Array[Dictionary] = [
        {
            "speaker":    "МАКС",
            "text":       "Готово. Ребята... спасибо, что хотя бы данные собрали.",
            "portrait_1": portrait_max_happy,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_kira_guilty,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "КИРА",
            "text":       "Макс, прости нас. Серьёзно. Мы больше так не будем.",
            "portrait_1": portrait_kira_guilty,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_max_happy,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "ДИМА",
            "text":       "Может, пойдём сдавать вместе? Как настоящая команда?",
            "portrait_1": portrait_dima_guilty,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_max_happy,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "ЮЛЯ",
            "text":       "Я пойду. Стыдно, но пойду.",
            "portrait_1": portrait_yulia_ashamed,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_max_happy,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "МАКС",
            "text":       "Астерион... спасибо.",
            "portrait_1": portrait_max_happy,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_unicorn_wise,
            "pos_2":      Vector2(0, 0)
        },
        # --- Профессор Всезнайкин заглядывает в дверь ---
        {
            "speaker":    "ПРОФЕССОР ВСЕЗНАЙКИН",
            "text":       "Максим, группа готова?",
            "portrait_1": portrait_professor_neutral,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_max_happy,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "МАКС",
            "text":       "Да, профессор. Мы готовы. Все вместе.",
            "portrait_1": portrait_max_happy,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_professor_neutral,
            "pos_2":      Vector2(0, 0)
        },
        # --- Профессор замечает Единорога ---
        {
            "speaker":    "ПРОФЕССОР ВСЕЗНАЙКИН",
            "text":       "Максим... почему у вас в команде лошадь?",
            "portrait_1": portrait_professor_squinting,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_unicorn_confident,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "ЕДИНОРОГ",
            "text":       "Я – консультант по командной работе.",
            "portrait_1": portrait_unicorn_confident,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_professor_squinting,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "ПРОФЕССОР ВСЕЗНАЙКИН",
            "text":       "...Поставил бы «отлично», но боюсь, меня уволят за веру в единорогов. Идите сдавать.",
            "portrait_1": portrait_professor_neutral,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_unicorn_confident,
            "pos_2":      Vector2(0, 0)
        }
        # Завершение → _on_dialogue_finished → _start_dialogue_finale
    ]

    dm.start(lines)

# ==============================================================
# ФАЗА 11 — ФИНАЛЬНЫЙ ДИАЛОГ (коридор)
# Источник: ЕДИНОРОГ.docx → «Все выходят.» → конец Миссии 1
# Макс: всё сдано → Единорог спрашивает о портале → Алиса
# ==============================================================
func _start_dialogue_finale() -> void:
    _phase = Phase.DIALOGUE_FINALE
    _set_background(bg_university_corridor)

    if not dm or not dm.has_method("start"):
        push_warning("Mission1: DialogueManager не найден.")
        _show_plashka_finale()
        return

    var lines: Array[Dictionary] = [
        {
            "speaker":    "МАКС",
            "text":       "Всё сдал. Реферат приняли, зачёт – отлично, проект – похвалили. Отец будет гордиться.",
            "portrait_1": portrait_max_happy,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_unicorn_neutral,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "ЕДИНОРОГ",
            "text":       "Рад за тебя. А теперь скажи, Макс... ты не знаешь, как в вашем мире найти портал? Мне нужно вернуться домой, в Волшебный лес.",
            "portrait_1": portrait_unicorn_curious,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_max_happy,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "МАКС",
            "text":       "Порталы? Слушай, это не ко мне. Но у меня есть подруга – Алиса. Она фанатка фэнтези, аниме, магии, всего такого. Если кто и знает – то она. Она сейчас в кафе Жбан через дорогу.",
            "portrait_1": portrait_max_happy,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_unicorn_curious,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "ЕДИНОРОГ",
            "text":       "Спасибо, Макс.",
            "portrait_1": portrait_unicorn_neutral,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_max_happy,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "МАКС",
            "text":       "Это тебе спасибо. Если бы не ты... я бы всё провалил. Удачи, Астерион.",
            "portrait_1": portrait_max_happy,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_unicorn_neutral,
            "pos_2":      Vector2(0, 0)
        },
        # --- Макс уходит. Единорог смотрит ему вслед. ---
        {
            "speaker":    "ЕДИНОРОГ",
            "text":       "И тебе. И помни – ты сильнее, чем думаешь. Даже без магии.",
            "portrait_1": portrait_unicorn_wise,
            "pos_1":      Vector2(0, 0),
            "portrait_2": null,
            "pos_2":      Vector2.ZERO
        }
        # Завершение → _on_dialogue_finished → _show_plashka_finale
    ]

    dm.start(lines)

# ==============================================================
# ФАЗА 12 — ФИНАЛЬНАЯ ПЛАШКА
# Источник: ЕДИНОРОГ.docx → «ТЕМ ВРЕМЕНЕМ, В КАФЕ ЛУНА...»
# После плашки — fade out → mission_2.tscn
# ==============================================================
func _show_plashka_finale() -> void:
    _phase = Phase.PLASHKA_FINALE
    _reset_plashka()
    plashka_label.text = "ТЕМ ВРЕМЕНЕМ,\nВ КАФЕ ЖБАН..." # Текст твоей плашки

    # 1. Сначала подставляем финальную картинку на фон
    if background and finale_background_texture:
        background.texture = finale_background_texture
        
    await get_tree().create_timer(plashka_delay).timeout

    # 2. Проявляем плашку на 85% затемнения, чтобы картинку было видно, и показываем текст
    var tw: Tween = create_tween()
    tw.tween_property(plashka_rect,  "color",         Color(0, 0, 0, 0.85), 0.5)
    tw.parallel().tween_property(plashka_label, "modulate:a", 1.0,         0.5)
    await tw.finished

    # Ожидание 2 секунды, пока игрок читает текст
    await get_tree().create_timer(2.0).timeout
    
    # Запускаем плавное перетекание в чёрный экран
    _begin_fade_out()

# ==============================================================
# ФАЗА 13 — FADE OUT → Абсолютное затухание в стиль пролога
# ==============================================================
func _begin_fade_out() -> void:
    _phase = Phase.FADE_OUT
    
    # Создаем Tween для эффекта «перетекания»:
    # Текст плавно растворяется (0.0), а фон становится на 100% чёрным (1.0)
    var tw: Tween = create_tween()
    tw.tween_property(plashka_rect, "color", Color(0, 0, 0, 1.0), 1.0)
    tw.parallel().tween_property(plashka_label, "modulate:a", 0.0, 1.0)
    await tw.finished

    # Когда экран полностью стал чёрным — переключаем сцену на Миссию 2
    mission_completed.emit()
    get_tree().change_scene_to_file("res://scenes/mission_2.tscn")
