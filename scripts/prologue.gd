extends Node

enum Phase {
	FADE_IN,
	DIALOGUE,
	PLASHKA,
	FADE_OUT
}

var _phase := Phase.FADE_IN

@export_category("Backgrounds")
@export var university_background_texture : Texture2D
@export var background_view_time : float = 2.0

@onready var white_screen  : ColorRect  = $FadeLayer/WhiteScreen
@onready var plashka_rect  : ColorRect  = $PlashkaLayer/PlashkaRect
@onready var plashka_label : Label      = $PlashkaLayer/PlashkaLabel
@onready var dialogue_box  : Control    = $DialogueBox
@onready var dm            : Node       = $DialogueManager
@onready var background    : TextureRect = $Background

@onready var character_portrait_1 : TextureRect = $CharacterPortrait1
@onready var character_portrait_2 : TextureRect = $CharacterPortrait2

func _ready() -> void:
	dialogue_box.visible = false
	plashka_label.modulate.a = 0.0
	plashka_rect.color = Color(0, 0, 0, 0.0)
	if character_portrait_1: character_portrait_1.visible = false
	if character_portrait_2: character_portrait_2.visible = false
	if dm and dm.has_signal("dialogue_finished"):
		dm.dialogue_finished.connect(_on_dialogue_finished)
	if dm and dm.has_signal("line_changed"):
		dm.line_changed.connect(_on_dialogue_line_changed)
	_begin_fade_in()

	var _home := HomeOverlay.new()
	_home.current_scene_path = "res://scenes/prologue.tscn"
	add_child(_home)


func _input(event: InputEvent) -> void:
	if _phase != Phase.DIALOGUE:
		return
		
	var is_tap: bool = event is InputEventScreenTouch and event.pressed
	var is_click: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	
	if is_tap or is_click:
		if dm and dm.has_method("advance"):
			dm.advance()

func _begin_fade_in() -> void:
	_phase = Phase.FADE_IN
	
	white_screen.color = Color(1, 1, 1, 1.0)
	white_screen.modulate.a = 1.0
	white_screen.visible = true

	call_deferred("_start_prologue_dialogue_deferred")
	
	var tw := create_tween()
	tw.tween_property(white_screen, "modulate:a", 0.0, 1.5)
	await tw.finished
	white_screen.visible = false

func _start_prologue_dialogue_deferred() -> void:
	await get_tree().create_timer(0.1).timeout
	_start_prologue_dialogue()

func _start_prologue_dialogue() -> void:
	_phase = Phase.DIALOGUE
	
	if dm and dm.has_method("start"):
		var dialogue_data: Array[Dictionary] = [
			{
				"speaker": "ПРОХОЖИЙ 1", 
				"text": "Смотрите, лошадь!", 
				"portrait_1": preload("res://assets/pers/Group 114(1).png"),
				"pos_1": Vector2(150, 500),
				"portrait_2": preload("res://assets/pers/Group 123.png"),
				"pos_2": Vector2(0, 0)
			},
			{
				"speaker": "ПРОХОЖАЯ 2", 
				"text": "Это реклама? Кто оператор?", 
				"portrait_1": preload("res://assets/pers/Group 114(1).png"),
				"pos_1": Vector2(150, 500),
				"portrait_2": preload("res://assets/pers/Group 124.png"),
				"pos_2": Vector2(0, 0)
			},
			{
				"speaker": "ПОДРОСТОК", 
				"text": "Выложу в TikTok – меня точно лайкнут...",
				"portrait_1": preload("res://assets/pers/Group 114(1).png"),
				"pos_1": Vector2(150, 500),
				"portrait_2": preload("res://assets/pers/Group 125.png"),
				"pos_2": Vector2(0, 0)
			},
			{
				"speaker": "ДЕВУШКА С КОФЕ", 
				"text": "У него рог! Это единорог что ли?",
				"portrait_1": preload("res://assets/pers/Group 114(1).png"),
				"pos_1": Vector2(150, 500),
				"portrait_2": preload("res://assets/pers/Group 126.png"),
				"pos_2": Vector2(0, 0)
			},    
			{
				"speaker": "МУЖЧИНА В КОСТЮМЕ", 
				"text": "Наверное, флешмоб. Креативно.",
				"portrait_1": preload("res://assets/pers/Group 114(1).png"),
				"pos_1": Vector2(150, 500),
				"portrait_2": preload("res://assets/pers/Group 127.png"),
				"pos_2": Vector2(0, 0)
			},    
			{
				"speaker": "ЕДИНОРОГ", 
				"text": "Где деревья? Почему всё из камня? И зачем эти существа светят мне в глаза своими маленькими пластинками?", 
				"portrait_1": preload("res://assets/pers/Group 119.png"),
				"pos_1": Vector2(150, 500),
				"portrait_2": null,
				"pos_2": Vector2.ZERO
			},
			{
				"speaker": "ЕДИНОРОГ", 
				"text": "Ладно. Найду кого-нибудь, кто не пытается меня ослепить.", 
				"portrait_1": preload("res://assets/pers/Group 120(1).png"),
				"pos_1": Vector2(150, 500),
				"portrait_2": null,
				"pos_2": Vector2.ZERO
			}
		]
		
		dm.start(dialogue_data)

func _on_dialogue_line_changed(line_data: Dictionary) -> void:
	if character_portrait_1:
		var tex_1: Texture2D = line_data.get("portrait_1", null)
		if tex_1 == null:
			character_portrait_1.visible = false
		else:
			character_portrait_1.texture = tex_1
			character_portrait_1.visible = true
			character_portrait_1.global_position = line_data.get("pos_1", Vector2.ZERO)

	if character_portrait_2:
		var tex_2: Texture2D = line_data.get("portrait_2", null)
		if tex_2 == null:
			character_portrait_2.visible = false
		else:
			character_portrait_2.texture = tex_2
			character_portrait_2.visible = true
			character_portrait_2.global_position = line_data.get("pos_2", Vector2.ZERO)

func _on_dialogue_finished() -> void:
	if character_portrait_1: character_portrait_1.visible = false
	if character_portrait_2: character_portrait_2.visible = false
	_show_plashka("УНИВЕРСИТЕТСКИЙ ГОРОДОК.\n10 МИНУТ ДО ЗАЧЁТА.")

func _show_plashka(text: String) -> void:
	_phase = Phase.PLASHKA
	plashka_label.text = text
	
	if background and university_background_texture:
		background.texture = university_background_texture
	
	await get_tree().create_timer(background_view_time).timeout
	
	var tw := create_tween()
	tw.tween_property(plashka_rect, "color", Color(0, 0, 0, 0.85), 0.5)
	tw.parallel().tween_property(plashka_label, "modulate:a", 1.0, 0.5)
	await tw.finished
	
	await get_tree().create_timer(2.0).timeout
	_begin_fade_out()

func _begin_fade_out() -> void:
	_phase = Phase.FADE_OUT
	white_screen.visible = true
	white_screen.modulate.a = 0.0
	
	get_tree().change_scene_to_file("res://scenes/mission_1.tscn")
