extends Node2D
@onready var score_label: Label = $HUD/ScorePanel/ScoreLabel
@onready var fade: ColorRect = $HUD/Fade
@onready var level_transition: Control = $CanvasLayer/TransitionLayer
@onready var death_label: Label = %DeathLabel
@onready var confetti_particles: CPUParticles2D = %ConfettiParticles
@onready var unlock_overlay: Control = %UnlockOverlay
@onready var banner_panel: Panel = %BannerPanel
@onready var tip_panel: Panel = %TipPanel
@onready var camera_2d: Camera2D = $Camera2D

var level: int = 1
var score: int = 0
var current_level_root: Node = null
var has_shown_double_jump_unlock: bool = false

# Camera Shake
var shake_strength: float = 0.0
var shake_fade: float = 5.0

func _process(delta: float) -> void:
	if shake_strength > 0:
		shake_strength = lerpf(shake_strength, 0, shake_fade * delta)
		camera_2d.offset = random_offset()

func random_offset() -> Vector2:
	return Vector2(
		randf_range(-shake_strength, shake_strength),
		randf_range(-shake_strength, shake_strength)
	)

func start_shake(strength: float, fade: float = 5.0) -> void:
	shake_strength = strength
	shake_fade = fade

func _ready() -> void:
	fade.modulate.a = 1.0
	current_level_root = get_node("LevelRoot")
	await _load_level(level, true, false)

	if level == 3 and not has_shown_double_jump_unlock:
		_show_double_jump_unlock()

#Level Management

func _load_level(level_number: int, first_load: bool, reset_score: bool, skip_fade: bool = false, auto_appear: bool = true) -> void:
	# Fade out
	if not first_load and not skip_fade:
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
	if not skip_fade:
		_fade(0.0)
	else:
		fade.modulate.a = 0.0

	if auto_appear:
		var player = current_level_root.get_node_or_null("Player")
		if player:
			player.visible = true
			player.appear()

func _show_double_jump_unlock() -> void:
	has_shown_double_jump_unlock = true
	# Wait for appear to start/finish
	await get_tree().create_timer(1.0).timeout

	# Store original position before modifying
	var tip_target_pos = tip_panel.position.y

	Engine.time_scale = 0.2
	unlock_overlay.visible = true

	# Animate in
	banner_panel.scale = Vector2.ZERO
	# Move offscreen (down)
	tip_panel.position.y = tip_target_pos + 150

	var tween = create_tween().set_parallel(true)
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# Adjust duration for time scale: 0.5 real seconds = 0.1 game seconds
	tween.tween_property(banner_panel, "scale", Vector2.ONE, 0.1)
	# Delay 0.2 real seconds = 0.04 game seconds
	tween.tween_property(tip_panel, "position:y", tip_target_pos, 0.1).set_delay(0.04)

	await get_tree().create_timer(2.0, true, false, true).timeout # Ignore time scale

	# Animate out
	tween = create_tween().set_parallel(true)
	tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween.tween_property(banner_panel, "scale", Vector2.ZERO, 0.1)
	tween.tween_property(tip_panel, "position:y", tip_target_pos + 150, 0.1)

	await tween.finished
	unlock_overlay.visible = false
	Engine.time_scale = 1.0

func _setup_level(level_root: Node) -> void:
	var player = level_root.get_node_or_null("Player")
	if player:
		player.curr_level = level
		player.visible = false
		player.can_move = false
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

		# Confetti
		var flag = current_level_root.get_node_or_null("Flag")
		if flag:
			confetti_particles.global_position = flag.global_position
			confetti_particles.emitting = false
			confetti_particles.emitting = true

		await body.disappear()
		level += 1
		# Use the new transition with a callback to load the level in the middle
		await level_transition.play_transition(level, func(): await _load_level(level, false, false, true, false))

		var player = current_level_root.get_node_or_null("Player")
		if player:
			player.visible = true
			player.appear()

		if level == 3 and not has_shown_double_jump_unlock:
			_show_double_jump_unlock()

func _on_player_died(body: Node2D) -> void:
	body.die()
	start_shake(10.0, 20.0)

	death_label.text = [
	"OOPS!",
	"THAT HURT!",
	"WELP...",
	"NOT LIKE THIS",
	"I HATE SNAILS!",
	"SLIMY...",
	"DEFEATED BY A SNAIL. A SNAIL.",
	"THE SNAIL WON.",
	"TOUCHED BY A SNAIL RIP",
	"PINK MAN DOWN!",
	"PINK MAN HAS FALLEN",
	"RIP PINK MAN",
	"THE APPLES WEREN'T WORTH IT",
	"SO CLOSE TO THE FLAG...",
	"THE FLAG WILL HAVE TO WAIT",
	"BONKED.",
	"MAYBE LOOK WHERE YOU'RE GOING",
	"SKILL ISSUE",
	"INCREDIBLE PERFORMANCE",
	"WORLD CLASS PLATFORMING",
	"PHENOMENAL.",
	"TRY AGAIN BUDDY",
	"THE SNAIL IS CELEBRATING RIGHT NOW",
	"THAT SNAIL HAS NEVER FELT SO POWERFUL",
	"HUMILIATED BY A GASTROPOD",
	"A SNAIL. YOU LOST TO A SNAIL.",
	"MOLLUSKS: 1, YOU: 0",
].pick_random()
	var tween = create_tween()
	tween.tween_property(death_label, "modulate:a", 1.0, 0.2)
	await get_tree().create_timer(1.2).timeout
	tween = create_tween()
	tween.tween_property(death_label, "modulate:a", 0.0, 0.5)

	await _load_level(level, false, true)
	
func _increase_score() -> void:
	score += 1
	score_label.text = "SCORE: %s" % score
	
func _fade(to_alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(fade, "modulate:a", to_alpha, 1.0)
	await tween.finished
