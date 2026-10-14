extends Node3D
## 风中的草与花:草浪随风向起伏,花海成片铺开,水面自动留白

const GRASS_SHADER := "
shader_type spatial;
render_mode cull_disabled, specular_disabled;
uniform vec3 base_col : source_color = vec3(0.33, 0.42, 0.33);
uniform vec3 tip_col : source_color = vec3(0.62, 0.63, 0.40);
varying float v_tip;
void vertex() {
	v_tip = 1.0 - UV.y;
	float gust = 0.75 + 0.55 * sin(TIME * 0.4 + MODEL_MATRIX[3][2] * 0.045 + MODEL_MATRIX[3][0] * 0.03);
	float sway = sin(TIME * 1.6 + INSTANCE_CUSTOM.x * 6.2831) * 0.13 * v_tip * gust;
	VERTEX.x += sway;
	VERTEX.z += sway * 0.6;
}
void fragment() {
	ALBEDO = mix(base_col, tip_col, v_tip);
	ROUGHNESS = 1.0;
}
"

const BLOSSOM_SHADER := "
shader_type spatial;
render_mode cull_disabled, specular_disabled;
uniform sampler2D tex;
void vertex() {
	VERTEX *= INSTANCE_CUSTOM.x;
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	NORMAL = (VIEW_MATRIX * vec4(0.0, 0.0, 1.0, 0.0)).xyz;
}
void fragment() {
	vec4 c = texture(tex, UV);
	if (c.a < 0.5) {
		discard;
	}
	ALBEDO = c.rgb * COLOR.rgb;
	ROUGHNESS = 1.0;
}
"

const FIELDS := [
	[Vector2(42, 75), 14.0, Color(0.95, 0.72, 0.78), 800],
	[Vector2(16, 120), 12.0, Color(0.96, 0.93, 0.86), 620],
	[Vector2(55, 15), 12.0, Color(0.98, 0.85, 0.45), 620]
]

var terrain: Node3D
var rng := RandomNumberGenerator.new()
var _blossom_mat: ShaderMaterial

func _ready() -> void:
	terrain = get_node("../Terrain")
	rng.seed = 42
	_blossom_mat = _make_blossom_mat()
	_grass(6500, 58.0, 0.14, 0.62, Color(0.33, 0.42, 0.33), Color(0.60, 0.62, 0.40))
	_grass(4500, 48.0, 0.12, 0.5, Color(0.40, 0.47, 0.35), Color(0.66, 0.66, 0.44))
	_flowers()
	for f in FIELDS:
		_field(f)

func _ok(x: float, z: float) -> bool:
	return terrain.height(x, z) > terrain.water_y + 0.4

func _grass(count: int, spread: float, w: float, h: float, base: Color, tip: Color) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	var q := QuadMesh.new()
	q.size = Vector2(w, h)
	q.center_offset = Vector3(0, h * 0.5, 0)
	var sd := Shader.new()
	sd.code = GRASS_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = sd
	mat.set_shader_parameter("base_col", base)
	mat.set_shader_parameter("tip_col", tip)
	q.material = mat
	mm.mesh = q
	mm.instance_count = count
	var placed := 0
	for i in count:
		var z := rng.randf_range(-212.0, 212.0)
		var x: float = terrain.path_x(z) + rng.randf_range(-spread, spread)
		if not _ok(x, z):
			continue
		var y: float = terrain.height(x, z) - 0.06
		var tr := Transform3D(Basis(Vector3.UP, rng.randf() * TAU), Vector3(x, y, z))
		mm.set_instance_transform(placed, tr)
		mm.set_instance_custom_data(placed, Color(rng.randf(), 0, 0, 0))
		placed += 1
	mm.instance_count = placed
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	add_child(mi)

