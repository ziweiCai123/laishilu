extends SceneTree
## 一次性探针:采样地形函数,为洱海/风口/栈桥/花树选坐标

func _init() -> void:
	var t: Node3D = load("res://scripts/terrain.gd").new()
	t.noise_hi.seed = 7
	t.noise_hi.frequency = 0.012
	t.noise_hi.fractal_octaves = 4
	t.noise_lo.seed = 23
	t.noise_lo.frequency = 0.0042
	t.noise_lo.fractal_octaves = 3
	print("=== path_x ===")
	for z in [170, 145, 100, 60, 40, 28, 0, -50]:
		print("z=", z, " path_x=", snappedf(t.path_x(z), 0.1))
	print("=== lake center candidates ===")
	for p in [Vector2(95, 55), Vector2(100, 50), Vector2(90, 45), Vector2(105, 60), Vector2(95, 40)]:
		print(p, " h=", snappedf(t.height(p.x, p.y), 0.1))
	print("=== west slope z=40 (风候选) ===")
	var px40: float = t.path_x(40.0)
	for d in [18, 24, 30, 36, 44, 52]:
		var x: float = px40 - float(d)
		print("d=", d, " x=", snappedf(x, 0.1), " h=", snappedf(t.height(x, 40.0), 0.1))
	print("=== lakeshore transect z=30 (栈桥) ===")
	for x in range(40, 110, 6):
		print("x=", x, " h=", snappedf(t.height(float(x), 30.0), 0.1))
	print("=== misc ===")
	for p in [Vector2(58, -50), Vector2(50, -55), Vector2(66, -42), Vector2(33, 148), Vector2(41, 95), Vector2(35, 60), Vector2(46, 140), Vector2(30, 110)]:
		print(p, " h=", snappedf(t.height(p.x, p.y), 0.1))
	quit()
