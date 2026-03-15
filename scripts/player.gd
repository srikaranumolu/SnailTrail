extends CharacterBody2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var jump_sound: AudioStreamPlayer2D = $JumpSound
@onready var death_sound: AudioStreamPlayer2D = $DeathSound

const SPEED = 300.0
const JUMP_VELOCITY = -850.0
var alive: bool = true
var can_move: bool = true
var jump_count: int = 0
var curr_level: int = 1

func _physics_process(delta: float) -> void:
	if not alive:
		return

	if animated_sprite_2d.animation in ["appearing", "disappearing"] and animated_sprite_2d.is_playing():
		if not is_on_floor():
			velocity += get_gravity() * delta
		velocity.x = 0
		move_and_slide()
		return

	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		#account for falling off ledges
		if jump_count == 0:
			jump_count = 1
		if animated_sprite_2d.animation == "double_jump" and animated_sprite_2d.is_playing():
			pass
		elif velocity.y < 0:
			animated_sprite_2d.play("jumping")
		else:
			animated_sprite_2d.play("falling")
	else:
		jump_count = 0
		# Add animation
		if velocity.x > 1 or velocity.x < -1:
			animated_sprite_2d.play("running")
		else:
			animated_sprite_2d.play("idle")

	if can_move:
		if Input.is_action_just_pressed("jump"):
			var can_double_jump: bool = curr_level >= 3
			if jump_count < 2 and (jump_count == 0 or can_double_jump):
				jump_count += 1
				velocity.y = JUMP_VELOCITY
				jump_sound.play()
				if jump_count == 2:
					animated_sprite_2d.play("double_jump")

		var direction := Input.get_axis("left", "right")
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			
		move_and_slide()
		
		if direction == 1.0:
			animated_sprite_2d.flip_h = false
		if direction == -1.0:
			animated_sprite_2d.flip_h = true
	else:
		animated_sprite_2d.stop()
		

func die() -> void:
	animated_sprite_2d.animation = "dying"
	death_sound.play()
	alive = false

func appear() -> void:
	animated_sprite_2d.play("appearing")
	can_move = false
	await animated_sprite_2d.animation_finished
	can_move = true

func disappear() -> void:
	animated_sprite_2d.play("disappearing")
	can_move = false
	await animated_sprite_2d.animation_finished
	visible = false
