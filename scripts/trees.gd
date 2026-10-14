extends Node3D
## 苍山松柏与乱石:合并网格 + MultiMesh,一次绘制铺满山坡

var terrain: Node3D
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	terrain = get_node("../Terrain")
	rng.seed = 77
	_forest()
	_rocks()

func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, col: Color) -> void:
	st.set_smooth_group(-1)
	for v in [a, b, c]:
		st.set_color(col)
		st.add_vertex(v)

func _cone(st: SurfaceTool, y0: float, r: float, h: float, c0: Color, c1: Color) -> void:
	var segs := 7
	for i in segs:
		var a0 := TAU * float(i) / float(segs)
		var a1 := TAU * float(i + 1) / float(segs)
		var p0 := Vector3(cos(a0) * r, y0, sin(a0) * r)
		var p1 := Vector3(cos(a1) * r, y0, sin(a1) * r)
		var ap := Vector3(0.0, y0 + h, 0.0)
		_tri(st, p0, p1, ap, c0.lerp(c1, rng.randf() * 0.6))

func _trunk(st: SurfaceTool, h: float) -> void:
	var col := Color(0.32, 0.25, 0.20)
	var r := 0.16
	_tri(st, Vector3(-r, 0, 0), Vector3(r, 0, 0), Vector3(0, h, 0), col)
	_tri(st, Vector3(r, 0, 0), Vector3(0, 0, -r), Vector3(0, h, 0), col)
	_tri(st, Vector3(0, 0, -r), Vector3(-r, 0, 0), Vector3(0, h, 0), col)
	_tri(st, Vector3(-r, 0, 0), Vector3(0, 0, r), Vector3(0, h, 0), col)

func _finish(st: SurfaceTool) -> ArrayMesh:
	st.generate_normals()
	var mesh := st.commit()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 1.0
	mesh.surface_set_material(0, mat)
	return mesh

func _pine_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_trunk(st, 1.1)
	var dk := Color(0.13, 0.21, 0.16)
	var lt := Color(0.27, 0.39, 0.27)
	_cone(st, 0.8, 1.5, 2.0, dk, lt)
	_cone(st, 1.7, 1.15, 1.8, dk, lt)
	_cone(st, 2.6, 0.8, 1.6, dk, lt)
	_cone(st, 3.4, 0.45, 1.3, dk, lt)
	return _finish(st)

func _cypress_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_trunk(st, 0.9)
	var dk := Color(0.16, 0.24, 0.17)
	var lt := Color(0.30, 0.42, 0.26)
	_cone(st, 0.7, 0.8, 2.6, dk, lt)
	_cone(st, 2.1, 0.55, 2.0, dk, lt)
	_cone(st, 3.4, 0.3, 1.5, dk, lt)
	return _finish(st)

func _scatter(mm: MultiMesh, want: int, side_west: bool, dmin: float, dmax: float, tree: bool) -> void:
	var placed := 0
	for i in want * 4:
		if placed >= want:
			break
		var z := rng.randf_range(-190.0, 215.0)
		var d := rng.randf_range(dmin, dmax)
		var sign_f := -1.0 if side_west else 1.0
		var x: float = terrain.path_x(z) + sign_f * d
		var y: float = terrain.height(x, z)
		if y > 38.0 or y < terrain.water_y + 1.0:
			continue
		if Vector2(x - terrain.TERRACE_C.x, z - terrain.TERRACE_C.y).length() < 18.0:
			continue
		if Vector2(x - terrain.LAKE_C.x, z - terrain.LAKE_C.y).length() < 58.0:
			continue
		if tree:
			var s := rng.randf_range(0.7, 1.7)
			var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s * rng.randf_range(0.9, 1.35), s))
			mm.set_instance_transform(placed, Transform3D(basis, Vector3(x, y - 0.15, z)))
		else:
			var b := Basis.from_euler(Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU)) \
				.scaled(Vector3(rng.randf_range(0.5, 2.6), rng.randf_range(0.4, 1.4), rng.randf_range(0.5, 2.6)))
			mm.set_instance_transform(placed, Transform3D(b, Vector3(x, y - 0.25, z)))
		placed += 1
	mm.instance_count = placed
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	add_child(mi)

func _forest() -> void:
	var pine_mm := MultiMesh.new()
	pine_mm.transform_format = MultiMesh.TRANSFORM_3D
	pine_mm.mesh = _pine_mesh()
	pine_mm.instance_count = 560
	_scatter(pine_mm, 560, true, 26.0, 140.0, true)
	var cy_mm := MultiMesh.new()
	cy_mm.transform_format = MultiMesh.TRANSFORM_3D
	cy_mm.mesh = _cypress_mesh()
	cy_mm.instance_count = 150
	_scatter(cy_mm, 150, false, 18.0, 70.0, true)

func _rocks() -> void:
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 1.4
	sm.radial_segments = 8
	sm.rings = 4
	var rock_mat := StandardMaterial3D.new()
	rock_mat.albedo_color = Color(0.46, 0.46, 0.46)
	rock_mat.roughness = 1.0
	sm.material = rock_mat
	_rocks_side(sm, 130, true)
	_rocks_side(sm, 100, false)

func _rocks_side(sm: Mesh, want: int, side_west: bool) -> void:
	var rm := MultiMesh.new()
	rm.transform_format = MultiMesh.TRANSFORM_3D
	rm.mesh = sm
	rm.instance_count = want
	_scatter(rm, want, side_west, 13.0, 120.0, false)
