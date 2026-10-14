extends CanvasLayer
## 标题 · 歇一歇 · 回忆册 · 设置 · 尾声

signal started

var state := "title"   # title / play / pause / book / stars / settings / end
var player: CharacterBody3D
var mem: Node3D
var ui: CanvasLayer
var _ses_t := 0.0
var zh: SystemFont
var _btn: StyleBoxFlat
var _title_root: Control
var _pause_root: Control
var _book_root: Control
var _set_root: Control
var _stars_root: Control
var _end_root: Control
var _book_list: VBoxContainer
var _book_detail: VBoxContainer
var _title_hint: Label
var _stats_l: Label
var _quality_btn: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	player = get_node("../Player")
	mem = get_node("../Memories")
	ui = get_node("../UI")
	zh = SystemFont.new()
	zh.font_names = PackedStringArray(["Microsoft YaHei UI", "Microsoft YaHei", "SimHei"])
	_btn = StyleBoxFlat.new()
	_btn.bg_color = Color(0.945, 0.925, 0.885, 0.97)
	_btn.border_color = Color(0.659, 0.529, 0.31)
	_btn.set_border_width_all(1)
	_btn.set_corner_radius_all(2)
	_btn.content_margin_left = 20.0
	_btn.content_margin_right = 20.0
	_btn.content_margin_top = 9.0
	_btn.content_margin_bottom = 9.0
	_build_title()
	_build_pause()
	_build_book()
	_build_stars()
	_build_settings()
	_build_end()

func _label(text: String, size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", zh)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l

func _btn_box(texts: Array) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	for t in texts:
		v.add_child(_menu_button(t[0], t[1]))
	return v

func _menu_button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_override("font", zh)
	b.add_theme_font_size_override("font_size", 17)
	b.add_theme_color_override("font_color", Color(0.30, 0.27, 0.20))
	b.add_theme_color_override("font_hover_color", Color(0.14, 0.12, 0.08))
	var hb: StyleBoxFlat = _btn.duplicate()
	hb.bg_color = Color(0.90, 0.86, 0.78)
	b.add_theme_stylebox_override("normal", _btn.duplicate())
	b.add_theme_stylebox_override("hover", hb)
	b.add_theme_stylebox_override("pressed", hb)
	b.pressed.connect(cb)
	return b

func _dim(col: Color) -> ColorRect:
	var r := ColorRect.new()
	r.color = col
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return r

func _show(c: Control) -> void:
	c.visible = true
	c.modulate.a = 0.0
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(c, "modulate:a", 1.0, 0.5)

func _fade_out(c: Control) -> void:
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(c, "modulate:a", 0.0, 0.6)
	tw.tween_callback(func() -> void: c.visible = false)

# ---------- 标题 ----------

func _build_title() -> void:
	_title_root = _dim(Color(0.07, 0.09, 0.11, 0.30))
	add_child(_title_root)
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_title_root.add_child(cc)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 12)
	cc.add_child(v)
	v.add_child(_label("来时路", 52, Color(0.985, 0.955, 0.86)))
	v.add_child(_label("· The Road Hither ·", 15, Color(0.92, 0.88, 0.78, 0.8)))
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 46)
	v.add_child(sp)
	_title_hint = _label("点一下,或按任意键 · 开始行走", 16, Color(0.96, 0.93, 0.84))
	v.add_child(_title_hint)
	var tw := create_tween().set_loops()
	tw.tween_property(_title_hint, "modulate:a", 0.4, 1.4).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_title_hint, "modulate:a", 1.0, 1.4).set_trans(Tween.TRANS_SINE)

func _start_game() -> void:
	if state != "title":
		return
	state = "play"
	_ses_t = 0.0
	_fade_out(_title_root)
	player.control_enabled = true
	ui.counter.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	ui.play_intro()
	started.emit()

# ---------- 暂停 ----------

func _build_pause() -> void:
	_pause_root = _dim(Color(0.05, 0.06, 0.08, 0.52))
	_pause_root.visible = false
	add_child(_pause_root)
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_root.add_child(cc)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 22)
	cc.add_child(v)
	v.add_child(_label("歇 一 歇", 24, Color(0.97, 0.94, 0.85)))
	v.add_child(_btn_box([
		["继续行走", _resume],
		["回忆册", _open_book],
		["星 图", _open_stars],
		["设 置", _open_settings],
		["回到标题", _to_title],
		["离开山谷", _quit]
	]))

