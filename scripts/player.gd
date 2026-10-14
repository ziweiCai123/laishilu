extends CharacterBody3D
## 第三人称漫游:WASD 行走 · 空格跳跃/按住滑翔 · Q 回响 · X 坐下 · C 留灯

const WALK_SPEED := 4.6
const HEAVY_SPEED := 3.6
const GLIDE_SPEED := 9.5
const JUMP_VEL := 7.5
const GRAV := 20.0
const GLIDE_FALL := 2.4
const EDGE := 215.0

var pitch := -0.24
var gliding := false
var control_enabled := false
var heavy := false
var sitting := false
var mouse_sens := 0.0021
var _step_acc := 0.0
var _snd_acc := 0.0
var _t := 0.0
var soul_light: OmniLight3D
var soul_glow_mat: StandardMaterial3D
var step_player: AudioStreamPlayer
var _steps := {}
var scarf: Node3D
var wind_lift := 0.0
var _body_ref: Node3D
@onready var cam_arm: SpringArm3D = $CamYaw/Arm

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var trail := GPUParticles3D.new()
	trail.name = "Trail"
	trail.amount = 70
	trail.lifetime = 0.9
	trail.emitting = false
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.35
	pm.gravity = Vector3(0, -0.4, 0)
	pm.direction = Vector3(0, -1, 0)
	pm.spread = 30.0
	pm.initial_velocity_min = 0.2
	pm.initial_velocity_max = 0.8
	pm.scale_min = 0.4
	pm.scale_max = 1.1
	trail.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.12, 0.12)
	var qm := StandardMaterial3D.new()
	qm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	qm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	qm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	qm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	qm.albedo_color = Color(1.0, 0.9, 0.6, 0.4)
	qm.emission_enabled = true
	qm.emission = Color(1.0, 0.85, 0.5)
	qm.emission_energy_multiplier = 1.1
	q.material = qm
	trail.draw_pass_1 = q
	add_child(trail)

	soul_light = OmniLight3D.new()
	soul_light.light_color = Color(1.0, 0.88, 0.62)
	soul_light.omni_range = 6.5
	soul_light.light_energy = 0.85
	soul_light.shadow_enabled = false
	soul_light.position = Vector3(0, 1.4, 0)
	add_child(soul_light)
	var gt := GradientTexture2D.new()
	gt.width = 128
	gt.height = 128
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(0.5, 0.0)
	var gr := Gradient.new()
	gr.set_color(0, Color(1.0, 0.95, 0.8, 0.9))
	gr.set_color(1, Color(1.0, 0.95, 0.8, 0.0))
	gt.gradient = gr
	soul_glow_mat = StandardMaterial3D.new()
	soul_glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	soul_glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	soul_glow_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	soul_glow_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	soul_glow_mat.albedo_texture = gt
	soul_glow_mat.albedo_color = Color(1, 1, 1, 0.22)
	var glow := MeshInstance3D.new()
	var gq := QuadMesh.new()
	gq.size = Vector2(1.5, 1.5)
	gq.material = soul_glow_mat
	glow.mesh = gq
	glow.position = Vector3(0, 1.3, 0)
	add_child(glow)
	step_player = AudioStreamPlayer.new()
	step_player.volume_db = -12.0
	add_child(step_player)
	_steps = {
		"grass": load("res://assets/audio/step_grass.wav"),
		"snow": load("res://assets/audio/step_snow.wav"),
		"stone": load("res://assets/audio/step_stone.wav")
	}
	_body()
	scarf = Node3D.new()
	scarf.name = "Scarf"
	scarf.set_script(load("res://scripts/scarf.gd"))
	add_child(scarf)

func _body() -> void:
	_body_ref = Node3D.new()
	_body_ref.name = "Body"
	add_child(_body_ref)
	var core := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.30
	sm.height = 0.74
	var cm := StandardMaterial3D.new()
	cm.albedo_color = Color(1.0, 0.97, 0.88)
	cm.emission_enabled = true
	cm.emission = Color(1.0, 0.93, 0.75)
	cm.emission_energy_multiplier = 1.5
	cm.roughness = 0.6
	sm.material = cm
	core.mesh = sm
	core.scale = Vector3(1.0, 1.18, 0.92)
	core.position = Vector3(0, 0.62, 0)
	_body_ref.add_child(core)
	var shell := MeshInstance3D.new()
	var sm2 := SphereMesh.new()
	sm2.radius = 0.43
	sm2.height = 1.02
	sm2.radial_segments = 16
	sm2.rings = 8
	var cm2 := StandardMaterial3D.new()
	cm2.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cm2.albedo_color = Color(1.0, 0.95, 0.8, 0.14)
	cm2.emission_enabled = true
	cm2.emission = Color(1.0, 0.9, 0.65)
	cm2.emission_energy_multiplier = 0.7
	cm2.rim_enabled = true
	cm2.rim = 0.8
	cm2.rim_tint = 0.55
	sm2.material = cm2
	shell.mesh = sm2
	shell.scale = Vector3(1.0, 1.18, 0.92)
	shell.position = Vector3(0, 0.62, 0)
	shell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_body_ref.add_child(shell)

