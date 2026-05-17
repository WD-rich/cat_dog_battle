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
	draw_circle(Vector2(4, 14), 72, Color(0, 0, 0, 0.15))
	var body_rect := Rect2(Vector2(-58, -20), Vector2(116, 82))
	draw_rect(body_rect, body_color, true, 0.0)
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

	draw_rect(Rect2(Vector2(-20, 14), Vector2(40, 48)), Color(0.24, 0.15, 0.10), true, 0.0)
	draw_circle(Vector2(-25, -2), 5, Color(0.18, 0.12, 0.09))
	draw_circle(Vector2(25, -2), 5, Color(0.18, 0.12, 0.09))

	for i in range(max_durability):
		var x := -50 + i * 25
		var pip_color := Color(0.23, 0.86, 0.36) if i < durability else Color(0.55, 0.46, 0.42, 0.35)
		draw_circle(Vector2(x, 84), 9, pip_color)
		draw_circle(Vector2(x, 84), 9, Color(0.18, 0.12, 0.09), false, 2.0)

