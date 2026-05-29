class_name Mission2Script
extends Node2D

# ==============================================================
# СИГНАЛЫ
# ==============================================================
signal mission_completed

# ==============================================================
# ФАЗЫ
# ==============================================================
enum Phase {
    FADE_IN,
    DIALOGUE_INTRO,
    MINIGAME_A,
    DIALOGUE_BETWEEN,
    MINIGAME_B,
    DIALOGUE_OUTRO,
    PLASHKA,
    FADE_OUT
}

var _phase: Phase = Phase.FADE_IN

# ── Активные экземпляры мини-игр ────────────────────────────────────────────
var _mg_questionnaire: MinigameProfileQuestionnaire = null
var _mg_first_message: MinigameFirstMessage         = null

# ==============================================================
# ЭКСПОРТИРУЕМЫЕ АССЕТЫ
# ==============================================================
@export_category("Backgrounds")
@export var bg_cafe_luna:          Texture2D
@export var ui_app_profile_arseniy: Texture2D
@export var bg_sahara:             Texture2D
@export var background_view_time:  float = 1.5

@export_category("Portraits — Алиса")
@export var portrait_alisa_sad:       Texture2D
@export var portrait_alisa_surprised: Texture2D
@export var portrait_alisa_excited:   Texture2D
@export var portrait_alisa_happy:     Texture2D
@export var portrait_alisa_serious:   Texture2D
@export var portrait_alisa_laughing:  Texture2D

@export_category("Portraits — Единорог")
@export var portrait_unicorn_neutral: Texture2D
@export var portrait_unicorn_curious: Texture2D
@export var portrait_unicorn_wise:    Texture2D

@export_category("Portraits — Прочие")
@export var portrait_barista: Texture2D

@export_category("UI Assets — Мини-игры")
@export var ui_profile_alisa:   Texture2D
@export var ui_profile_arseniy: Texture2D

# ==============================================================
# ССЫЛКИ НА УЗЛЫ
# ==============================================================
@onready var black_screen:          ColorRect    = $FadeLayer/BlackScreen
@onready var background:            TextureRect  = $Background
@onready var dm:                    Node         = $DialogueManager
@onready var dialogue_box:          Control      = $DialogueBox
@onready var character_portrait_1:  TextureRect  = $CharacterPortrait1
@onready var character_portrait_2:  TextureRect  = $CharacterPortrait2
@onready var plashka_rect:          ColorRect    = $PlashkaLayer/PlashkaRect
@onready var plashka_label:         Label        = $PlashkaLayer/PlashkaLabel
@onready var minigame_layer:        CanvasLayer  = $MinigameLayer
@onready var minigame_ui_rect:      TextureRect  = $MinigameLayer/UIRect

# ==============================================================
# ДАННЫЕ МИНИ-ИГРЫ А — «Заполни анкету» (4 вопроса)
# ==============================================================
const MINIGAME_A_DATA: Array[Dictionary] = [
    {
        "question":       "Чем занимаешься в свободное время?",
        "options":        ["Сижу дома",
                           "Читаю фэнтези, изучаю мифологию",
                           "Путешествую по другим мирам"],
        "correct_index":  1,
        "reactions": [
            "Ну и что? Все сидят дома...",
            "Честно и интересно. Мне нравится.",
			"Это звучит как будто я схожу с ума."
        ]
    },
    {
        "question":       "Что ищешь?",
        "options":        ["Серьёзные отношения с умным человеком",
                           "Принца на белом коне",
                           "Не знаю, посмотрим"],
        "correct_index":  0,
        "reactions": [
            "Прямо и по делу. Хорошо.",
            "Нет. Просто нет.",
			"Это значит «мне всё равно». Плохой сигнал."
        ]
    },
    {
        "question":       "Опиши себя в трёх словах",
        "options":        ["Тихая, умная, одинокая",
                           "Начитанная, вдумчивая, со странностями",
                           "Просто обычная девушка"],
        "correct_index":  1,
        "reactions": [
            "Последнее слово убери. Пожалуйста.",
            "Странности — это не минус. Это характер.",
			"Я НЕ обычная. Ну то есть... в хорошем смысле."
        ]
    },
    {
        "question":       "Твоя любимая книга?",
        "options":        ["(оставить пустым)",
                           "Властелин колец. Толкин создал целый язык.",
                           "Люблю всё подряд"],
        "correct_index":  1,
        "reactions": [
            "Пустое поле — это как пустой взгляд. Нет.",
            "Это правда. И это прекрасно.",
			"Это значит ничего конкретно. Скучно."
        ]
    }
]

