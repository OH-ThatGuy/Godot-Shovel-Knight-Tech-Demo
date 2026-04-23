extends CanvasLayer

@export var player: Node2D
@export var black_screen: ColorRect
@export var camera: Camera2D
@export var rooms: Node2D
@export var scroll_speed := 900.0
@export var linger_time := 1.0
@export var death_anim_time := 0.5

var busy := false

func _ready():
	if black_screen == null:
		return

	var view_size = get_viewport().get_visible_rect().size
	black_screen.position = Vector2(view_size.x, 0)

func pit_death():
	if busy:
		return

	if player == null or black_screen == null:
		return

	busy = true

	var view_size = get_viewport().get_visible_rect().size

	player.set_physics_process(false)

	var tween_in = create_tween()
	tween_in.tween_property(black_screen, "position", Vector2(0, 0), view_size.x / scroll_speed)
	await tween_in.finished

	await get_tree().create_timer(linger_time).timeout

	if player.has_method("_reset_player"):
		player._reset_player()

	if rooms != null and rooms.has_method("update_room_for_player"):
		rooms.update_room_for_player()

	if camera != null and camera.has_method("snap_to_player"):
		camera.snap_to_player()

	var tween_out = create_tween()
	tween_out.tween_property(black_screen, "position", Vector2(-view_size.x, 0), view_size.x / scroll_speed)
	await tween_out.finished

	black_screen.position = Vector2(view_size.x, 0)

	player.set_physics_process(true)

	busy = false

func spike_death():
	if busy:
		return

	if player == null or black_screen == null:
		return

	busy = true

	player.set_physics_process(false)

	if player.has_method("play_death_animation"):
		player.play_death_animation()

	await get_tree().create_timer(death_anim_time).timeout

	var view_size = get_viewport().get_visible_rect().size

	var tween_in = create_tween()
	tween_in.tween_property(black_screen, "position", Vector2(0, 0), view_size.x / scroll_speed)
	await tween_in.finished

	await get_tree().create_timer(linger_time).timeout

	if player.has_method("_reset_player"):
		player._reset_player()

	if rooms != null and rooms.has_method("update_room_for_player"):
		rooms.update_room_for_player()

	if camera != null and camera.has_method("snap_to_player"):
		camera.snap_to_player()

	var tween_out = create_tween()
	tween_out.tween_property(black_screen, "position", Vector2(-view_size.x, 0), view_size.x / scroll_speed)
	await tween_out.finished

	black_screen.position = Vector2(view_size.x, 0)

	player.set_physics_process(true)

	busy = false
