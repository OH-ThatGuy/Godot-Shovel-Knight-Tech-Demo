extends Area2D

const SPEED := 220.0
const MAX_DISTANCE := 120.0

var direction: int = 1
var mode: String = "horizontal"
var player: CharacterBody2D
var stopped: bool = false
var distance_traveled: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var chain: Line2D = $Chain


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func setup_visuals() -> void:
	if mode == "horizontal":
		rotation_degrees = 0
		sprite.flip_h = (direction == -1)
	else:
		rotation_degrees = -90
		sprite.flip_h = false


func _physics_process(delta: float) -> void:
	if stopped:
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


func _on_body_entered(_body: Node) -> void:
	if stopped:
		return
	_stop()


func _stop() -> void:
	stopped = true

	if Input.is_action_pressed("Fire"):
		player.start_grapple_pull(global_position, mode)
	else:
		player.grapple_flying = false

	queue_free()
