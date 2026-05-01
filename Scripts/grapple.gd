extends Area2D

const SPEED := 220.0
const MAX_DISTANCE := 120.0
const START_INVISIBLE_FRAMES := 18

var direction: int = 1
var mode: String = "horizontal"
var player: CharacterBody2D
var stopped: bool = false
var distance_traveled: float = 0.0
var can_show_visuals: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var chain: Line2D = $Chain


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

	sprite.visible = false
	chain.visible = false

	for i in START_INVISIBLE_FRAMES:
		await get_tree().physics_frame

	can_show_visuals = true
	sprite.visible = true


func setup_visuals() -> void:
	if mode == "horizontal":
		rotation_degrees = 0
		sprite.flip_h = (direction == -1)
	else:
		rotation_degrees = -90
		sprite.flip_h = false


func _physics_process(delta: float) -> void:
	if stopped:
		_update_chain()

		if player != null and not player.grappling:
			queue_free()

		return

	var movement: Vector2 = Vector2.ZERO
	if mode == "horizontal":
		movement.x = SPEED * direction * delta
	else:
		movement.y = -SPEED * delta

	global_position += movement
	distance_traveled += movement.length()

	_update_chain()

	if distance_traveled >= MAX_DISTANCE:
		_stop()


func _update_chain() -> void:
	if player == null or chain == null:
		return

	if not can_show_visuals:
		chain.visible = false
		return

	var start_pos: Vector2 = player.grapple_spawn.global_position
	var end_pos: Vector2 = global_position

	start_pos = to_local(start_pos)
	end_pos = to_local(end_pos)

	if start_pos.distance_to(end_pos) < 2.0:
		chain.visible = false
		return
	else:
		chain.visible = true

	chain.points = [start_pos, end_pos]


func _on_body_entered(body: Node) -> void:
	if stopped:
		return

	if body.has_method("take_damage"):
		body.take_damage(1, global_position)
		_stop_without_freeing()
		return

	_stop()


func _on_area_entered(area: Area2D) -> void:
	if stopped:
		return

	if area.has_method("take_damage"):
		area.take_damage(1, global_position)
		_stop_without_freeing()
		return

	if area.get_parent() != null and area.get_parent().has_method("take_damage"):
		area.get_parent().take_damage(1, global_position)
		_stop_without_freeing()
		return


func _stop_without_freeing() -> void:
	stopped = true

	if player != null:
		player.grapple_flying = false

	queue_free()


func _stop() -> void:
	stopped = true

	if Input.is_action_pressed("Fire"):
		player.start_grapple_pull(global_position, mode)
	else:
		player.grapple_flying = false
		queue_free()
