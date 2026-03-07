extends Node2D
@onready var score_label: Label = $HUD/ScorePanel/ScoreLabel

var level: int = 1
var score: int = 0
var current_level_root = null
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_level_root = get_node("LevelRoot")
	_load_level(level)
#Level Management

func _load_level(level_number: int) -> void:
	if current_level_root:
		if current_level_root.get_parent() == self:
			remove_child(current_level_root)
		current_level_root.queue_free()
		
	var level_path = "res://scenes/levels/level%s.tscn" % level_number
	current_level_root = load(level_path).instantiate()
	add_child(current_level_root)
	current_level_root.name = "LevelRoot"
	_setup_level(current_level_root)

func _setup_level(level_root: Node) -> void:
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
func _on_flag_entered(body) -> void:
	if body.name == "Player":
		body.can_move = false
		print(body)
		level += 1
		_load_level(level)
		print(level)

func _on_player_died(body) -> void:
	body.die()
	
func _increase_score() -> void:
	score += 1
	score_label.text = "SCORE: %s" % score