# ==============================================================
# ДАННЫЕ МИНИ-ИГРЫ Б — «Первое сообщение» (3 варианта)
# ==============================================================
const MINIGAME_B_DATA: Array[Dictionary] = [
    {
        "message":          "Хай",
        "response_speaker": "АРСЕНИЙ",
        "response_text":    "...",
        "alisa_reaction":   "Это всё что ты придумал?!",
        "unicorn_comment":  "",
        "is_correct":       false
    },
    {
        "message":          "О! Я как раз думала об этой книге. Что скажешь о концовке?",
        "response_speaker": "АРСЕНИЙ",
        "response_text":    "Честно? Меня она разбила. Давай встретимся и поговорим?",
        "alisa_reaction":   "",
        "unicorn_comment":  "",
        "is_correct":       true
    },
    {
        "message":          "Приветствую, странник! Готов к квесту знакомства?",
        "response_speaker": "АРСЕНИЙ",
        "response_text":    "Хаха :)",
        "alisa_reaction":   "Он написал «хаха» со смайлом. Я в панике. Это хорошо или плохо?",
        "unicorn_comment":  "Думаю «хаха» — это хорошо.",
        "is_correct":       false
    }
]

var _minigame_a_score: int = 0

# ==============================================================
# READY
# ==============================================================
func _ready() -> void:
    if background and bg_cafe_luna:
        background.texture = bg_cafe_luna

    if character_portrait_1: character_portrait_1.visible = false
    if character_portrait_2: character_portrait_2.visible = false
    minigame_layer.visible   = false
    minigame_ui_rect.visible = false

    plashka_label.modulate.a = 0.0
    plashka_rect.color       = Color(0, 0, 0, 0.0)

    if dm:
        if dm.has_signal("dialogue_finished"):
            dm.dialogue_finished.connect(_on_dialogue_finished)
        if dm.has_signal("line_changed"):
            dm.line_changed.connect(_on_dialogue_line_changed)

    _begin_fade_in()

    var _home := HomeOverlay.new()
    _home.current_scene_path = "res://scenes/mission_2.tscn"
    add_child(_home)

# ==============================================================
# INPUT — пропуск реплик только в диалоговых фазах
# ==============================================================
func _input(event: InputEvent) -> void:
    # === ЗАГЛУШКА ОТ HOME OVERLAY ===
    if get_tree().root.has_meta("dialogue_input_blocked") and \
       get_tree().root.get_meta("dialogue_input_blocked"):
        return
    var is_dialogue_active: bool = (
        _phase == Phase.DIALOGUE_INTRO   or
        _phase == Phase.DIALOGUE_BETWEEN or
        _phase == Phase.DIALOGUE_OUTRO
     )
    
    if not is_dialogue_active:
        return

    var is_tap: bool = event is InputEventScreenTouch and event.pressed
    var is_click: bool = (
        event is InputEventMouseButton and 
        event.pressed and 
        event.button_index == MOUSE_BUTTON_LEFT
    )

    if (is_tap or is_click) and dm and dm.has_method("advance"):
        dm.advance()

