extends Node2D

@export var bar: Polygon2D
@export var hud_height := 32.0


func _ready():
	var view_size = get_viewport().get_visible_rect().size

	position = Vector2(-view_size.x * 0.5, -view_size.y * 0.5)
	z_index = 1
	z_as_relative = false

	if bar != null:
		bar.polygon = PackedVector2Array([
			Vector2(0, 0),
			Vector2(view_size.x, 0),
			Vector2(view_size.x, hud_height),
			Vector2(0, hud_height)
		])
		bar.position = Vector2.ZERO
