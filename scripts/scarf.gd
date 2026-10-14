extends Node3D
## 飘巾:Verlet 丝带,拾起的记忆越多,颜色越暖、丝带越长

const N := 13
const SEG := 0.17

var points := PackedVector3Array()
var prev := PackedVector3Array()
var progress := 0.0
var mesh_inst: MeshInstance3D
var im: ImmediateMesh
var _t := 0.0

func _ready() -> void:
	for i in N:
		points.append(global_position)
		prev.append(global_position)
	im = ImmediateMesh.new()
	mesh_inst = MeshInstance3D.new()
	mesh_inst.mesh = im
	mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.vertex_color_use_as_albedo = true
	mesh_inst.material_override = mat
	add_child(mesh_inst)

func reset() -> void:
	for i in N:
		points[i] = global_position
		prev[i] = global_position

func _process(delta: float) -> void:
	_t += delta
	var dt := minf(delta, 1.0 / 30.0)
	var pl := get_parent() as CharacterBody3D
	var gliding: bool = pl != null and pl.gliding
	var wind_boost: float = pl.wind_lift if pl != null else 0.0
	var anchor := to_global(Vector3(0, 0.62, -0.22))
	points[0] = anchor
	prev[0] = anchor
	var wind := Vector3(0.35, 0.04, -0.94) * (0.9 + 0.5 * sin(_t * 1.1)) * (1.0 + wind_boost * 2.4)
	if gliding:
		wind *= 2.8
		wind.y += 0.8
	for i in range(1, N):
		var v := (points[i] - prev[i]) * 0.965
		if v.length() > 0.6:
			v = v.normalized() * 0.6
		prev[i] = points[i]
		var acc := Vector3(0, -3.5, 0) + wind \
			+ Vector3(sin(_t * 7.0 + i * 1.3), 0, cos(_t * 6.1 + i * 1.7)) * 0.6
		points[i] += v + acc * dt * dt
	var seg := SEG * (1.0 + 0.28 * progress)
	for k in 3:
		for i in range(1, N):
			var d: Vector3 = points[i] - points[i - 1]
			var l := d.length()
			if l > 0.0001:
				var corr := d * ((l - seg) / l)
				if i > 1:
					points[i] -= corr * 0.5
					points[i - 1] += corr * 0.5
				else:
					points[i] -= corr
	_render()

func _render() -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var cp := cam.global_position
	var base_col := Color(0.93, 0.90, 0.82).lerp(Color(1.0, 0.78, 0.42), progress)
	im.clear_surfaces()
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i in N:
		var p := points[i]
		var dir := Vector3.DOWN
		if i < N - 1:
			dir = (points[i + 1] - p).normalized()
		var side := dir.cross(p - cp)
		if side.length() < 0.001:
			side = Vector3(1, 0, 0)
		side = side.normalized()
		var tt := float(i) / float(N - 1)
		var w := lerpf(0.17, 0.045, tt) * (1.0 + 0.12 * sin(_t * 5.0 + tt * 9.0))
		var c := base_col
		c.a = (1.0 - tt * tt) * 0.85 + 0.1
		im.surface_set_color(c)
		im.surface_add_vertex(p + side * w)
		im.surface_set_color(c)
		im.surface_add_vertex(p - side * w)
	im.surface_end()
