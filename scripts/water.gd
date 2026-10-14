extends Node3D
## 洱海:深度岸沫水面的平面 + 落水护送

const WATER_SHADER := "
shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back;
uniform vec4 shallow_col : source_color = vec4(0.30, 0.62, 0.62, 1.0);
uniform vec4 deep_col : source_color = vec4(0.07, 0.26, 0.36, 1.0);
uniform sampler2D depth_tex : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D wave_n : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D wave_n2 : hint_normal, filter_linear_mipmap, repeat_enable;
void vertex() {
	VERTEX.y += (sin(TIME * 0.7 + VERTEX.x * 0.11) + cos(TIME * 0.5 + VERTEX.z * 0.09)) * 0.05;
}
void fragment() {
	float raw = texture(depth_tex, SCREEN_UV).r;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, raw);
	vec4 vview = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	vview.xyz /= vview.w;
	float wdepth = max(VERTEX.z - vview.z, 0.0);
	float dep_t = smoothstep(0.3, 6.0, wdepth);
	vec2 uv1 = UV * 9.0 + vec2(TIME * 0.021, TIME * 0.013);
	vec2 uv2 = UV * 5.0 - vec2(TIME * 0.017, TIME * 0.026);
	vec3 n1 = texture(wave_n, uv1).rgb;
	vec3 n2 = texture(wave_n, uv2).rgb;
	vec3 nrm = normalize(mix(n1, n2, 0.5) * 2.0 - 1.0);
	NORMAL_MAP = nrm * 0.5 + 0.5;
	vec2 off = nrm.xy * 0.03 * clamp(wdepth * 0.25, 0.05, 1.0);
	vec3 refr = texture(screen_tex, SCREEN_UV + off).rgb;
	vec3 water_col = mix(shallow_col.rgb, deep_col.rgb, dep_t);
	ALBEDO = mix(refr, water_col, mix(0.45, 0.78, dep_t));
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	ALBEDO = mix(ALBEDO, vec3(0.72, 0.82, 0.92), fres * 0.55);
	ROUGHNESS = 0.06;
	SPECULAR = 0.6;
	vec3 sp = texture(wave_n, UV * 46.0 + vec2(TIME * 0.05, TIME * 0.03)).rgb * 2.0 - 1.0;
	float g = pow(clamp(sp.x * 0.6 + sp.z * 0.6, 0.0, 1.0), 7.0);
	EMISSION = vec3(1.0, 0.95, 0.82) * g * 0.6 * smoothstep(0.45, 1.0, fres);
	float foam = (1.0 - smoothstep(0.0, 1.4, wdepth)) * (0.55 + 0.45 * sin(TIME * 1.8 + wdepth * 14.0));
	ALBEDO = mix(ALBEDO, vec3(0.93, 0.95, 0.93), clamp(foam, 0.0, 1.0) * 0.8);
	ALPHA = clamp(mix(0.55, 0.97, dep_t) - foam * 0.1, 0.0, 1.0);
}
"

var terrain: Node3D
var player: CharacterBody3D
var ui: CanvasLayer
var _cooldown := 0.0

func _ready() -> void:
	terrain = get_node("../Terrain")
	player = get_node("../Player")
	ui = get_node("../UI")
	var c: Vector2 = terrain.LAKE_C
	var wy: float = terrain.water_y
	var plane := PlaneMesh.new()
	plane.size = Vector2(128, 128)
	plane.subdivide_width = 48
	plane.subdivide_depth = 48
	var sh := Shader.new()
	sh.code = WATER_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = sh
	for pname in ["wave_n", "wave_n2"]:
		var nt := NoiseTexture2D.new()
		var nz := FastNoiseLite.new()
		nz.seed = 12 if pname == "wave_n" else 34
		nz.frequency = 0.05
		nz.fractal_octaves = 3
		nt.noise = nz
		nt.seamless = true
		nt.width = 256
		nt.height = 256
		nt.as_normal_map = true
		mat.set_shader_parameter(pname, nt)
	plane.material = mat
	var mi := MeshInstance3D.new()
	mi.mesh = plane
	mi.position = Vector3(c.x, wy, c.y)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	var a := Area3D.new()
	a.collision_layer = 0
	a.collision_mask = 2
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(84.0, 8.0, 84.0)
	cs.shape = bs
	a.add_child(cs)
	a.position = Vector3(c.x, wy + 2.5, c.y)
	a.body_entered.connect(_on_in_water)
	add_child(a)

func _process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)

func _on_in_water(body: Node3D) -> void:
	if _cooldown > 0.0 or body != player:
		return
	_cooldown = 4.0
	var sx := 30.0
	var sz := 34.0
	player.velocity = Vector3.ZERO
	player.global_position = Vector3(sx, terrain.height(sx, sz) + 1.1, sz)
	if player.has_node("Scarf"):
		player.get_node("Scarf").reset()
	var ch := get_node_or_null("../Chime")
	if ch:
		ch.pitch_scale = 0.75
		ch.play()
	ui.flash_hint("湖光轻轻托住了你，送回岸边")
