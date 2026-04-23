extends Area2D

@export var death_transition: CanvasLayer


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.name != "Treasure Knight":
		return

	if death_transition != null and death_transition.has_method("pit_death"):
		death_transition.pit_death()
