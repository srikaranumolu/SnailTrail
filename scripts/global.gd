extends Node

var selected_level: int = 1

func save_score(level_num: int, new_score: int) -> void:
	var scores = {}
	if FileAccess.file_exists("user://scores.save"):
		var file = FileAccess.open("user://scores.save", FileAccess.READ)
		var content = file.get_as_text()
		var json = JSON.new()
		if json.parse(content) == OK:
			if json.data is Dictionary:
				scores = json.data

	var level_key = "level" + str(level_num)
	var current_best = scores.get(level_key, 0)

	if new_score > current_best:
		scores[level_key] = new_score
		var file = FileAccess.open("user://scores.save", FileAccess.WRITE)
		file.store_string(JSON.stringify(scores))
