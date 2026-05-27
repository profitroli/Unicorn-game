class_name Mission2Script
extends Node2D

# ==============================================================
# СИГНАЛЫ
# ==============================================================
signal mission_completed

# ==============================================================
# ФАЗЫ — расширенный паттерн из prologue.gd
# ==============================================================
enum Phase {
    FADE_IN,
    DIALOGUE_INTRO,    # Кафе: Алиса одна → появление Единорога → «Покажи приложение»
    MINIGAME_A,        # «Заполни анкету» (4 вопроса с вариантами)
    DIALOGUE_BETWEEN,  # Лайк от Арсения → решение написать
    MINIGAME_B,        # «Первое сообщение»
    DIALOGUE_OUTRO,    # Разговор о портале → прощание
    PLASHKA,           # «САХАРА. 38°C В ТЕНИ. ТРЕТИЙ ДЕНЬ БЕЗ ВОДЫ.»
    FADE_OUT
}

var _phase: Phase = Phase.FADE_IN

# ==============================================================
# PLACEHOLDER-ПЕРЕМЕННЫЕ ДЛЯ ВИЗУАЛЬНЫХ АСЕТОВ
# Заменяй пути к файлам через Инспектор или прямо здесь.
# ==============================================================

@export_category("Backgrounds")
## Фон: кафе «Луна» — приглушённый свет, гирлянды
@export var bg_cafe_luna: Texture2D
@export var ui_app_profile_arseniy: Texture2D
## Длительность показа фона перед плашкой (сек)
@export var background_view_time: float = 1.5

@export_category("Portraits — Алиса")
## Алиса грустная (смотрит в телефон, одна)
@export var portrait_alisa_sad: Texture2D
## Алиса удивлённая (видит Единорога)
@export var portrait_alisa_surprised: Texture2D
## Алиса восторженная (дракон! звёзды! книги!)
@export var portrait_alisa_excited: Texture2D
## Алиса счастливая (после ответа Арсения)
@export var portrait_alisa_happy: Texture2D
## Алиса серьёзная (разговор о портале)
@export var portrait_alisa_serious: Texture2D
## Алиса смеётся
@export var portrait_alisa_laughing: Texture2D

@export_category("Portraits — Единорог")
## Нейтральный / спокойный
@export var portrait_unicorn_neutral: Texture2D
## Любопытный / озадаченный
@export var portrait_unicorn_curious: Texture2D
## Мудрый / торжественный
@export var portrait_unicorn_wise: Texture2D

@export_category("Portraits — Прочие")
## Бариста кафе (пытается запретить вход)
@export var portrait_barista: Texture2D

@export_category("UI Assets — Мини-игры")
## Заполненный профиль Алисы в приложении знакомств
@export var ui_profile_alisa: Texture2D
## Профиль Арсения: фото с телескопом на крыше, 19 лет
@export var ui_profile_arseniy: Texture2D
## Экран чата — сообщение принято, «пишет...»
@export var ui_chat_typing: Texture2D

# ==============================================================
# КЭШИРОВАННЫЕ ССЫЛКИ НА УЗЛЫ
# Все пути — точная копия структуры prologue.tscn
# ==============================================================
@onready var black_screen: ColorRect        = $FadeLayer/BlackScreen
@onready var background: TextureRect        = $Background
@onready var dm: Node                       = $DialogueManager
@onready var dialogue_box: Control          = $DialogueBox
@onready var character_portrait_1: TextureRect = $CharacterPortrait1
@onready var character_portrait_2: TextureRect = $CharacterPortrait2
@onready var plashka_rect: ColorRect        = $PlashkaLayer/PlashkaRect
@onready var plashka_label: Label           = $PlashkaLayer/PlashkaLabel
## Слой для UI мини-игр — поверх всего, кроме диалога
@onready var minigame_layer: CanvasLayer    = $MinigameLayer
## TextureRect внутри MinigameLayer для показа профилей / UI
@onready var minigame_ui_rect: TextureRect  = $MinigameLayer/UIRect

