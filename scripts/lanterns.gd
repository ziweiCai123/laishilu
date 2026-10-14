extends Node3D
## 留灯:每次来,可以给下次的自己点一盏灯

const MAX_LANTERNS := 60

var terrain: Node3D
var items: Array = []
var _t := 0.0

func _ready() -> void:
	terrain = get_node("../Terrain")
	add_to_group("lanterns")
	for L in Save.data["lanterns"]:
		_spawn(Vector3(L["x"], L["y"], L["z"]), false)

func try_light(pos: Vector3) -> void:
	if items.size() >= MAX_LANTERNS:
		get_node("../UI").flash_hint("灯已经够多了,让山谷歇一歇")
		return
	var p := Vector3(pos.x, terrain.height(pos.x, pos.z), pos.z)
	for it in items:
		if it["root"].position.distance_to(p) < 7.0:
			get_node("../UI").flash_hint("这盏灯的光,已经照到这里了")
			return
	_spawn(p, true)
	Save.add_lantern(p)
	var ch := get_node_or_null("../Chime")
	if ch:
		ch.pitch_scale = 1.25
		ch.volume_db = -10.0
		ch.play()

func _spawn(p: Vector3, fresh: bool) -> void:
	var root := Node3D.new()
	root.position = p
	add_child(root)
	var pole := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.04
	cm.bottom_radius = 0.05
	cm.height = 2.1
	var pm := StandardMaterial3D.new()
	pm.albedo_color = Color(0.40, 0.32, 0.22)
	pm.roughness = 1.0
	cm.material = pm
	pole.mesh = cm
	pole.position = Vector3(0, 1.05, 0)
	root.add_child(pole)
	var lamp := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.3, 0.4, 0.3)
	var lm := StandardMaterial3D.new()
	lm.albedo_color = Color(1.0, 0.82, 0.5)
	lm.emission_enabled = true
	lm.emission = Color(1.0, 0.75, 0.4)
	lm.emission_energy_multiplier = 1.8
	bm.material = lm
	lamp.mesh = bm
	lamp.position = Vector3(0, 2.15, 0)
	root.add_child(lamp)
	var li := OmniLight3D.new()
	li.light_color = Color(1.0, 0.78, 0.45)
	li.omni_range = 7.0
	li.light_energy = 1.1
	li.shadow_enabled = false
	li.distance_fade_enabled = true
	li.distance_fade_begin = 10.0
	li.distance_fade_length = 8.0
	li.position = Vector3(0, 2.2, 0)
	root.add_child(li)
	items.append({"root": root, "lm": lm, "li": li, "ph": randf() * TAU})
	if fresh:
		root.scale = Vector3.ONE * 0.01
		create_tween().tween_property(root, "scale", Vector3.ONE, 0.7) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	_t += delta
	for it in items:
		var k := 0.92 + 0.08 * sin(_t * 1.4 + it["ph"])
		it["li"].light_energy = 1.05 * k
		it["lm"].emission_energy_multiplier = 1.7 * k
