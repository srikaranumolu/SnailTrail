extends Node

var music_player: AudioStreamPlayer


func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	music_player.stream = load("res://assets/sounds/music.ogg")
	music_player.autoplay = true
	music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	music_player.play()
