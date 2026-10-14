extends Node3D
## 开场布置:日光角度、远方雪脊、声景、玩家落位、环境系统

const SKY_SHADER := "
shader_type sky;

uniform vec3 top_color : source_color = vec3(0.36, 0.54, 0.76);
uniform vec3 horizon_color : source_color = vec3(0.93, 0.86, 0.72);
uniform float cloud_cover : hint_range(0.0, 1.0) = 0.5;

float hash12(vec2 p) {
	p = fract(p * vec2(123.34, 345.45));
	p += dot(p, p + 34.345);
	return fract(p.x * p.y);
}
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash12(i);
	float b = hash12(i + vec2(1.0, 0.0));
	float c = hash12(i + vec2(0.0, 1.0));
	float d = hash12(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}
float fbm(vec2 p) {
	float s = 0.0;
	float a = 0.5;
	for (int i = 0; i < 3; i++) {
		s += a * vnoise(p);
		p = p * 2.17 + 7.31;
		a *= 0.5;
	}
	return s;
}

void sky() {
	float y = EYEDIR.y;
	vec3 col = mix(horizon_color, top_color, smoothstep(-0.04, 0.42, y));
	col = mix(horizon_color * 0.94, col, smoothstep(-0.30, -0.02, y));
	if (LIGHT0_ENABLED) {
		float sd = max(dot(EYEDIR, LIGHT0_DIRECTION), 0.0);
		col += LIGHT0_COLOR * LIGHT0_ENERGY * (pow(sd, 1200.0) * 4.0 + pow(sd, 60.0) * 0.14);
	}
	float cy = max(y, 0.055);
	vec2 cuv = EYEDIR.xz / cy * 0.85;
	float w1 = fbm(cuv * 1.7 + 11.3);
	float w2 = fbm(cuv * 1.7 + 37.9);
	float den = fbm(cuv + vec2(w1, w2) * 0.55);
	float cir = smoothstep(1.18 - cloud_cover, 1.34 - cloud_cover, den) * smoothstep(0.02, 0.22, y);
	vec3 cloud_col = mix(horizon_color, vec3(1.0, 0.98, 0.94), 0.55);
	if (LIGHT0_ENABLED) {
		float sd2 = max(dot(EYEDIR, LIGHT0_DIRECTION), 0.0);
		cloud_col += LIGHT0_COLOR * LIGHT0_ENERGY * pow(sd2, 8.0) * 0.12;
	}
	col = mix(col, cloud_col, cir * 0.5);
	COLOR = col;
}
"

func _ready() -> void:
	$Sun.rotation_degrees = Vector3(-31.0, 200.0, 0.0)
	var terrain := $Terrain
	var p := $Player
	p.position.y = terrain.height(p.position.x, p.position.z) + 1.1
	_ridge(-40.0, -500.0, 760.0, 175.0, 5)
	_ridge(420.0, -240.0, 420.0, 120.0, 9)
	_ridge(-430.0, -80.0, 460.0, 135.0, 13)
	_audio()
	_systems()
	_visual()
	_apply_settings()

func _process(delta: float) -> void:
	var menus := get_node_or_null("Menus")
	if menus and menus.state == "title":
		$Player.rotate_y(delta * 0.05)

func _apply_settings() -> void:
	var s: Dictionary = Save.data["settings"]
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(float(s.get("vol", 0.9)), 0.0001)))
	$Player.mouse_sens = 0.0021 * float(s.get("sens", 1.0))
	apply_quality(str(s.get("quality", "high")) == "high")

func apply_quality(high: bool) -> void:
	get_viewport().msaa_3d = Viewport.MSAA_4X if high else Viewport.MSAA_DISABLED
	var env := $WorldEnvironment.environment as Environment
	if env:
		env.ssao_enabled = high
		env.sdfgi_enabled = high