func _blossom_tex() -> ImageTexture:
	var n := 48
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var half := float(n) * 0.5
	for y in n:
		for x in n:
			var p := (Vector2(float(x), float(y)) - Vector2(half, half)) / half
			var d := p.length()
			var ang := atan2(p.y, p.x)
			var lobe := pow(maxf(cos(ang * 5.0), 0.0), 1.4)
			var rr := 0.30 + 0.62 * lobe
			var a := clampf((rr - d) / 0.10, 0.0, 1.0)
			var col := Color(1.0, 1.0, 1.0, a)
			if d < 0.20 and a > 0.0:
				var core := smoothstep(0.20, 0.08, d)
				col = Color(1.0, 1.0, 1.0, a).lerp(Color(1.0, 0.84, 0.45, a), core)
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

func _make_blossom_mat() -> ShaderMaterial:
	var sd := Shader.new()
	sd.code = BLOSSOM_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = sd
	mat.set_shader_parameter("tex", _blossom_tex())
	return mat

func _flower_mm(count: int) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	var q := QuadMesh.new()
	q.size = Vector2(0.26, 0.26)
	q.center_offset = Vector3(0, 0.13, 0)
	q.material = _blossom_mat
	mm.mesh = q
	mm.instance_count = count
	return mm

func _flowers() -> void:
	var cols := [Color(0.78, 0.64, 0.42), Color(0.92, 0.89, 0.82), Color(0.62, 0.44, 0.33)]
	for c in cols:
		var mm := _flower_mm(200)
		var placed := 0
		for i in 400:
			if placed >= 200:
				break
			var z := rng.randf_range(-212.0, 212.0)
			var x: float = terrain.path_x(z) + rng.randf_range(-24.0, 24.0)
			if not _ok(x, z):
				continue
			var y: float = terrain.height(x, z) + 0.03
			mm.set_instance_transform(placed, Transform3D(Basis.IDENTITY, Vector3(x, y, z)))
			mm.set_instance_color(placed, c * rng.randf_range(0.82, 1.12))
			mm.set_instance_custom_data(placed, Color(rng.randf_range(0.7, 1.4), 0, 0, 0))
			placed += 1
		mm.instance_count = placed
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = mm
		add_child(mi)

func _field(f: Array) -> void:
	var c: Vector2 = f[0]
	var r: float = f[1]
	var col: Color = f[2]
	var n: int = f[3]
	var mm := _flower_mm(n)
	var placed := 0
	for i in n * 2:
		if placed >= n:
			break
		var ang := rng.randf() * TAU
		var rr := sqrt(rng.randf()) * r
		var x: float = c.x + cos(ang) * rr
		var z: float = c.y + sin(ang) * rr
		if not _ok(x, z):
			continue
		var y: float = terrain.height(x, z) + 0.03
		mm.set_instance_transform(placed, Transform3D(Basis.IDENTITY, Vector3(x, y, z)))
		mm.set_instance_color(placed, col * rng.randf_range(0.82, 1.12))
		mm.set_instance_custom_data(placed, Color(rng.randf_range(0.7, 1.5), 0, 0, 0))
		placed += 1
	mm.instance_count = placed
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	add_child(mi)
	var gp := GPUParticles3D.new()
	gp.amount = 18
	gp.lifetime = 6.0
	gp.emitting = true
	gp.position = Vector3(c.x, terrain.height(c.x, c.y) + 1.2, c.y)
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(r * 0.8, 0.5, r * 0.8)
	pm.direction = Vector3(0.4, -1, 0.1)
	pm.spread = 10.0
	pm.initial_velocity_min = 0.3
	pm.initial_velocity_max = 0.8
	pm.gravity = Vector3(0, -0.25, 0)
	pm.angular_velocity_min = -60.0
	pm.angular_velocity_max = 60.0
	pm.scale_min = 0.5
	pm.scale_max = 1.0
	gp.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.08, 0.08)
	var qm := StandardMaterial3D.new()
	qm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	qm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	qm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	var pc := col
	pc.a = 0.7
	qm.albedo_color = pc
	q.material = qm
	gp.draw_pass_1 = q
	add_child(gp)
