extends Node

enum MusicOptions {
	NONE,
	CITY,
	FLOREST
}
var cur_music: MusicOptions = MusicOptions.NONE

var music_paths = {
	MusicOptions.CITY: "res://assets/audios/music/City.ogg",
	MusicOptions.FLOREST: "res://assets/audios/music/Forest.ogg",
}

@onready var music_player: AudioStreamPlayer = $MusicPlayer

func _process(delta: float) -> void:
	if !music_player.playing and cur_music != MusicOptions.NONE:
		var path = music_paths.get(cur_music, "")
		
		if path != "" and ResourceLoader.exists(path):
			music_player.stream = load(path)
			music_player.play()
		else: 
			print("Ficheiro de música não encontrado!")

func set_music(music_index: int):
	var options = MusicOptions.values()
	if music_index >= 0 and music_index < options.size():
		cur_music = options[music_index]
	else:
		print("Índice de música inválido: ", music_index)
