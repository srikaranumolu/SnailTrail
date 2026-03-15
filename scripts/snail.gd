extends Area2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var floor_ray: RayCast2D = $FloorRay
@onready var wall_ray: RayCast2D = $WallRay
@export var no_wall_flip = false 

signal player_died

@export var SPEED = 100.0 
@export var initial_direction = -1
var direction = -1.0
var can_move = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if initial_direction == 1:
		_flip()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not can_move: return

	position.x += direction * SPEED * delta
	if not floor_ray.is_colliding():
			_flip()
			
	if not no_wall_flip:
		if wall_ray.is_colliding():
				var collider = wall_ray.get_collider()
				if collider.name != "Player":
					_flip()
		
		


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" and body.alive:
		player_died.emit(body)

func _flip() -> void:
	direction *= -1
	animated_sprite_2d.flip_h = !animated_sprite_2d.flip_h
	
	floor_ray.position.x *= -1
	wall_ray.target_position *= -1
