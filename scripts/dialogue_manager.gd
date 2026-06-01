extends Node

signal dialogue_finished
signal line_changed(line_data: Dictionary) 

@export var dialogue_box   : Control
@export var speaker_label  : Label
@export var text_label     : RichTextLabel
@export var continue_hint  : Label

const TYPING_SPEED := 0.035

var _lines: Array[Dictionary] = []
var _index: int = 0
var _typing: bool = false

func start(lines: Array[Dictionary]) -> void:
    _lines = lines
    _index = 0
    
    if not dialogue_box or not speaker_label or not text_label:
        push_error("DialogueManager: Не все узлы привязаны в Инспекторе!")
        return
        
    dialogue_box.visible = true
    _show_line()

func _show_line() -> void:
    if _index >= _lines.size():
        dialogue_box_hide()
        return

    var line: Dictionary = _lines[_index]
    line_changed.emit(line) 
    
    speaker_label.text = line.get("speaker", "")
    speaker_label.visible = speaker_label.text != ""
    text_label.text = ""
    
    if continue_hint:
        continue_hint.visible = false
        
    _typing = true
    _type_text(line.get("text", ""))

func _type_text(full: String) -> void:
    for i in full.length():
        if not _typing:
            text_label.text = full
            break
            
        text_label.text += full[i]
        
        # Звук печати
        if i % 8 == 0:  # каждый второй символ
            var audio = get_node_or_null("/root/AudioManager")
            if audio:
                audio.play_typing()
        
        await get_tree().create_timer(TYPING_SPEED).timeout
    
    _typing = false
    if continue_hint:
        continue_hint.visible = true

func advance() -> void:
    if _typing:
        _typing = false
    else:
        _index += 1
        _show_line()

func dialogue_box_hide() -> void:
    if dialogue_box:
        dialogue_box.visible = false
    dialogue_finished.emit()