func _pause() -> void:
	if state != "play":
		return
	state = "pause"
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_show(_pause_root)

func _resume() -> void:
	state = "play"
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_fade_out(_pause_root)

func _open_book() -> void:
	state = "book"
	_rebuild_book()
	_fade_out(_pause_root)
	_show(_book_root)

func _open_settings() -> void:
	state = "settings"
	_fade_out(_pause_root)
	_show(_set_root)

func _open_stars() -> void:
	state = "stars"
	_fade_out(_pause_root)
	_show(_stars_root)

func _sub_back() -> void:
	state = "pause"
	var cur := _book_root if _book_root.visible else _set_root
	if _stars_root.visible:
		cur = _stars_root
	_fade_out(cur)
	_show(_pause_root)

func _to_title() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _quit() -> void:
	get_tree().quit()

# ---------- 回忆册 ----------

func _build_book() -> void:
	_book_root = _dim(Color(0.05, 0.06, 0.08, 0.45))
	_book_root.visible = false
	add_child(_book_root)
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_book_root.add_child(cc)
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.957, 0.937, 0.902, 0.98)
	sb.border_color = Color(0.659, 0.529, 0.31)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	sb.content_margin_left = 26.0
	sb.content_margin_right = 26.0
	sb.content_margin_top = 22.0
	sb.content_margin_bottom = 20.0
	panel.add_theme_stylebox_override("panel", sb)
	panel.custom_minimum_size = Vector2(880, 540)
	cc.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)
	v.add_child(_label("回 忆 册", 22, Color(0.48, 0.39, 0.22)))
	v.add_child(_label("拾起过的,都在这里;还在雾里的,替你守着。", 12, Color(0.6, 0.56, 0.47)))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 22)
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(h)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(270, 400)
	h.add_child(scroll)
	_book_list = VBoxContainer.new()
	_book_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_book_list.add_theme_constant_override("separation", 4)
	scroll.add_child(_book_list)
	_book_detail = VBoxContainer.new()
	_book_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_book_detail.add_theme_constant_override("separation", 7)
	h.add_child(_book_detail)
	var back := _menu_button("返回", _sub_back)
	v.add_child(back)

func _rebuild_book() -> void:
	for c in _book_list.get_children():
		c.queue_free()
	var any := false
	for n in mem.nodes:
		var m: Dictionary = n.memory
		var b := Button.new()
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_override("font", zh)
		b.add_theme_font_size_override("font_size", 15)
		b.add_theme_color_override("font_hover_color", Color(0.14, 0.12, 0.08))
		if n.is_collected:
			any = true
			b.text = "◆  " + str(m.get("title", "记忆"))
			b.add_theme_color_override("font_color", Color(0.30, 0.27, 0.20))
			b.pressed.connect(_book_show.bind(n))
		else:
			b.text = "◇  尚未拾起"
			b.add_theme_color_override("font_color", Color(0.64, 0.60, 0.52))
			b.disabled = true
		_book_list.add_child(b)
	if any:
		for n in mem.nodes:
			if n.is_collected:
				_book_show(n)
				break

func _book_show(n) -> void:
	for c in _book_detail.get_children():
		c.queue_free()
	var m: Dictionary = n.memory
	var t := _label(str(m.get("title", "记忆")), 21, Color(0.48, 0.39, 0.22))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_book_detail.add_child(t)
	var d := _label(str(m.get("date", "")), 12, Color(0.6, 0.56, 0.47))
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_book_detail.add_child(d)
	var tn := str(m.get("type", "whisper"))
	var type_cn := "一段悄悄话"
	if tn == "photo":
		type_cn = "一张照片"
	elif tn == "object":
		type_cn = "一件小物"
	var ty := _label(type_cn, 12, Color(0.6, 0.56, 0.47))
	ty.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_book_detail.add_child(ty)
	if tn == "photo" and str(m.get("image", "")) != "":
		var p := "res://assets/photos/" + str(m.get("image"))
		if ResourceLoader.exists(p):
			var ph := TextureRect.new()
			ph.texture = load(p)
			ph.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ph.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			ph.custom_minimum_size = Vector2(0, 230)
			_book_detail.add_child(ph)
	var body := _label(str(m.get("caption", "")) if tn == "photo" else str(m.get("text", "")), 16, Color(0.23, 0.25, 0.28))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_book_detail.add_child(body)

