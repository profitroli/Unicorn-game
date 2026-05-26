class_name Mission3Script
extends Node2D

## ==============================================================
## ТОЧКА ВХОДА — Mission 3 начинается СРАЗУ после плашки
## «САХАРА. 38°C В ТЕНИ. ТРЕТИЙ ДЕНЬ БЕЗ ВОДЫ.»,
## которую показывает Mission 2 перед сменой сцены.
## ==============================================================

signal mission_completed

# ==============================================================
# ФАЗЫ — полный цикл Миссии 3
# Источник: ЕДИНОРОГ.docx → МИССИЯ 3 + ЭПИЛОГ
# ==============================================================
enum Phase {
	FADE_IN,
	DIALOGUE_DESERT_INTRO,   # Сахара: Ксения/Игорь → Единорог → «Нужна ваша помощь»
	MINIGAME_WATER,          # «Детектор воды» (сетка 6×6, 8 попыток)
	DIALOGUE_POST_WATER,     # После воды: радость → разговор о портале
	DIALOGUE_PRE_PORTAL,     # Зона аномалии: «Грань тонкая...» перед мини-игрой
	MINIGAME_PORTAL,         # «Найди портал» (6 частиц + ловушки-миражи)
	DIALOGUE_PORTAL_OPEN,    # Портал открылся → «Дом»
	DIALOGUE_FAREWELL,       # Монолог о людях → прощание → «Веру.»
	FADE_TO_FOREST,          # Вспышка белого → лес → затемнение выходит
	DIALOGUE_EPILOGUE,       # Лес на рассвете: Луна, Гром, Астерион
	PLASHKA_FINAL,           # «Земля оказалась странным местом...» + «Конец I части»
	FADE_OUT
}

var _phase: Phase = Phase.FADE_IN

# ==============================================================
# ВИЗУАЛЬНЫЕ АССЕТЫ — ФОНЫ
# ==============================================================
@export_category("Backgrounds")
## Бесконечные золотые дюны, разбитый джип, палатка — точка старта миссии
@export var bg_sahara_desert: Texture2D
## Та же пустыня, но в воздухе плавают светящиеся частицы аномалии
@export var bg_sahara_anomaly: Texture2D
## Закатное солнце окрашивает дюны в оранжевый и розовый — открытый портал
@export var bg_portal_sunset: Texture2D
## Волшебный лес на рассвете — мягкий свет сквозь листву, пение птиц
@export var bg_magic_forest: Texture2D
## Пауза перед появлением текста плашки (сек)
@export var plashka_delay: float = 1.0

# ==============================================================
# ВИЗУАЛЬНЫЕ АССЕТЫ — КСЕНИЯ
# ==============================================================
@export_category("Portraits — Ксения")
## Слабая, пересохшие губы, сидит в тени («Вода кончилась вчера»)
@export var portrait_ksenia_weak: Texture2D
## Щурится на солнце, поднимает голову («Единорог. В Сахаре.»)
@export var portrait_ksenia_squinting: Texture2D
## Решительная, схватила лопату («Покажи. Я больше не буду жаловаться на дождь.»)
@export var portrait_ksenia_hopeful: Texture2D
## Смеётся, пьёт воду («Я никогда не думала, что вода...»)
@export var portrait_ksenia_happy: Texture2D
## Благодарная, серьёзная («Спасибо. Мы бы погибли.»)
@export var portrait_ksenia_grateful: Texture2D
## Тронута до глубины души — прижимает руку к груди (прощальная сцена)
@export var portrait_ksenia_moved: Texture2D

# ==============================================================
# ВИЗУАЛЬНЫЕ АССЕТЫ — ИГОРЬ
# ==============================================================
@export_category("Portraits — Игорь")
## Сосредоточен, чинит рацию, не смотрит на Ксению
@export var portrait_igor_focused: Texture2D
## Замер с рацией в руках («Ксюша... ты тоже это видишь?»)
@export var portrait_igor_frozen: Texture2D
## Восторженный — учёный в экстазе («Родник?! Я же говорил!»)
@export var portrait_igor_excited: Texture2D
## Кризис мировоззрения («С одной стороны — горжусь. С другой...»)
@export var portrait_igor_crisis: Texture2D
## Уверовавший, тихо улыбается («Теперь я верю.»)
@export var portrait_igor_believer: Texture2D
## Жадно пьёт воду из найденного родника
@export var portrait_igor_drinking: Texture2D
## Снимает панаму — прощание с Единорогом
@export var portrait_igor_moved: Texture2D

# ==============================================================
# ВИЗУАЛЬНЫЕ АССЕТЫ — ЕДИНОРОГ / АСТЕРИОН
# ==============================================================
@export_category("Portraits — Единорог / Астерион")
## Встряхивается, в гриве песок («Везде песок. Даже в гриве.»)
@export var portrait_unicorn_dusty: Texture2D
## Нейтральный, спокойный
@export var portrait_unicorn_neutral: Texture2D
## Любопытный — принюхивается, наклоняет голову
@export var portrait_unicorn_curious: Texture2D
## Мудрый, торжественный
@export var portrait_unicorn_wise: Texture2D
## Рог мягко светится — монолог о магии людей
@export var portrait_unicorn_glowing: Texture2D
## Кланяется — последнее прощание перед шагом в портал
@export var portrait_unicorn_farewell: Texture2D

# ==============================================================
# ВИЗУАЛЬНЫЕ АССЕТЫ — ЭПИЛОГ (ЛЕС)
# ==============================================================
@export_category("Portraits — Эпилог")
## Луна — радостная, подбегает к Астериону
@export var portrait_luna_happy: Texture2D
## Гром — сдержанный, скептически поднимает бровь
@export var portrait_grom_reserved: Texture2D
## Астерион дома, в лесу — тёплая улыбка
@export var portrait_asterion_smiling: Texture2D

