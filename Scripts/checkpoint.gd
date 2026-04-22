extends Area2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var respawn_marker: Marker2D = $Marker2D

@export var inactive_frame: int = 0
@export var active_frame: int = 1

var active: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	add_to_group("checkpoints")
	_update_visual()


func _on_body_entered(body: Node) -> void:
	if body.name != "Treasure Knight":
		return

	if active:
		return

	_activate_checkpoint(body)


func _activate_checkpoint(player: Node) -> void:
	for checkpoint in get_tree().get_nodes_in_group("checkpoints"):
		if checkpoint != self and checkpoint.has_method("set_active"):
			checkpoint.set_active(false)

	set_active(true)

	if "spawn_position" in player:
		player.spawn_position = respawn_marker.global_position


func set_active(value: bool) -> void:
	active = value
	_update_visual()


func _update_visual() -> void:
	if sprite == null:
		return

	sprite.modulate = Color(1, 1, 1, 1) if active else Color(0.6, 0.6, 0.6, 1)

	sprite.frame = active_frame if active else inactive_frame
