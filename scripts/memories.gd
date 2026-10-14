extends Node3D
## 读取 memories.json,在来时路上点亮记忆;Q 回响时唤醒最近的光柱

var nodes: Array = []

func _ready() -> void:
	add_to_group("memories")
	var f := FileAccess.open("res://memories.json", FileAccess.READ)
	if f == null:
		push_warning("memories.json 不存在")
		return
	var data: Variant = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		push_warning("memories.json 解析失败")
		return
	var terrain := get_node("../Terrain")
	for m: Dictionary in data.get("memories", []):
		var pos: Array = m.get("pos", [0.0, 0.0])
		if pos.size() < 2:
			continue
		var node := Area3D.new()
		node.set_script(load("res://scripts/memory_node.gd"))
		node.memory = m
		node.position = Vector3(float(pos[0]), terrain.height(float(pos[0]), float(pos[1])) + 1.5, float(pos[1]))
		node.near_changed.connect(_on_near)
		node.picked.connect(_on_picked)
		add_child(node)
		nodes.append(node)
	await get_tree().process_frame
	var got := 0
	for n in nodes:
		if n.is_collected:
			got += 1
	get_node("../UI").set_memory_counts(got, nodes.size())

func _on_near(near: bool) -> void:
	get_node("../UI").show_prompt(near)

func _on_picked(id: String) -> void:
	Save.collect_memory(id)
	var got := 0
	for n in nodes:
		if n.is_collected:
			got += 1
	get_node("../UI").set_memory_counts(got, nodes.size())

func echo_pulse() -> void:
	var best: Node = null
	var bd := INF
	var player := get_node("../Player")
	for n in nodes:
		if n.is_collected:
			continue
		var d: float = n.global_position.distance_to(player.global_position)
		if d < bd:
			bd = d
			best = n
	if best:
		best.excite()
