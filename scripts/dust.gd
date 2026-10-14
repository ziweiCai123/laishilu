extends GPUParticles3D
## 环绕玩家的暖色光尘:记忆长河的悬浮微光

func _ready() -> void:
	amount = 90
	lifetime = 8.0
	preprocess = 8.0
	visibility_aabb = AABB(Vector3(-30, -14, -30), Vector3(60, 28, 60))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(24, 12, 24)
	pm.gravity = Vector3.ZERO
	pm.direction = Vector3(1, 0, 0.3)
	pm.spread = 180.0
	pm.initial_velocity_min = 0.12
	pm.initial_velocity_max = 0.45
	pm.scale_min = 0.4
	pm.scale_max = 1.3
	process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.06, 0.06)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_color = Color(1.0, 0.93, 0.7, 0.3)
	q.material = m
	draw_pass_1 = q

func _process(_delta: float) -> void:
	var p := get_node("../Player")
	global_position = p.global_position + Vector3(0, 4.0, 0)
