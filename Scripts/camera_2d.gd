extends Camera2D

@export var player: Node2D
@export var transition_speed := 350.0

var left := 0.0
var right := 0.0
var top := 0.0
var bottom := 0.0

var transitioning := false
var target_position := Vector2.ZERO


func _process(delta):
	if player == null:
		return

	var view_size = get_viewport_rect().size
	var half_w = view_size.x * 0.5
	var half_h = view_size.y * 0.5

	if transitioning:
		var dir = target_position - global_position
		var move = dir.normalized() * transition_speed * delta

		if move.length() >= dir.length():
			global_position = target_position
			transitioning = false
			player.set_physics_process(true)
		else:
			global_position += move

		return

	var cam_x = player.global_position.x
	var room_width = right - left

	if room_width <= view_size.x:
		cam_x = (left + right) * 0.5
	else:
		cam_x = clamp(cam_x, left + half_w, right - half_w)

	var cam_y = bottom - half_h

	global_position = Vector2(cam_x, cam_y)


func set_camera_zone(l, r, t, b, do_transition):
	left = l
	right = r
	top = t
	bottom = b

	var view_size = get_viewport_rect().size
	var half_w = view_size.x * 0.5
	var half_h = view_size.y * 0.5

	var room_width = right - left
	var target_x: float

	if room_width <= view_size.x:
		target_x = (left + right) * 0.5
	else:
		target_x = clamp(player.global_position.x, left + half_w, right - half_w)

	var target_y = bottom - half_h
	var target = Vector2(target_x, target_y)

	if do_transition:
		target_position = target
		transitioning = true
		player.set_physics_process(false)
	else:
		global_position = target
		transitioning = false


func snap_to_player():
	if player == null:
		return

	var view_size = get_viewport_rect().size
	var half_w = view_size.x * 0.5
	var half_h = view_size.y * 0.5

	var cam_x = player.global_position.x
	var room_width = right - left

	if room_width <= view_size.x:
		cam_x = (left + right) * 0.5
	else:
		cam_x = clamp(cam_x, left + half_w, right - half_w)

	var cam_y = bottom - half_h

	global_position = Vector2(cam_x, cam_y)
	target_position = global_position
	transitioning = false
