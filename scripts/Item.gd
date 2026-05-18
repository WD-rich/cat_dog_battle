extends Node2D
class_name BattleItem

const UI_FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")

var kind := "boom"
var held_by: Node = null
var pickup_lock := 0.0
var throw_velocity := Vector2.ZERO
var thrown_by_team := ""
var projectile_time := 0.0
var spin := 0.0
var spawn_point := Vector2.ZERO

var _sprite: Sprite2D
var _label: Label

const ITEM_TEXTURES := {
	"boom": preload("res://assets/visuals/item_boom.svg"),
	"repair": preload("res://assets/visuals/item_repair.svg"),
	"speed": preload("res://assets/visuals/item_speed.svg"),
	"shield": preload("res://assets/visuals/item_shield.svg"),
	"sock": preload("res://assets/visuals/item_sock.svg"),
}


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = ITEM_TEXTURES.get(kind)
	_sprite.scale = Vector2(0.62, 0.62)
	_sprite.visible = false
	add_child(_sprite)

	_label = Label.new()
	_label.text = _display_name()
	_label.position = Vector2(-54, 34)
	_label.size = Vector2(108, 24)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_override("font", UI_FONT)
	_label.add_theme_font_size_override("font_size", 13)
	_label.add_theme_color_override("font_color", Color(0.18, 0.11, 0.08))
	_label.add_theme_color_override("font_outline_color", Color(1.0, 0.94, 0.72, 0.95))
	_label.add_theme_constant_override("outline_size", 4)
	add_child(_label)


func setup(item_kind: String, start_position: Vector2) -> void:
	kind = item_kind
	global_position = start_position
	spawn_point = start_position
	z_index = 20
	queue_redraw()


func is_carry_item() -> bool:
	return kind == "boom" or kind == "repair" or kind == "sock"


func can_pick_up() -> bool:
	return held_by == null and pickup_lock <= 0.0 and projectile_time <= 0.0


func pickup(pet: Node) -> bool:
	if not can_pick_up():
		return false
	if kind == "speed":
		pet.add_speed_boost(5.0)
		queue_free()
		return true
	if kind == "shield":
		pet.add_shield(4.0)
		queue_free()
		return true
	held_by = pet
	pet.carried_item = self
	throw_velocity = Vector2.ZERO
	projectile_time = 0.0
	pickup_lock = 0.15
	return true


func drop(drop_position: Vector2, lock_time := 0.65) -> void:
	if held_by != null and held_by.carried_item == self:
		held_by.carried_item = null
	held_by = null
	global_position = drop_position
	throw_velocity = Vector2.ZERO
	projectile_time = 0.0
	pickup_lock = lock_time


func throw_from(pet: Node, direction: Vector2) -> void:
	if direction.length() < 0.1:
		direction = Vector2.RIGHT if pet.team == "cat" else Vector2.LEFT
	if held_by != null and held_by.carried_item == self:
		held_by.carried_item = null
	thrown_by_team = pet.team
	held_by = null
	global_position = pet.global_position + direction.normalized() * 34.0
	throw_velocity = direction.normalized() * 760.0
	projectile_time = 1.0
	pickup_lock = 0.45


func kick(direction: Vector2, force := 560.0) -> void:
	if direction.length() < 0.1:
		return
	if held_by != null and held_by.carried_item == self:
		held_by.carried_item = null
	held_by = null
	throw_velocity = direction.normalized() * force
	projectile_time = 0.45
	pickup_lock = 0.45


func _process(delta: float) -> void:
	if held_by != null:
		global_position = held_by.global_position + Vector2(0, -40)
	else:
		global_position += throw_velocity * delta
		throw_velocity = throw_velocity.move_toward(Vector2.ZERO, 880.0 * delta)
		if projectile_time > 0.0:
			projectile_time = max(0.0, projectile_time - delta)
		if pickup_lock > 0.0:
			pickup_lock = max(0.0, pickup_lock - delta)
		spin += delta * 5.0
	if _sprite != null:
		var bob := sin(spin * 1.8) * 2.5
		_sprite.position = Vector2(0, bob)
		_sprite.rotation = sin(spin) * 0.08
	if _label != null:
		_label.visible = held_by == null
	queue_redraw()


