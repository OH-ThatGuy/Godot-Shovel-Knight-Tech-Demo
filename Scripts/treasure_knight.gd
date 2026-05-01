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
@export var death_transition: CanvasLayer
@export var max_health := 5
@export var knockback_force := 190.0
@export var knockback_up_force := -120.0
@export var invincible_time := 1.0
@export var up_grapple_spawn_offset := Vector2(6, -10)

@onready var grapple_spawn := $GrappleSpawn
@onready var pivot_node := $PivotNode
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

var health: int = 5
var invincible: bool = false
var damaged: bool = false
var dying: bool = false
var firing: bool = false
var fired_from_ground: bool = false
var flash_tween: Tween = null


func _ready() -> void:
	spawn_position = global_position
	health = max_health
	anim_player.animation_finished.connect(_on_anim_finished)
	grapple_spawn_offset = grapple_spawn.position
	_apply_facing_direction()


func _physics_process(delta: float) -> void:
	on_floor = is_on_floor()

	if Input.is_action_just_pressed("Debug_Reset"):
		_reset_player()

	if firing and not grapple_flying and not grappling:
		firing = false
		fired_from_ground = false

	if damaged or dying:
		if not on_floor:
			if velocity.y < -50:
				velocity.y += GRAVITY * 0.85 * delta
			elif velocity.y < 60:
				velocity.y += GRAVITY * 0.42 * delta
			else:
				velocity.y += GRAVITY * 1.25 * delta

			velocity.y = min(velocity.y, MAX_FALL_SPEED)

		move_and_slide()
		return

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

		firing = true
		fired_from_ground = on_floor

		if grapple_mode == "up":
			if fired_from_ground:
				anim_player.play("FireUpGround")
			else:
				anim_player.play("FireUpAir")
		else:
			if fired_from_ground:
				anim_player.play("FireGround")
			else:
				anim_player.play("FireAir")

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
		if not firing:
			anim_player.play("JumpUp")
		turning = false

	if Input.is_action_just_released("ui_accept") and velocity.y < 0:
		velocity.y = max(velocity.y, MIN_JUMP_VELOCITY)
		jump_held = false

	elif Input.is_action_pressed("ui_down") and on_floor:
		velocity.x = 0
		if not turning and not firing:
			anim_player.play("Crouch")

	elif not turning:
		var direction: float = Input.get_axis("ui_left", "ui_right")

		if direction != 0:
			if sign(direction) != facing_direction and on_floor and abs(velocity.x) > 0:
				velocity.x = 0
				turn_dir = int(sign(direction))
				if not firing:
					anim_player.play("Turn")
				turning = true
			else:
				if on_floor:
					velocity.x = move_toward(velocity.x, direction * SPEED, ACCEL * delta)
					if not firing:
						anim_player.play("Run")
				else:
					velocity.x = move_toward(velocity.x, direction * SPEED, AIR_ACCEL * delta)

				facing_direction = int(sign(direction))
				_apply_facing_direction()
				_update_grapple_spawn()
		else:
			velocity.x = move_toward(velocity.x, 0, ACCEL * delta)
			if on_floor and not turning and not firing:
				anim_player.play("Idle")

	if not on_floor and not firing:
		if velocity.y < 40:
			anim_player.play("JumpUp")
		else:
			anim_player.play("JumpDown")

	move_and_slide()


func take_damage(source_position: Vector2) -> void:
	if invincible or dying:
		return

	health -= 1
	invincible = true
	damaged = true
	firing = false
	fired_from_ground = false
	grapple_flying = false
	grappling = false
	grapple_point = Vector2.ZERO

	if current_grapple != null:
		current_grapple.queue_free()
		current_grapple = null

	var dir: float = sign(global_position.x - source_position.x)
	if dir == 0:
		dir = -facing_direction

	velocity.x = dir * knockback_force
	velocity.y = knockback_up_force

	anim_player.play("Damage")
	_start_iframe_flash()

	await get_tree().create_timer(0.24).timeout
	velocity.x = 0

	await get_tree().create_timer(0.26).timeout
	damaged = false

	if health <= 0:
		dying = true
		_stop_iframe_flash()

		while not is_on_floor():
			await get_tree().physics_frame

		if death_transition != null and death_transition.has_method("spike_death"):
			death_transition.spike_death()
		return

	await get_tree().create_timer(invincible_time).timeout
	_stop_iframe_flash()
	invincible = false


func play_death_animation() -> void:
	velocity = Vector2.ZERO
	grapple_flying = false
	grappling = false
	grapple_point = Vector2.ZERO
	turning = false
	turn_dir = 0
	jump_held = false
	firing = false
	fired_from_ground = false
	anim_player.play("Death")


func _start_iframe_flash() -> void:
	if flash_tween != null:
		flash_tween.kill()

	flash_tween = create_tween()
	flash_tween.set_loops()
	flash_tween.tween_property(sprite, "modulate", Color(1.35, 1.35, 1.35, 1), 0.12)
	flash_tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.12)


func _stop_iframe_flash() -> void:
	if flash_tween != null:
		flash_tween.kill()
		flash_tween = null

	sprite.modulate = Color(1, 1, 1, 1)


func _apply_facing_direction() -> void:
	pivot_node.scale.x = facing_direction


func _update_grapple_spawn() -> void:
	grapple_spawn.position.x = grapple_spawn_offset.x * facing_direction


func _spawn_grapple() -> void:
	current_grapple = grapple_scene.instantiate()
	get_parent().add_child(current_grapple)

	if grapple_mode == "up":
		current_grapple.global_position = grapple_spawn.global_position + Vector2(facing_direction * up_grapple_spawn_offset.x, up_grapple_spawn_offset.y)
	else:
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

	if mode == "horizontal":
		firing = true
		if fired_from_ground:
			anim_player.play("FireAir")
	else:
		firing = true
		if fired_from_ground:
			anim_player.play("FireUpAir")


func _stop_grapple() -> void:
	grapple_flying = false
	grappling = false
	firing = false
	fired_from_ground = false


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
	health = max_health
	invincible = false
	damaged = false
	dying = false
	firing = false
	fired_from_ground = false
	facing_direction = 1
	_apply_facing_direction()
	_stop_iframe_flash()
	anim_player.play("Idle")


func _on_anim_finished(anim_name: StringName) -> void:
	if anim_name == "FireGround" or anim_name == "FireAir" or anim_name == "FireUpGround" or anim_name == "FireUpAir":
		if not grapple_flying and not grappling:
			firing = false
			fired_from_ground = false

	if turning and anim_name == "Turn":
		turning = false
		facing_direction = turn_dir
		_apply_facing_direction()
		_update_grapple_spawn()

		if Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right"):
			anim_player.play("Run")
		else:
			anim_player.play("Idle")
