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

	print("Entered room:", room.name)

	var shape_node = room.get_node("CollisionShape2D")
	if shape_node == null:
		push_warning("Room '%s' missing CollisionShape2D" % room.name)
		return

	var shape = shape_node.shape
	if shape is RectangleShape2D:
		var extents = shape.extents
		var center = shape_node.global_position

		var left = center.x - extents.x
		var right = center.x + extents.x
		var top = center.y - extents.y
		var bottom = center.y + extents.y

		camera.set_camera_zone(left, right, top, bottom, true)