func _visual() -> void:
	var env := ($WorldEnvironment.environment as Environment)
	if env:
		env.ssao_enabled = true
		env.ssao_intensity = 2.0
		env.ssao_radius = 1.4
		env.ssao_light_affect = 0.15
		env.sdfgi_enabled = true
		env.sdfgi_use_occlusion = true
		env.sdfgi_cascades = 4
		env.glow_intensity = 0.7
		env.glow_hdr_threshold = 1.05
		env.glow_bloom = 0.0
		env.tonemap_exposure = 1.05
		env.fog_height = 12.0
		env.fog_height_density = 0.03
		env.fog_sky_affect = 0.25
		env.volumetric_fog_density = 0.007
		env.adjustment_enabled = true
		env.adjustment_saturation = 1.07
		env.adjustment_contrast = 1.03
		var sky_shader := Shader.new()
		sky_shader.code = SKY_SHADER
		var sky_mat := ShaderMaterial.new()
		sky_mat.shader = sky_shader
		sky_mat.set_shader_parameter("top_color", Color(0.36, 0.54, 0.76))
		sky_mat.set_shader_parameter("horizon_color", Color(0.93, 0.86, 0.72))
		sky_mat.set_shader_parameter("cloud_cover", 0.5)
		var sky := Sky.new()
		sky.sky_material = sky_mat
		env.sky = sky
		env.fog_light_color = Color(0.93, 0.89, 0.80)
	var sun := $Sun
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_max_distance = 340.0
	sun.shadow_blur = 1.0
	get_viewport().msaa_3d = Viewport.MSAA_4X

func _snow_t(h: float) -> float:
	return clampf((h / 170.0 - 0.42) / 0.33, 0.0, 1.0)

func _tri_v(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, col: Color) -> void:
	st.set_smooth_group(-1)
	for v in [a, b, c]:
		st.set_color(col)
		st.add_vertex(v)