# ==============================================================
# ДАННЫЕ МИНИ-ИГРЫ А — «Заполни анкету» (4 вопроса)
# Источник: ЕДИНОРОГ.docx → ЧАСТЬ А
# ==============================================================
const MINIGAME_A_DATA: Array[Dictionary] = [
    {
        "question":       "Чем занимаешься в свободное время?",
        "options": [
            "Сижу дома",
            "Читаю фэнтези, изучаю мифологию",
            "Путешествую по другим мирам"
        ],
        "correct_index":  1,
        "reactions": [
            "Ну и что? Все сидят дома...",
            "Честно и интересно. Мне нравится.",
            "Это звучит как будто я схожу с ума."
        ]
    },
    {
        "question":       "Что ищешь?",
        "options": [
            "Серьёзные отношения с умным человеком",
            "Принца на белом коне",
            "Не знаю, посмотрим"
        ],
        "correct_index":  0,
        "reactions": [
            "Прямо и по делу. Хорошо.",
            "Нет. Просто нет.",
            "Это значит «мне всё равно». Плохой сигнал."
        ]
    },
    {
        "question":       "Опиши себя в трёх словах",
        "options": [
            "Тихая, умная, одинокая",
            "Начитанная, вдумчивая, со странностями",
            "Просто обычная девушка"
        ],
        "correct_index":  1,
        "reactions": [
            "Последнее слово убери. Пожалуйста.",
            "Странности – это не минус. Это характер.",
            "Я НЕ обычная. Ну то есть... в хорошем смысле."
        ]
    },
    {
        "question":       "Твоя любимая книга?",
        "options": [
            "(оставить пустым)",
            "Властелин колец. Толкин создал целый язык.",
            "Люблю всё подряд"
        ],
        "correct_index":  1,
        "reactions": [
            "Пустое поле — это как пустой взгляд. Нет.",
            "Это правда. И это прекрасно.",
            "Это значит ничего конкретно. Скучно."
        ]
    }
]

# ==============================================================
# ДАННЫЕ МИНИ-ИГРЫ Б — «Первое сообщение»
# Источник: ЕДИНОРОГ.docx → ЧАСТЬ Б
# ==============================================================
const MINIGAME_B_DATA: Array[Dictionary] = [
    {
        "message":          "Хай",
        "response_speaker": "АРСЕНИЙ",
        "response_text":    "...",
        "alisa_reaction":   "Это всё, что ты придумал?!",
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
        "unicorn_comment":  "Думаю, «хаха» – это хорошо.",
        "is_correct":       false
    }
]

# Счётчик правильных ответов в мини-игре А
var _minigame_a_score: int = 0

# ==============================================================
# READY
# ==============================================================
func _ready() -> void:
    # Применяем фон кафе, если текстура назначена через Инспектор
    if background and bg_cafe_luna:
        background.texture = bg_cafe_luna

    # Скрываем портреты и UI до старта
    if character_portrait_1: character_portrait_1.visible = false
    if character_portrait_2: character_portrait_2.visible = false
    minigame_layer.visible = false
    minigame_ui_rect.visible = false

    # Плашка — невидима
    plashka_label.modulate.a = 0.0
    plashka_rect.color = Color(0, 0, 0, 0.0)

    # Подписываемся на сигналы DialogueManager
    # Структура — идентично prologue.gd
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
# INPUT — пропуск реплик, только во время диалоговых фаз
# Копия _input из prologue.gd
# ==============================================================
func _input(event: InputEvent) -> void:
  var is_dialogue_phase: bool = (
    _phase == Phase.DIALOGUE_INTRO   or
    _phase == Phase.DIALOGUE_BETWEEN or
    _phase == Phase.DIALOGUE_OUTRO
  )
  if not is_dialogue_phase:
    return

  var is_tap: bool = event is InputEventScreenTouch and event.pressed
  var is_click: bool = (
    event is InputEventMouseButton
    and event.pressed
    and event.button_index == MOUSE_BUTTON_LEFT
  )

  if (is_tap or is_click) and dm and dm.has_method("advance"):
    dm.advance()

# ==============================================================
# ФАЗА 1 — FADE IN
# Идентично mission_1.gd: чёрный экран → прозрачность → старт
# ==============================================================
func _begin_fade_in() -> void:
    _phase = Phase.FADE_IN

    black_screen.modulate.a = 1.0
    black_screen.visible = true

    var tween: Tween = create_tween()
    tween.tween_property(black_screen, "modulate:a", 0.0, 1.0)
    await tween.finished

    black_screen.visible = false
    _start_dialogue_intro()

