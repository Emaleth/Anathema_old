extends Node

var num_players = 8
var bus = "UI"

var available = []
var queue = []


func _ready():
	make_pool()


func make_pool():
	for i in num_players:
		var p = AudioStreamPlayer.new()
		add_child(p)
		available.append(p)
		p.finished.connect(on_stream_finished.bind(p))
		p.bus = bus


func on_stream_finished(stream):
	available.append(stream)


func play(sound_path):
	queue.append(sound_path)


func _process(_delta):
	process_audion()


func process_audion():
	if not queue.is_empty() and not available.is_empty():
		available[0].stream = load(queue.pop_front())
		available[0].play()
		available.pop_front()