# ==============================================================
# ФАЗА 1 — FADE IN
# ==============================================================
func _begin_fade_in() -> void:
    _phase = Phase.FADE_IN
    black_screen.modulate.a = 1.0
    black_screen.visible    = true

    var tween: Tween = create_tween()
    tween.tween_property(black_screen, "modulate:a", 0.0, 1.0)
    await tween.finished

    black_screen.visible = false
    _start_dialogue_intro()

# ==============================================================
# ФАЗА 2 — ДИАЛОГ-ВСТУПЛЕНИЕ (кафе)
# ==============================================================
func _start_dialogue_intro() -> void:
    _phase = Phase.DIALOGUE_INTRO

    if not dm or not dm.has_method("start"):
        push_warning("Mission2: DialogueManager не найден, пропускаем диалог.")
        _start_minigame_a()
        return

    var lines: Array[Dictionary] = [
        {
            "speaker":    "АЛИСА",
            "text":       "Ну почему... Почему все находят кого-то, а я – нет?",
            "portrait_1": portrait_alisa_sad,
            "pos_1":      Vector2(0, 0),
            "portrait_2": null,
            "pos_2":      Vector2.ZERO
        },
        {
            "speaker":    "БАРИСТА",
            "text":       "Э-э-э... домашних животных нельзя...",
            "portrait_1": portrait_barista,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_unicorn_neutral,
            "pos_2":      Vector2(0, 0),
        },
        {
            "speaker":    "ЕДИНОРОГ",
            "text":       "Я не домашнее животное. Я ищу Алису.",
            "portrait_1": portrait_unicorn_curious,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_alisa_sad,
            "pos_2":      Vector2(0, 0),
        },
        {
            "speaker":    "АЛИСА",
            "text":       "Единорог?! Я думала, вы только в книжках существуете...",
            "portrait_1": portrait_alisa_surprised,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_unicorn_neutral,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "ЕДИНОРОГ",
            "text":       "В книжках мы тоже, но я вот – живой. Ты Алиса? Макс сказал, ты разбираешься в магии.",
            "portrait_1": portrait_unicorn_curious,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_alisa_surprised,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "АЛИСА",
            "text":       "Потрясающе! У тебя рог точь-в-точь как на обложке Хроник Нарнии! Да, я Алиса! Макс прислал тебя?",
            "portrait_1": portrait_alisa_excited,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_unicorn_neutral,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "ЕДИНОРОГ",
            "text":       "Я помог ему с учёбой. А теперь ищу дорогу домой. Но сначала... что за тоска у тебя в глазах? Она почти осязаема.",
            "portrait_1": portrait_unicorn_curious,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_alisa_excited,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "АЛИСА",
            "text":       "Ох... Я просто устала быть одна. Все подруги с кем-то знакомятся, ходят на свидания... А я сижу тут, читаю фэнтези.",
            "portrait_1": portrait_alisa_sad,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_unicorn_neutral,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "ЕДИНОРОГ",
            "text":       "Воображаемые персонажи – отличная компания. У меня друг дракон, мы с ним... ой. Неважно.",
            "portrait_1": portrait_unicorn_curious,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_alisa_sad,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "АЛИСА",
            "text":       "У тебя есть друг дракон?! Настоящий?!",
            "portrait_1": portrait_alisa_excited,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_unicorn_neutral,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "ЕДИНОРОГ",
            "text":       "Сейчас не об этом. Давай решать твою проблему. Как люди находят себе пару? В моём лесу мы просто трубим рогом, и все собираются.",
            "portrait_1": portrait_unicorn_curious,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_alisa_excited,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "АЛИСА",
            "text":       "Здесь так не работает. Есть приложения для знакомств. Но я не умею преподносить себя... Всегда пишу что-то не то.",
            "portrait_1": portrait_alisa_sad,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_unicorn_neutral,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "ЕДИНОРОГ",
            "text":       "Покажи мне это «приложение». Будем колдовать вместе.",
            "portrait_1": portrait_unicorn_wise,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_alisa_sad,
            "pos_2":      Vector2(0, 0)
        }
    ]
    dm.start(lines)