# ---------- 星图 ----------

func _build_stars() -> void:
	_stars_root = _dim(Color(0.04, 0.05, 0.09, 0.97))
	_stars_root.visible = false
	add_child(_stars_root)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 10)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stars_root.add_child(v)
	v.add_child(_label("成 长 星 图", 22, Color(0.97, 0.93, 0.80)))
	v.add_child(_label("亮着的是你拾回的光,按拾起的顺序连成星座。", 12, Color(0.72, 0.74, 0.82)))
	var cc := CenterContainer.new()
	cc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(cc)
	var sf := StarField.new()
	sf.mem = mem
	sf.custom_minimum_size = Vector2(760, 440)
	cc.add_child(sf)
	var bc := CenterContainer.new()
	v.add_child(bc)
	bc.add_child(_menu_button("返回", _sub_back))

class StarField extends Control:
	var mem: Node3D
	var _t := 0.0

	func _process(_delta: float) -> void:
		_t += _delta
		queue_redraw()

	func _pos_for(id: String, cx: float, cy: float, rad: float) -> Vector2:
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(id)
		var ang := rng.randf() * TAU
		var rr := (0.22 + 0.78 * rng.randf()) * rad
		return Vector2(cx + cos(ang) * rr, cy + sin(ang) * rr * 0.78)

	func _draw() -> void:
		var cx := size.x * 0.5
		var cy := size.y * 0.5
		var rad := minf(size.x, size.y) * 0.42
		var fr := RandomNumberGenerator.new()
		fr.seed = 99
		for i in 110:
			var p := Vector2(fr.randf_range(0.0, size.x), fr.randf_range(0.0, size.y))
			var a := fr.randf_range(0.05, 0.20) * (0.7 + 0.3 * sin(_t * 1.4 + i))
			draw_circle(p, fr.randf_range(0.6, 1.5), Color(0.82, 0.86, 0.96, a))
		if mem == null:
			return
		var pts := {}
		for n in mem.nodes:
			var id: String = str(n.memory.get("id", ""))
			pts[id] = [self._pos_for(id, cx, cy, rad), n.is_collected]
		var got: Array = Save.data["collected"]
		var prev := Vector2.ZERO
		var prev_ok := false
		for id in got:
			var sid := str(id)
			if not pts.has(sid):
				continue
			var p: Vector2 = pts[sid][0]
			if prev_ok:
				draw_line(prev, p, Color(1.0, 0.88, 0.55, 0.30), 1.0)
			prev = p
			prev_ok = true
		for id in pts:
			var e: Array = pts[id]
			var p2: Vector2 = e[0]
			if e[1]:
				var tw: float = 0.8 + 0.2 * sin(_t * 2.2 + p2.x)
				draw_circle(p2, 7.5, Color(1.0, 0.9, 0.6, 0.10 * tw))
				draw_circle(p2, 3.2 * tw, Color(1.0, 0.94, 0.70, 0.95))
			else:
				draw_arc(p2, 2.6, 0, TAU, 14, Color(0.72, 0.75, 0.85, 0.30), 1.0)

# ---------- 设置 ----------

func _build_settings() -> void:
	_set_root = _dim(Color(0.05, 0.06, 0.08, 0.52))
	_set_root.visible = false
	add_child(_set_root)
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_set_root.add_child(cc)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 18)
	cc.add_child(v)
	v.add_child(_label("设 置", 24, Color(0.97, 0.94, 0.85)))
	v.add_child(_slider_row("主音量", 0.0, 1.0, 0.05, float(Save.data["settings"]["vol"]), _on_vol))
	v.add_child(_slider_row("鼠标灵敏度", 0.4, 2.0, 0.05, float(Save.data["settings"]["sens"]), _on_sens))
	_quality_btn = _menu_button(_quality_text(), _on_quality)
	var qwrap := CenterContainer.new()
	qwrap.add_child(_quality_btn)
	v.add_child(qwrap)
	v.add_child(_btn_box([["返回", _sub_back]]))

