# scripts/save_system.gd
# ── Зарегистрируй как Autoload с именем "SaveSystem" ──────────────────────────
# Project → Project Settings → Autoload → + → scripts/save_system.gd → Name: SaveSystem
extends Node
class_name SaveSystemManager

signal saves_updated

const SAVE_PATH : String = "user://game_saves.json"
const MAX_SLOTS : int    = 3

## Человекочитаемые названия сцен для отображения в UI.
const SCENE_LABELS: Dictionary = {
  "res://scenes/prologue.tscn":  "Пролог",
  "res://scenes/mission_1.tscn": "Миссия 1 — Студент в панике",
  "res://scenes/mission_2.tscn": "Миссия 2 — Личная жизнь Алисы",
  "res://scenes/mission_3.tscn": "Миссия 3 — Вода в пустыне",
}

# Каждый слот: { id, scene_path, label, date, time, ts }
var _slots: Array[Dictionary] = []

# ── Lifecycle ────────────────────────────────────────────────────────────────
func _ready() -> void:
  _load_from_disk()

# ── Public API ───────────────────────────────────────────────────────────────
func get_slots() -> Array[Dictionary]:
  return _slots.duplicate(true)

func get_count() -> int:
  return _slots.size()

func can_add() -> bool:
  return _slots.size() < MAX_SLOTS

func label_for(scene_path: String) -> String:
  return SCENE_LABELS.get(scene_path, "Неизвестная сцена")

## Создаёт новый слот для указанной сцены.
## Возвращает false, если достигнут лимит.
func create_save(scene_path: String) -> bool:
  if not can_add():
    return false

  var dt := Time.get_datetime_dict_from_system()
  _slots.append({
    "id":         Time.get_ticks_msec(),
    "scene_path": scene_path,
    "label":      label_for(scene_path),
    "date":       "%02d.%02d.%04d" % [dt.day,   dt.month, dt.year],
    "time":       "%02d:%02d"       % [dt.hour,  dt.minute],
    "ts":          Time.get_unix_time_from_system(),
  })
  _persist()
  saves_updated.emit()
  return true

## Удаляет слот по индексу (0-based).
func delete_at(index: int) -> void:
  if index < 0 or index >= _slots.size():
    return
  _slots.remove_at(index)
  _persist()
  saves_updated.emit()

## Удаляет последний добавленный слот.
func delete_last() -> void:
  if not _slots.is_empty():
    _slots.pop_back()
    _persist()
    saves_updated.emit()

## Возвращает путь к сцене слота по индексу, "" при ошибке.
func scene_at(index: int) -> String:
  if index < 0 or index >= _slots.size():
    return ""
  return _slots[index].get("scene_path", "")

# ── Disk I/O ─────────────────────────────────────────────────────────────────
func _persist() -> void:
  var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
  if not file:
    push_error("[SaveSystem] Не удалось открыть файл для записи: %s" % SAVE_PATH)
    return
  file.store_string(JSON.stringify(_slots, "\t"))
  file.close()

func _load_from_disk() -> void:
  if not FileAccess.file_exists(SAVE_PATH):
    return
  var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
  if not file:
    push_error("[SaveSystem] Не удалось открыть файл для чтения: %s" % SAVE_PATH)
    return
  var raw := file.get_as_text()
  file.close()

  var j := JSON.new()
  if j.parse(raw) != OK:
    push_error("[SaveSystem] Ошибка парсинга JSON: %s" % j.get_error_message())
    return

  var data: Variant = j.get_data()
  if data is Array:
    _slots.clear()
    for entry: Variant in data:
      if entry is Dictionary:
        _slots.append(entry as Dictionary)
  print("[SaveSystem] Загружено слотов: %d" % _slots.size())