# ==============================================================
# ОБРАБОТЧИК СМЕНЫ СТРОКИ ДИАЛОГА
# ==============================================================
func _on_dialogue_line_changed(line_data: Dictionary) -> void:
    if character_portrait_1:
        var tex_1: Texture2D = line_data.get("portrait_1", null)
        if tex_1 == null:
            character_portrait_1.visible = false
        else:
            character_portrait_1.texture         = tex_1
            character_portrait_1.visible         = true
            character_portrait_1.global_position = line_data.get("pos_1", Vector2.ZERO)

    if character_portrait_2:
        var tex_2: Texture2D = line_data.get("portrait_2", null)
        if tex_2 == null:
            character_portrait_2.visible = false
        else:
            character_portrait_2.texture         = tex_2
            character_portrait_2.visible         = true
            character_portrait_2.global_position = line_data.get("pos_2", Vector2.ZERO)

    # Показ профиля Арсения поверх диалога (только во время диалогов, не мини-игр)
    var ui_key: String = line_data.get("show_ui", "")
    match ui_key:
        "profile_arseniy":
            if ui_app_profile_arseniy:
                minigame_ui_rect.texture = ui_app_profile_arseniy
                minigame_ui_rect.visible = true
                minigame_layer.visible   = true
               
        "profile_alisa":
            if ui_profile_alisa:
                minigame_ui_rect.texture = ui_profile_alisa
                minigame_ui_rect.visible = true
                minigame_layer.visible   = true 
                
        "":
            minigame_ui_rect.visible = false
            if _phase != Phase.MINIGAME_A and _phase != Phase.MINIGAME_B:
                minigame_layer.visible = false
       
# ==============================================================
# РОУТЕР ЗАВЕРШЕНИЯ ДИАЛОГОВ
# ==============================================================
func _on_dialogue_finished() -> void:
    if character_portrait_1: character_portrait_1.visible = false
    if character_portrait_2: character_portrait_2.visible = false

    match _phase:
        Phase.DIALOGUE_INTRO:
            _start_minigame_a()
        Phase.DIALOGUE_BETWEEN:
            _start_minigame_b()
        Phase.DIALOGUE_OUTRO:
            _show_plashka("САХАРА. 38°C В ТЕНИ.\nТРЕТИЙ ДЕНЬ БЕЗ ВОДЫ.")

# ==============================================================
# ФАЗА 3 — МИНИ-ИГРА А: «Заполни анкету»
# ==============================================================
func _start_minigame_a() -> void:
    _phase = Phase.MINIGAME_A
    _minigame_a_score = 0

    minigame_layer.visible = true
    minigame_layer.layer = 210          # ← ВЫШЕ HomeOverlay (200)
    minigame_ui_rect.visible = false

    if is_instance_valid(_mg_questionnaire):
        _mg_questionnaire.queue_free()

    _mg_questionnaire = preload("res://scenes/minigame_profile_questionnaire.tscn").instantiate() as MinigameProfileQuestionnaire
    minigame_layer.add_child(_mg_questionnaire)
    
    _mg_questionnaire.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _mg_questionnaire.mouse_filter = Control.MOUSE_FILTER_IGNORE

    _mg_questionnaire.setup(
        MINIGAME_A_DATA,
        portrait_alisa_excited,
        portrait_alisa_happy,
        portrait_alisa_sad
    )
    _mg_questionnaire.completed.connect(_on_minigame_a_completed)


func _on_minigame_a_completed(score: int) -> void:
    _minigame_a_score = score

    if is_instance_valid(_mg_questionnaire):
        _mg_questionnaire.queue_free()
        _mg_questionnaire = null

    # Меньше 2 правильных → полный перезапуск анкеты
    if score < 2:
        _start_minigame_a()
        return

    # Успех — прячем слой и запускаем диалог с лайком от Арсения
    minigame_layer.visible = false
    _start_dialogue_between()