# ==============================================================
# КОНФИГУРАЦИЯ МИНИ-ИГРЫ 4 — «Детектор воды»
# Источник: ЕДИНОРОГ.docx → МИНИ-ИГРА 4
# Сетка 6×6. Рог = детектор. Расстояние = Манхэттен или Евклид.
# ==============================================================
const MINIGAME_WATER_CONFIG: Dictionary = {
	"grid_cols":          6,     # Ширина сетки
	"grid_rows":          6,     # Высота сетки
	"water_cell_count":   2,     # Кол-во скрытых источников воды
	"max_attempts":       8,     # Попыток до перезапуска
	"rating_legendary":   4,     # 1–4 попытки  → «Невероятно!»
	"rating_great":       6,     # 5–6 попыток  → «Отличная работа»
	"rating_ok":          8,     # 7–8 попыток  → «Еле успели, но нашли»
}

## Уровни сигнала рога по дистанции (Евклид, клеток)
## max_distance: верхняя граница расстояния для этого уровня
## Используется мини-игрой для окраски маркеров и индикатора
const WATER_SIGNAL_LEVELS: Array = [
	{ "max_distance": 0,  "label": "ВОДА! 💧",   "color": "ffffff" },  # Попадание
	{ "max_distance": 1,  "label": "Горячо!",    "color": "ff8800" },  # Вплотную
	{ "max_distance": 2,  "label": "Тепло",      "color": "ffee00" },  # Рядом
	{ "max_distance": 3,  "label": "Прохладно",  "color": "00ccff" },  # Далеко
	{ "max_distance": 99, "label": "Ничего",     "color": "888888" },  # Нет сигнала
]

# ==============================================================
# КОНФИГУРАЦИЯ МИНИ-ИГРЫ 5 — «Найди портал»
# Источник: ЕДИНОРОГ.docx → МИНИ-ИГРА 7 (по счёту всей игры)
# Tap-to-move, без таймера. Ловушки-миражи снимают магию.
# ==============================================================
const MINIGAME_PORTAL_CONFIG: Dictionary = {
	"particle_count":     6,     # Частиц аномалии на карте
	"trap_stone_count":   4,     # Миражных камней-ловушек
	"magic_points_max":   5,     # Единиц магии (жизней)
	"has_timer":          false, # Без таймера — медитативная финальная игра
	"unicorn_speed_px":   200,   # Скорость движения единорога (пикс/сек)
}

# ==============================================================
# ССЫЛКИ НА УЗЛЫ
# ==============================================================
@onready var black_screen: ColorRect           = $FadeLayer/BlackScreen
@onready var background: TextureRect           = $Background
@onready var dm: Node                          = $DialogueManager
@onready var dialogue_box: Control             = $DialogueBox
@onready var character_portrait_1: TextureRect = $CharacterPortrait1
@onready var character_portrait_2: TextureRect = $CharacterPortrait2
@onready var plashka_rect: ColorRect           = $PlashkaLayer/PlashkaRect
@onready var plashka_label: Label              = $PlashkaLayer/PlashkaLabel
@onready var minigame_layer: CanvasLayer       = $MinigameLayer

# ==============================================================
# ГОТОВНОСТЬ
# ==============================================================
func _ready() -> void:
	_set_background(bg_sahara_desert)

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
	_home.current_scene_path = "res://scenes/mission_3.tscn"
	add_child(_home)

