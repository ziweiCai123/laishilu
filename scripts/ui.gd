extends CanvasLayer
## 纸感 UI:靠近提示、记忆卡、计数、开场引导

var card_open := false
var _near := 0
var _mem_got := 0
var _mem_total := 0
var _motes := 0
var prompt: Label
var card: PanelContainer
var title_l: Label
var date_l: Label
var body_l: Label
var photo: TextureRect
var counter: Label
var chapter_box: VBoxContainer
var chapter_title: Label
var chapter_body: Label
var _ch_tw: Tween
var sit_hint: Label
var hint_l: Label
var _hint_tw: Tween
var player: CharacterBody3D
var intro: Label

func _ready() -> void:
	var zh := SystemFont.new()
	zh.font_names = PackedStringArray(["Microsoft YaHei UI", "Microsoft YaHei", "SimHei"])
	player = get_node("../Player")

	counter = Label.new()
	counter.add_theme_font_override("font", zh)
	counter.add_theme_font_size_override("font_size", 15)
	counter.add_theme_color_override("font_color", Color(0.97, 0.93, 0.8))
	counter.add_theme_color_override("font_shadow_color", Color(0.08, 0.1, 0.12, 0.6))
	counter.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	counter.offset_left = 22.0
	counter.offset_top = 16.0
	counter.offset_right = 460.0
	counter.offset_bottom = 44.0
	add_child(counter)
	counter.visible = false

	prompt = Label.new()
	prompt.text = "按 E · 触碰这段记忆"
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_override("font", zh)
	prompt.add_theme_font_size_override("font_size", 19)
	prompt.add_theme_color_override("font_color", Color(0.98, 0.94, 0.82))
	prompt.add_theme_color_override("font_shadow_color", Color(0.1, 0.12, 0.14, 0.55))
	prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	prompt.offset_left = -200.0
	prompt.offset_right = 200.0
	prompt.offset_top = -150.0
	prompt.offset_bottom = -118.0
	prompt.visible = false
	add_child(prompt)

	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cc)

	card = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.957, 0.937, 0.902, 0.96)
	sb.border_color = Color(0.659, 0.529, 0.31)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	sb.content_margin_left = 32.0
	sb.content_margin_right = 32.0
	sb.content_margin_top = 26.0
	sb.content_margin_bottom = 24.0
	card.add_theme_stylebox_override("panel", sb)
	card.custom_minimum_size = Vector2(480, 0)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	card.add_child(vb)

	title_l = Label.new()
	title_l.add_theme_font_override("font", zh)
	title_l.add_theme_font_size_override("font_size", 24)
	title_l.add_theme_color_override("font_color", Color(0.48, 0.39, 0.22))
	vb.add_child(title_l)

	date_l = Label.new()
	date_l.add_theme_font_override("font", zh)
	date_l.add_theme_font_size_override("font_size", 13)
	date_l.add_theme_color_override("font_color", Color(0.6, 0.56, 0.47))
	vb.add_child(date_l)

	photo = TextureRect.new()
	photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	photo.custom_minimum_size = Vector2(0, 260)
	photo.visible = false
	vb.add_child(photo)

	body_l = Label.new()
	body_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_l.add_theme_font_override("font", zh)
	body_l.add_theme_font_size_override("font_size", 17)
	body_l.add_theme_color_override("font_color", Color(0.23, 0.25, 0.28))
	vb.add_child(body_l)

	var hint := Label.new()
	hint.text = "E · 合上"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_override("font", zh)
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.6, 0.56, 0.47))
	vb.add_child(hint)

	card.visible = false
	card.modulate.a = 0.0
	cc.add_child(card)

	intro = Label.new()
	intro.text = "WASD 行走 · 空格 跳起后按住滑翔\nE 触碰路边的光 · Q 回响寻光 · X 坐下 · C 留灯\nEsc 歇一歇"
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro.add_theme_font_override("font", zh)
	intro.add_theme_font_size_override("font_size", 16)
	intro.add_theme_color_override("font_color", Color(0.97, 0.94, 0.85))
	intro.add_theme_color_override("font_shadow_color", Color(0.1, 0.12, 0.14, 0.5))
	intro.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	intro.offset_left = -320.0
	intro.offset_right = 320.0
	intro.offset_top = -240.0
	intro.offset_bottom = -178.0
	intro.modulate.a = 0.0
	add_child(intro)

	sit_hint = Label.new()
	sit_hint.text = "X · 起身"
	sit_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sit_hint.add_theme_font_override("font", zh)
	sit_hint.add_theme_font_size_override("font_size", 14)
	sit_hint.add_theme_color_override("font_color", Color(0.95, 0.91, 0.78))
	sit_hint.add_theme_color_override("font_shadow_color", Color(0.1, 0.12, 0.14, 0.5))
	sit_hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	sit_hint.offset_left = -80.0
	sit_hint.offset_right = 80.0
	sit_hint.offset_top = -104.0
	sit_hint.offset_bottom = -80.0
	sit_hint.visible = false
	add_child(sit_hint)

	hint_l = Label.new()
	hint_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_l.add_theme_font_override("font", zh)
	hint_l.add_theme_font_size_override("font_size", 16)
	hint_l.add_theme_color_override("font_color", Color(0.97, 0.93, 0.8))
	hint_l.add_theme_color_override("font_shadow_color", Color(0.1, 0.12, 0.14, 0.55))
	hint_l.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	hint_l.offset_left = -240.0
	hint_l.offset_right = 240.0
	hint_l.offset_top = -196.0
	hint_l.offset_bottom = -164.0
	hint_l.visible = false
	add_child(hint_l)

	chapter_box = VBoxContainer.new()
	chapter_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	chapter_box.offset_left = -360.0
	chapter_box.offset_right = 360.0
	chapter_box.offset_top = 110.0
	chapter_box.offset_bottom = 420.0
	chapter_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chapter_box.modulate.a = 0.0
	add_child(chapter_box)
	chapter_title = Label.new()
	chapter_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chapter_title.add_theme_font_override("font", zh)
	chapter_title.add_theme_font_size_override("font_size", 27)
	chapter_title.add_theme_color_override("font_color", Color(0.99, 0.95, 0.8))
	chapter_title.add_theme_color_override("font_shadow_color", Color(0.1, 0.12, 0.14, 0.55))
	chapter_box.add_child(chapter_title)
	chapter_body = Label.new()
	chapter_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chapter_body.add_theme_font_override("font", zh)
	chapter_body.add_theme_font_size_override("font_size", 17)
	chapter_body.add_theme_color_override("font_color", Color(0.96, 0.93, 0.85))
	chapter_body.add_theme_color_override("font_shadow_color", Color(0.1, 0.12, 0.14, 0.5))
	chapter_box.add_child(chapter_body)

