extends Node3D
## 程序化苍山洱海:花甸坝子 — 洱海湖盆 — 苍山西脊,一路向北抬升

const SIZE := 460.0
const SEG := 208

const TERRAIN_SHADER := "
shader_type spatial;
render_mode cull_disabled;

varying vec3 v_col;
varying vec3 v_wp;
varying vec3 v_wn;

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
float tri_no(vec3 p, vec3 w, float sc) {
	vec3 q = p * sc;
	float wsum = w.x + w.y + w.z;
	return (fbm(q.xy) * w.z + fbm(q.yz) * w.x + fbm(q.zx) * w.y) / max(wsum, 0.001);
}
void vertex() {
	v_col = COLOR.rgb;
	v_wp = VERTEX;
	v_wn = NORMAL;
}
void fragment() {
	vec3 w = pow(abs(v_wn), vec3(4.0));
	float m1 = tri_no(v_wp, w, 0.09);
	float m2 = tri_no(v_wp, w, 0.62);
	float fine = tri_no(v_wp, w, 3.1);
	vec3 alb = v_col * (0.70 + 0.60 * m1) * (0.86 + 0.26 * m2);
	alb *= 0.93 + 0.14 * fine;
	float slope = 1.0 - clamp(v_wn.y, 0.0, 1.0);
	alb = mix(alb, alb * vec3(0.80, 0.78, 0.76), slope * 0.45);
	ALBEDO = alb;
	ROUGHNESS = clamp(0.99 - 0.3 * m2, 0.6, 1.0);
	float e = 0.5;
	float h0 = tri_no(v_wp, w, 2.3);
	float hx = tri_no(v_wp + vec3(e, 0.0, 0.0), w, 2.3);
	float hz = tri_no(v_wp + vec3(0.0, 0.0, e), w, 2.3);
	vec3 grad = vec3(hx - h0, 0.0, hz - h0) / e;
	vec3 wn = normalize(v_wn - grad * 0.5);
	if (wn.y < 0.06) {
		wn = normalize(vec3(wn.x, 0.06, wn.z));
	}
	NORMAL = normalize((INV_VIEW_MATRIX * vec4(wn, 0.0)).xyz);
}
"

const LAKE_C := Vector2(75.0, 42.0)
const LAKE_FLOOR := 2.0
const WATER_Y := 2.4
const TERRACE_C := Vector2(-2.0, 105.0)

var noise_hi := FastNoiseLite.new()
var noise_lo := FastNoiseLite.new()
var water_y := WATER_Y
var terrace_h := 9.0

func _ready() -> void:
	noise_hi.seed = 7
	noise_hi.frequency = 0.012
	noise_hi.fractal_octaves = 4
	noise_lo.seed = 23
	noise_lo.frequency = 0.0042
	noise_lo.fractal_octaves = 3
	terrace_h = _raw(TERRACE_C.x, TERRACE_C.y) + 0.5
	_build()

func path_x(z: float) -> float:
	return 46.0 * sin(z * 0.012) + 18.0 * sin(z * 0.031 + 1.7)

func _raw(x: float, z: float) -> float:
	var d := absf(x - path_x(z))
	var t := clampf((d - 12.0) / 55.0, 0.0, 1.0)
	var side := t * t * (3.0 - 2.0 * t)
	var base := noise_lo.get_noise_2d(x, z) * 7.0 + noise_hi.get_noise_2d(x, z) * 3.5
	var mountain := side * (36.0 + 30.0 * absf(noise_lo.get_noise_2d(x * 0.55 + 40.0, z * 0.55)))
	var ascent := (230.0 - z) * 0.085
	var h := base * (0.5 + side) + mountain + ascent * (0.35 + 0.65 * side)
	var dw := path_x(z) - x
	var ridge := smoothstep(26.0, 85.0, dw)
	var rn := (noise_lo.get_noise_2d(x * 0.3 - 77.0, z * 0.3) + 1.0) * 0.5
	return h + ridge * (6.0 + 24.0 * rn)

func height(x: float, z: float) -> float:
	var h := _raw(x, z)
	var lake_d := Vector2(x - LAKE_C.x, z - LAKE_C.y).length()
	var plain_t := 1.0 - smoothstep(30.0, 62.0, lake_d)
	h = lerpf(h, LAKE_FLOOR, plain_t)
	h -= (1.0 - smoothstep(0.0, 36.0, lake_d)) * 6.2
	var td := Vector2(x - TERRACE_C.x, z - TERRACE_C.y).length()
	h = lerpf(h, terrace_h, 1.0 - smoothstep(11.0, 22.0, td))
	return h

func color_at(x: float, z: float, h: float) -> Color:
	var d := absf(x - path_x(z))
	var path_t := 1.0 - clampf((d - 5.0) / 9.0, 0.0, 1.0)
	var c_grass_a := Color(0.40, 0.47, 0.36)
	var c_grass_b := Color(0.33, 0.42, 0.35)
	var c_rock := Color(0.45, 0.46, 0.46)
	var c_snow := Color(0.94, 0.94, 0.91)
	var c_path := Color(0.78, 0.68, 0.48)
	var c := c_grass_a.lerp(c_grass_b, clampf(noise_hi.get_noise_2d(x * 1.7, z * 1.7) + 0.5, 0.0, 1.0))
	c = c.lerp(c_rock, clampf((h - 24.0) / 16.0, 0.0, 1.0))
	c = c.lerp(c_snow, clampf((h - 42.0) / 12.0, 0.0, 1.0))
	var low := 1.0 - clampf((h - 24.0) / 10.0, 0.0, 1.0)
	c = c.lerp(c_path, path_t * low)
	if h < water_y + 0.9:
		var w := clampf((water_y + 0.9 - h) / 3.0, 0.0, 1.0)
		c = c.lerp(Color(0.76, 0.70, 0.52), minf(w * 1.6, 1.0))
	if h < water_y - 0.3:
		c = c.lerp(Color(0.30, 0.38, 0.34), 0.7)
	var j := noise_hi.get_noise_2d(x * 11.0, z * 11.0) * 0.09
	return Color(c.r + j, c.g + j, c.b + j)

func _build() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var step := SIZE / float(SEG)
	var half := SIZE / 2.0
	for iz in SEG:
		for ix in SEG:
			var x0 := -half + ix * step
			var z0 := -half + iz * step
			var x1 := x0 + step
			var z1 := z0 + step
			var v00 := Vector3(x0, height(x0, z0), z0)
			var v10 := Vector3(x1, height(x1, z0), z0)
			var v01 := Vector3(x0, height(x0, z1), z1)
			var v11 := Vector3(x1, height(x1, z1), z1)
			_tri(st, v00, v10, v11)
			_tri(st, v00, v11, v01)
	st.generate_normals()
	var mesh := st.commit()
	var mat := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = TERRAIN_SHADER
	mat.shader = sh
	mesh.surface_set_material(0, mat)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	add_child(mi)
	mi.create_trimesh_collision()

func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	st.set_smooth_group(-1)
	for v in [a, b, c]:
		st.set_color(color_at(v.x, v.z, v.y))
		st.add_vertex(v)
