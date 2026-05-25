extends Control
class_name CustomizationMenu

@onready var panels: Array[Control] = [
	$TextureRect/ContentPanel/GrivaPanel,
	$TextureRect/ContentPanel/HvostPanel,
	$TextureRect/ContentPanel/RogPanel,
	$TextureRect/ContentPanel/TeloPanel,
]

var _griva_layer: TextureRect
var _hvost_layer: TextureRect
var _rog_layer:   TextureRect
var _aks_layer:   TextureRect

var _temp_griva_path: String = ""
var _temp_hvost_path: String = ""
var _temp_rog_path:   String = ""
var _temp_aks_path:   String = ""

var _color_griva: Color = Color.WHITE
var _color_hvost: Color = Color.WHITE
var _color_rog:   Color = Color.WHITE
var _color_aks:   Color = Color.WHITE

var _current_tab: int = 0

var _save_tween: Tween


func _ready() -> void:
	_load_from_global()

	$TextureRect/MenuButton.pressed.connect(_on_back_pressed)

	if has_node("TextureRect/SaveButton"):
		$TextureRect/SaveButton.pressed.connect(_on_save_pressed)

	show_panel(0)
	$TextureRect/TabContainer/GrivaButton.pressed.connect(func(): show_panel(0))
	$TextureRect/TabContainer/HvostButton.pressed.connect(func(): show_panel(1))
	$TextureRect/TabContainer/RogButton.pressed.connect(func(): show_panel(2))
	$TextureRect/TabContainer/TeloButton.pressed.connect(func(): show_panel(3))

	var telo_panel := $TextureRect/ContentPanel/TeloPanel
	if telo_panel.has_node("ResetButton"):
		telo_panel.get_node("ResetButton").pressed.connect(_on_reset_aks_pressed)

	call_deferred("_prepare_unicorn_layers")

	_connect_shape_buttons()

	_connect_color_buttons()

func _load_from_global() -> void:
	if not has_node("/root/GlobalData"):
		return
	var g: GlobalDataManager = get_node("/root/GlobalData")
	_temp_griva_path = g.temp_griva_path
	_temp_hvost_path = g.temp_hvost_path
	_temp_rog_path   = g.temp_rog_path
	_temp_aks_path   = g.temp_aks_path
	_color_griva     = g.color_griva
	_color_hvost     = g.color_hvost
	_color_rog       = g.color_rog
	_color_aks       = g.color_aks

func _prepare_unicorn_layers() -> void:
	var main_rect: TextureRect = $TextureRect
	var base_unicorn: TextureRect = $TextureRect/Unicorn

	base_unicorn.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	base_unicorn.stretch_mode = TextureRect.STRETCH_SCALE

	var pos:  Vector2 = base_unicorn.position
	var size: Vector2 = base_unicorn.size

	_hvost_layer = _create_layer(main_rect, "HvostLayer", pos, size)
	_griva_layer = _create_layer(main_rect, "GrivaLayer", pos, size)
	_rog_layer   = _create_layer(main_rect, "RogLayer",   pos, size)
	_aks_layer   = _create_layer(main_rect, "AksLayer",   pos, size)

	var unicorn_idx: int = base_unicorn.get_index()
	main_rect.move_child(_hvost_layer, unicorn_idx)       
	main_rect.move_child(_griva_layer, unicorn_idx)     
	main_rect.move_child(_rog_layer,   unicorn_idx + 3)    
	main_rect.move_child(_aks_layer,   unicorn_idx + 4)    

	_apply_all_layers()


func _create_layer(
		parent:     Control,
		layer_name: String,
		layer_pos:  Vector2,
		layer_size: Vector2
) -> TextureRect:
	var layer := TextureRect.new()
	layer.name         = layer_name
	layer.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	layer.stretch_mode = TextureRect.STRETCH_SCALE
	layer.position     = layer_pos
	layer.size         = layer_size
	parent.add_child(layer)
	return layer

func _apply_all_layers() -> void:
	if not _griva_layer:  
		return
	_set_layer_texture(_griva_layer, _temp_griva_path)
	_set_layer_texture(_hvost_layer, _temp_hvost_path)
	_set_layer_texture(_rog_layer,   _temp_rog_path)
	_set_layer_texture(_aks_layer,   _temp_aks_path)

	_griva_layer.modulate = _color_griva
	_hvost_layer.modulate = _color_hvost
	_rog_layer.modulate   = _color_rog
	_aks_layer.modulate   = _color_aks


func _set_layer_texture(layer: TextureRect, path: String) -> void:
	if path != "" and ResourceLoader.exists(path):
		layer.texture = load(path)
	else:
		layer.texture = null

