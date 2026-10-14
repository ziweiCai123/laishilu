extends Node3D
## 情境化首次提示:每局一次,在恰当的时刻轻声说

var player: CharacterBody3D
var mem: Node3D
var ui: CanvasLayer
var _q := false
var _x := false
var _c := false
var _idle := 0.0
var _c_wait := -1.0

func _ready() -> void:
	player = get_node("../Player")
	mem = get_node("../Memories")
	ui = get_node("../UI")

func _process(delta: float) -> void:
	if not player.control_enabled:
		return
	if not _q and player.position.z < -62.0 and _uncollected() > 0:
		_q = true
		ui.flash_hint("按 Q · 回响,雾里寻光")
	if not _c:
		if _total() - _uncollected() >= 1 and _c_wait < 0.0:
			_c_wait = 8.0
		if _c_wait > 0.0:
			_c_wait -= delta
			if _c_wait <= 0.0:
				_c = true
				ui.flash_hint("C · 在喜欢的地方留一盏灯,给下次的自己")
	var moving := Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_A) \
		or Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_D) \
		or Input.is_physical_key_pressed(KEY_SPACE)
	if not _x and player.is_on_floor() and not player.sitting and not moving:
		_idle += delta
		if _idle > 20.0:
			_x = true
			ui.flash_hint("走累了,就按 X · 坐下歇歇")
	else:
		_idle = 0.0

func _uncollected() -> int:
	var n := 0
	for m in mem.nodes:
		if not m.is_collected:
			n += 1
	return n

func _total() -> int:
	return mem.nodes.size()
