extends CharacterBody2D

const SPEED := 120.0
const JUMP_VELOCITY := -380.0
const MIN_JUMP_VELOCITY := -180.0
const GRAVITY := 1200.0
const ACCEL := 400.0
const AIR_ACCEL := 1200.0
const MAX_FALL_SPEED := 600.0

const GRAPPLE_PULL_SPEED := 220.0

@export var grapple_scene: PackedScene
@onready var grapple_spawn := $GrappleSpawn
@onready var anim_player := $PivotNode/AnimationPlayer
@onready var sprite := $PivotNode/Sprite2D

var spawn_position: Vector2
var grapple_spawn_offset: Vector2

var facing_direction: int = 1
var turning: bool = false
var turn_dir: int = 0
var jump_held: bool = false
var on_floor: bool = false

var grapple_flying: bool = false
var grappling: bool = false
var grapple_point: Vector2 = Vector2.ZERO
var current_grapple: Area2D = null
var grapple_mode: String = "horizontal"
var air_grapple_available: bool = true


func _ready() -> void:
	spawn_position = global_position
	anim_player.animation_finished.connect(_on_anim_finished)
	grapple_spawn_offset = grapple_spawn.position


func _physics_process(delta: float) -> void:
	on_floor = is_on_floor()

	if Input.is_action_just_pressed("Debug_Reset"):
		_reset_player()

	if on_floor:
		air_grapple_available = true

	if grapple_flying:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if grappling:
		var prev_position: Vector2 = global_position

		if grapple_mode == "horizontal":
			velocity.y = 0
			var dir: float = 1.0 if grapple_point.x > global_position.x else -1.0
			velocity.x = GRAPPLE_PULL_SPEED * dir
		else:
			velocity.x = 0
			velocity.y = -GRAPPLE_PULL_SPEED * 0.88

		move_and_slide()

		if grapple_mode == "horizontal":
			if (velocity.x > 0 and global_position.x >= grapple_point.x) \
			or (velocity.x < 0 and global_position.x <= grapple_point.x):
				_stop_grapple()
		else:
			if global_position.y <= grapple_point.y:
				_stop_grapple()

		if global_position.distance_to(prev_position) < 0.1:
			_stop_grapple()

		return

	if Input.is_action_just_pressed("Fire") \
	and not grappling \
	and not grapple_flying \
	and (on_floor or air_grapple_available):

		if not on_floor:
			air_grapple_available = false

		grapple_mode = "up" if Input.is_action_pressed("ui_up") else "horizontal"
		_spawn_grapple()

	if not on_floor:
		if velocity.y < -50:
			velocity.y += GRAVITY * 0.85 * delta
		elif velocity.y < 60:
			velocity.y += GRAVITY * 0.42 * delta
		else:
			velocity.y += GRAVITY * 1.25 * delta

		velocity.y = min(velocity.y, MAX_FALL_SPEED)

	if Input.is_action_just_pressed("ui_accept") and on_floor:
		velocity.y = JUMP_VELOCITY
		jump_held = true
		anim_player.play("JumpUp")
		turning = false

	if Input.is_action_just_released("ui_accept") and velocity.y < 0:
		velocity.y = max(velocity.y, MIN_JUMP_VELOCITY)
		jump_held = false

	elif Input.is_action_pressed("ui_down") and on_floor:
		velocity.x = 0
		if not turning:
			anim_player.play("Crouch")

	elif not turning:
		var direction: float = Input.get_axis("ui_left", "ui_right")

		if direction != 0:
			if sign(direction) != facing_direction and on_floor and abs(velocity.x) > 0:
				velocity.x = 0
				turn_dir = int(sign(direction))
				sprite.flip_h = (turn_dir == 1)
				anim_player.play("Turn")
				turning = true
			else:
				if on_floor:
					velocity.x = move_toward(velocity.x, direction * SPEED, ACCEL * delta)
					anim_player.play("Run")
				else:
					velocity.x = move_toward(velocity.x, direction * SPEED, AIR_ACCEL * delta)

				facing_direction = int(sign(direction))
				sprite.flip_h = (facing_direction == -1)
				_update_grapple_spawn()
		else:
			velocity.x = move_toward(velocity.x, 0, ACCEL * delta)
			if on_floor and not turning:
				anim_player.play("Idle")

	if not on_floor:
		if velocity.y < 40:
			anim_player.play("JumpUp")
		else:
			anim_player.play("JumpDown")

	move_and_slide()


func _update_grapple_spawn() -> void:
	grapple_spawn.position.x = grapple_spawn_offset.x * facing_direction


func _spawn_grapple() -> void:
	current_grapple = grapple_scene.instantiate()
	get_parent().add_child(current_grapple)

	current_grapple.global_position = grapple_spawn.global_position + Vector2(facing_direction * 4, 0)

	current_grapple.player = self
	current_grapple.mode = grapple_mode
	current_grapple.direction = facing_direction
	current_grapple.setup_visuals()

	grapple_flying = true


func start_grapple_pull(point: Vector2, mode: String) -> void:
	grapple_point = point
	grapple_mode = mode
	grapple_flying = false
	grappling = true


func _stop_grapple() -> void:
	grapple_flying = false
	grappling = false


func _reset_player() -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	grapple_flying = false
	grappling = false
	grapple_point = Vector2.ZERO
	air_grapple_available = true
	turning = false
	turn_dir = 0
	jump_held = false
	anim_player.play("Idle")


func play_death_animation() -> void:
	velocity = Vector2.ZERO
	grapple_flying = false
	grappling = false
	grapple_point = Vector2.ZERO
	turning = false
	turn_dir = 0
	jump_held = false
	anim_player.play("Death")


func _on_anim_finished(anim_name: StringName) -> void:
	if turning and anim_name == "Turn":
		turning = false
		facing_direction = turn_dir
		_update_grapple_spawn()

		if Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right"):
			anim_player.play("Run")
		else:
			anim_player.play("Idle")