# ==============================================================
# ФАЗА 4 — ДИАЛОГ-СВЯЗКА (лайк от Арсения)
# ==============================================================
func _start_dialogue_between() -> void:
    _phase = Phase.DIALOGUE_BETWEEN

    if not dm or not dm.has_method("start"):
        push_warning("Mission2: DialogueManager не найден.")
        _start_minigame_b()
        return

    var lines: Array[Dictionary] = [
        {
            "show_ui":    "profile_alisa"
        },
        {
            "speaker":    "АЛИСА",
            "text":       "Готово... Ой, тут сразу кто-то лайкнул!",
            "portrait_1": portrait_alisa_excited,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_unicorn_neutral,
            "pos_2":      Vector2(0, 0),
        },
        {
            "show_ui":    "profile_arseniy"
        },
        {
            "speaker":    "АЛИСА",
            "text":       "Арсений... У него фото со звёздами. И в описании: «Ночую на крыше, наблюдаю за галактиками. Ищу того, кто тоже смотрит вверх». Ого...",
            "portrait_1": portrait_alisa_excited,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_unicorn_neutral,
            "pos_2":      Vector2(0, 0),
        },
        {
            "speaker":    "ЕДИНОРОГ",
            "text":       "Звёзды и магия всегда рядом. Он смотрит в небо – ты читаешь о других мирах. Это хорошее совпадение.",
            "portrait_1": portrait_unicorn_wise,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_alisa_excited,
            "pos_2":      Vector2(0, 0),
            "show_ui":    ""
        },
        {
            "speaker":    "АЛИСА",
            "text":       "Что мне написать?! Я никогда не пишу первая! А вдруг я всё испорчу?",
            "portrait_1": portrait_alisa_sad,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_unicorn_wise,
            "pos_2":      Vector2(0, 0),
            "show_ui":    ""
        }
    ]
    dm.start(lines)

# ==============================================================
# ФАЗА 5 — МИНИ-ИГРА Б: «Первое сообщение»
# ==============================================================
func _start_minigame_b() -> void:
    _phase = Phase.MINIGAME_B

    minigame_layer.visible = true
    minigame_layer.layer = 210          # ← ВЫШЕ HomeOverlay
    minigame_ui_rect.visible = false

    if is_instance_valid(_mg_first_message):
        _mg_first_message.queue_free()

    _mg_first_message = preload("res://scenes/minigame_first_message.tscn").instantiate() as MinigameFirstMessage
    minigame_layer.add_child(_mg_first_message)
    
    _mg_first_message.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _mg_first_message.mouse_filter = Control.MOUSE_FILTER_IGNORE

    _mg_first_message.setup(MINIGAME_B_DATA, ui_app_profile_arseniy)
    _mg_first_message.completed.connect(_on_minigame_b_completed)


## Вызывается когда MinigameFirstMessage эмитирует completed()
## (только при правильном выборе — все повторы обрабатываются внутри мини-игры)
func _on_minigame_b_completed() -> void:
    if is_instance_valid(_mg_first_message):
        _mg_first_message.queue_free()
        _mg_first_message = null

    minigame_layer.visible   = false
    minigame_ui_rect.visible = false
    _start_dialogue_outro()

