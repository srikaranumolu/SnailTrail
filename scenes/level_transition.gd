extends Control
@onready var diamond_rect: TextureRect = %DiamondRect
@onready var splash_panel: PanelContainer = %SplashPanel
@onready var level_label: Label = %LevelLabel
func _ready() -> void:
	diamond_rect.scale = Vector2.ZERO
	splash_panel.visible = false

func play_transition(level_number: int, load_callback: Callable = Callable()) -> void:
	level_label.text = "LEVEL %d" % level_number

	# Ensure correct pivot for scaling from center
	diamond_rect.pivot_offset = diamond_rect.size / 2

	# 1. Diamond In (Cover Screen)
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	# Scale up to cover the screen. 60x should be enough given base size 40 -> 2400px diagonal
	tween.tween_property(diamond_rect, "scale", Vector2(60, 60), 0.5)
	await tween.finished

	# 2. Execute loading logic while screen is covered
	if load_callback.is_valid():
		# If the callback returns a signal (async), await it
		var result = load_callback.call()
		if result is Signal:
			await result

	# 3. Splash Panel Drop In
	splash_panel.visible = true
	var viewport_size = get_viewport_rect().size
	# Start above screen
	splash_panel.position = Vector2(viewport_size.x / 2 - splash_panel.size.x / 2, -splash_panel.size.y)

	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	# Drop to center
	var target_y = viewport_size.y / 2 - splash_panel.size.y / 2
	tween.tween_property(splash_panel, "position:y", target_y, 0.5)
	await tween.finished

	# 4. Wait
	await get_tree().create_timer(1.2).timeout

	# 5. Splash Panel Bounce Out
	tween = create_tween()
	tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween.tween_property(splash_panel, "position:y", -splash_panel.size.y, 0.5)
	await tween.finished
	splash_panel.visible = false

	# 6. Diamond Out (Reveal Screen)
	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(diamond_rect, "scale", Vector2.ZERO, 0.5)
	await tween.finished
