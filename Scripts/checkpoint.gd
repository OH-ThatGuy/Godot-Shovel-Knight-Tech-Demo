extends Area2D

@export var order := 0
@export var manager: Node
@export var orb: Sprite2D

var was_activated := false
var is_current := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	add_to_group("checkpoints")
	_update_visual()


func _on_body_entered(body: Node) -> void:
	if body.name != "Treasure Knight":
		return

	if manager != null and manager.has_method("try_activate_checkpoint"):
		manager.try_activate_checkpoint(self)


func set_checkpoint_state(activated: bool, current: bool) -> void:
	was_activated = activated
	is_current = current
	_update_visual()


func _update_visual() -> void:
	if orb == null:
		return

	if is_current:
		orb.modulate = Color(1, 1, 1, 1)
	elif was_activated:
		orb.modulate = Color(0.75, 0.75, 0.75, 1)
	else:
		orb.modulate = Color(0.35, 0.35, 0.35, 1)
