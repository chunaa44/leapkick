extends Node

# volume of each sound in dB (0 = normal, negative = quieter)
const VOLUMES = {
	"hit": 0.0,
	"jump": -8.0,
	"dive": -4.0,
}

# how many sounds can overlap before the oldest gets cut off
const VOICES = 4

var streams = {}
var voices = []
var next_steal = 0

func _ready():
	for key in VOLUMES:
		streams[key] = find_sound(key)

	for i in VOICES:
		var voice = AudioStreamPlayer.new()
		add_child(voice)
		voices.append(voice)

func find_sound(sound):
	# accepts .wav, .ogg or .mp3 in res://sounds/
	for ext in ["wav", "ogg", "mp3"]:
		var path = "res://sounds/" + sound + "." + ext
		if ResourceLoader.exists(path):
			return load(path)
	return null

func play(sound):
	var stream = streams.get(sound)
	if stream == null:
		# missing file or unknown name, stay silent
		return

	# use a free voice, or cut off the oldest one if all are busy
	var voice = null
	for v in voices:
		if v.playing == false:
			voice = v
			break
	if voice == null:
		voice = voices[next_steal]
		next_steal = (next_steal + 1) % VOICES

	voice.stream = stream
	voice.volume_db = VOLUMES[sound]
	voice.pitch_scale = randf_range(0.95, 1.05)
	voice.play()
