# AudioManager.gd
extends Node

@onready var music_player := AudioStreamPlayer.new()
@onready var sfx_player   := AudioStreamPlayer.new()

var sounds: Dictionary = {}

func _ready() -> void:
    # Добавляем плееры в сцену
    add_child(music_player)
    add_child(sfx_player)
    
    music_player.bus = "Master"
    sfx_player.bus   = "Master"
    
    _load_all_sounds()


func _load_all_sounds() -> void:
    # Музыка
    sounds["mm"]       = load("res://assets/music/mm.mp3")
    sounds["portal"]   = load("res://assets/music/portal-otkryivaetsya--gul.mp3")
    sounds["cafe"]     = load("res://assets/music/кафе.mp3")
    sounds["desert"]   = load("res://assets/music/пустыня.mp3")
    sounds["school"]   = load("res://assets/music/школа.mp3")
    sounds["birds"]    = load("res://assets/music/пение птиц (1) (online-audio-converter.com).mp3")
    sounds["cas"]      = load("res://assets/music/cas.mp3")

    # SFX
    sounds["click"]    = load("res://assets/music/клик.mp3")
    sounds["typing"]   = load("res://assets/music/печатает.mp3")
    sounds["minigame"] = load("res://assets/music/мини игры.mp3")


func play_music(track_name: String, volume_db: float = 0.0) -> void:
    if sounds.has(track_name):
        music_player.stream = sounds[track_name]
        music_player.volume_db = volume_db
        music_player.play()
    else:
        push_warning("AudioManager: Музыка не найдена → " + track_name)


func play_sfx(sfx_name: String, volume_db: float = 0.0) -> void:
    if sounds.has(sfx_name):
        sfx_player.stream = sounds[sfx_name]
        sfx_player.volume_db = volume_db
        sfx_player.play()
    else:
        push_warning("AudioManager: SFX не найден → " + sfx_name)


func stop_music() -> void:
    music_player.stop()


func set_master_volume(volume_db: float) -> void:
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), volume_db)


# Удобные методы
func play_click() -> void:
    play_sfx("click", -8.0)

func play_typing() -> void:
    play_sfx("typing", -14.0)
