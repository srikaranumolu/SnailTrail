extends Node2D
@onready var score_label: Label = $HUD/ScorePanel/ScoreLabel
@onready var fade: ColorRect = $HUD/Fade

var level: int = 1
var score: int = 0
var current_level_root: Node = null
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	fade.modulate.a = 1.0
	current_level_root = get_node("LevelRoot")
	await _load_level(level, true, false)
#Level Management

func _load_level(level_number: int, first_load: bool, reset_score: bool) -> void:
	# Fade out
	if not first_load:
		await _fade(1.0)
		
	if reset_score:
		score = 0
	score_label.text = "SCORE: %s" % score	
	if current_level_root:
		if current_level_root.get_parent() == self:
			remove_child(current_level_root)
		current_level_root.queue_free()
		
	var level_path = "res://scenes/levels/level%s.tscn" % level_number
	current_level_root = load(level_path).instantiate()
	add_child(current_level_root)
	current_level_root.name = "LevelRoot"
	_setup_level(current_level_root)
	
	# Fade in
	await _fade(0.0)

func _setup_level(level_root: Node) -> void:
	var player = level_root.get_node_or_null("Player")
	if player:
		player.curr_level = level
	# Connect exit
	var flag = level_root.get_node_or_null("Flag")
	if flag:
		flag.body_entered.connect(_on_flag_entered)
	
	# Connect enemies
	var enemies = level_root.get_node_or_null("Enemies")
	if enemies:
		for enemy in enemies.get_children():
			enemy.player_died.connect(_on_player_died)
			
	# Connect apples
	var apples = level_root.get_node_or_null("Apples")
	if apples:
		for apple in apples.get_children():
			apple.collected.connect(_increase_score)
			


#SIGNAL HANDLERS
func _on_flag_entered(body: Node2D) -> void:
	if body.name == "Player":
		body.can_move = false
		level += 1
		await _load_level(level, false, false)
		
func _on_player_died(body: Node2D) -> void:
	body.die()
	await _load_level(level, false, true)
	
func _increase_score() -> void:
	score += 1
	score_label.text = "SCORE: %s" % score
	
func _fade(to_alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(fade, "modulate:a", to_alpha, 1.5)
	await tween.finished
	