# ==============================================================
# ФАЗА 6 — ФИНАЛЬНЫЙ ДИАЛОГ (разговор о портале → прощание)
# ==============================================================
func _start_dialogue_outro() -> void:
    _phase = Phase.DIALOGUE_OUTRO

    if not dm or not dm.has_method("start"):
        push_warning("Mission2: DialogueManager не найден.")
        _show_plashka("САХАРА. 38°C В ТЕНИ.\nТРЕТИЙ ДЕНЬ БЕЗ ВОДЫ.")
        return

    var lines: Array[Dictionary] = [
        {
            "speaker":    "АЛИСА",
            "text":       "Он предлагает встретиться. Завтра. В книжном.",
            "portrait_1": portrait_alisa_happy,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_unicorn_neutral,
            "pos_2":      Vector2(0, 0),
            "show_ui":    ""
        },
        {
            "speaker":    "ЕДИНОРОГ",
            "text":       "Это хороший знак?",
            "portrait_1": portrait_unicorn_curious,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_alisa_happy,
            "pos_2":      Vector2(0, 0),
            "show_ui":    ""
        },
        {
            "speaker":    "АЛИСА",
            "text":       "Это идеальный знак. Я никогда не думала, что мне поможет единорог.",
            "portrait_1": portrait_alisa_laughing,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_unicorn_neutral,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "ЕДИНОРОГ",
            "text":       "Я никогда не думал, что попаду в мир без магии и найду тебе парня.",
            "portrait_1": portrait_unicorn_curious,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_alisa_laughing,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "АЛИСА",
            "text":       "Слушай... ты говорил, что ищешь дорогу домой. Портал?",
            "portrait_1": portrait_alisa_serious,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_unicorn_neutral,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "ЕДИНОРОГ",
            "text":       "Да. Мне нужно в Волшебный лес. Ты что-то знаешь?",
            "portrait_1": portrait_unicorn_curious,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_alisa_serious,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "АЛИСА",
            "text":       "Я читала на форуме «Аномалии Земли»... В пустыне Сахара последние две недели наблюдают светящиеся врата в песке. Мираж не длится две недели, правда?",
            "portrait_1": portrait_alisa_excited,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_unicorn_neutral,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "АЛИСА",
            "text":       "Мой дядя – Игорь. Он в той экспедиции, геолог. Немного сумасшедший, но лучший в своём деле. Правда, от него три дня нет вестей...",
            "portrait_1": portrait_alisa_serious,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_unicorn_neutral,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "АЛИСА",
            "text":       "Иди на окраину города, там есть старая обсерватория. В подвале – портал. Дед был исследователем аномалий — он писал о разрыве ткани реальности под ней.",
            "portrait_1": portrait_alisa_serious,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_unicorn_curious,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "ЕДИНОРОГ",
            "text":       "Ты удивительная, Алиса. Спасибо.",
            "portrait_1": portrait_unicorn_wise,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_alisa_serious,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "АЛИСА",
            "text":       "Это тебе спасибо. Без тебя я бы так и сидела тут одна со своим латте. Передай дяде Игорю привет. И спаси его, если что.",
            "portrait_1": portrait_alisa_happy,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_unicorn_wise,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "ЕДИНОРОГ",
            "text":       "Обещаю.",
            "portrait_1": portrait_unicorn_curious,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_alisa_happy,
            "pos_2":      Vector2(0, 0)
        }
    ]
    dm.start(lines)

# ==============================================================
# ФАЗА 7 — ПЛАШКА «САХАРА…»
# ==============================================================
func _show_plashka(text: String) -> void:
    _phase = Phase.PLASHKA
    plashka_label.text = text

    if background and bg_sahara:
        background.texture = bg_sahara

    await get_tree().create_timer(background_view_time).timeout

    var tw: Tween = create_tween()
    tw.tween_property(plashka_rect,  "color",         Color(0, 0, 0, 0.85), 0.5)
    tw.parallel().tween_property(plashka_label, "modulate:a", 1.0,          0.5)
    await tw.finished

    await get_tree().create_timer(2.5).timeout
    _begin_fade_out()

# ==============================================================
# ФАЗА 8 — FADE OUT → Mission 3
# ==============================================================
func _begin_fade_out() -> void:
    _phase = Phase.FADE_OUT

    black_screen.visible    = true
    black_screen.modulate.a = 0.0

    var tween: Tween = create_tween()
    tween.tween_property(black_screen, "modulate:a", 1.0, 1.0)
    await tween.finished

    mission_completed.emit()
    get_tree().change_scene_to_file("res://scenes/mission_3.tscn")
