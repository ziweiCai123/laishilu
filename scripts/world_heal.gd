extends Node3D
## 世界痊愈:收集让山谷苏醒;低谷让身体先于文字感到沉重

const LOW_S := -62.0
const LOW_N := -152.0

var env: Environment
var player: CharacterBody3D
var mem: Node3D
var wind: AudioStreamPlayer
var notes: Array = []
var drone: AudioStreamPlayer
var _players: Array = []
var _note_i := 2
var _timer := 2.0
var _heavy_in := false
var _rng := RandomNumberGenerator.new()
var sun: DirectionalLight3D

func _ready() -> void:
	env = get_node("../WorldEnvironment").environment
	player = get_node("../Player")
	mem = get_node("../Memories")
	wind = get_node("../Wind")
	sun = get_node("../Sun")
	_rng.seed = 8
	for i in 6:
		notes.append(load("res://assets/audio/note_%d.wav" % i))
	drone = AudioStreamPlayer.new()
	drone.stream = load("res://assets/audio/drone.wav")
	drone.volume_db = -60.0
	add_child(drone)
	var ds := drone.stream as AudioStreamWAV
	if ds:
		ds.loop_mode = AudioStreamWAV.LOOP_FORWARD
		ds.loop_begin = 0
		ds.loop_end = ds.data.size() / 2
	drone.play()
	for i in 4:
		var p := AudioStreamPlayer.new()
		p.volume_db = -60.0
		add_child(p)
		_players.append(p)

func _process(delta: float) -> void:
	var got := 0
	for n in mem.nodes:
		if n.is_collected:
			got += 1
	var total: int = maxi(mem.nodes.size(), 1)
	var heal := float(got) / float(total)
	if player.has_node("Scarf"):
		player.get_node("Scarf").progress = heal
	var heavy := player.position.z < LOW_S and player.position.z > LOW_N
	if heavy != _heavy_in:
		_heavy_in = heavy
		player.heavy = heavy
	var fog_t: float = lerpf(0.0009, 0.00038, heal) * (2.2 if heavy else 1.0)
	var sat_t: float = lerpf(1.06, 1.18, heal) * (0.82 if heavy else 1.0)
	var vfog_t: float = lerpf(0.005, 0.003, heal) * (2.0 if heavy else 1.0)
	env.fog_density = lerpf(env.fog_density, fog_t, delta * 0.8)
	env.adjustment_saturation = lerpf(env.adjustment_saturation, sat_t, delta * 0.8)
	env.volumetric_fog_density = lerpf(env.volumetric_fog_density, vfog_t, delta * 0.8)
	var wind_db := -9.0 + (3.0 if heavy else 0.0) - (5.0 if player.sitting else 0.0)
	wind.volume_db = lerpf(wind.volume_db, wind_db, delta * 2.0)
	var jt := clampf((170.0 - player.position.z) / 375.0, 0.0, 1.0)
	sun.rotation_degrees = Vector3(lerpf(-31.0, -14.0, jt), lerpf(200.0, 214.0, jt), 0.0)
	sun.light_energy = lerpf(1.35, 1.12, jt)
	sun.light_color = Color(1.0, 0.918, 0.8).lerp(Color(1.0, 0.82, 0.65), jt)
	var sm := env.sky.sky_material as ShaderMaterial
	if sm:
		sm.set_shader_parameter("top_color", Color(0.45, 0.56, 0.70).lerp(Color(0.40, 0.40, 0.55), jt))
		sm.set_shader_parameter("horizon_color", Color(0.93, 0.81, 0.68).lerp(Color(0.86, 0.71, 0.63), jt))
	env.fog_light_color = Color(0.906, 0.882, 0.8).lerp(Color(0.84, 0.76, 0.70), jt)
	if heavy:
		_timer = 1.0
		drone.volume_db = lerpf(drone.volume_db, -13.0, delta * 1.5)
	else:
		drone.volume_db = lerpf(drone.volume_db, -60.0, delta * 1.5)
		var voices := mini(got, 5)
		if voices > 0:
			_timer -= delta
			if _timer <= 0.0:
				_timer = _rng.randf_range(3.2, 5.8) - voices * 0.35
				_play_note(voices)

func _play_note(voices: int) -> void:
	_note_i = clampi(_note_i + _rng.randi_range(-2, 2), 0, notes.size() - 1)
	for p in _players:
		if not p.playing:
			p.stream = notes[_note_i]
			p.volume_db = -14.0 + voices * 1.2
			p.play()
			return