# ==============================================================
# ФАЗА 2 — ДИАЛОГ-ВСТУПЛЕНИЕ
# Источник: ЕДИНОРОГ.docx → начало Миссии 2 до «Покажи приложение»
# Фон: кафе «Луна». Алиса грустная → Единорог входит → знакомятся
# ==============================================================
func _start_dialogue_intro() -> void:
    _phase = Phase.DIALOGUE_INTRO

    if not dm or not dm.has_method("start"):
        push_warning("Mission2: DialogueManager не найден, пропускаем диалог.")
        _start_minigame_a()
        return

    # Структура словарей — 1-в-1 как в prologue.gd
    # Поле "show_ui": имя UI-асета из @export для показа в _on_dialogue_line_changed
    var lines: Array[Dictionary] = [
        # --- Алиса одна, смотрит в телефон ---
        {
            "speaker":    "АЛИСА",
            "text":       "Ну почему... Почему все находят кого-то, а я – нет?",
            "portrait_1": portrait_alisa_sad,
            "pos_1":      Vector2(0, 0),
            "portrait_2": null,
            "pos_2":      Vector2.ZERO
        },
        # --- Единорог входит, бариста реагирует ---
        {
            "speaker":    "БАРИСТА",
            "text":       "Э-э-э... домашних животных нельзя...",
            "portrait_1": portrait_barista,          # portrait_barista — placeholder
            "pos_1":      Vector2(0, 0),
            "portrait_2": null,
            "pos_2":      Vector2.ZERO
        },
        {
            "speaker":    "ЕДИНОРОГ",
            "text":       "Я не домашнее животное. Я ищу Алису.",
            "portrait_1": portrait_unicorn_neutral,
            "pos_1":      Vector2(0, 0),
            "portrait_2": null,
            "pos_2":      Vector2.ZERO
        },
        # --- Алиса замечает, удивляется ---
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
            "portrait_1": portrait_unicorn_neutral,
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
        # --- Алиса открывается ---
        {
            "speaker":    "АЛИСА",
            "text":       "Ох... Я просто устала быть одна. Все подруги с кем-то знакомятся, ходят на свидания... А я сижу тут, читаю фэнтези и разговариваю с воображаемыми персонажами.",
            "portrait_1": portrait_alisa_sad,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_unicorn_curious,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "ЕДИНОРОГ",
            "text":       "Воображаемые персонажи – отличная компания. У меня друг дракон, мы с ним... ой. Неважно.",
            "portrait_1": portrait_unicorn_neutral,
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
            "portrait_2": portrait_unicorn_curious,
            "pos_2":      Vector2(0, 0)
        },
        # --- Триггер мини-игры А ---
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
# ОБРАБОТЧИК СИГНАЛА: смена строки диалога
# Расширен по сравнению с prologue.gd: обрабатывает поле "show_ui"
# ==============================================================
func _on_dialogue_line_changed(line_data: Dictionary) -> void:
    # --- Портрет 1 (идентично prologue.gd) ---
    if character_portrait_1:
        var tex_1: Texture2D = line_data.get("portrait_1", null)
        if tex_1 == null:
            character_portrait_1.visible = false
        else:
            character_portrait_1.texture = tex_1
            character_portrait_1.visible = true
            character_portrait_1.global_position = line_data.get("pos_1", Vector2.ZERO)

    # --- Портрет 2 (идентично prologue.gd) ---
    if character_portrait_2:
        var tex_2: Texture2D = line_data.get("portrait_2", null)
        if tex_2 == null:
            character_portrait_2.visible = false
        else:
            character_portrait_2.texture = tex_2
            character_portrait_2.visible = true
            character_portrait_2.global_position = line_data.get("pos_2", Vector2.ZERO)

    # --- РАСШИРЕНИЕ: показ UI-картинки (профиль Арсения и т.д.) ---
    # Поле "show_ui" содержит имя @export-переменной с текстурой.
    # Добавляй случаи сюда по мере появления новых UI-асетов.
    var ui_key: String = line_data.get("show_ui", "")
    match ui_key:
        "profile_arseniy":
            # Показываем профиль Арсения поверх диалога
            if ui_app_profile_arseniy:             # placeholder: ui_app_profile_arseniy
                minigame_ui_rect.texture = ui_app_profile_arseniy
                minigame_ui_rect.visible = true
                minigame_layer.visible   = true
        "":
            # Нет UI — скрываем слой, если он был показан
            minigame_ui_rect.visible = false
            if _phase != Phase.MINIGAME_A and _phase != Phase.MINIGAME_B:
                minigame_layer.visible = false

# ==============================================================
# ОБРАБОТЧИК СИГНАЛА: диалог закончен → роутинг по фазам
# ==============================================================
func _on_dialogue_finished() -> void:
    # Скрываем портреты
    if character_portrait_1: character_portrait_1.visible = false
    if character_portrait_2: character_portrait_2.visible = false

    # Переходим в следующую фазу в зависимости от текущей
    match _phase:
        Phase.DIALOGUE_INTRO:
            _start_minigame_a()
        Phase.DIALOGUE_BETWEEN:
            _start_minigame_b()
        Phase.DIALOGUE_OUTRO:
            _show_plashka("САХАРА. 38°C В ТЕНИ.\nТРЕТИЙ ДЕНЬ БЕЗ ВОДЫ.")

# ==============================================================
# ФАЗА 3 — МИНИ-ИГРА А: «Заполни анкету»
# Источник: ЕДИНОРОГ.docx → ЧАСТЬ А
# Данные: MINIGAME_A_DATA (4 вопроса, правильный + реакция)
# ==============================================================
func _start_minigame_a() -> void:
    _phase = Phase.MINIGAME_A
    _minigame_a_score = 0

    minigame_layer.visible = true

    # TODO: создай UI мини-игры A и подключи сигнал завершения.
    # Когда все вопросы отвечены — вызывай:
    #   _on_minigame_a_completed(score: int)
    #
    # Данные для UI: MINIGAME_A_DATA
    # Пример подключения (если есть отдельная сцена мини-игры):
    #   var mg_a = preload("res://scenes/minigame_questionnaire.tscn").instantiate()
    #   add_child(mg_a)
    #   mg_a.setup(MINIGAME_A_DATA)
    #   mg_a.completed.connect(_on_minigame_a_completed)

    push_warning("Mission2: MINIGAME_A — заглушка, замени на реальный UI.")
    await get_tree().create_timer(0.1).timeout
    _on_minigame_a_completed(4)  # ЗАГЛУШКА: 4/4 правильных

# Вызывается мини-игрой A по сигналу.
# score: количество правильных ответов из 4.
func _on_minigame_a_completed(score: int) -> void:
    _minigame_a_score = score

    if score < 2:
        # Пересдача — перезапускаем мини-игру A
        _start_minigame_a()
        return

    # Убираем мини-игровый слой
    minigame_layer.visible   = false
    minigame_ui_rect.visible = false

    _start_dialogue_between()

# ==============================================================
# ФАЗА 4 — ДИАЛОГ-СВЯЗКА
# Источник: ЕДИНОРОГ.docx → «ДИАЛОГ МЕЖДУ ЧАСТЯМИ»
# Лайк от Арсения, Алиса волнуется, показываем его профиль
# ==============================================================
func _start_dialogue_between() -> void:
    _phase = Phase.DIALOGUE_BETWEEN

    if not dm or not dm.has_method("start"):
        push_warning("Mission2: DialogueManager не найден.")
        _start_minigame_b()
        return

    var lines: Array[Dictionary] = [
        # show_ui = "profile_arseniy" → _on_dialogue_line_changed покажет ui_app_profile_arseniy
        {
            "speaker":    "АЛИСА",
            "text":       "Готово... Ой, тут сразу кто-то лайкнул!",
            "portrait_1": portrait_alisa_excited,
            "pos_1":      Vector2(0, 0),
            "portrait_2": null,
            "pos_2":      Vector2.ZERO,
            "show_ui":    "profile_arseniy"          # ui_app_profile_arseniy — placeholder
        },
        {
            "speaker":    "АЛИСА",
            "text":       "Арсений... У него фото со звёздами. И в описании: «Ночую на крыше, наблюдаю за галактиками. Ищу того, кто тоже смотрит вверх». Ого...",
            "portrait_1": portrait_alisa_excited,
            "pos_1":      Vector2(0, 0),
            "portrait_2": null,
            "pos_2":      Vector2.ZERO,
            "show_ui":    "profile_arseniy"
        },
        {
            "speaker":    "ЕДИНОРОГ",
            "text":       "Звёзды и магия всегда рядом. Он смотрит в небо – ты читаешь о других мирах. Это хорошее совпадение.",
            "portrait_1": portrait_unicorn_wise,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_alisa_excited,
            "pos_2":      Vector2(0, 0),
            "show_ui":    ""                         # убираем профиль
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
# Источник: ЕДИНОРОГ.docx → ЧАСТЬ Б
# Данные: MINIGAME_B_DATA (3 варианта, один правильный)
# ==============================================================
func _start_minigame_b() -> void:
    _phase = Phase.MINIGAME_B

    minigame_layer.visible = true

    # TODO: создай UI мини-игры Б и подключи сигнал завершения.
    # Когда игрок выбрал вариант — вызывай:
    #   _on_minigame_b_option_selected(option_index: int)
    #
    # Данные для UI: MINIGAME_B_DATA
    # Пример:
    #   var mg_b = preload("res://scenes/minigame_message.tscn").instantiate()
    #   add_child(mg_b)
    #   mg_b.setup(MINIGAME_B_DATA)
    #   mg_b.option_chosen.connect(_on_minigame_b_option_selected)

    push_warning("Mission2: MINIGAME_B — заглушка, замени на реальный UI.")
    await get_tree().create_timer(0.1).timeout
    _on_minigame_b_option_selected(1)  # ЗАГЛУШКА: правильный вариант (индекс 1)

# Вызывается мини-игрой Б: игрок выбрал вариант с индексом option_index.
func _on_minigame_b_option_selected(option_index: int) -> void:
    if option_index < 0 or option_index >= MINIGAME_B_DATA.size():
        push_error("Mission2: Неверный индекс варианта мини-игры Б: %d" % option_index)
        return

    var chosen: Dictionary = MINIGAME_B_DATA[option_index]

    if not chosen.get("is_correct", false):
        # Неверный выбор — повтор
        _start_minigame_b()
        return

    minigame_layer.visible   = false
    minigame_ui_rect.visible = false

    _start_dialogue_outro()

# ==============================================================
# ФАЗА 6 — ФИНАЛЬНЫЙ ДИАЛОГ
# Источник: ЕДИНОРОГ.docx → «ПРОДОЛЖЕНИЕ ДИАЛОГА» и «прощание»
# Арсений зовёт на встречу → разговор о портале → прощание
# ==============================================================
func _start_dialogue_outro() -> void:
    _phase = Phase.DIALOGUE_OUTRO

    if not dm or not dm.has_method("start"):
        push_warning("Mission2: DialogueManager не найден.")
        _show_plashka("САХАРА. 38°C В ТЕНИ.\nТРЕТИЙ ДЕНЬ БЕЗ ВОДЫ.")
        return

    var lines: Array[Dictionary] = [
        # --- Победа: Арсений зовёт на встречу ---
        {
            "speaker":    "АЛИСА",
            "text":       "Он предлагает встретиться. Завтра. В книжном.",
            "portrait_1": portrait_alisa_happy,
            "pos_1":      Vector2(0, 0),
            "portrait_2": null,
            "pos_2":      Vector2.ZERO,
            "show_ui":    "profile_arseniy"          # ui_app_profile_arseniy — placeholder
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
            "portrait_2": portrait_unicorn_curious,
            "pos_2":      Vector2(0, 0),
            "show_ui":    ""
        },
        {
            "speaker":    "ЕДИНОРОГ",
            "text":       "Я никогда не думал, что попаду в мир без магии и найду тебе парня.",
            "portrait_1": portrait_unicorn_neutral,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_alisa_laughing,
            "pos_2":      Vector2(0, 0)
        },
        # --- Поворот: портал ---
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
            "text":       "Я читала на форуме «Аномалии Земли»... Это такое сообщество, мы собираем странные случаи по миру.",
            "portrait_1": portrait_alisa_serious,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_unicorn_curious,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "ЕДИНОРОГ",
            "text":       "Люди собирают странности? Это... удивительно рационально для вашего вида.",
            "portrait_1": portrait_unicorn_curious,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_alisa_serious,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "АЛИСА",
            "text":       "Так, сейчас... вот! В пустыне Сахара, в районе Тенере, последние две недели наблюдают светящиеся врата в песке. Геологи думают, что это миражи. Но мираж не длится две недели, правда?",
            "portrait_1": portrait_alisa_excited,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_unicorn_curious,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "ЕДИНОРОГ",
            "text":       "Сахара... Где это?",
            "portrait_1": portrait_unicorn_curious,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_alisa_excited,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "АЛИСА",
            "text":       "Африка. Очень далеко и очень жарко. Но у меня есть контакт!",
            "portrait_1": portrait_alisa_excited,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_unicorn_curious,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "ЕДИНОРОГ",
            "text":       "Контакт?",
            "portrait_1": portrait_unicorn_curious,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_alisa_excited,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "АЛИСА",
            "text":       "Мой дядя – Игорь. Он как раз в той экспедиции, геолог. Немного сумасшедший, но лучший в своём деле. Правда, от него три дня нет вестей...",
            "portrait_1": portrait_alisa_serious,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_unicorn_curious,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "ЕДИНОРОГ",
            "text":       "Значит, ему может понадобиться помощь. Как мне попасть в эту Сахару?",
            "portrait_1": portrait_unicorn_wise,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_alisa_serious,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "АЛИСА",
            "text":       "Я отправлю тебя. У меня есть доступ к координатам экспедиции. Закрой глаза.",
            "portrait_1": portrait_alisa_excited,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_unicorn_wise,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "ЕДИНОРОГ",
            "text":       "Что?",
            "portrait_1": portrait_unicorn_curious,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_alisa_excited,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "АЛИСА",
            "text":       "Шучу! Короткая телепортация – это не ко мне. Но я знаю, где они. Иди на окраину города, там есть старая обсерватория. В подвале – портал. В детстве я нашла дневник деда.",
            "portrait_1": portrait_alisa_serious,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_unicorn_curious,
            "pos_2":      Vector2(0, 0)
        },
        {
            "speaker":    "АЛИСА",
            "text":       "Он был исследователем аномалий и писал, что под старой обсерваторией есть разрыв ткани реальности. Я никогда не была там, но уверена — это то, что тебе нужно.",
            "portrait_1": portrait_alisa_serious,
            "pos_1":      Vector2(0, 0),
            "portrait_2": portrait_unicorn_curious,
            "pos_2":      Vector2(0, 0)
        },
        # --- Прощание ---
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
            "portrait_1": portrait_unicorn_neutral,
            "pos_1":      Vector2(0, 0),
            "portrait_2": null,
            "pos_2":      Vector2.ZERO
        }
    ]

    dm.start(lines)

# ==============================================================
# ФАЗА 7 — ПЛАШКА
# Источник: ЕДИНОРОГ.docx → [Затемнение. Плашка: «САХАРА...»]
# Идентично _show_plashka() из prologue.gd
# ==============================================================
func _show_plashka(text: String) -> void:
    _phase = Phase.PLASHKA
    plashka_label.text = text

    await get_tree().create_timer(background_view_time).timeout

    var tw: Tween = create_tween()
    tw.tween_property(plashka_rect,  "color",         Color(0, 0, 0, 0.85), 0.5)
    tw.parallel().tween_property(plashka_label, "modulate:a", 1.0,          0.5)
    await tw.finished

    await get_tree().create_timer(2.5).timeout
    _begin_fade_out()

# ==============================================================
# ФАЗА 8 — FADE OUT → Mission 3
# Идентично mission_1.gd, но затемнение (чёрный)
# ==============================================================
func _begin_fade_out() -> void:
    _phase = Phase.FADE_OUT

    black_screen.visible   = true
    black_screen.modulate.a = 0.0

    var tween: Tween = create_tween()
    tween.tween_property(black_screen, "modulate:a", 1.0, 1.0)
    await tween.finished

    mission_completed.emit()
    get_tree().change_scene_to_file("res://scenes/mission_3.tscn")