func set_memory_counts(got: int, total: int) -> void:
	_mem_got = got
	_mem_total = total
	_update_counter()

func set_motes(n: int) -> void:
	_motes = n
	_update_counter()

func _update_counter() -> void:
	counter.text = "◈ 记忆 %d / %d      ✦ 光屑 %d" % [_mem_got, _mem_total, _motes]

func show_chapter(title: String, text: String) -> void:
	if _ch_tw and _ch_tw.is_valid():
		_ch_tw.kill()
	chapter_title.text = title
	chapter_body.text = text
	chapter_box.modulate.a = 0.0
	_ch_tw = create_tween()
	_ch_tw.tween_property(chapter_box, "modulate:a", 1.0, 1.6)
	_ch_tw.tween_interval(4.8)
	_ch_tw.tween_property(chapter_box, "modulate:a", 0.0, 2.4)

func play_intro() -> void:
	var tw := create_tween()
	tw.tween_property(intro, "modulate:a", 1.0, 1.4)
	tw.tween_interval(7.0)
	tw.tween_property(intro, "modulate:a", 0.0, 2.2)

func flash_hint(text: String) -> void:
	if _hint_tw and _hint_tw.is_valid():
		_hint_tw.kill()
	hint_l.text = text
	hint_l.visible = true
	hint_l.modulate.a = 1.0
	_hint_tw = create_tween()
	_hint_tw.tween_interval(2.4)
	_hint_tw.tween_property(hint_l, "modulate:a", 0.0, 1.2)
	_hint_tw.tween_callback(func() -> void: hint_l.visible = false)

func _process(_delta: float) -> void:
	sit_hint.visible = player.sitting and not card_open

func show_prompt(v: bool) -> void:
	_near = maxi(0, _near + (1 if v else -1))
	prompt.visible = _near > 0 and not card_open

func show_memory(m: Dictionary) -> void:
	card_open = true
	prompt.visible = false
	title_l.text = str(m.get("title", "记忆"))
	date_l.text = str(m.get("date", ""))
	var t := str(m.get("type", "whisper"))
	photo.visible = false
	if t == "photo" and str(m.get("image", "")) != "":
		var p := "res://assets/photos/" + str(m.get("image"))
		if ResourceLoader.exists(p):
			photo.texture = load(p)
			photo.visible = true
	if t == "photo":
		body_l.text = str(m.get("caption", ""))
	else:
		body_l.text = str(m.get("text", ""))
	card.visible = true
	create_tween().tween_property(card, "modulate:a", 1.0, 0.35)

func hide_card() -> void:
	if not card_open:
		return
	card_open = false
	var tw := create_tween()
	tw.tween_property(card, "modulate:a", 0.0, 0.22)
	tw.tween_callback(func() -> void:
		card.visible = false
		prompt.visible = _near > 0
	)

func _unhandled_input(event: InputEvent) -> void:
	if card_open and event is InputEventKey and event.pressed and not event.echo \
			and (event.physical_keycode == KEY_E or event.physical_keycode == KEY_ESCAPE):
		hide_card()
		get_viewport().set_input_as_handled()