func _connect_shape_buttons() -> void:
	# Грива
	$"TextureRect/ContentPanel/GrivaPanel/1".pressed.connect(func(): _apply_element("griva", "res://assets/group/Group 129(4).png"))
	$"TextureRect/ContentPanel/GrivaPanel/2".pressed.connect(func(): _apply_element("griva", "res://assets/group/Group 129(1).png"))
	$"TextureRect/ContentPanel/GrivaPanel/3".pressed.connect(func(): _apply_element("griva", "res://assets/group/Group 129(7).png"))
	$"TextureRect/ContentPanel/GrivaPanel/4".pressed.connect(func(): _apply_element("griva", "res://assets/group/Group 129(11).png"))
	# Хвост
	$"TextureRect/ContentPanel/HvostPanel/1".pressed.connect(func(): _apply_element("hvost", "res://assets/group/Group 129(5).png"))
	$"TextureRect/ContentPanel/HvostPanel/2".pressed.connect(func(): _apply_element("hvost", "res://assets/group/Group 129(2).png"))
	$"TextureRect/ContentPanel/HvostPanel/3".pressed.connect(func(): _apply_element("hvost", "res://assets/group/Group 129(8).png"))
	$"TextureRect/ContentPanel/HvostPanel/4".pressed.connect(func(): _apply_element("hvost", "res://assets/group/Group 129(10).png"))
	# Рог
	$"TextureRect/ContentPanel/RogPanel/1".pressed.connect(func(): _apply_element("rog", "res://assets/group/Group 129(6) 1 1.png"))
	$"TextureRect/ContentPanel/RogPanel/2".pressed.connect(func(): _apply_element("rog", "res://assets/group/Group 130 1.png"))
	$"TextureRect/ContentPanel/RogPanel/3".pressed.connect(func(): _apply_element("rog", "res://assets/group/Group 129(9).png"))
	$"TextureRect/ContentPanel/RogPanel/4".pressed.connect(func(): _apply_element("rog", "res://assets/group/Group 129(12) 1 1.png"))
	# Аксессуары
	$"TextureRect/ContentPanel/TeloPanel/1".pressed.connect(func(): _apply_element("aks", "res://assets/group/Group 129(13).png"))
	$"TextureRect/ContentPanel/TeloPanel/2".pressed.connect(func(): _apply_element("aks", "res://assets/group/Group 129(15).png"))
	$"TextureRect/ContentPanel/TeloPanel/3".pressed.connect(func(): _apply_element("aks", "res://assets/group/Group 129(14).png"))
	$"TextureRect/ContentPanel/TeloPanel/4".pressed.connect(func(): _apply_element("aks", "res://assets/group/Group 129(16).png"))


func _apply_element(type: String, img_path: String) -> void:
	if not ResourceLoader.exists(img_path):
		push_warning("[Customization] Файл не найден: %s" % img_path)
		return
	var tex: Texture2D = load(img_path)
	match type:
		"griva":
			if _griva_layer: _griva_layer.texture = tex
			_temp_griva_path = img_path
		"hvost":
			if _hvost_layer: _hvost_layer.texture = tex
			_temp_hvost_path = img_path
		"rog":
			if _rog_layer: _rog_layer.texture = tex
			_temp_rog_path = img_path
		"aks":
			if _aks_layer: _aks_layer.texture = tex
			_temp_aks_path = img_path


func _connect_color_buttons() -> void:
	_connect_color_btn("TextureRect/Color/Blue",     Color.from_string("87cefa", Color.BLUE))
	_connect_color_btn("TextureRect/Color/Green",    Color.from_string("90ee90", Color.GREEN))
	_connect_color_btn("TextureRect/Color/DarkBlue", Color.from_string("3333cc", Color.DARK_BLUE))
	_connect_color_btn("TextureRect/Color/Purple",   Color.from_string("ff00ff", Color.PURPLE))
	_connect_color_btn("TextureRect/Color/Pink",     Color.from_string("ff69b4", Color.PINK))
	_connect_color_btn("TextureRect/Color/Red",      Color.from_string("ff0000", Color.RED))
	_connect_color_btn("TextureRect/Color/Yellow",   Color.from_string("feff03", Color.YELLOW))
	_connect_color_btn("TextureRect/Color/Orange",   Color.from_string("d2691e", Color.ORANGE))
	_connect_color_btn("TextureRect/Color/White",    Color.WHITE)
	_connect_color_btn("TextureRect/Color/Black",    Color.from_string("000000", Color.BLACK))


func _connect_color_btn(node_path: String, color: Color) -> void:
	if not has_node(node_path):
		return
	var btn := get_node(node_path) as Button
	btn.modulate = color
	btn.pressed.connect(func(): _apply_color(color))


func _apply_color(color: Color) -> void:
	match _current_tab:
		0:
			if _griva_layer: _griva_layer.modulate = color
			_color_griva = color
		1:
			if _hvost_layer: _hvost_layer.modulate = color
			_color_hvost = color
		2:
			if _rog_layer: _rog_layer.modulate = color
			_color_rog = color
		3:
			if _aks_layer: _aks_layer.modulate = color
			_color_aks = color

func _on_reset_aks_pressed() -> void:
	if _aks_layer:
		_aks_layer.texture  = null
		_aks_layer.modulate = Color.WHITE
	_temp_aks_path = ""
	_color_aks     = Color.WHITE

func show_panel(index: int) -> void:
	_current_tab = index
	for i: int in range(panels.size()):
		panels[i].visible = (i == index)

func _on_save_pressed() -> void:
	_commit_to_global()
	_show_save_feedback()

func _commit_to_global() -> void:
	if not has_node("/root/GlobalData"):
		push_error("[Customization] GlobalData не найден в Autoload!")
		return
	var g: GlobalDataManager = get_node("/root/GlobalData")
	g.save_unicorn_with_colors(
		_temp_griva_path, _temp_hvost_path, _temp_rog_path, _temp_aks_path,
		_color_griva, _color_hvost, _color_rog, _color_aks
	)

func _show_save_feedback() -> void:
	if not has_node("TextureRect/SaveButton"):
		return
	if _save_tween:
		_save_tween.kill()
	var btn := $TextureRect/SaveButton as Button
	_save_tween = create_tween()
	_save_tween.tween_property(btn, "modulate", Color(0.4, 1.0, 0.4), 0.15)
	_save_tween.tween_property(btn, "modulate", Color.WHITE, 0.4)

func _on_back_pressed() -> void:
	_commit_to_global()
	get_tree().change_scene_to_file("res://scenes/mainmenu.tscn")
