extends Node2D
class_name BattleBase

signal durability_changed(base: BattleBase)
signal destroyed(base: BattleBase)

var team := "cat"
var durability := 5
var max_durability := 5
var radius := 76.0
var body_color := Color.WHITE
var roof_color := Color.WHITE

var _sprite: Sprite2D

const BASE_TEXTURES := {
	"cat": preload("res://assets/visuals/base_cat.svg"),
	"dog": preload("res://assets/visuals/base_dog.svg"),
}


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = BASE_TEXTURES.get(team)
	_sprite.scale = Vector2(0.95, 0.95)
	_sprite.position = Vector2(0, 2)
	_sprite.visible = false
	add_child(_sprite)


func setup(base_team: String, start_position: Vector2) -> void:
	team = base_team
	global_position = start_position
	if team == "cat":
		body_color = Color(1.0, 0.71, 0.42)
		roof_color = Color(0.93, 0.31, 0.18)
	else:
		body_color = Color(0.55, 0.78, 1.0)
		roof_color = Color(0.18, 0.42, 0.85)
	queue_redraw()


func damage(amount: int) -> void:
	if durability <= 0:
		return
	durability = max(0, durability - amount)
	durability_changed.emit(self)
	queue_redraw()
	if durability <= 0:
		destroyed.emit(self)


func repair(amount: int) -> bool:
	if durability >= max_durability:
		return false
	durability = min(max_durability, durability + amount)
	durability_changed.emit(self)
	queue_redraw()
	return true


func contains_point(point: Vector2) -> bool:
	return global_position.distance_to(point) <= radius


func _draw() -> void:
	if _sprite != null and _sprite.texture != null:
		draw_texture_rect(_sprite.texture, Rect2(Vector2(-84, -90), Vector2(168, 168)), false)
	else:
		draw_circle(Vector2(4, 14), 72, Color(0, 0, 0, 0.15))
		var body_rect := Rect2(Vector2(-58, -20), Vector2(116, 82))
		_draw_filled_rect(body_rect, body_color)
		draw_rect(body_rect, Color(0.18, 0.12, 0.09), false, 4.0)

		if team == "cat":
			draw_polygon(
				PackedVector2Array([Vector2(-68, -16), Vector2(0, -78), Vector2(68, -16)]),
				PackedColorArray([roof_color, roof_color, roof_color])
			)
			draw_polyline(PackedVector2Array([Vector2(-68, -16), Vector2(0, -78), Vector2(68, -16), Vector2(-68, -16)]), Color(0.18, 0.12, 0.09), 4.0)
			draw_polygon(PackedVector2Array([Vector2(-52, -44), Vector2(-38, -84), Vector2(-20, -48)]), PackedColorArray([roof_color, roof_color, roof_color]))
			draw_polygon(PackedVector2Array([Vector2(52, -44), Vector2(38, -84), Vector2(20, -48)]), PackedColorArray([roof_color, roof_color, roof_color]))
		else:
			draw_polygon(
				PackedVector2Array([Vector2(-70, -18), Vector2(-34, -70), Vector2(34, -70), Vector2(70, -18)]),
				PackedColorArray([roof_color, roof_color, roof_color, roof_color])
			)
			draw_polyline(PackedVector2Array([Vector2(-70, -18), Vector2(-34, -70), Vector2(34, -70), Vector2(70, -18)]), Color(0.18, 0.12, 0.09), 4.0)

		_draw_filled_rect(Rect2(Vector2(-20, 14), Vector2(40, 48)), Color(0.24, 0.15, 0.10))
		draw_circle(Vector2(-25, -2), 5, Color(0.18, 0.12, 0.09))
		draw_circle(Vector2(25, -2), 5, Color(0.18, 0.12, 0.09))

	_draw_damage_marks()

	for i in range(max_durability):
		var x := -50 + i * 25
		var pip_color := Color(0.23, 0.86, 0.36) if i < durability else Color(0.55, 0.46, 0.42, 0.35)
		draw_circle(Vector2(x, 84), 9, pip_color)
		draw_circle(Vector2(x, 84), 9, Color(0.18, 0.12, 0.09), false, 2.0)


func _draw_damage_marks() -> void:
	var lost := max_durability - durability
	if lost <= 0:
		return
	var crack := Color(0.20, 0.12, 0.08, 0.85)
	draw_polyline(PackedVector2Array([Vector2(-30, -34), Vector2(-16, -18), Vector2(-26, -2), Vector2(-8, 12)]), crack, 4.0)
	if lost >= 2:
		draw_polyline(PackedVector2Array([Vector2(34, -26), Vector2(18, -10), Vector2(30, 8), Vector2(12, 24)]), crack, 4.0)
		draw_circle(Vector2(-58, 44), 7, Color(0.45, 0.31, 0.22, 0.75))
	if lost >= 3:
		draw_polyline(PackedVector2Array([Vector2(-4, -60), Vector2(8, -42), Vector2(-2, -24), Vector2(16, -6)]), crack, 4.0)
		draw_circle(Vector2(56, 54), 8, Color(0.45, 0.31, 0.22, 0.75))
	if lost >= 4:
		draw_circle(Vector2(-18, 60), 9, Color(0.54, 0.36, 0.22, 0.82))
		draw_line(Vector2(-52, -76), Vector2(-20, -52), Color(0.22, 0.13, 0.08, 0.75), 5.0)


func _draw_filled_rect(rect: Rect2, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		rect.position,
		rect.position + Vector2(rect.size.x, 0),
		rect.position + rect.size,
		rect.position + Vector2(0, rect.size.y),
	]), color)