func _unhandled_input(event: InputEvent) -> void:
	if not control_enabled:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sens)
		pitch = clampf(pitch - event.relative.y * mouse_sens, -1.2, 0.55)
		cam_arm.rotation.x = pitch
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_SPACE:
				if is_on_floor() and not sitting:
					velocity.y = JUMP_VEL
			KEY_Q:
				_echo()
			KEY_X:
				_toggle_sit()
			KEY_C:
				get_tree().call_group("lanterns", "try_light", global_position)

func _toggle_sit() -> void:
	if not sitting and not is_on_floor():
		return
	sitting = not sitting
	var tw := create_tween()
	tw.tween_property(cam_arm, "spring_length", 10.0 if sitting else 5.6, 1.6) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _echo() -> void:
	var ch := get_node_or_null("../../Chime")
	if ch:
		ch.pitch_scale = 0.6
		ch.play()
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.82
	tm.outer_radius = 1.0
	var rm := StandardMaterial3D.new()
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	rm.cull_mode = BaseMaterial3D.CULL_DISABLED
	rm.albedo_color = Color(1.0, 0.88, 0.6, 0.5)
	rm.emission_enabled = true
	rm.emission = Color(1.0, 0.85, 0.55)
	rm.emission_energy_multiplier = 0.8
	tm.material = rm
	ring.mesh = tm
	var terrain := get_node("../Terrain")
	var rx := global_position.x
	var rz := global_position.z
	ring.position = Vector3(rx, terrain.height(rx, rz) + 0.4, rz)
	var e := 1.2
	var hx: float = terrain.height(rx + e, rz) - terrain.height(rx - e, rz)
	var hz: float = terrain.height(rx, rz + e) - terrain.height(rx, rz - e)
	ring.basis = Basis(Quaternion(Vector3.UP, Vector3(-hx, 2.0 * e, -hz).normalized()))
	get_parent().add_child(ring)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(ring, "scale", Vector3(18.0, 2.2, 18.0), 1.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(rm, "albedo_color:a", 0.0, 1.8)
	tw.chain().tween_callback(ring.queue_free)
	get_tree().call_group("memories", "echo_pulse")

func _physics_process(delta: float) -> void:
	var ix := 0.0
	var iz := 0.0
	if control_enabled and not sitting:
		ix = (1.0 if Input.is_physical_key_pressed(KEY_D) else 0.0) - (1.0 if Input.is_physical_key_pressed(KEY_A) else 0.0)
		iz = (1.0 if Input.is_physical_key_pressed(KEY_S) else 0.0) - (1.0 if Input.is_physical_key_pressed(KEY_W) else 0.0)
	var dir := transform.basis * Vector3(ix, 0, iz)
	if dir.length_squared() > 0.001:
		dir = dir.normalized()
	var space := control_enabled and not sitting and Input.is_physical_key_pressed(KEY_SPACE)
	gliding = (not is_on_floor()) and space and velocity.y < 1.5 and dir.length() > 0.1
	if wind_lift > 0.0:
		if gliding:
			velocity.y = move_toward(velocity.y, 2.0, 9.0 * delta)
		wind_lift = maxf(wind_lift - delta * 0.9, 0.0)
	var trail := get_node_or_null("Trail")
	if trail:
		trail.emitting = gliding
	if gliding:
		velocity.y = move_toward(velocity.y, -GLIDE_FALL, 10.0 * delta)
	else:
		velocity.y -= GRAV * delta
	var speed := HEAVY_SPEED if heavy else WALK_SPEED
	if gliding:
		speed = GLIDE_SPEED
	var accel := 28.0 if is_on_floor() else 10.0
	velocity.x = move_toward(velocity.x, dir.x * speed, accel * delta)
	velocity.z = move_toward(velocity.z, dir.z * speed, accel * delta)
	move_and_slide()
	global_position.x = clampf(global_position.x, -EDGE, EDGE)
	global_position.z = clampf(global_position.z, -EDGE, EDGE)
	if control_enabled and not sitting and is_on_floor():
		_step_acc += Vector2(velocity.x, velocity.z).length() * delta
		if _step_acc > 8.0:
			Save.add_steps(_step_acc)
			_step_acc = 0.0
		var hv := Vector2(velocity.x, velocity.z).length()
		if hv > 1.0:
			_snd_acc += hv * delta
			if _snd_acc > 2.3:
				_snd_acc = 0.0
				_play_step()

func _play_step() -> void:
	var terrain := get_node("../Terrain")
	var x := global_position.x
	var z := global_position.z
	var h: float = terrain.height(x, z)
	var key := "grass"
	if h > 38.0:
		key = "snow"
	elif absf(x - terrain.path_x(z)) < 9.0:
		key = "stone"
	if _steps.has(key):
		step_player.stream = _steps[key]
		step_player.pitch_scale = randf_range(0.9, 1.1)
		step_player.play()

func _process(delta: float) -> void:
	_t += delta
	if soul_light:
		soul_light.light_energy = 0.75 + 0.18 * sin(_t * 1.1)
	if soul_glow_mat:
		soul_glow_mat.albedo_color.a = 0.20 + 0.06 * sin(_t * 1.3)
	if _body_ref:
		_body_ref.position.y = sin(_t * 2.2) * 0.05
