extends Node
## 효과음과 배경음악. 발사·적 피격·보석 소리와 배경음악은 assets/sounds 의 파일을 쓰고,
## 레벨업·플레이어 피격 소리는 코드로 파형을 만들어 쓴다.
## 다른 곳에서는 get_tree().call_group("sfx", "play", "shoot")처럼 부른다.

const MIX_RATE := 22050
const BGM := preload("res://assets/sounds/bgm.mp3")
const BGM_VOLUME_DB := -10.0

# 이름: [볼륨(dB), 동시에 겹쳐 낼 수 있는 수]
const SETTINGS := {
	"shoot": [-8.0, 4],
	"enemy_hit": [-6.0, 6],
	"gem": [-8.0, 6],
	"level_up": [-4.0, 1],
	"hit": [-4.0, 2],
}

var _players := {}


func _ready() -> void:
	add_to_group("sfx")
	# 레벨업 소리는 게임이 멈춘 순간에 나므로 멈춰 있어도 동작해야 한다
	process_mode = Node.PROCESS_MODE_ALWAYS
	var streams := {
		"shoot": preload("res://assets/sounds/attack.mp3"),
		"enemy_hit": preload("res://assets/sounds/defens.mp3"),
		"gem": preload("res://assets/sounds/jew.mp3"),
		"level_up": make_level_up(),
		"hit": make_hit(),
	}
	for sound_name in streams:
		var player := AudioStreamPlayer.new()
		player.stream = streams[sound_name]
		player.volume_db = SETTINGS[sound_name][0]
		player.max_polyphony = SETTINGS[sound_name][1]
		add_child(player)
		_players[sound_name] = player
	play_bgm()


func play_bgm() -> void:
	# 원본 파일 설정은 건드리지 않고, 복사본에만 반복을 켠다
	var music: AudioStreamMP3 = BGM.duplicate()
	music.loop = true
	var player := AudioStreamPlayer.new()
	player.name = "Bgm"
	player.stream = music
	player.volume_db = BGM_VOLUME_DB
	add_child(player)
	player.play()


func play(sound_name: String) -> void:
	_players[sound_name].play()


func duration_of(sound_name: String) -> float:
	return _players[sound_name].stream.get_length()


## 밝게 올라가는 세 음(도-미-솔)
func make_level_up() -> AudioStreamWAV:
	var notes := [523.25, 659.25, 783.99]
	return build(0.36, func(t: float, progress: float) -> float:
		var note_index := mini(int(progress * notes.size()), notes.size() - 1)
		var note_progress := progress * notes.size() - note_index
		return sin(TAU * notes[note_index] * t) * (1.0 - note_progress * 0.6))


## 낮게 깔리는 '쿵' 소리: 180Hz에서 90Hz로 내려가는 톱니파
func make_hit() -> AudioStreamWAV:
	return build(0.15, func(t: float, progress: float) -> float:
		var frequency := lerpf(180.0, 90.0, progress)
		return saw(t * frequency) * (1.0 - progress))


func build(duration: float, wave: Callable) -> AudioStreamWAV:
	var count := int(duration * MIX_RATE)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var t := float(i) / MIX_RATE
		var sample: float = clampf(wave.call(t, float(i) / count), -1.0, 1.0)
		data.encode_s16(i * 2, int(sample * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	return stream


func saw(phase: float) -> float:
	return fmod(phase, 1.0) * 2.0 - 1.0
