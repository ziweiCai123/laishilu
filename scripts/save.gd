extends Node
## 存档:记忆/光屑/灯火/步数/设置,持久于 user://laishilu_save.json

var data := {}

func _ready() -> void:
	data = {
		"collected": [], "motes": [], "lanterns": [], "steps": 0,
		"settings": {"vol": 0.9, "sens": 1.0, "quality": "high"}
	}
	var f := FileAccess.open("user://laishilu_save.json", FileAccess.READ)
	if f:
		var parsed: Variant = JSON.parse_string(f.get_as_text())
		if parsed is Dictionary:
			for k in ["collected", "motes", "lanterns"]:
				if parsed.get(k) is Array:
					data[k] = parsed[k]
			data["steps"] = int(parsed.get("steps", 0))
			var s: Variant = parsed.get("settings", {})
			if s is Dictionary:
				data["settings"].merge(s, true)

func flush() -> void:
	var f := FileAccess.open("user://laishilu_save.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))

func has_collected(id: String) -> bool:
	return data["collected"].has(id)

func collect_memory(id: String) -> void:
	if not data["collected"].has(id):
		data["collected"].append(id)
		flush()

func collect_mote(i: int) -> bool:
	if data["motes"].has(i):
		return false
	data["motes"].append(i)
	flush()
	return true

func add_lantern(pos: Vector3) -> void:
	data["lanterns"].append({"x": pos.x, "y": pos.y, "z": pos.z})
	flush()

func add_steps(d: float) -> void:
	data["steps"] = int(data["steps"]) + int(d)
