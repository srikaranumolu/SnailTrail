extends Control
@onready var diamond_rect: TextureRect = %DiamondRect
@onready var splash_panel: PanelContainer = %SplashPanel
@onready var level_label: Label = %LevelLabel
func _ready() -> void:
	diamond_rect.scale = Vector2.ZERO
	splash_panel.visible = false

func play_transition(level_number: int, load_callback: Callable = Callable()) -> void:
	level_label.text = "LEVEL %d" % level_number

	diamond_rect.pivot_offset = diamond_rect.size / 2

	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(diamond_rect, "scale", Vector2(60, 60), 0.5)
	await tween.finished

	if load_callback.is_valid():
		var result = load_callback.call()
		if result is Signal:
			await result

	splash_panel.visible = true
	var viewport_size = get_viewport_rect().size
	splash_panel.position = Vector2(viewport_size.x / 2 - splash_panel.size.x / 2, -splash_panel.size.y)

	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	var target_y = viewport_size.y / 2 - splash_panel.size.y / 2
	tween.tween_property(splash_panel, "position:y", target_y, 0.5)
	await tween.finished

	await get_tree().create_timer(1.2).timeout

	tween = create_tween()
	tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween.tween_property(splash_panel, "position:y", -splash_panel.size.y, 0.5)
	await tween.finished
	splash_panel.visible = false

	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(diamond_rect, "scale", Vector2.ZERO, 0.5)
	await tween.finished
