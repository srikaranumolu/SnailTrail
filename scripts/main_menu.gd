extends Control

@onready var background: TextureRect = %Background
@onready var player: CharacterBody2D = %Player
@onready var menu_camera: Camera2D = %MenuCamera
@onready var fade: ColorRect = %Fade

@onready var play_button_panel: Panel = %PlayButton
@onready var level_select_panel: PanelContainer = %LevelSelectPanel
@onready var leaderboard_panel: PanelContainer = %LeaderboardPanel
@onready var settings_panel: PanelContainer = %SettingsPanel

@onready var levels_btn: Button = %LevelsBtn
@onready var leaderboard_btn: Button = %LeaderboardBtn
@onready var restart_btn: Button = %RestartBtn
@onready var settings_btn: Button = %SettingsBtn

@onready var levels_area: Area2D = %LevelsButtonArea
@onready var leaderboard_area: Area2D = %LeaderboardButtonarea
@onready var restart_area: Area2D = %RestartButtonArea
@onready var settings_area: Area2D = %SettingsButtonArea

@onready var levels_icon: Sprite2D = %LevelsIcon
@onready var leaderboard_icon: Sprite2D = %LeaderboardIcon
@onready var restart_icon: Sprite2D = %RestartIcon
@onready var settings_icon: Sprite2D = %SettingsIcon

@onready var volume_slider: HSlider = %VolumeSlider
@onready var title_label: Label = %Title
@onready var play_button_area: Area2D = %PlayButtonArea
@onready var title_snail: Node2D = %Snail3

@onready var level1_score_label: Label = %Level1ScoreLabel
@onready var level2_score_label: Label = %Level2ScoreLabel
@onready var level3_score_label: Label = %Level3ScoreLabel

var hovered_icons: Dictionary = {}
var current_open_panel: Control = null

func _ready() -> void:
	# 1. Fade Setup
	fade.visible = true
	fade.modulate.a = 0.0
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE

	#var level_size = Vector2(880, 440)
	#var viewport_size = get_viewport_rect().size
	#var zoom_x = viewport_size.x / level_size.x
	#var zoom_y = viewport_size.y / level_size.y
	#var zoom_val = min(zoom_x, zoom_y)
	#var level_size = Vector2(880, 440)
	#var viewport_size = get_viewport_rect().size
	#var zoom_x = viewport_size.x / level_size.x
	#var zoom_y = viewport_size.y / level_size.y

	#var zoom_val = min(zoom_x, zoom_y)
	#if menu_camera: menu_camera.zoom = Vector2(zoom_val, zoom_val)

	#Player Setup
	player.curr_level = 1 # no double jump
	player.can_move = true

	
	title_label.position.y = -200
	var original_snail_y = title_snail.position.y
	if "can_move" in title_snail:
		title_snail.can_move = false

	title_snail.position.y = original_snail_y - 241

	var tween = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	tween.tween_property(title_label, "position:y", 41.0, 0.6)
	tween.tween_property(title_snail, "position:y", original_snail_y, 0.6)

	tween.finished.connect(func():
		if "can_move" in title_snail:
			title_snail.can_move = true
	)

	#  Connect Signals
	play_button_panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	play_button_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	for child in play_button_panel.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE

	play_button_panel.gui_input.connect(_on_play_button_gui_input)
	play_button_panel.mouse_entered.connect(_on_play_button_mouse_entered)
	play_button_panel.mouse_exited.connect(_on_play_button_mouse_exited)

	_setup_icon_button(levels_btn, levels_icon, level_select_panel)
	_setup_icon_button(leaderboard_btn, leaderboard_icon, leaderboard_panel)
	_setup_icon_button(settings_btn, settings_icon, settings_panel)
	if restart_btn:
		restart_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		restart_btn.pressed.connect(func():
			_animate_icon_click(restart_icon)
			get_tree().reload_current_scene()
		)
		restart_btn.mouse_entered.connect(func(): _set_icon_hover(restart_icon, true))
		restart_btn.mouse_exited.connect(func(): _set_icon_hover(restart_icon, false))

	var panels_with_close = [level_select_panel, leaderboard_panel, settings_panel]
	for p in panels_with_close:
		if p:
			var close_btn = p.find_child("CloseBtn", true, false)
			if close_btn:
				close_btn.pressed.connect(func(): close_panel(p))


	if %Level1Btn: %Level1Btn.pressed.connect(func(): _load_game(1))
	if %Level2Btn: %Level2Btn.pressed.connect(func(): _load_game(2))
	if %Level3Btn: %Level3Btn.pressed.connect(func(): _load_game(3))

	# Volume Slider
	volume_slider.value_changed.connect(_on_volume_changed)
	
	_load_scores()
	


