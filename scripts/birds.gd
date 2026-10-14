extends Node3D
## 绕谷盘旋的飞鸟

var birds: Array = []
var _t := 0.0

func _ready() -> void:
	var terrain := get_node("../Terrain")
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in 5:
		var zc := rng.randf_range(-160.0, 120.0)
		var cx: float = terrain.path_x(zc)
		var b := Node3D.new()
		var bm := StandardMaterial3D.new()
		bm.albedo_color = Color(0.18, 0.22, 0.26)
		bm.roughness = 1.0
		for side in [-1.0, 1.0]:
			var pivot := Node3D.new()
			pivot.name = "L" if side < 0 else "R"
			var w := MeshInstance3D.new()
			var q := QuadMesh.new()
			q.size = Vector2(0.9, 0.22)
			q.center_offset = Vector3(side * 0.45, 0, 0)
			q.material = bm
			w.mesh = q
			pivot.add_child(w)
			b.add_child(pivot)
		birds.append({
			"n": b,
			"cx": cx, "cz": zc,
			"r": rng.randf_range(16.0, 34.0),
			"ang": rng.randf() * TAU,
			"spd": rng.randf_range(0.12, 0.22) * (1.0 if rng.randf() < 0.7 else -1.0),
			"h": terrain.height(cx, zc) + rng.randf_range(16.0, 26.0),
			"ph": rng.randf() * TAU
		})
		add_child(b)

func _process(delta: float) -> void:
	_t += delta
	for b in birds:
		b["ang"] += b["spd"] * delta
		var a: float = b["ang"]
		var n: Node3D = b["n"]
		n.position = Vector3(
			b["cx"] + cos(a) * b["r"],
			b["h"] + sin(_t * 0.5 + b["ph"]) * 1.5,
			b["cz"] + sin(a) * b["r"]
		)
		var s := signf(b["spd"])
		n.rotation.y = atan2(-sin(a) * s, cos(a) * s)
		var flap := sin(_t * 9.0 + b["ph"]) * 0.55
		n.get_node("L").rotation.z = flap
		n.get_node("R").rotation.z = -flap
