# AudioManager.gd
extends Node

@onready var music_player := AudioStreamPlayer.new()
@onready var sfx_player   := AudioStreamPlayer.new()
@onready var click_player := AudioStreamPlayer.new()
@onready var typing_player:= AudioStreamPlayer.new()

var sounds: Dictionary = {}
var base_music_vol: float = 0.0
var base_sfx_vol: float = 0.0

func _ready() -> void:
    add_child(music_player)
    add_child(sfx_player)
    add_child(click_player)
    add_child(typing_player)
    
    # Полифония: звуки не будут прерывать друг друга
    sfx_player.max_polyphony = 5
    click_player.max_polyphony = 10
    typing_player.max_polyphony = 10
    
    _load_all_sounds()
    
    # Заранее назначаем стримы системным звукам
    if sounds.has("click"):  click_player.stream  = sounds["click"]
    if sounds.has("typing"): typing_player.stream = sounds["typing"]
    
    # Жестко фиксируем громкость UI (они всегда громкие!)
    click_player.volume_db  = 5.0
    typing_player.volume_db = -5.0
    
    # Загружаем сохраненную громкость с задержкой (чтобы GlobalData успел прогрузиться)
    call_deferred("_load_saved_volume")
    
    # Подключаем звук клика ко ВСЕМ кнопкам (даже тем, что уже на сцене)
    _connect_buttons(get_tree().root)
    get_tree().node_added.connect(_on_node_added)


func _load_all_sounds() -> void:
    sounds["mm"]       = load("res://assets/music/mm.mp3")
    sounds["cas"]      = load("res://assets/music/кас.mp3")
    sounds["cafe"]     = load("res://assets/music/кафе.mp3")
    sounds["desert"]   = load("res://assets/music/пустыня.mp3")
    sounds["school"]   = load("res://assets/music/школа.mp3")
    sounds["birds"]    = load("res://assets/music/пение птиц (1) (online-audio-converter.com).mp3")
    sounds["portal"]   = load("res://assets/music/portal-otkryivaetsya--gul.mp3")
    sounds["minigame"] = load("res://assets/music/мини игры.mp3")

    sounds["click"]    = load("res://assets/music/клик.mp3")
    sounds["typing"]   = load("res://assets/music/печатает.mp3")

# Рекурсивно находим все кнопки при старте
func _connect_buttons(node: Node) -> void:
    if node is BaseButton:
        if not node.pressed.is_connected(play_click):
            node.pressed.connect(play_click)
    for child in node.get_children():
        _connect_buttons(child)

# Автоматически подключаем кнопки, которые появляются по ходу игры
func _on_node_added(node: Node) -> void:
    if node is BaseButton:
        if not node.pressed.is_connected(play_click):
            node.pressed.connect(play_click)


var _playback_positions: Dictionary = {}

func play_music(track_name: String, volume_db: float = 0.0) -> void:
    if not sounds.has(track_name):
        push_warning("AudioManager: Музыка не найдена → " + track_name)
        return

    # Если этот трек УЖЕ играет, ничего не трогаем (музыка продолжает идти)
    if music_player.stream == sounds[track_name] and music_player.playing:
        return

    # 1. Запоминаем текущую позицию старого трека (если он играл)
    if music_player.stream != null and music_player.playing:
        _playback_positions[music_player.stream.resource_path] = music_player.get_playback_position()

    # 2. Переключаем на новый стрим
    music_player.stream = sounds[track_name]
    music_player.volume_db = volume_db
    
    # 3. Достаем сохраненную позицию для нового трека (если мы его уже слушали)
    var saved_pos = _playback_positions.get(sounds[track_name].resource_path, 0.0)
    
    # 4. Запускаем с той секунды, где остановились
    music_player.play(saved_pos)

# Дополнительно: метод для полного сброса, если нужно начать трек "с чистого листа"
func play_music_from_start(track_name: String, volume_db: float = 0.0) -> void:
    if sounds.has(track_name):
        _playback_positions[sounds[track_name].resource_path] = 0.0
        music_player.stream = sounds[track_name]
        music_player.volume_db = volume_db
        music_player.play(0.0)

func play_sfx(sfx_name: String, volume_db: float = 0.0) -> void:
    if sounds.has(sfx_name):
        sfx_player.stream = sounds[sfx_name]
        base_sfx_vol = volume_db
        _update_volumes()
        sfx_player.play()
    else:
        push_warning("AudioManager: SFX не найден → " + sfx_name)

func stop_music() -> void:
    music_player.stop()

# ======================== ГРОМКОСТЬ ========================
func set_master_volume(volume_db: float) -> void:
    var g = get_node_or_null("/root/GlobalData")
    if g and g.has_method("set_master_volume"):
        g.set_master_volume(volume_db)
    _update_volumes()

func _update_volumes() -> void:
    var g = get_node_or_null("/root/GlobalData")
    var db = g.get_master_volume() if g else 0.0
    
    if db <= -30.0:
        music_player.volume_db = -80.0
        sfx_player.volume_db   = -80.0
    else:
        music_player.volume_db = base_music_vol + db
        sfx_player.volume_db   = base_sfx_vol + db
    # click_player и typing_player здесь не меняются! Они независимы.

func _load_saved_volume() -> void:
    _update_volumes()

# ======================== УДОБНЫЕ МЕТОДЫ ========================
func play_click()    -> void: click_player.play()
func play_typing()   -> void: typing_player.play()
func play_minigame() -> void: play_music("minigame", -6.0)
func play_portal()   -> void: play_sfx("portal", 5.0)
