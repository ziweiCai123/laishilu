extends Node3D
## 讲故事的人:序章低语、终点的光、尾声仪式

var chapters: Array = []
var ep_all_text := ""
var ep_partial_text := "%d"
var _ep_all := false
var _ep_partial := false
var _t := 0.0
var _pro_done := false
var player: CharacterBody3D
var mem: Node3D
var ui: CanvasLayer
var menus: CanvasLayer
var beacon_pillar_mat: StandardMaterial3D
var beacon_core_mat: StandardMaterial3D
var beacon_light: OmniLight3D

func _ready() -> void:
	var f := FileAccess.open("res://story.json", FileAccess.READ)
	if f:
		var data: Variant = JSON.parse_string(f.get_as_text())
		if data is Dictionary:
			chapters = data.get("chapters", [])
			var epi: Dictionary = data.get("epilogue", {})
			ep_all_text = str(epi.get("all", ""))
			ep_partial_text = str(epi.get("partial", "%d"))
	player = get_node("../Player")
	mem = get_node("../Memories")
	ui = get_node("../UI")
	menus = get_node("../Menus")
	_build_beacon()
	if menus.state != "title":
		_prologue()
	else:
		await menus.started
		_prologue()

func _prologue() -> void:
	await get_tree().create_timer(1.6).timeout
	if chapters.size() > 0:
		ui.show_chapter(str(chapters[0].get("title", "")), str(chapters[0].get("text", "")))
	_pro_done = true

func _build_beacon() -> void:
	var terrain := get_node("../Terrain")
	var x: float = terrain.path_x(-205.0)
	var y: float = terrain.height(x, -205.0)
	var root := Node3D.new()
	root.position = Vector3(x, y, -205.0)
	add_child(root)
	var pillar := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.7
	cm.bottom_radius = 2.2
	cm.height = 70.0
	cm.cap_top = false
	cm.cap_bottom = false
	beacon_pillar_mat = StandardMaterial3D.new()
	beacon_pillar_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beacon_pillar_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beacon_pillar_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	beacon_pillar_mat.albedo_color = Color(1.0, 0.9, 0.62, 0.09)
	beacon_pillar_mat.emission_enabled = true
	beacon_pillar_mat.emission = Color(1.0, 0.88, 0.58)
	beacon_pillar_mat.emission_energy_multiplier = 0.8
	cm.material = beacon_pillar_mat
	pillar.mesh = cm
	pillar.position = Vector3(0, 35.0, 0)
	root.add_child(pillar)
	var core := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.6
	sm.height = 1.2
	beacon_core_mat = StandardMaterial3D.new()
	beacon_core_mat.albedo_color = Color(1.0, 0.9, 0.7)
	beacon_core_mat.emission_enabled = true
	beacon_core_mat.emission = Color(1.0, 0.86, 0.55)
	beacon_core_mat.emission_energy_multiplier = 2.4
	sm.material = beacon_core_mat
	core.mesh = sm
	core.position = Vector3(0, 2.0, 0)
	root.add_child(core)
	beacon_light = OmniLight3D.new()
	beacon_light.light_color = Color(1.0, 0.88, 0.6)
	beacon_light.omni_range = 34.0
	beacon_light.light_energy = 1.4
	beacon_light.position = Vector3(0, 3.0, 0)
	root.add_child(beacon_light)

func _process(delta: float) -> void:
	_t += delta
	var boost := 1.9 if _ep_all else 1.0
	if beacon_pillar_mat:
		beacon_pillar_mat.albedo_color.a = (0.07 + 0.03 * sin(_t * 0.8)) * boost
		beacon_pillar_mat.emission_energy_multiplier = (0.7 + 0.25 * sin(_t * 0.8)) * boost
	if beacon_core_mat:
		beacon_core_mat.emission_energy_multiplier = (2.2 + 0.5 * sin(_t * 1.2)) * boost
	if beacon_light:
		beacon_light.light_energy = (1.2 + 0.3 * sin(_t * 0.9)) * boost
	if not _pro_done or menus.state == "title":
		return
	var got := 0
	for n in mem.nodes:
		if n.is_collected:
			got += 1
	var total: int = mem.nodes.size()
	if player.position.z < -198.0:
		if total > 0 and got >= total:
			if not _ep_all:
				_ep_all = true
				ui.show_chapter("尾声", ep_all_text)
				_ending()
		elif not _ep_partial:
			_ep_partial = true
			ui.show_chapter("雾还留着几段光", ep_partial_text % got)

func _ending() -> void:
	await get_tree().create_timer(5.5).timeout
	if is_instance_valid(self) and is_inside_tree() and is_instance_valid(menus):
		menus.show_ending()
