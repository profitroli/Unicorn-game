extends Control
class_name UnicornDisplay

@onready var _hvost_layer:  TextureRect = $UnicornContainer/HvostLayer
@onready var _griva_layer:  TextureRect = $UnicornContainer/GrivaLayer
@onready var _base_unicorn: TextureRect = $UnicornContainer/BaseUnicorn
@onready var _rog_layer:    TextureRect = $UnicornContainer/RogLayer
@onready var _aks_layer:    TextureRect = $UnicornContainer/AksLayer

const HOVER_TINT:     Color = Color(1.18, 1.1, 1.35, 1.0)  
const NORMAL_TINT:    Color = Color.WHITE
const TWEEN_DURATION: float = 0.18

var _hover_tween: Tween


func _ready() -> void:
	if not has_node("/root/GlobalData"):
		push_error("[UnicornDisplay] GlobalData не зарегистрирован в Autoload!")
		return

	var g: GlobalDataManager = get_node("/root/GlobalData")
	g.unicorn_updated.connect(_on_unicorn_updated)
	_apply_from_global()

	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)


func _on_mouse_entered() -> void:
	_animate(HOVER_TINT)


func _on_mouse_exited() -> void:
	_animate(NORMAL_TINT)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_flash_and_go()


func _animate(tint: Color) -> void:
	if _hover_tween:
		_hover_tween.kill()
	_hover_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	_hover_tween.tween_property(self, "modulate", tint, TWEEN_DURATION)


func _flash_and_go() -> void:
	if _hover_tween:
		_hover_tween.kill()

	var flash := create_tween().set_ease(Tween.EASE_OUT)
	flash.tween_property(self, "modulate", Color(1.5, 1.5, 1.5, 1.0), 0.06)
	flash.tween_property(self, "modulate", HOVER_TINT, 0.12)
	await flash.finished

	get_tree().change_scene_to_file("res://scenes/customization.tscn")


func _on_unicorn_updated() -> void:
	_apply_from_global()


func _apply_from_global() -> void:
	if not has_node("/root/GlobalData"):
		return

	var g: GlobalDataManager = get_node("/root/GlobalData")

	_set_texture(_griva_layer, g.temp_griva_path)
	_set_texture(_hvost_layer, g.temp_hvost_path)
	_set_texture(_rog_layer,   g.temp_rog_path)
	_set_texture(_aks_layer,   g.temp_aks_path)

	_griva_layer.modulate = g.color_griva
	_hvost_layer.modulate = g.color_hvost
	_rog_layer.modulate   = g.color_rog
	_aks_layer.modulate   = g.color_aks

	_griva_layer.visible = (_griva_layer.texture != null)
	_hvost_layer.visible = (_hvost_layer.texture != null)
	_rog_layer.visible   = (_rog_layer.texture   != null)
	_aks_layer.visible   = (_aks_layer.texture   != null)


func _set_texture(layer: TextureRect, path: String) -> void:
	if not is_instance_valid(layer):
		return
	if path != "" and ResourceLoader.exists(path):
		layer.texture = load(path)
	else:
		layer.texture = null
