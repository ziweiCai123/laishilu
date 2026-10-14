extends Node3D
## 风口:上升气流柱,把滑翔托成飞行

var radius := 9.0
var col_h := 46.0
var player: CharacterBody3D
var area: Area3D

func _ready() -> void:
	player = get_node("../Player")
	area = Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = radius
	cyl.height = col_h
	cs.shape = cyl
	area.add_child(cs)
	area.position = Vector3(0, col_h * 0.5, 0)
	add_child(area)
	var gp := GPUParticles3D.new()
	gp.amount = 30
	gp.lifetime = 3.2
	gp.emitting = true
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pm.emission_ring_axis = Vector3(0, 1, 0)
	pm.emission_ring_radius = radius * 0.75
	pm.emission_ring_inner_radius = radius * 0.25
	pm.emission_ring_height = 2.0
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 6.0
	pm.initial_velocity_min = 5.0
	pm.initial_velocity_max = 8.5
	pm.gravity = Vector3.ZERO
	pm.scale_min = 0.5
	pm.scale_max = 1.2
	gp.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.06, 1.1)
	var qm := StandardMaterial3D.new()
	qm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	qm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	qm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	qm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	qm.albedo_color = Color(1.0, 0.97, 0.85, 0.16)
	q.material = qm
	gp.draw_pass_1 = q
	add_child(gp)
	if ResourceLoader.exists("res://assets/audio/gust.wav"):
		var w := AudioStreamPlayer3D.new()
		w.stream = load("res://assets/audio/gust.wav")
		w.volume_db = -6.0
		w.max_distance = 40.0
		add_child(w)
		var ws := w.stream as AudioStreamWAV
		if ws:
			ws.loop_mode = AudioStreamWAV.LOOP_FORWARD
			ws.loop_begin = 0
			ws.loop_end = ws.data.size() / 2
		w.play()

func _physics_process(_delta: float) -> void:
	if area.overlaps_body(player):
		player.wind_lift = 2.2