func _draw() -> void:
	if kind == "boom":
		var pulse := 1.0 + sin(spin * 3.2) * 0.12
		draw_circle(Vector2(0, -1), 36.0 * pulse, Color(1.0, 0.72, 0.10, 0.24))
		draw_circle(Vector2(0, -1), 27.0 * pulse, Color(1.0, 0.42, 0.10, 0.22), false, 5.0)
		if held_by == null:
			draw_colored_polygon(PackedVector2Array([
				Vector2(0, -58),
				Vector2(-13, -38),
				Vector2(13, -38),
			]), Color(1.0, 0.36, 0.12, 0.86))
			draw_polyline(PackedVector2Array([Vector2(0, -58), Vector2(-13, -38), Vector2(13, -38), Vector2(0, -58)]), Color(0.22, 0.13, 0.08), 2.5)

	if _sprite != null and _sprite.texture != null:
		var bob := sin(spin * 1.8) * 2.5
		var size := Vector2(76, 76) if kind == "boom" else Vector2(60, 60)
		draw_texture_rect(_sprite.texture, Rect2(Vector2(-size.x / 2.0, -size.y / 2.0 - 1 + bob), size), false)
		return

	var shadow := Color(0, 0, 0, 0.16)
	draw_circle(Vector2(3, 12), 20, shadow)

	if kind == "boom":
		draw_circle(Vector2.ZERO, 22, Color(1.0, 0.54, 0.20))
		draw_circle(Vector2.ZERO, 22, Color(0.20, 0.12, 0.08), false, 3.0)
		draw_circle(Vector2(6, -5), 7, Color(1.0, 0.92, 0.30))
		draw_line(Vector2(14, -17), Vector2(24, -28), Color(0.20, 0.12, 0.08), 4.0)
		draw_circle(Vector2(27, -31), 5, Color(1.0, 0.16, 0.10))
	elif kind == "repair":
		_draw_filled_rect(Rect2(Vector2(-19, -21), Vector2(38, 42)), Color(0.35, 0.86, 0.58))
		draw_rect(Rect2(Vector2(-19, -21), Vector2(38, 42)), Color(0.16, 0.11, 0.08), false, 3.0)
		_draw_filled_rect(Rect2(Vector2(-5, -15), Vector2(10, 30)), Color.WHITE)
		_draw_filled_rect(Rect2(Vector2(-15, -5), Vector2(30, 10)), Color.WHITE)
	elif kind == "speed":
		draw_circle(Vector2.ZERO, 20, Color(1.0, 0.86, 0.21))
		draw_circle(Vector2.ZERO, 20, Color(0.16, 0.11, 0.08), false, 3.0)
		draw_arc(Vector2.ZERO, 10, 0.25, TAU - 0.25, 24, Color(0.16, 0.11, 0.08), 4.0)
		draw_line(Vector2(0, 7), Vector2(0, 24), Color(0.16, 0.11, 0.08), 4.0)
	elif kind == "shield":
		draw_polygon(
			PackedVector2Array([Vector2(0, -25), Vector2(22, -13), Vector2(16, 20), Vector2(0, 28), Vector2(-16, 20), Vector2(-22, -13)]),
			PackedColorArray([Color(0.44, 0.72, 1.0), Color(0.44, 0.72, 1.0), Color(0.44, 0.72, 1.0), Color(0.44, 0.72, 1.0), Color(0.44, 0.72, 1.0), Color(0.44, 0.72, 1.0)])
		)
		draw_polyline(PackedVector2Array([Vector2(0, -25), Vector2(22, -13), Vector2(16, 20), Vector2(0, 28), Vector2(-16, 20), Vector2(-22, -13), Vector2(0, -25)]), Color(0.16, 0.11, 0.08), 3.0)
	else:
		draw_circle(Vector2(-8, 0), 14, Color(0.65, 0.62, 0.58))
		draw_circle(Vector2(7, 3), 15, Color(0.74, 0.70, 0.66))
		draw_circle(Vector2(17, -2), 10, Color(0.58, 0.55, 0.50))
		draw_circle(Vector2(-2, 0), 3, Color(0.18, 0.12, 0.09))


func _draw_filled_rect(rect: Rect2, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		rect.position,
		rect.position + Vector2(rect.size.x, 0),
		rect.position + rect.size,
		rect.position + Vector2(0, rect.size.y),
	]), color)


func _display_name() -> String:
	if kind == "boom":
		return "罐头炸弹"
	if kind == "repair":
		return "胶带卷"
	if kind == "speed":
		return "铃铛"
	if kind == "shield":
		return "抱枕盾"
	if kind == "sock":
		return "臭袜子"
	return "道具"