# ==============================================================
# INPUT — пропуск реплик, только в диалоговых фазах
# ==============================================================
func _input(event: InputEvent) -> void:
	var is_dialogue_active: bool = (
		_phase == Phase.DIALOGUE_DESERT_INTRO  or
		_phase == Phase.DIALOGUE_POST_WATER    or
		_phase == Phase.DIALOGUE_PRE_PORTAL    or
		_phase == Phase.DIALOGUE_PORTAL_OPEN   or
		_phase == Phase.DIALOGUE_FAREWELL      or
		_phase == Phase.DIALOGUE_EPILOGUE
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

# ==============================================================
# ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
# ==============================================================
func _set_background(texture: Texture2D) -> void:
	if background and texture:
		background.texture = texture

func _reset_plashka() -> void:
	plashka_label.modulate.a = 0.0
	plashka_rect.color       = Color(0, 0, 0, 0.0)

func _hide_portraits() -> void:
	if character_portrait_1: character_portrait_1.visible = false
	if character_portrait_2: character_portrait_2.visible = false

# ==============================================================
# РОУТЕР ЗАВЕРШЕНИЯ ДИАЛОГОВ
# ==============================================================
func _on_dialogue_finished() -> void:
	_hide_portraits()

	match _phase:
		Phase.DIALOGUE_DESERT_INTRO:  _start_minigame_water()
		Phase.DIALOGUE_POST_WATER:    _start_dialogue_pre_portal()
		Phase.DIALOGUE_PRE_PORTAL:    _start_minigame_portal()
		Phase.DIALOGUE_PORTAL_OPEN:   _start_dialogue_farewell()
		Phase.DIALOGUE_FAREWELL:      _begin_fade_to_forest()
		Phase.DIALOGUE_EPILOGUE:      _show_plashka_final()

# ==============================================================
# ОБРАБОТЧИК СМЕНЫ СТРОКИ ДИАЛОГА — портреты
# Идентично mission_1.gd и mission_2.gd
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

# ==============================================================
# ФАЗА 1 — FADE IN
# ==============================================================
func _begin_fade_in() -> void:
	_phase = Phase.FADE_IN

	black_screen.color      = Color.BLACK
	black_screen.modulate.a = 1.0
	black_screen.visible    = true

	var tween: Tween = create_tween()
	tween.tween_property(black_screen, "modulate:a", 0.0, 1.0)
	await tween.finished

	black_screen.visible = false
	_start_dialogue_desert_intro()

# ==============================================================
# ФАЗА 2 — ДИАЛОГ «ПУСТЫНЯ: ЗНАКОМСТВО»
# Источник: ЕДИНОРОГ.docx → начало МИССИИ 3
# Ксения и Игорь умирают от жажды → Единорог появляется →
# «Нужна ваша помощь» → переход к мини-игре
# ==============================================================
func _start_dialogue_desert_intro() -> void:
	_phase = Phase.DIALOGUE_DESERT_INTRO
	_set_background(bg_sahara_desert)

	if not dm or not dm.has_method("start"):
		push_warning("Mission3: DialogueManager не найден, пропускаем диалог.")
		_start_minigame_water()
		return

	var lines: Array[Dictionary] = [
		# --- Ксения слабым голосом ---
		{
			"speaker":    "КСЕНИЯ",
			"text":       "Игря... я больше не могу. Вода кончилась вчера. Мы идём кругами.",
			"portrait_1": portrait_ksenia_weak,
			"pos_1":      Vector2(1400, 400),
			"portrait_2": portrait_igor_focused,
			"pos_2":      Vector2(150, 400)
		},
		{
			"speaker":    "ИГОРЬ",
			"text":       "Не кругами. Мы идём... стратегическим зигзагом.",
			"portrait_1": portrait_igor_focused,
			"pos_1":      Vector2(150, 400),
			"portrait_2": portrait_ksenia_weak,
			"pos_2":      Vector2(1400, 400)
		},
		{
			"speaker":    "КСЕНИЯ",
			"text":       "Мы заблудились.",
			"portrait_1": portrait_ksenia_weak,
			"pos_1":      Vector2(1400, 400),
			"portrait_2": portrait_igor_focused,
			"pos_2":      Vector2(150, 400)
		},
		{
			"speaker":    "ИГОРЬ",
			"text":       "Геологи не блудят! Мы исследуем альтернативные маршруты.",
			"portrait_1": portrait_igor_focused,
			"pos_1":      Vector2(150, 400),
			"portrait_2": portrait_ksenia_weak,
			"pos_2":      Vector2(1400, 400)
		},
		# --- Песок светится. Появляется Единорог. ---
		{
			"speaker":    "ЕДИНОРОГ",
			"text":       "Фух. Песок. Везде песок. Даже в гриве.",
			"portrait_1": portrait_unicorn_dusty,
			"pos_1":      Vector2(700, 380),
			"portrait_2": null,
			"pos_2":      Vector2.ZERO
		},
		{
			"speaker":    "ИГОРЬ",
			"text":       "Ксюша... ты тоже это видишь?",
			"portrait_1": portrait_igor_frozen,
			"pos_1":      Vector2(150, 400),
			"portrait_2": portrait_unicorn_dusty,
			"pos_2":      Vector2(700, 380)
		},
		{
			"speaker":    "КСЕНИЯ",
			"text":       "Единорог. В Сахаре. Либо у меня тепловой удар...",
			"portrait_1": portrait_ksenia_squinting,
			"pos_1":      Vector2(1400, 400),
			"portrait_2": portrait_unicorn_dusty,
			"pos_2":      Vector2(700, 380)
		},
		{
			"speaker":    "ИГОРЬ",
			"text":       "Либо это новый вид адаптированной лошади! Биолюминисценция рога – возможно, мутация под воздействием ультрафиолета!",
			"portrait_1": portrait_igor_crisis,
			"pos_1":      Vector2(150, 400),
			"portrait_2": portrait_unicorn_dusty,
			"pos_2":      Vector2(700, 380)
		},
		# --- Единорог представляется ---
		{
			"speaker":    "ЕДИНОРОГ",
			"text":       "Я не «адаптированная лошадь». Я Астерион. Из Волшебного леса. Меня прислала Алиса. Твоя племянница.",
			"portrait_1": portrait_unicorn_neutral,
			"pos_1":      Vector2(700, 380),
			"portrait_2": portrait_igor_crisis,
			"pos_2":      Vector2(150, 400)
		},
		{
			"speaker":    "ИГОРЬ",
			"text":       "Алиса? Моя Алиса? Та самая, которая в детстве верила в фей?!",
			"portrait_1": portrait_igor_frozen,
			"pos_1":      Vector2(150, 400),
			"portrait_2": portrait_unicorn_neutral,
			"pos_2":      Vector2(700, 380)
		},
		{
			"speaker":    "ЕДИНОРОГ",
			"text":       "Она до сих пор верит. И, кстати, передаёт привет.",
			"portrait_1": portrait_unicorn_curious,
			"pos_1":      Vector2(700, 380),
			"portrait_2": portrait_igor_frozen,
			"pos_2":      Vector2(150, 400)
		},
		{
			"speaker":    "ИГОРЬ",
			"text":       "Ну всё. Моя племянница дружит с магическим существом. С одной стороны – я горжусь. С другой – у меня кризис мировоззрения.",
			"portrait_1": portrait_igor_crisis,
			"pos_1":      Vector2(150, 400),
			"portrait_2": portrait_unicorn_curious,
			"pos_2":      Vector2(700, 380)
		},
		{
			"speaker":    "КСЕНИЯ",
			"text":       "Подожди... Алиса сказала, где мы? Значит, ты пришёл нам на помощь...?",
			"portrait_1": portrait_ksenia_squinting,
			"pos_1":      Vector2(1400, 400),
			"portrait_2": portrait_unicorn_curious,
			"pos_2":      Vector2(700, 380)
		},
		# --- Единорог принюхивается → родник ---
		{
			"speaker":    "ЕДИНОРОГ",
			"text":       "Я чувствую воду. Она глубоко под песком. Родник.",
			"portrait_1": portrait_unicorn_curious,
			"pos_1":      Vector2(700, 380),
			"portrait_2": portrait_ksenia_squinting,
			"pos_2":      Vector2(1400, 400)
		},
		{
			"speaker":    "ИГОРЬ",
			"text":       "Родник?! Я же говорил! Я говорил, что под этим плато должна быть вода! Где?! Где копать?!",
			"portrait_1": portrait_igor_excited,
			"pos_1":      Vector2(150, 400),
			"portrait_2": portrait_unicorn_curious,
			"pos_2":      Vector2(700, 380)
		},
		{
			"speaker":    "ЕДИНОРОГ",
			"text":       "Мой рог чувствует магию воды. Но копать копытами я не могу – в лесу земля мягкая, а здесь... сплошной камень под песком. Нужна ваша помощь.",
			"portrait_1": portrait_unicorn_neutral,
			"pos_1":      Vector2(700, 380),
			"portrait_2": portrait_igor_excited,
			"pos_2":      Vector2(150, 400)
		},
		# --- Ксения хватает лопату --- (последняя реплика → МГ)
		{
			"speaker":    "КСЕНИЯ",
			"text":       "Показывай. Я больше никогда в жизни не буду жаловаться на дождь. Обещаю.",
			"portrait_1": portrait_ksenia_hopeful,
			"pos_1":      Vector2(1400, 400),
			"portrait_2": portrait_unicorn_neutral,
			"pos_2":      Vector2(700, 380)
		}
		# Завершение → _on_dialogue_finished → _start_minigame_water
	]

	dm.start(lines)

# ==============================================================
# ФАЗА 3 — МИНИ-ИГРА «ДЕТЕКТОР ВОДЫ»
# Источник: ЕДИНОРОГ.docx → МИНИ-ИГРА 4
# Конфигурация: MINIGAME_WATER_CONFIG + WATER_SIGNAL_LEVELS
# ==============================================================
func _start_minigame_water() -> void:
	_phase = Phase.MINIGAME_WATER
	minigame_layer.visible = true

	# TODO: инстанцируй сцену мини-игры и подключи сигналы.
	# var mg = preload("res://scenes/minigame_water_detector.tscn").instantiate()
	# minigame_layer.add_child(mg)
	# mg.setup(MINIGAME_WATER_CONFIG, WATER_SIGNAL_LEVELS)
	# mg.completed.connect(_on_minigame_water_completed)

	push_warning("Mission3: MINIGAME_WATER — заглушка. Подключи UI.")
	await get_tree().create_timer(0.1).timeout
	_on_minigame_water_completed(true, 3)  # ЗАГЛУШКА: победа, 3 попытки

## Вызывается мини-игрой по сигналу.
## is_success: нашли оба источника до исчерпания попыток.
## attempts_used: сколько попыток ушло (для рейтинга).
func _on_minigame_water_completed(is_success: bool, attempts_used: int) -> void:
	if not is_success:
		# Превышено max_attempts → перезапуск
		push_warning("Mission3: MINIGAME_WATER — провал. Перезапуск.")
		minigame_layer.visible = false
		_start_minigame_water()
		return

	# Подбираем рейтинговую строку (для UI мини-игры)
	var rating_text: String
	if attempts_used <= MINIGAME_WATER_CONFIG["rating_legendary"]:
		rating_text = "Невероятно!"
	elif attempts_used <= MINIGAME_WATER_CONFIG["rating_great"]:
		rating_text = "Отличная работа"
	else:
		rating_text = "Еле успели, но нашли"

	print("[Mission3] Вода найдена. Попытки: %d. Рейтинг: %s" % [attempts_used, rating_text])
	minigame_layer.visible = false
	_start_dialogue_post_water()

# ==============================================================
# ФАЗА 4 — ДИАЛОГ ПОСЛЕ ВОДЫ
# Источник: ЕДИНОРОГ.docx → «ДИАЛОГ ПОСЛЕ МИНИ-ИГРЫ»
# Радость → благодарность → разговор о портале в Сахаре
# ==============================================================
func _start_dialogue_post_water() -> void:
	_phase = Phase.DIALOGUE_POST_WATER

	if not dm or not dm.has_method("start"):
		push_warning("Mission3: DialogueManager не найден.")
		_start_dialogue_pre_portal()
		return

	var lines: Array[Dictionary] = [
		# --- Вода бьёт из песка ---
		{
			"speaker":    "ИГОРЬ",
			"text":       "Есть! Вода! Ксюша, тащи канистры!",
			"portrait_1": portrait_igor_excited,
			"pos_1":      Vector2(150, 400),
			"portrait_2": null,
			"pos_2":      Vector2.ZERO
		},
		{
			"speaker":    "КСЕНИЯ",
			"text":       "Я никогда не думала, что вода может быть такой вкусной.",
			"portrait_1": portrait_ksenia_happy,
			"pos_1":      Vector2(1400, 400),
			"portrait_2": portrait_igor_drinking,
			"pos_2":      Vector2(150, 400)
		},
		{
			"speaker":    "ИГОРЬ",
			"text":       "Лучшая экспедиция в моей жизни. Нас спас единорог. Мне никто не поверит.",
			"portrait_1": portrait_igor_drinking,
			"pos_1":      Vector2(150, 400),
			"portrait_2": portrait_ksenia_happy,
			"pos_2":      Vector2(1400, 400)
		},
		{
			"speaker":    "КСЕНИЯ",
			"text":       "Спасибо. Мы бы погибли.",
			"portrait_1": portrait_ksenia_grateful,
			"pos_1":      Vector2(1400, 400),
			"portrait_2": portrait_unicorn_neutral,
			"pos_2":      Vector2(700, 380)
		},
		# --- Единорог спрашивает о портале ---
		# Примечание: в оригинале «Соня сказала» — очевидная опечатка,
		# правильно «Алиса» (см. финал Миссии 2)
		{
			"speaker":    "ЕДИНОРОГ",
			"text":       "Я ищу портал. Алиса сказала, здесь видели светящиеся врата.",
			"portrait_1": portrait_unicorn_curious,
			"pos_1":      Vector2(700, 380),
			"portrait_2": portrait_ksenia_grateful,
			"pos_2":      Vector2(1400, 400)
		},
		{
			"speaker":    "ИГОРЬ",
			"text":       "Да, аномалия в квадрате ВР311. Мы шли туда, когда сломались. Я думал – мираж, но теперь...",
			"portrait_1": portrait_igor_believer,
			"pos_1":      Vector2(150, 400),
			"portrait_2": portrait_unicorn_curious,
			"pos_2":      Vector2(700, 380)
		},
		{
			"speaker":    "ЕДИНОРОГ",
			"text":       "Теперь?",
			"portrait_1": portrait_unicorn_curious,
			"pos_1":      Vector2(700, 380),
			"portrait_2": portrait_igor_believer,
			"pos_2":      Vector2(150, 400)
		},
		{
			"speaker":    "ИГОРЬ",
			"text":       "Теперь я верю. Если единороги существуют, почему бы не существовать порталам?",
			"portrait_1": portrait_igor_believer,
			"pos_1":      Vector2(150, 400),
			"portrait_2": portrait_unicorn_curious,
			"pos_2":      Vector2(700, 380)
		},
		{
			"speaker":    "КСЕНИЯ",
			"text":       "Там маршрут сложный. Но с водой мы дойдём.",
			"portrait_1": portrait_ksenia_hopeful,
			"pos_1":      Vector2(1400, 400),
			"portrait_2": portrait_unicorn_neutral,
			"pos_2":      Vector2(700, 380)
		},
		# --- Последняя реплика → смена фона на аномалию ---
		{
			"speaker":    "ЕДИНОРОГ",
			"text":       "Я чую магию. Она в той стороне. Идите за мной.",
			"portrait_1": portrait_unicorn_wise,
			"pos_1":      Vector2(700, 380),
			"portrait_2": null,
			"pos_2":      Vector2.ZERO
		}
		# Завершение → _on_dialogue_finished → _start_dialogue_pre_portal
	]

	dm.start(lines)

# ==============================================================
# ФАЗА 5 — ДИАЛОГ У АНОМАЛИИ (до мини-игры с частицами)
# Источник: ЕДИНОРОГ.docx → реплики у аномалии перед МГ 7
# Единорог: «Грань тонкая» → Игорь: «Магия Земли» → Ксения: «Звёзды»
# ==============================================================
func _start_dialogue_pre_portal() -> void:
	_phase = Phase.DIALOGUE_PRE_PORTAL
	_set_background(bg_sahara_anomaly)

	if not dm or not dm.has_method("start"):
		push_warning("Mission3: DialogueManager не найден.")
		_start_minigame_portal()
		return

	var lines: Array[Dictionary] = [
		{
			"speaker":    "ЕДИНОРОГ",
			"text":       "Я чувствую – здесь магия Земли ближе всего. Грань между мирами тонкая, как крылья бабочки.",
			"portrait_1": portrait_unicorn_wise,
			"pos_1":      Vector2(700, 380),
			"portrait_2": null,
			"pos_2":      Vector2.ZERO
		},
		{
			"speaker":    "ИГОРЬ",
			"text":       "Магия Земли... Так вот что это за аномалии. Я годами их изучал...",
			"portrait_1": portrait_igor_believer,
			"pos_1":      Vector2(150, 400),
			"portrait_2": portrait_unicorn_wise,
			"pos_2":      Vector2(700, 380)
		},
		{
			"speaker":    "КСЕНИЯ",
			"text":       "Это красиво. Как падающие звёзды.",
			"portrait_1": portrait_ksenia_hopeful,
			"pos_1":      Vector2(1400, 400),
			"portrait_2": portrait_unicorn_wise,
			"pos_2":      Vector2(700, 380)
		},
		{
			"speaker":    "ИГОРЬ",
			"text":       "Невероятно... Энергия концентрируется в центре. Прямо как в моих расчётах!",
			"portrait_1": portrait_igor_believer,
			"pos_1":      Vector2(1400, 400),
			"portrait_2": portrait_unicorn_wise,
			"pos_2":      Vector2(700, 380)
		},
		# --- Объяснение механики мини-игры в нарративе ---
		{
			"speaker":    "ЕДИНОРОГ",
			"text":       "Эти частицы – осколки магии этого места. Собери их вместе, и портал откроется.",
			"portrait_1": portrait_unicorn_wise,
			"pos_1":      Vector2(700, 380),
			"portrait_2": portrait_ksenia_hopeful,
			"pos_2":      Vector2(1400, 400)
		}
		# Завершение → _on_dialogue_finished → _start_minigame_portal
	]

	dm.start(lines)

# ==============================================================
# ФАЗА 6 — МИНИ-ИГРА «НАЙДИ ПОРТАЛ»
# Источник: ЕДИНОРОГ.docx → МИНИ-ИГРА 7 (счёт по всей игре)
# Конфигурация: MINIGAME_PORTAL_CONFIG
# Tap-to-move, без таймера. Ловушки = потеря магии.
# ==============================================================
func _start_minigame_portal(particles_override: int = -1) -> void:
	_phase = Phase.MINIGAME_PORTAL
	minigame_layer.visible = true

	# particles_override: если >= 0, мини-игра стартует
	# с меньшим числом частиц (потеря при перезапуске, как в ТЗ)
	var config: Dictionary = MINIGAME_PORTAL_CONFIG.duplicate()
	if particles_override >= 0:
		config["particle_count"] = particles_override

	# TODO: инстанцируй сцену мини-игры и подключи сигналы.
	# var mg = preload("res://scenes/minigame_find_portal.tscn").instantiate()
	# minigame_layer.add_child(mg)
	# mg.setup(config)
	# mg.completed.connect(_on_minigame_portal_completed)

	push_warning("Mission3: MINIGAME_PORTAL — заглушка. Подключи UI.")
	await get_tree().create_timer(0.1).timeout
	_on_minigame_portal_completed(true, 5)  # ЗАГЛУШКА: победа, магия не потрачена

## Вызывается мини-игрой по сигналу.
## is_success: все частицы собраны до исчерпания магии.
## magic_remaining: оставшихся единиц магии (0 = провал).
func _on_minigame_portal_completed(is_success: bool, magic_remaining: int) -> void:
	if not is_success or magic_remaining <= 0:
		# Магия на нуле → перезапуск с одной лишней частицей (согласно ТЗ)
		var particles_on_retry: int = max(
			1,
			MINIGAME_PORTAL_CONFIG["particle_count"] - 1
		)
		push_warning(
            "Mission3: MINIGAME_PORTAL — провал. Перезапуск с %d частицами."
			% particles_on_retry
		)
		minigame_layer.visible = false
		_start_minigame_portal(particles_on_retry)
		return

	minigame_layer.visible = false
	_start_dialogue_portal_open()

# ==============================================================
# ФАЗА 7 — ДИАЛОГ «ПОРТАЛ ОТКРЫЛСЯ»
# Источник: ЕДИНОРОГ.docx → «ПОСЛЕ СБОРА ЧАСТИЦ» → «ПРОДОЛЖЕНИЕ»
# Игорь: «Боже мой» → Ксения → Единорог: «Дом»
# ==============================================================
func _start_dialogue_portal_open() -> void:
	_phase = Phase.DIALOGUE_PORTAL_OPEN
	_set_background(bg_portal_sunset)

	if not dm or not dm.has_method("start"):
		push_warning("Mission3: DialogueManager не найден.")
		_start_dialogue_farewell()
		return

	var lines: Array[Dictionary] = [
		{
			"speaker":    "ИГОРЬ",
			"text":       "Боже мой... это реально.",
			"portrait_1": portrait_igor_believer,
			"pos_1":      Vector2(150, 400),
			"portrait_2": null,
			"pos_2":      Vector2.ZERO
		},
		{
			"speaker":    "КСЕНИЯ",
			"text":       "Портал в другой мир... Я думала, такое только в книгах.",
			"portrait_1": portrait_ksenia_moved,
			"pos_1":      Vector2(1400, 400),
			"portrait_2": portrait_igor_believer,
			"pos_2":      Vector2(150, 400)
		},
		{
			"speaker":    "ЕДИНОРОГ",
			"text":       "Дом. Я почти чувствую запах леса.",
			"portrait_1": portrait_unicorn_wise,
			"pos_1":      Vector2(700, 380),
			"portrait_2": null,
			"pos_2":      Vector2.ZERO
		}
		# Завершение → _on_dialogue_finished → _start_dialogue_farewell
	]

	dm.start(lines)

# ==============================================================
# ФАЗА 8 — ПРОЩАЛЬНЫЙ ДИАЛОГ
# Источник: ЕДИНОРОГ.docx → финальная сцена Миссии 3
# Фляга → монолог Астериона о людях → прощание →
# «Веру.» (последняя реплика, портал закрылся за ним)
# ==============================================================
func _start_dialogue_farewell() -> void:
	_phase = Phase.DIALOGUE_FAREWELL

	if not dm or not dm.has_method("start"):
		push_warning("Mission3: DialogueManager не найден.")
		_begin_fade_to_forest()
		return

	var lines: Array[Dictionary] = [
		# --- Игорь протягивает флягу ---
		{
			"speaker":    "ИГОРЬ",
			"text":       "Возьми. На память. И... спасибо. За воду. За всё.",
			"portrait_1": portrait_igor_moved,
			"pos_1":      Vector2(150, 400),
			"portrait_2": portrait_unicorn_neutral,
			"pos_2":      Vector2(700, 380)
		},
		{
			"speaker":    "ЕДИНОРОГ",
			"text":       "Спасибо. Ты хороший человек, Игорь. Даже если называешь меня «адаптированной лошадью».",
			"portrait_1": portrait_unicorn_curious,
			"pos_1":      Vector2(700, 380),
			"portrait_2": portrait_igor_moved,
			"pos_2":      Vector2(150, 400)
		},
		{
			"speaker":    "ИГОРЬ",
			"text":       "Прости за это. Знаешь, я больше никогда не буду скептиком.",
			"portrait_1": portrait_igor_moved,
			"pos_1":      Vector2(150, 400),
			"portrait_2": portrait_unicorn_curious,
			"pos_2":      Vector2(700, 380)
		},
		{
			"speaker":    "КСЕНИЯ",
			"text":       "Передай своему лесу – в мире людей есть те, кто верит.",
			"portrait_1": portrait_ksenia_moved,
			"pos_1":      Vector2(1400, 400),
			"portrait_2": portrait_unicorn_wise,
			"pos_2":      Vector2(700, 380)
		},
		# --- МОНОЛОГ АСТЕРИОНА о магии людей (рог светится) ---
		{
			"speaker":    "ЕДИНОРОГ",
			"text":       "Знаете... В моём мире магия повсюду. Она в траве, в воде, в воздухе. Она даётся даром – просто потому что ты единорог. Мы не ценим её. Мы просто... живём.",
			"portrait_1": portrait_unicorn_glowing,
			"pos_1":      Vector2(700, 380),
			"portrait_2": null,
			"pos_2":      Vector2.ZERO
		},
		{
			"speaker":    "ИГОРЬ",
			"text":       "А мы?",
			"portrait_1": portrait_igor_moved,
			"pos_1":      Vector2(150, 400),
			"portrait_2": portrait_unicorn_glowing,
			"pos_2":      Vector2(700, 380)
		},
		{
			"speaker":    "АСТЕРИОН",
			"text":       "А вы создаёте магию сами. Из ничего. Из упрямства. Из желания жить, когда жить невозможно. Из любви к звёздам, когда до них – миллионы ваших «километров».",
			"portrait_1": portrait_unicorn_glowing,
			"pos_1":      Vector2(700, 380),
			"portrait_2": portrait_igor_moved,
			"pos_2":      Vector2(150, 400)
		},
		{
			"speaker":    "АСТЕРИОН",
			"text":       "Из надежды, что завтра будет лучше, даже если сегодня – песок во рту и сломанный джип.",
			"portrait_1": portrait_unicorn_glowing,
			"pos_1":      Vector2(700, 380),
			"portrait_2": portrait_igor_moved,
			"pos_2":      Vector2(150, 400)
		},
		{
			"speaker":    "АСТЕРИОН",
			"text":       "В моём лесу я много раз видел чудеса. Говорящие деревья. Реки, текущие вверх. Драконов, танцующих в грозу.",
			"portrait_1": portrait_unicorn_glowing,
			"pos_1":      Vector2(700, 380),
			"portrait_2": null,
			"pos_2":      Vector2.ZERO
		},
		{
			"speaker":    "АСТЕРИОН",
			"text":       "Но то, что делаете вы – встаёте каждое утро без магии и продолжаете идти – это... это больше, чем чудо.",
			"portrait_1": portrait_unicorn_glowing,
			"pos_1":      Vector2(700, 380),
			"portrait_2": null,
			"pos_2":      Vector2.ZERO
		},
		{
			"speaker":    "КСЕНИЯ",
			"text":       "Ты говоришь так, будто мы особенные...",
			"portrait_1": portrait_ksenia_moved,
			"pos_1":      Vector2(1400, 400),
			"portrait_2": portrait_unicorn_glowing,
			"pos_2":      Vector2(700, 380)
		},
		{
			"speaker":    "АСТЕРИОН",
			"text":       "Потому что вы особенные. Все вы. Даже те, кто светил мне в глаза пластинками на той шумной улице. Они просто хотели запомнить чудо.",
			"portrait_1": portrait_unicorn_glowing,
			"pos_1":      Vector2(700, 380),
			"portrait_2": portrait_ksenia_moved,
			"pos_2":      Vector2(1400, 400)
		},
		{
			"speaker":    "ИГОРЬ",
			"text":       "Мы запомним. Тебя. Обещаю.",
			"portrait_1": portrait_igor_moved,
			"pos_1":      Vector2(150, 400),
			"portrait_2": portrait_unicorn_glowing,
			"pos_2":      Vector2(700, 380)
		},
		# --- Единорог кланяется (медленно, с достоинством) ---
		{
			"speaker":    "АСТЕРИОН",
			"text":       "Люди – вы странные. Вы слабы без магии, но ваше упорство – это и есть магия.",
			"portrait_1": portrait_unicorn_farewell,
			"pos_1":      Vector2(700, 380),
			"portrait_2": null,
			"pos_2":      Vector2.ZERO
		},
		{
			"speaker":    "АСТЕРИОН",
			"text":       "Магия, которую не выучить по книгам. Магия, которую не наколдовать. Магия, рождённая в сердце, которое бьётся, даже когда всё против вас. Берегите её.",
			"portrait_1": portrait_unicorn_farewell,
			"pos_1":      Vector2(700, 380),
			"portrait_2": null,
			"pos_2":      Vector2.ZERO
		},
		{
			"speaker":    "АСТЕРИОН",
			"text":       "И передайте Максу и Алисе – их единорог вернулся домой. И он гордится тем, что был человеком. Хотя бы пару дней.",
			"portrait_1": portrait_unicorn_farewell,
			"pos_1":      Vector2(700, 380),
			"portrait_2": null,
			"pos_2":      Vector2.ZERO
		},
		{
			"speaker":    "ИГОРЬ",
			"text":       "Прощай, Астерион. Ты лучший геолог, которого я знаю.",
			"portrait_1": portrait_igor_moved,
			"pos_1":      Vector2(150, 400),
			"portrait_2": portrait_unicorn_farewell,
			"pos_2":      Vector2(700, 380)
		},
		{
			"speaker":    "КСЕНИЯ",
			"text":       "Прощай. Спасибо за воду. Возвращайся снова.",
			"portrait_1": portrait_ksenia_moved,
			"pos_1":      Vector2(1400, 400),
			"portrait_2": portrait_unicorn_farewell,
			"pos_2":      Vector2(700, 380)
		},
		# --- Единорог у портала, последние слова ---
		{
			"speaker":    "АСТЕРИОН",
			"text":       "Если когда-нибудь ваш мир станет слишком тёмным – посмотрите на звёзды. Там, за ними, есть лес. И в нём – единорог, который помнит вас.",
			"portrait_1": portrait_unicorn_farewell,
			"pos_1":      Vector2(700, 380),
			"portrait_2": null,
			"pos_2":      Vector2.ZERO
		},
		# --- Портал закрылся. Игорь и Ксения смотрят на светящийся песок. ---
		{
			"speaker":    "ИГОРЬ",
			"text":       "Мы тоже нашли кое-что важное...",
			"portrait_1": portrait_igor_moved,
			"pos_1":      Vector2(150, 400),
			"portrait_2": null,
			"pos_2":      Vector2.ZERO
		},
		{
			"speaker":    "КСЕНИЯ",
			"text":       "Что?",
			"portrait_1": portrait_ksenia_moved,
			"pos_1":      Vector2(1400, 400),
			"portrait_2": portrait_igor_moved,
			"pos_2":      Vector2(150, 400)
		},
		{
			"speaker":    "ИГОРЬ",
			"text":       "Веру.",
			"portrait_1": portrait_igor_moved,
			"pos_1":      Vector2(150, 400),
			"portrait_2": portrait_ksenia_moved,
			"pos_2":      Vector2(1400, 400)
		}
		# Завершение → _on_dialogue_finished → _begin_fade_to_forest
	]

	dm.start(lines)

# ==============================================================
# ФАЗА 9 — ПЕРЕХОД В ЛЕС
# Яркая белая вспышка (шаг Единорога в портал) →
# смена фона → тёмное затемнение уходит → лес
# ==============================================================
func _begin_fade_to_forest() -> void:
	_phase = Phase.FADE_TO_FOREST
	_hide_portraits()

	# Шаг 1: яркая вспышка белого — «Единорог шагает в портал»
	black_screen.color      = Color.WHITE
	black_screen.modulate.a = 0.0
	black_screen.visible    = true

	var tw_flash: Tween = create_tween()
	tw_flash.tween_property(black_screen, "modulate:a", 1.0, 0.25)
	await tw_flash.finished

	await get_tree().create_timer(0.35).timeout

	# Шаг 2: переключаем на чёрный экран, ставим фон леса
	black_screen.color = Color.BLACK
	_set_background(bg_magic_forest)

	# Шаг 3: мягкое появление леса
	var tw_in: Tween = create_tween()
	tw_in.tween_property(black_screen, "modulate:a", 0.0, 1.2)
	await tw_in.finished

	black_screen.visible = false
	_start_dialogue_epilogue()

# ==============================================================
# ФАЗА 10 — ЭПИЛОГ (Волшебный лес)
# Источник: ЕДИНОРОГ.docx → «ЭПИЛОГ – Возвращение домой»
# Луна и Гром встречают Астериона → латте и «приложения» →
# «Конец первой части. Продолжение следует...»
# ==============================================================
func _start_dialogue_epilogue() -> void:
	_phase = Phase.DIALOGUE_EPILOGUE

	if not dm or not dm.has_method("start"):
		push_warning("Mission3: DialogueManager не найден.")
		_show_plashka_final()
		return

	var lines: Array[Dictionary] = [
		# --- Луна подбегает ---
		{
			"speaker":    "ЛУНА",
			"text":       "Астерион! Ты вернулся!",
			"portrait_1": portrait_luna_happy,
			"pos_1":      Vector2(150, 400),
			"portrait_2": portrait_asterion_smiling,
			"pos_2":      Vector2(1400, 400)
		},
		{
			"speaker":    "ГРОМ",
			"text":       "Мы думали, тебя похитили двуногие.",
			"portrait_1": portrait_grom_reserved,
			"pos_1":      Vector2(500, 400),
			"portrait_2": portrait_asterion_smiling,
			"pos_2":      Vector2(1400, 400)
		},
		{
			"speaker":    "АСТЕРИОН",
			"text":       "Двуногие зовут себя людьми. И нет, не похитили. Помогли.",
			"portrait_1": portrait_asterion_smiling,
			"pos_1":      Vector2(1400, 400),
			"portrait_2": portrait_grom_reserved,
			"pos_2":      Vector2(500, 400)
		},
		{
			"speaker":    "ЛУНА",
			"text":       "Помогли? Разве они не опасны?",
			"portrait_1": portrait_luna_happy,
			"pos_1":      Vector2(150, 400),
			"portrait_2": portrait_asterion_smiling,
			"pos_2":      Vector2(1400, 400)
		},
		{
			"speaker":    "АСТЕРИОН",
			"text":       "Опасна только их «сессия» и отсутствие воды в пустыне. Но они создали «интернет», чтобы искать порталы, и «приложения», чтобы искать любовь. Это почти как магия.",
			"portrait_1": portrait_asterion_smiling,
			"pos_1":      Vector2(1400, 400),
			"portrait_2": portrait_luna_happy,
			"pos_2":      Vector2(150, 400)
		},
		{
			"speaker":    "ГРОМ",
			"text":       "Любовь через стеклянные пластинки?",
			"portrait_1": portrait_grom_reserved,
			"pos_1":      Vector2(500, 400),
			"portrait_2": portrait_asterion_smiling,
			"pos_2":      Vector2(1400, 400)
		},
		{
			"speaker":    "АСТЕРИОН",
			"text":       "Да. И ещё они изобрели латте. Очень странный напиток. Вкусный.",
			"portrait_1": portrait_asterion_smiling,
			"pos_1":      Vector2(1400, 400),
			"portrait_2": portrait_grom_reserved,
			"pos_2":      Vector2(500, 400)
		},
		{
			"speaker":    "ЛУНА",
			"text":       "Может... нам тоже сходить? Посмотреть на этот мир людей?",
			"portrait_1": portrait_luna_happy,
			"pos_1":      Vector2(150, 400),
			"portrait_2": portrait_asterion_smiling,
			"pos_2":      Vector2(1400, 400)
		},
		{
			"speaker":    "ГРОМ",
			"text":       "Ты серьёзно?",
			"portrait_1": portrait_grom_reserved,
			"pos_1":      Vector2(500, 400),
			"portrait_2": portrait_luna_happy,
			"pos_2":      Vector2(150, 400)
		},
		{
			"speaker":    "ЛУНА",
			"text":       "Ну а что? Астерион же вернулся живой. И с историями.",
			"portrait_1": portrait_luna_happy,
			"pos_1":      Vector2(150, 400),
			"portrait_2": portrait_grom_reserved,
			"pos_2":      Vector2(500, 400)
		},
		# --- Финальная реплика Астериона ---
		{
			"speaker":    "АСТЕРИОН",
			"text":       "Поверьте, это только начало. Думаю, им скоро понадобится наша помощь снова. В конце концов, у них даже нет магии погоды. Только «прогноз». И он часто ошибается.",
			"portrait_1": portrait_asterion_smiling,
			"pos_1":      Vector2(1400, 400),
			"portrait_2": portrait_luna_happy,
			"pos_2":      Vector2(150, 400)
		}
		# Завершение → _on_dialogue_finished → _show_plashka_final
	]

	dm.start(lines)

# ==============================================================
# ФАЗА 11 — ФИНАЛЬНЫЕ ПЛАШКИ (две подряд)
# Источник: ЕДИНОРОГ.docx → финальные плашки игры
# «Земля оказалась странным местом...» → «Конец I части»
# ==============================================================
func _show_plashka_final() -> void:
	_phase = Phase.PLASHKA_FINAL
	_reset_plashka()

	await get_tree().create_timer(plashka_delay).timeout

	# ── Первая плашка ──────────────────────────────────────────
	# Задаем размер шрифта в 80 пикселей одной строкой
	plashka_label.add_theme_font_size_override("font_size", 60)
	
	plashka_label.text = "Земля оказалась странным местом.\nНо разве не все \nлучшие места – странные?"

	var tw_in_1: Tween = create_tween()
	tw_in_1.tween_property(plashka_rect,  "color",          Color(0, 0, 0, 0.85), 0.5)
	tw_in_1.parallel().tween_property(plashka_label, "modulate:a", 1.0,          0.5)
	await tw_in_1.finished

	await get_tree().create_timer(3.0).timeout

	# ── Переход ко второй плашке ───────────────────────────────
	var tw_out: Tween = create_tween()
	tw_out.tween_property(plashka_label, "modulate:a", 0.0, 0.4)
	await tw_out.finished

	# ── Вторая плашка ──────────────────────────────────────────
	plashka_label.text = "Конец первой части.\nПродолжение следует..."

	var tw_in_2: Tween = create_tween()
	tw_in_2.tween_property(plashka_label, "modulate:a", 1.0, 0.5)
	await tw_in_2.finished

	await get_tree().create_timer(3.5).timeout

	_begin_fade_out()

# ==============================================================
# ФАЗА 12 — FADE OUT → Главное меню
# ==============================================================
func _begin_fade_out() -> void:
	_phase = Phase.FADE_OUT

	black_screen.color      = Color.BLACK
	black_screen.visible    = true
	black_screen.modulate.a = 0.0

	var tween: Tween = create_tween()
	tween.tween_property(black_screen, "modulate:a", 1.0, 1.5)
	await tween.finished

	mission_completed.emit()
	# TODO: Замени на сцену финальных титров, если они будут.
	get_tree().change_scene_to_file("res://scenes/mainmenu.tscn")
