extends Node2D

@export var player: Node2D
@export var camera: Camera2D


func _ready():
	for room in get_children():
		if room is Area2D:
			room.body_entered.connect(func(body):
				_on_room_entered(body, room)
			)


func _on_room_entered(body, room):
	if body != player:
		return

	_apply_room(room, true)


func update_room_for_player():
	for room in get_children():
		if room is Area2D and _room_contains_point(room, player.global_position):
			_apply_room(room, false)
			return


func _apply_room(room, do_transition):
	var shape_node = room.get_node("CollisionShape2D")
	if shape_node == null:
		return

	var shape = shape_node.shape
	if shape is RectangleShape2D:
		var extents = shape.extents
		var center = shape_node.global_position

		var left = center.x - extents.x
		var right = center.x + extents.x
		var top = center.y - extents.y
		var bottom = center.y + extents.y

		camera.set_camera_zone(left, right, top, bottom, do_transition)


func _room_contains_point(room, point: Vector2) -> bool:
	var shape_node = room.get_node("CollisionShape2D")
	if shape_node == null:
		return false

	var shape = shape_node.shape
	if shape is RectangleShape2D:
		var extents = shape.extents
		var center = shape_node.global_position

		var left = center.x - extents.x
		var right = center.x + extents.x
		var top = center.y - extents.y
		var bottom = center.y + extents.y

		return point.x >= left and point.x <= right and point.y >= top and point.y <= bottom

	return false
