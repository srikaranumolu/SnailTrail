extends CharacterBody2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var jump_sound: AudioStreamPlayer2D = $JumpSound
@onready var music: AudioStreamPlayer2D = $Music
@onready var death_sound: AudioStreamPlayer2D = $DeathSound

const SPEED = 300.0
const JUMP_VELOCITY = -850.0
var alive = true
var can_move = true
func _ready():
	music.play()

func _physics_process(delta: float) -> void:
	if not alive:
		return
	# Add animation
	if velocity.x > 1 or velocity.x < -1:
		animated_sprite_2d.animation = "running"
	else:
		animated_sprite_2d.animation = "idle"
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		if velocity.y < 0:
			animated_sprite_2d.animation = "jumping"
		else:
			animated_sprite_2d.animation = "falling"

	if can_move:
		# Handle jump.
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY
			jump_sound.play()

		# Get the input direction and handle the movement/deceleration.
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
