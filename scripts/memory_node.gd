extends Area3D
## 记忆烛光:未拾起时立着引路的光柱;拾起后化作常明的小灯

signal near_changed(near: bool)
signal picked(id: String)

var memory := {}
var is_collected := false
var _t := randf() * TAU
var _inside := false
var _cd := 0.0
var _excite := 0.0
var _fading := false
var core: MeshInstance3D
var halo: MeshInstance3D
var lamp: OmniLight3D
var pillar: MeshInstance3D
var core_mat: StandardMaterial3D
var halo_mat: StandardMaterial3D
var pillar_mat: StandardMaterial3D
@onready var ui: CanvasLayer = get_node("../../UI")

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var cs := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 2.4
	cs.shape = sph
	add_child(cs)

	core = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.2
	sm.height = 0.4
	core_mat = StandardMaterial3D.new()
	core_mat.albedo_color = Color(1.0, 0.96, 0.82)
	core_mat.emission_enabled = true
	core_mat.emission = Color(1.0, 0.85, 0.5)
	core_mat.emission_energy_multiplier = 2.6
	sm.material = core_mat
	core.mesh = sm
	add_child(core)

	halo = MeshInstance3D.new()
	var hm := SphereMesh.new()
	hm.radius = 0.62
	hm.height = 1.24
	halo_mat = StandardMaterial3D.new()
	halo_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	halo_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	halo_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	halo_mat.albedo_color = Color(1.0, 0.9, 0.6, 0.14)
	hm.material = halo_mat
	halo.mesh = hm
	add_child(halo)

	lamp = OmniLight3D.new()
	lamp.light_color = Color(1.0, 0.86, 0.56)
	lamp.omni_range = 8.0
	lamp.distance_fade_enabled = true
	lamp.distance_fade_begin = 12.0
	lamp.distance_fade_length = 10.0
	add_child(lamp)

	if str(memory.get("type", "")) == "object":
		var om := MeshInstance3D.new()
		om.name = "Obj"
		var pm := PrismMesh.new()
		pm.size = Vector3(0.9, 0.5, 0.55)
		var omat := StandardMaterial3D.new()
		omat.albedo_color = Color(0.85, 0.72, 0.5)
		omat.metallic = 0.3
		omat.roughness = 0.4
		omat.emission_enabled = true
		omat.emission = Color(0.9, 0.7, 0.4)
		omat.emission_energy_multiplier = 0.5
		pm.material = omat
		om.mesh = pm
		om.position = Vector3(0, 0.55, 0)
		add_child(om)

	pillar = MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.45
	cm.bottom_radius = 1.15
	cm.height = 46.0
	cm.radial_segments = 12
	cm.cap_top = false
	cm.cap_bottom = false
	pillar_mat = StandardMaterial3D.new()
	pillar_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pillar_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pillar_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	pillar_mat.albedo_color = Color(1.0, 0.9, 0.62, 0.1)
	pillar_mat.emission_enabled = true
	pillar_mat.emission = Color(1.0, 0.88, 0.58)
	pillar_mat.emission_energy_multiplier = 0.7
	cm.material = pillar_mat
	pillar.mesh = cm
	pillar.position = Vector3(0, 23, 0)
	add_child(pillar)

	is_collected = Save.has_collected(str(memory.get("id", "")))
	if is_collected:
		_apply_collected_look()

	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)

func _apply_collected_look() -> void:
	pillar.visible = false
	lamp.light_energy = 1.0
	lamp.omni_range = 6.0
	core_mat.emission_energy_multiplier = 1.4
	halo_mat.albedo_color = Color(1.0, 0.9, 0.6, 0.09)

func excite() -> void:
	if not is_collected:
		_excite = 1.0

func _process(delta: float) -> void:
	_cd = maxf(0.0, _cd - delta)
	_excite = maxf(0.0, _excite - delta / 3.0)
	_t += delta
	var pulse := 0.5 + 0.5 * sin(_t * 1.7)
	core.position.y = sin(_t * 1.1) * 0.16
	halo.position.y = core.position.y
	halo.scale = Vector3.ONE * (0.92 + pulse * 0.22)
	lamp.light_energy = (1.1 + pulse * 1.1) if not is_collected else 1.0
	if pillar.visible and not _fading:
		pillar_mat.albedo_color.a = 0.08 + pulse * 0.05 + _excite * 0.14
		pillar_mat.emission_energy_multiplier = 0.7 + _excite * 2.2
	var obj := get_node_or_null("Obj")
	if obj:
		obj.rotate_y(delta * 0.8)

func _on_enter(body: Node3D) -> void:
	if body is CharacterBody3D:
		_inside = true
		near_changed.emit(true)
		var ch := get_node_or_null("../../Chime")
		if ch:
			ch.pitch_scale = 1.0
			ch.play()

func _on_exit(body: Node3D) -> void:
	if body is CharacterBody3D:
		_inside = false
		near_changed.emit(false)

func _unhandled_input(event: InputEvent) -> void:
	if not (_inside and _cd <= 0.0 and not ui.card_open):
		return
	if not (event is InputEventKey and event.pressed and not event.echo \
			and event.physical_keycode == KEY_E):
		return
	_cd = 0.6
	if not is_collected:
		is_collected = true
		_fading = true
		var tw := create_tween()
		tw.tween_property(pillar_mat, "albedo_color:a", 0.0, 1.1)
		tw.tween_callback(func() -> void:
			pillar.visible = false
			_fading = false
		)
		_apply_collected_look()
		picked.emit(str(memory.get("id", "")))
		var ch2 := get_node_or_null("../../Chime2")
		if ch2:
			ch2.play()
	ui.show_memory(memory)
	get_viewport().set_input_as_handled()
