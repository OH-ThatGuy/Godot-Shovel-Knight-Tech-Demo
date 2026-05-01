extends CharacterBody2D

@export var speed := 35.0
@export var gravity := 900.0
@export var death_launch_y := -260.0
@export var death_launch_x := 80.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var wall_check_left: RayCast2D = $WallCheckLeft
@onready var wall_check_right: RayCast2D = $WallCheckRight
@onready var floor_check_left: RayCast2D = $FloorCheckLeft
@onready var floor_check_right: RayCast2D = $FloorCheckRight
@onready var player_hitbox: Area2D = $PlayerHitbox
@onready var smoke: AnimatedSprite2D = $Smoke

var direction := 1
var health := 3
var dead := false


func _ready() -> void:
	anim_player.play("Walk")
	sprite.flip_h = false
	smoke.visible = false


func _physics_process(delta: float) -> void:
	if dead:
		velocity.y += gravity * delta
		move_and_slide()

		if is_on_floor():
			velocity = Vector2.ZERO
			set_physics_process(false)

			sprite.visible = false
			player_hitbox.monitoring = false

			if smoke != null:
				smoke.visible = true
				smoke.play("smoke")
				await smoke.animation_finished

			queue_free()

		return

	velocity.y += gravity * delta
	velocity.x = direction * speed

	if direction < 0 and (wall_check_left.is_colliding() or not floor_check_left.is_colliding()):
		_turn_around()
	elif direction > 0 and (wall_check_right.is_colliding() or not floor_check_right.is_colliding()):
		_turn_around()

	move_and_slide()

	for body in player_hitbox.get_overlapping_bodies():
		if body.name == "Treasure Knight" and body.has_method("take_damage"):
			body.take_damage(global_position)


func _turn_around() -> void:
	direction *= -1
	sprite.flip_h = direction < 0


func take_damage(damage := 1, source_position := Vector2.ZERO) -> void:
	if dead:
		return

	health -= damage

	if health <= 0:
		die(source_position)


func die(source_position: Vector2) -> void:
	dead = true
	player_hitbox.monitoring = false
	anim_player.stop()

	var dir: float = sign(global_position.x - source_position.x)
	if dir == 0:
		dir = -direction

	velocity.x = dir * death_launch_x
	velocity.y = death_launch_y

	sprite.rotation_degrees = 180
