# scripts/save_system.gd
extends Node
class_name SaveSystemManager

signal saves_updated

const SAVE_PATH : String = "user://game_saves.json"
const MAX_SLOTS : int    = 3

const SCENE_LABELS: Dictionary = {
  "res://scenes/prologue.tscn":  "Пролог",
  "res://scenes/mission_1.tscn": "Миссия 1 — Студент в панике",
  "res://scenes/mission_2.tscn": "Миссия 2 — Личная жизнь Алисы",
  "res://scenes/mission_3.tscn": "Миссия 3 — Вода в пустыне",
}

var _slots: Array[Dictionary] = []

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

## Создаёт новый слот. Присваивает наименьший свободный порядковый номер (1–3).
## Возвращает false если достигнут лимит.
func create_save(scene_path: String) -> bool:
  if not can_add():
    return false

  var dt := Time.get_datetime_dict_from_system()
  _slots.append({
    "id":         Time.get_ticks_msec(),
    "number":     _get_next_slot_number(),   # ← порядковый номер
    "scene_path": scene_path,
    "label":      label_for(scene_path),
    "date":       "%02d.%02d.%04d" % [dt.day, dt.month, dt.year],
    "time":       "%02d:%02d"      % [dt.hour, dt.minute],
    "ts":          Time.get_unix_time_from_system(),
  })
  _persist()
  saves_updated.emit()
  return true

func delete_at(index: int) -> void:
  if index < 0 or index >= _slots.size():
    return
  _slots.remove_at(index)
  _persist()
  saves_updated.emit()

## Оставлен для совместимости, но теперь не используется в главном меню.
func delete_last() -> void:
  if not _slots.is_empty():
    _slots.pop_back()
    _persist()
    saves_updated.emit()

func scene_at(index: int) -> String:
  if index < 0 or index >= _slots.size():
    return ""
  return _slots[index].get("scene_path", "")

# ── Helpers ──────────────────────────────────────────────────────────────────

## Возвращает наименьший незанятый номер из диапазона 1..MAX_SLOTS.
func _get_next_slot_number() -> int:
  # Собираем уже занятые номера
  var used: Array[int] = []
  for slot: Dictionary in _slots:
    var n: int = slot.get("number", 0)
    if n > 0:
      used.append(n)

  # Ищем первый свободный
  for n: int in range(1, MAX_SLOTS + 1):
    if n not in used:
      return n

  return _slots.size() + 1  # fallback (не должен достигаться при лимите 3)

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

  # Миграция: старые сохранения без поля "number" получают номер по позиции
  for i: int in range(_slots.size()):
    if not _slots[i].has("number"):
      _slots[i]["number"] = i + 1

  print("[SaveSystem] Загружено слотов: %d" % _slots.size())
