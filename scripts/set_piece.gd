extends Node3D
## 定格瞬间:栈桥尽头,镜头带你飞过洱海

var terrain: Node3D
var player: CharacterBody3D
var ui: CanvasLayer
var _done := false

func _ready() -> void:
	terrain = get_node("../Terrain")
	player = get_node("../Player")
	ui = get_node("../UI")
	var wy: float = terrain.water_y
	var c: Vector2 = terrain.LAKE_C
	var a := Area3D.new()
	a.collision_layer = 0
	a.collision_mask = 2
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(5.0, 7.0, 5.0)
	cs.shape = bs
	a.add_child(cs)
	a.position = Vector3(c.x - 11.0, wy + 2.0, c.y)
	a.body_entered.connect(func(b: Node3D) -> void:
		if b == player and not _done:
			_done = true
			_go()
	)
	add_child(a)

func _go() -> void:
	player.control_enabled = false
	var ch := get_node_or_null("../Chime2")
	if ch:
		ch.play()
	var th := get_node_or_null("../Theme")
	if th:
		create_tween().tween_property(th, "volume_db", -6.0, 2.0)
	_petals()
	var cam := Camera3D.new()
	cam.fov = 62.0
	add_child(cam)
	cam.current = true
	var wy: float = terrain.water_y
	var c: Vector2 = terrain.LAKE_C
	var pa := Vector3(c.x - 16.0, wy + 4.5, c.y - 8.0)
	var pb := Vector3(c.x + 2.0, wy + 14.0, c.y - 26.0)
	var la := Vector3(terrain.TERRACE_C.x, terrain.terrace_h + 8.0, terrain.TERRACE_C.y)
	var lb := Vector3(0.0, 60.0, -260.0)
	var tw := create_tween()
	tw.tween_method(func(t: float) -> void:
		var tt: float = clampf(t, 0.0, 1.0)
		cam.global_position = pa.lerp(pb, tt)
		cam.look_at(la.lerp(lb, tt), Vector3.UP)
	, 0.0, 1.0, 9.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(_finish.bind(cam, th))

func _petals() -> void:
	var gp := GPUParticles3D.new()
	gp.amount = 130
	gp.lifetime = 3.5
	gp.one_shot = true
	gp.explosiveness = 0.85
	gp.emitting = true
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 1.6
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 70.0
	pm.initial_velocity_min = 2.0
	pm.initial_velocity_max = 6.0
	pm.gravity = Vector3(0, -1.2, 0)
	pm.scale_min = 0.5
	pm.scale_max = 1.3
	gp.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.1, 0.1)
	var qm := StandardMaterial3D.new()
	qm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	qm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	qm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	qm.albedo_color = Color(0.96, 0.78, 0.84, 0.85)
	q.material = qm
	gp.draw_pass_1 = q
	gp.position = Vector3(terrain.LAKE_C.x - 11.0, terrain.water_y + 2.2, terrain.LAKE_C.y)
	add_child(gp)

func _finish(cam: Camera3D, th: Node) -> void:
	if is_instance_valid(th):
		create_tween().tween_property(th, "volume_db", -15.0, 3.0)
	var pc: Camera3D = player.get_node("CamYaw/Arm/Cam")
	if is_instance_valid(pc):
		pc.current = true
	if is_instance_valid(cam):
		cam.queue_free()
	if is_instance_valid(player):
		player.control_enabled = true
	ui.show_chapter("第一章 · 风与花 · 完", "风把你举过了湖面。\n切片到这里——再往北，雾还盖着路，丽江在修建。")