func _ridge(cx: float, cz: float, span: float, h0: float, seed_v: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var n := 26
	var xs := PackedFloat32Array()
	var hs := PackedFloat32Array()
	for i in n + 1:
		var t := float(i) / float(n)
		var taper := 0.55 + 0.45 * sin(t * PI)
		var pk := 0.42 if i % 2 == 0 else 1.0
		hs.append(h0 * pk * (0.72 + 0.55 * rng.randf()) * taper)
		xs.append(cx + (t - 0.5) * span + rng.randf_range(-6.0, 6.0))
	var rock := Color(0.38, 0.44, 0.52)
	var snow := Color(0.93, 0.94, 0.96)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in n:
		var xa: float = xs[i]
		var xb: float = xs[i + 1]
		var ha: float = hs[i]
		var hb: float = hs[i + 1]
		var zf: float = cz + rng.randf_range(-5.0, 5.0)
		var zb: float = zf - 30.0
		var ca := rock.lerp(snow, _snow_t(ha))
		var cb := rock.lerp(snow, _snow_t(hb))
		_tri_v(st, Vector3(xa, -40.0, zf), Vector3(xb, -40.0, zf), Vector3(xb, hb, zf), cb)
		_tri_v(st, Vector3(xa, -40.0, zf), Vector3(xb, hb, zf), Vector3(xa, ha, zf), ca)
		_tri_v(st, Vector3(xb, -40.0, zb), Vector3(xa, -40.0, zb), Vector3(xa, ha, zb), ca * 0.85)
		_tri_v(st, Vector3(xb, -40.0, zb), Vector3(xa, ha, zb), Vector3(xb, hb, zb), cb * 0.85)
		_tri_v(st, Vector3(xa, ha, zf), Vector3(xb, hb, zf), Vector3(xb, hb, zb), cb)
		_tri_v(st, Vector3(xa, ha, zf), Vector3(xb, hb, zb), Vector3(xa, ha, zb), ca)
	st.generate_normals()
	var mesh := st.commit()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 1.0
	mesh.surface_set_material(0, mat)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	add_child(mi)

func _audio() -> void:
	var wind := AudioStreamPlayer.new()
	wind.name = "Wind"
	wind.stream = load("res://assets/audio/wind.wav")
	wind.volume_db = -9.0
	add_child(wind)
	var ws := wind.stream as AudioStreamWAV
	if ws:
		ws.loop_mode = AudioStreamWAV.LOOP_FORWARD
		ws.loop_begin = 0
		ws.loop_end = ws.data.size() / 2
	wind.play()
	var chime := AudioStreamPlayer.new()
	chime.name = "Chime"
	chime.stream = load("res://assets/audio/chime.wav")
	chime.volume_db = -4.0
	add_child(chime)
	var chime2 := AudioStreamPlayer.new()
	chime2.name = "Chime2"
	chime2.stream = load("res://assets/audio/collect.wav")
	chime2.volume_db = -6.0
	add_child(chime2)
	if ResourceLoader.exists("res://assets/audio/dali_theme.wav"):
		var theme := AudioStreamPlayer.new()
		theme.name = "Theme"
		theme.stream = load("res://assets/audio/dali_theme.wav")
		theme.volume_db = -15.0
		add_child(theme)
		var ts := theme.stream as AudioStreamWAV
		if ts:
			ts.loop_mode = AudioStreamWAV.LOOP_FORWARD
			ts.loop_begin = 0
			ts.loop_end = ts.data.size() / 2
		theme.play()

func _systems() -> void:
	var grass := Node3D.new()
	grass.name = "Grass"
	grass.set_script(load("res://scripts/grass.gd"))
	add_child(grass)
	var trees := Node3D.new()
	trees.name = "Trees"
	trees.set_script(load("res://scripts/trees.gd"))
	add_child(trees)
	var motes := Node3D.new()
	motes.name = "Motes"
	motes.set_script(load("res://scripts/motes.gd"))
	add_child(motes)
	var birds := Node3D.new()
	birds.name = "Birds"
	birds.set_script(load("res://scripts/birds.gd"))
	add_child(birds)
	var dust := GPUParticles3D.new()
	dust.name = "Dust"
	dust.set_script(load("res://scripts/dust.gd"))
	add_child(dust)
	var gates := Node3D.new()
	gates.name = "Gates"
	gates.set_script(load("res://scripts/gates.gd"))
	add_child(gates)
	var lanterns := Node3D.new()
	lanterns.name = "Lanterns"
	lanterns.set_script(load("res://scripts/lanterns.gd"))
	add_child(lanterns)
	var water := Node3D.new()
	water.name = "Water"
	water.set_script(load("res://scripts/water.gd"))
	add_child(water)
	var landmarks := Node3D.new()
	landmarks.name = "Landmarks"
	landmarks.set_script(load("res://scripts/landmarks.gd"))
	add_child(landmarks)
	var winds := Node3D.new()
	winds.name = "WindZone"
	var wy: float = $Terrain.height(-11.0, 40.0)
	winds.position = Vector3(-11.0, wy, 40.0)
	winds.set_script(load("res://scripts/wind_zone.gd"))
	add_child(winds)
	var heal := Node3D.new()
	heal.name = "WorldHeal"
	heal.set_script(load("res://scripts/world_heal.gd"))
	add_child(heal)
	var menus := CanvasLayer.new()
	menus.name = "Menus"
	menus.set_script(load("res://scripts/menus.gd"))
	add_child(menus)
	var hints := Node3D.new()
	hints.name = "Hints"
	hints.set_script(load("res://scripts/hints.gd"))
	add_child(hints)
	var piece := Node3D.new()
	piece.name = "SetPiece"
	piece.set_script(load("res://scripts/set_piece.gd"))
	add_child(piece)
	var storyteller := Node3D.new()
	storyteller.name = "Storyteller"
	storyteller.set_script(load("res://scripts/storyteller.gd"))
	add_child(storyteller)
