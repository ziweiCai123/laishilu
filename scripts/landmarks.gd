extends Node3D
## 大理地标:崇圣三塔 · 洱海栈桥 · 北岸花树

var terrain: Node3D
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	terrain = get_node("../Terrain")
	rng.seed = 21
	_pagodas()
	_pier()
	_grove()

func _mat(col: Color, rough := 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	return m

func _box(pos: Vector3, size: Vector3, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	bm.material = m
	mi.mesh = bm
	mi.position = pos
	add_child(mi)
	return mi

func _pagodas() -> void:
	var cx: float = terrain.TERRACE_C.x
	var cz: float = terrain.TERRACE_C.y
	for off in [[0.0, 0.0, 7.6], [0.0, -6.0, 5.2], [0.0, 6.0, 5.2]]:
		var px: float = cx + float(off[0])
		var pz: float = cz + float(off[1])
		var h: float = float(off[2])
		_pagoda(px, pz, h)

func _pagoda(px: float, pz: float, h: float) -> void:
	var base_y: float = terrain.height(px, pz)
	var white := _mat(Color(0.93, 0.91, 0.86))
	var dark := _mat(Color(0.52, 0.45, 0.37))
	_box(Vector3(px, base_y + 0.3, pz), Vector3(h * 0.42, 0.6, h * 0.42), _mat(Color(0.80, 0.76, 0.68)))
	var y := base_y + 0.6
	var radii := [h * 0.145, h * 0.115, h * 0.088, h * 0.062]
	for i in radii.size():
		var r: float = radii[i]
		var th: float = h * 0.235
		var mi := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = r * 0.82
		cm.bottom_radius = r
		cm.height = th
		cm.radial_segments = 10
		cm.material = white
		mi.mesh = cm
		mi.position = Vector3(px, y + th * 0.5, pz)
		add_child(mi)
		var eave := MeshInstance3D.new()
		var em := CylinderMesh.new()
		em.top_radius = r * 1.05
		em.bottom_radius = r * 1.42
		em.height = 0.09
		em.radial_segments = 10
		em.material = dark
		eave.mesh = em
		eave.position = Vector3(px, y + th, pz)
		add_child(eave)
		y += th + 0.09
	var fin := MeshInstance3D.new()
	var fm := CylinderMesh.new()
	fm.top_radius = 0.03
	fm.bottom_radius = 0.06
	fm.height = h * 0.16
	var gm := _mat(Color(0.82, 0.68, 0.40), 0.5)
	gm.emission_enabled = true
	gm.emission = Color(0.85, 0.7, 0.4)
	gm.emission_energy_multiplier = 0.5
	fm.material = gm
	fin.mesh = fm
	fin.position = Vector3(px, y + h * 0.08, pz)
	add_child(fin)

func _pier() -> void:
	var wy: float = terrain.water_y
	var deck_y: float = wy + 0.42
	var z := 42.0
	var wood_a := Color(0.52, 0.40, 0.28)
	var wood_b := Color(0.46, 0.35, 0.25)
	for i in 29:
		var px := 36.5 + i * 0.95
		var m := _mat(wood_a.lerp(wood_b, rng.randf()))
		var pl := _box(Vector3(px, deck_y + rng.randf_range(-0.012, 0.012), z), Vector3(0.9, 0.12, 2.4), m)
		pl.rotation.y = rng.randf_range(-0.03, 0.03)
	var body := StaticBody3D.new()
	body.collision_layer = 1
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(28.5, 0.3, 2.5)
	cs.shape = bs
	body.add_child(cs)
	body.position = Vector3(50.0, deck_y, z)
	add_child(body)
	var ramp := StaticBody3D.new()
	ramp.collision_layer = 1
	var rcs := CollisionShape3D.new()
	var rbs := BoxShape3D.new()
	rbs.size = Vector3(3.6, 0.24, 2.5)
	rcs.shape = rbs
	ramp.add_child(rcs)
	ramp.position = Vector3(36.0, deck_y + 0.12, z)
	ramp.rotation = Vector3(0, 0, -0.085)
	add_child(ramp)
	var rmi := MeshInstance3D.new()
	var rbm := BoxMesh.new()
	rbm.size = Vector3(3.6, 0.14, 2.5)
	rbm.material = _mat(wood_b)
	rmi.mesh = rbm
	rmi.position = ramp.position
	rmi.rotation = ramp.rotation
	add_child(rmi)
	for side in [-1.0, 1.0]:
		for i in 6:
			var px := 38.0 + i * 4.8
			_box(Vector3(px, deck_y + 0.35, z + side * 1.12), Vector3(0.1, 1.1, 0.1), _mat(wood_b))
		_box(Vector3(50.0, deck_y + 0.88, z + side * 1.12), Vector3(26.0, 0.08, 0.09), _mat(wood_a))
		_box(Vector3(64.2, deck_y + 0.45, z + side * 1.12), Vector3(0.1, 1.5, 0.1), _mat(wood_b))
	_box(Vector3(65.4, deck_y + 0.95, z), Vector3(0.14, 2.1, 0.14), _mat(wood_b))
	var lamp := _box(Vector3(65.4, deck_y + 2.1, z), Vector3(0.34, 0.44, 0.34), _mat(Color(0.9, 0.75, 0.45), 0.6))
	var lm := lamp.mesh.surface_get_material(0) as StandardMaterial3D
	lm.emission_enabled = true
	lm.emission = Color(1.0, 0.8, 0.45)
	lm.emission_energy_multiplier = 1.8
	var li := OmniLight3D.new()
	li.light_color = Color(1.0, 0.85, 0.55)
	li.omni_range = 7.0
	li.light_energy = 1.1
	li.distance_fade_enabled = true
	li.distance_fade_begin = 8.0
	li.distance_fade_length = 6.0
	li.shadow_enabled = false
	li.position = Vector3(65.4, deck_y + 2.2, z)
	add_child(li)

func _grove() -> void:
	var gx := 60.0
	var gz := -2.0
	for i in 6:
		var ang := rng.randf() * TAU
		var rr := rng.randf_range(2.5, 9.0)
		var px: float = gx + cos(ang) * rr
		var pz: float = gz + sin(ang) * rr * 0.8
		var py: float = terrain.height(px, pz)
		var th := rng.randf_range(2.4, 3.4)
		var trunk := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.1
		cm.bottom_radius = 0.17
		cm.height = th
		cm.material = _mat(Color(0.38, 0.31, 0.27))
		trunk.mesh = cm
		trunk.position = Vector3(px, py + th * 0.5, pz)
		trunk.rotation.z = rng.randf_range(-0.06, 0.06)
		add_child(trunk)
		for k in 2:
			var cs := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = rng.randf_range(1.1, 1.7)
			sm.height = sm.radius * 1.6
			sm.radial_segments = 9
			sm.rings = 5
			var pm := _mat(Color(0.92, 0.76, 0.80).lerp(Color(0.88, 0.68, 0.75), rng.randf()), 1.0)
			pm.emission_enabled = true
			pm.emission = Color(0.95, 0.75, 0.8)
			pm.emission_energy_multiplier = 0.12
			sm.material = pm
			cs.mesh = sm
			cs.position = Vector3(px + rng.randf_range(-0.6, 0.6), py + th + k * 0.9, pz + rng.randf_range(-0.6, 0.6))
			add_child(cs)
	var gp := GPUParticles3D.new()
	gp.amount = 46
	gp.lifetime = 7.0
	gp.emitting = true
	gp.position = Vector3(gx, terrain.height(gx, gz) + 4.5, gz)
	var pm2 := ParticleProcessMaterial.new()
	pm2.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm2.emission_box_extents = Vector3(9.0, 0.5, 7.0)
	pm2.direction = Vector3(0.3, -1, 0.1)
	pm2.spread = 12.0
	pm2.initial_velocity_min = 0.4
	pm2.initial_velocity_max = 1.0
	pm2.gravity = Vector3(0, -0.35, 0)
	pm2.angular_velocity_min = -90.0
	pm2.angular_velocity_max = 90.0
	pm2.scale_min = 0.5
	pm2.scale_max = 1.1
	gp.process_material = pm2
	var q := QuadMesh.new()
	q.size = Vector2(0.09, 0.09)
	var qm := StandardMaterial3D.new()
	qm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	qm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	qm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	qm.albedo_color = Color(0.95, 0.8, 0.85, 0.75)
	q.material = qm
	gp.draw_pass_1 = q
	add_child(gp)
