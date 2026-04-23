extends Node2D

@export var player: Node2D

var current_checkpoint: Area2D = null
var highest_order_reached := -1


func _ready() -> void:
	for checkpoint in get_children():
		if checkpoint.has_method("set_checkpoint_state"):
			checkpoint.set_checkpoint_state(checkpoint.was_activated, false)


func try_activate_checkpoint(checkpoint: Area2D) -> void:
	if player == null:
		return

	if checkpoint.was_activated and checkpoint.order < highest_order_reached:
		return

	if current_checkpoint == checkpoint:
		return

	checkpoint.was_activated = true
	highest_order_reached = max(highest_order_reached, checkpoint.order)
	current_checkpoint = checkpoint
	player.spawn_position = checkpoint.get_node("Marker2D").global_position

	for other in get_children():
		if other.has_method("set_checkpoint_state"):
			other.set_checkpoint_state(other.was_activated, other == current_checkpoint)
