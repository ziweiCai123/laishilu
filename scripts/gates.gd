extends Node3D
## 章节之门:牌坊 + 故事触发器(数据来自 story.json)

var terrain: Node3D
var ui: CanvasLayer

func _ready() -> void:
	terrain = get_node("../Terrain")
	ui = get_node("../UI")
	_arch(145.0)
	var f := FileAccess.open("res://story.json", FileAccess.READ)
	var chapters: Array = []
	if f:
		var d: Variant = JSON.parse_string(f.get_as_text())
		if d is Dictionary:
			chapters = d.get("chapters", [])
	for i in range(1, chapters.size()):
		var z: float = float(chapters[i].get("z", 0.0))
		_trigger(terrain.path_x(z), z, str(chapters[i].get("title", "")), str(chapters[i].get("text", "")))

func _box(pos: Vector3, size: Vector3, col: Color, rot_y := 0.0, tilt := 0.0) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = 1.0
	bm.material = m
	mi.mesh = bm
	mi.position = pos
	mi.rotation = Vector3(tilt, rot_y, tilt * 0.7)
	add_child(mi)

func _arch(z: float) -> void:
	var x: float = terrain.path_x(z)
	var y: float = terrain.height(x, z)
	var wood := Color(0.44, 0.32, 0.21)
	_box(Vector3(x - 4.2, y + 2.6, z), Vector3(0.55, 5.2, 0.55), wood)
	_box(Vector3(x + 4.2, y + 2.6, z), Vector3(0.55, 5.2, 0.55), wood)
	_box(Vector3(x, y + 5.35, z), Vector3(10.5, 0.5, 0.75), wood)
	_box(Vector3(x, y + 6.1, z), Vector3(12.5, 0.4, 0.55), wood)
	_box(Vector3(x, y + 4.4, z), Vector3(1.3, 0.85, 0.12), Color(0.52, 0.22, 0.16))

func _trigger(x: float, z: float, title: String, text: String) -> void:
	var a := Area3D.new()
	a.collision_layer = 0
	a.collision_mask = 2
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(18.0, 26.0, 5.0)
	cs.shape = bs
	a.add_child(cs)
	a.position = Vector3(x, terrain.height(x, z) + 9.0, z)
	a.body_entered.connect(func(body: Node3D) -> void:
		if body is CharacterBody3D and not a.has_meta("done"):
			a.set_meta("done", true)
			ui.show_chapter(title, text)
	)
	add_child(a)