func _process(delta: float) -> void:
	background.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED

	var time = Time.get_ticks_msec() / 1000.0
	var idle_scale_val = 4.0 + sin(time * 5.0) * 0.2
	var idle_scale = Vector2(idle_scale_val, idle_scale_val)

	_update_icon_scale(levels_icon, idle_scale)
	_update_icon_scale(leaderboard_icon, idle_scale)
	_update_icon_scale(restart_icon, idle_scale)
	_update_icon_scale(settings_icon, idle_scale)

	_align_button(levels_btn, levels_area)
	_align_button(leaderboard_btn, leaderboard_area)
	_align_button(restart_btn, restart_area)
	_align_button(settings_btn, settings_area)

func _align_button(btn: Button, area: Area2D) -> void:
	if not btn or not area: return
	
	var screen_pos = area.get_global_transform_with_canvas().origin

	btn.global_position = screen_pos - (btn.size / 2.0)
	
func open_panel(panel: Control) -> void:
	if current_open_panel: return 
	current_open_panel = panel

	_set_main_ui_enabled(false)

	panel.visible = true

	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	panel.pivot_offset = panel.size / 2

	panel.scale = Vector2(0.00001, 0.00001)
	
	var tween = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.3)
	
	player.can_move = false
	player.velocity = Vector2.ZERO # stop the movement immediately
	if player.animated_sprite_2d:
		player.animated_sprite_2d.play("idle") 

func close_panel(panel: Control) -> void:
	var tween = create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(panel, "scale", Vector2(0.00001, 0.00001), 0.2)
	tween.finished.connect(func(): 
		panel.visible = false
		player.can_move = true
		current_open_panel = null
		_set_main_ui_enabled(true)
	)

func _set_main_ui_enabled(enabled: bool) -> void:
	var mode = Control.MOUSE_FILTER_STOP if not enabled else Control.MOUSE_FILTER_IGNORE
	# Uese

	levels_btn.disabled = not enabled
	leaderboard_btn.disabled = not enabled
	settings_btn.disabled = not enabled
	if restart_btn: restart_btn.disabled = not enabled
	if enabled:
		play_button_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		play_button_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _load_game(level_number: int) -> void:
	player.can_move = false
	fade.visible = true
	fade.mouse_filter = Control.MOUSE_FILTER_STOP

	var tween = create_tween()
	tween.tween_property(fade, "modulate:a", 1.0, 0.4)
	tween.finished.connect(func():
		Global.selected_level = level_number
		get_tree().change_scene_to_file("res://scenes/main.tscn")
	)

func _load_scores() -> void:
	if FileAccess.file_exists("user://scores.save"):
		var file = FileAccess.open("user://scores.save", FileAccess.READ)
		var content = file.get_as_text()
		var json = JSON.new()
		var error = json.parse(content)
		if error == OK:
			var data = json.data
			if data.has("level1"): level1_score_label.text = "LEVEL 1: " + str(data.level1)
			if data.has("level2"): level2_score_label.text = "LEVEL 2: " + str(data.level2)
			if data.has("level3"): level3_score_label.text = "LEVEL 3: " + str(data.level3)
		else:
			print("Error parsing scores")
	else:
		pass

func _on_play_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_load_game(1)

func _on_play_button_mouse_entered() -> void:
	var tween = create_tween()
	tween.tween_property(play_button_panel, "scale", Vector2(1.05, 1.05), 0.1)

func _on_play_button_mouse_exited() -> void:
	var tween = create_tween()
	tween.tween_property(play_button_panel, "scale", Vector2.ONE, 0.1)

# Volume
func _on_volume_changed(value: float) -> void:
	var db = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(0, db)

func _setup_icon_button(btn: Button, icon: Sprite2D, panel: Control = null) -> void:
	if not btn or not icon: return

	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.pressed.connect(func():
		_animate_icon_click(icon)
		if panel: open_panel(panel)
	)
	btn.mouse_entered.connect(func(): _set_icon_hover(icon, true))
	btn.mouse_exited.connect(func(): _set_icon_hover(icon, false))

func _set_icon_hover(icon: Sprite2D, is_hovering: bool):
	hovered_icons[icon] = is_hovering
	if is_hovering:
		var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(icon, "scale", Vector2(5.5, 5.5), 0.2)

func _update_icon_scale(icon: Sprite2D, idle_scale: Vector2):
	if icon and not hovered_icons.get(icon, false):
		var tween = create_tween()
		tween.tween_property(icon, "scale", idle_scale, 0.1)

func _animate_icon_click(icon: Sprite2D):
	var tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(icon, "scale", Vector2(3.0, 3.0), 0.1)
	tween.tween_property(icon, "scale", Vector2(5.5, 5.5), 0.2)