func _slider_row(name_s: String, mn: float, mx: float, st: float, val: float, cb: Callable) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	var l := _label(name_s, 15, Color(0.93, 0.90, 0.80))
	l.custom_minimum_size = Vector2(120, 0)
	h.add_child(l)
	var s := HSlider.new()
	s.min_value = mn
	s.max_value = mx
	s.step = st
	s.value = val
	s.custom_minimum_size = Vector2(220, 20)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.value_changed.connect(cb)
	h.add_child(s)
	var vl := _label("%d%%" % int(val * 100), 14, Color(0.93, 0.90, 0.80))
	vl.custom_minimum_size = Vector2(52, 0)
	s.value_changed.connect(func(v2: float) -> void: vl.text = "%d%%" % int(v2 * 100))
	h.add_child(vl)
	return h

func _on_vol(v: float) -> void:
	Save.data["settings"]["vol"] = v
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(v, 0.0001)))
	Save.flush()

func _on_sens(v: float) -> void:
	Save.data["settings"]["sens"] = v
	player.mouse_sens = 0.0021 * v
	Save.flush()

func _quality_text() -> String:
	return "画质 · 高" if str(Save.data["settings"]["quality"]) == "high" else "画质 · 低"

func _on_quality() -> void:
	var high := str(Save.data["settings"]["quality"]) != "high"
	Save.data["settings"]["quality"] = "high" if high else "low"
	get_parent().apply_quality(high)
	_quality_btn.text = _quality_text()
	Save.flush()

# ---------- 尾声 ----------

func _build_end() -> void:
	_end_root = _dim(Color(0.09, 0.07, 0.05, 0.78))
	_end_root.visible = false
	add_child(_end_root)
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_end_root.add_child(cc)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 14)
	cc.add_child(v)
	v.add_child(_label("来时路", 36, Color(0.985, 0.955, 0.86)))
	v.add_child(_label("· 尾 声 ·", 14, Color(0.92, 0.88, 0.78, 0.85)))
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 14)
	v.add_child(sp)
	_stats_l = _label("", 17, Color(0.95, 0.92, 0.83))
	v.add_child(_stats_l)
	var sp2 := Control.new()
	sp2.custom_minimum_size = Vector2(0, 10)
	v.add_child(sp2)
	v.add_child(_label("「雪的尽头,是你走过的全部路。」", 15, Color(0.90, 0.85, 0.72)))
	var sp3 := Control.new()
	sp3.custom_minimum_size = Vector2(0, 22)
	v.add_child(sp3)
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 16)
	v.add_child(h)
	var stay := _menu_button("留在山谷", _stay)
	var again := _menu_button("回到标题", _to_title)
	h.add_child(stay)
	h.add_child(again)

func show_ending() -> void:
	if state == "end":
		return
	state = "end"
	player.control_enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var got := 0
	for n in mem.nodes:
		if n.is_collected:
			got += 1
	_stats_l.text = "拾起记忆 %d / %d\n光屑 %d / 40\n灯火 %d 盏\n走过 %d 步 · 山中 %d 分钟" % [
		got, mem.nodes.size(), Save.data["motes"].size(),
		Save.data["lanterns"].size(), int(Save.data["steps"]), int(_ses_t / 60.0)
	]
	_show(_end_root)

func _stay() -> void:
	state = "play"
	player.control_enabled = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_fade_out(_end_root)

# ---------- 输入 ----------

func _unhandled_input(event: InputEvent) -> void:
	if state == "title":
		if (event is InputEventKey and event.pressed and not event.echo) \
				or (event is InputEventMouseButton and event.pressed):
			_start_game()
			get_viewport().set_input_as_handled()
		return
	if state == "play":
		if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
			if ui.card_open:
				return
			_pause()
			get_viewport().set_input_as_handled()
	elif state == "pause":
		if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
			_resume()
			get_viewport().set_input_as_handled()
	elif state == "book" or state == "settings" or state == "stars":
		if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
			_sub_back()
			get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if state == "play" and not get_tree().paused:
		_ses_t += delta
