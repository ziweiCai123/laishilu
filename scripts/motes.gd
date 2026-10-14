extends Node3D
## 光之屑:散落谷中,穿过即拾,存档持久

const N := 40
var alive: Array = []
var _t := 0.0

func _ready() -> void:
	var terrain := get_node("../Terrain")
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	for i in N:
		if Save.data["motes"].has(i):
			continue
		var z := rng.randf_range(-205.0, 205.0)
		var x: float = terrain.path_x(z) + rng.randf_range(-14.0, 14.0)
		var y: float = terrain.height(x, z) + rng.randf_range(1.4, 5.5)
		var a := Area3D.new()
		a.collision_layer = 0
		a.collision_mask = 2
		var cs := CollisionShape3D.new()
		var sph := SphereShape3D.new()
		sph.radius = 1.1
		cs.shape = sph
		a.add_child(cs)
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.09
		sm.height = 0.18
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.95, 0.78)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.85, 0.5)
		mat.emission_energy_multiplier = 2.2
		sm.material = mat
		mi.mesh = sm
		a.add_child(mi)
		a.position = Vector3(x, y, z)
		a.body_entered.connect(_on_mote.bind(i, a))
		add_child(a)
		alive.append({ "n": a, "ph": rng.randf() * TAU, "y": y })
	await get_tree().process_frame
	get_node("../UI").set_motes(Save.data["motes"].size())

func _process(delta: float) -> void:
	_t += delta
	for m in alive:
		if is_instance_valid(m["n"]):
			m["n"].position.y = m["y"] + sin(_t * 1.3 + m["ph"]) * 0.35

func _on_mote(i: int, a: Area3D, body: Node3D) -> void:
	if not (body is CharacterBody3D):
		return
	if not Save.collect_mote(i):
		return
	alive = alive.filter(func(m: Dictionary) -> bool: return m["n"] != a)
	var ch := get_node_or_null("../Chime")
	if ch:
		ch.pitch_scale = 1.4
		ch.play()
	get_node("../UI").set_motes(Save.data["motes"].size())
	var tw := create_tween()
	tw.tween_property(a, "scale", Vector3.ONE * 0.01, 0.3)
	tw.tween_callback(a.queue_free)
