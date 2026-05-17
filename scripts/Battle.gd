extends Node2D

const PetScript := preload("res://scripts/Pet.gd")
const BaseScript := preload("res://scripts/Base.gd")
const ItemScript := preload("res://scripts/Item.gd")
const GameDataScript := preload("res://scripts/GameData.gd")
const ARENA_TEXTURE := preload("res://assets/visuals/arena_living_room.svg")

const MAP_RECT := Rect2(18, 64, 1244, 606)
const CAT_BASE_POS := Vector2(112, 360)
const DOG_BASE_POS := Vector2(1168, 360)

var pets: Array = []
var items: Array = []
var bases := {}
var obstacle_rects: Array[Rect2] = []
var aux_spawn_points := [
	Vector2(640, 165),
	Vector2(640, 555),
	Vector2(330, 205),
	Vector2(950, 205),
	Vector2(330, 515),
	Vector2(950, 515),
	Vector2(455, 360),
	Vector2(825, 360),
]

var player_pet: Node = null
var player_team := "cat"
var enemy_team := "dog"
var match_over := false
var match_time_limit := 180.0
var match_time_left := 180.0
var boom_respawn_timer := 0.0
var aux_spawn_timer := 4.0
var elapsed := 0.0
var last_event := ""
var event_timer := 0.0
var rng := RandomNumberGenerator.new()

var hud_layer: CanvasLayer
var score_label: Label
var status_label: Label
var cooldown_label: Label
var objective_label: Label
var event_label: Label
var touch_controls: Control
var result_panel: Panel
var result_label: Label

var touch_up_held := false
var touch_down_held := false
var touch_left_held := false
var touch_right_held := false
var touch_attack_held := false
var touch_skill_held := false
var touch_drop_requested := false
var touch_move := Vector2.ZERO


func _ready() -> void:
	rng.randomize()
	player_team = GameState.player_team
	enemy_team = "dog" if player_team == "cat" else "cat"
	match_time_left = match_time_limit
	_create_map()
	_create_bases()
	_create_pets()
	_create_hud()
	_spawn_item("boom", Vector2(640, 360))
	_spawn_item("repair", Vector2(455, 360))
	_spawn_item("shield", Vector2(640, 555))
	_spawn_item("speed", Vector2(640, 165))
	_spawn_item("sock", Vector2(825, 360))
	_show_event("Grab the Boom Snack and invade the enemy base.")
	update_hud()


func _physics_process(delta: float) -> void:
	if match_over:
		if Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_SPACE):
			get_tree().change_scene_to_file("res://scenes/Main.tscn")
		return

	elapsed += delta
	match_time_left = max(0.0, match_time_left - delta)
	if event_timer > 0.0:
		event_timer = max(0.0, event_timer - delta)
	if match_time_left <= 0.0:
		_finish_by_time()
		return
	_handle_player_input()
	for pet in pets:
		if pet != player_pet:
			_drive_ai(pet, delta)

	_process_dash_hits()
	_process_sock_hits()
	_process_item_pickups()
	_process_deliveries()
	_process_item_bounds()
	_tick_spawners(delta)
	update_hud()


func _draw() -> void:
	if ARENA_TEXTURE != null:
		draw_texture_rect(ARENA_TEXTURE, Rect2(Vector2.ZERO, Vector2(1280, 720)), false)
		draw_rect(MAP_RECT, Color(0.26, 0.17, 0.11, 0.35), false, 5.0)
	else:
		_draw_filled_rect(Rect2(Vector2.ZERO, Vector2(1280, 720)), Color(0.99, 0.93, 0.78))
		_draw_filled_rect(MAP_RECT, Color(0.94, 0.84, 0.65))
		draw_rect(MAP_RECT, Color(0.26, 0.17, 0.11), false, 5.0)
		_draw_filled_rect(Rect2(Vector2(438, 242), Vector2(404, 236)), Color(0.86, 0.58, 0.45, 0.46))
		draw_rect(Rect2(Vector2(438, 242), Vector2(404, 236)), Color(0.51, 0.30, 0.22), false, 3.0)
		draw_circle(Vector2(640, 360), 56, Color(1.0, 0.82, 0.32, 0.22))
		draw_circle(Vector2(640, 360), 56, Color(0.63, 0.43, 0.14, 0.55), false, 3.0)

		for rect in obstacle_rects:
			_draw_filled_rect(rect, Color(0.64, 0.40, 0.28))
			draw_rect(rect, Color(0.24, 0.14, 0.09), false, 4.0)
			draw_line(rect.position + Vector2(8, 8), rect.position + rect.size - Vector2(8, 8), Color(0.78, 0.55, 0.38), 2.0)


func _create_map() -> void:
	obstacle_rects = [
		Rect2(Vector2(286, 112), Vector2(168, 76)),
		Rect2(Vector2(826, 112), Vector2(168, 76)),
		Rect2(Vector2(286, 504), Vector2(176, 82)),
		Rect2(Vector2(818, 504), Vector2(176, 82)),
		Rect2(Vector2(502, 92), Vector2(276, 58)),
		Rect2(Vector2(505, 578), Vector2(270, 56)),
	]

	for rect in obstacle_rects:
		var body := StaticBody2D.new()
		body.position = rect.position + rect.size * 0.5
		var shape_node := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = rect.size
		shape_node.shape = shape
		body.add_child(shape_node)
		add_child(body)
	queue_redraw()


func _create_bases() -> void:
	var cat_base := BaseScript.new()
	cat_base.setup("cat", CAT_BASE_POS)
	cat_base.destroyed.connect(_on_base_destroyed)
	add_child(cat_base)
	bases["cat"] = cat_base

	var dog_base := BaseScript.new()
	dog_base.setup("dog", DOG_BASE_POS)
	dog_base.destroyed.connect(_on_base_destroyed)
	add_child(dog_base)
	bases["dog"] = dog_base


func _create_pets() -> void:
	var cat_keys := _team_lineup("cat")
	var dog_keys := _team_lineup("dog")
	_create_team("cat", cat_keys, CAT_BASE_POS + Vector2(145, 0))
	_create_team("dog", dog_keys, DOG_BASE_POS + Vector2(-145, 0))


func _team_lineup(team: String) -> Array:
	var keys := GameDataScript.team_pet_keys(team)
	if team == player_team:
		var selected := GameState.get_selected_pet(team)
		if keys.has(selected):
			keys.erase(selected)
			keys.insert(0, selected)
	return keys


func _create_team(team: String, keys: Array, center: Vector2) -> void:
	var roles := ["striker", "escort", "defender"]
	var offsets := [Vector2.ZERO, Vector2(74, -112), Vector2(74, 112)] if team == "cat" else [Vector2.ZERO, Vector2(-74, -112), Vector2(-74, 112)]
	for i in range(keys.size()):
		var pet := PetScript.new()
		var controlled := team == player_team and i == 0
		pet.setup(GameDataScript.pet_data(keys[i]), team, controlled, roles[i], self)
		if controlled:
			pet.apply_level(GameState.get_pet_level(keys[i]))
		pet.home_base = bases[team]
		pet.target_base = bases[_other_team(team)]
		pet.global_position = center + offsets[i]
		add_child(pet)
		pets.append(pet)
		if controlled:
			player_pet = pet


func _create_hud() -> void:
	hud_layer = CanvasLayer.new()
	add_child(hud_layer)

	score_label = Label.new()
	score_label.position = Vector2(424, 14)
	score_label.size = Vector2(432, 34)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 24)
	score_label.add_theme_color_override("font_color", Color(0.15, 0.09, 0.06))
	hud_layer.add_child(score_label)

	status_label = Label.new()
	status_label.position = Vector2(24, 674)
	status_label.size = Vector2(1230, 32)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 16)
	status_label.add_theme_color_override("font_color", Color(0.21, 0.14, 0.10))
	hud_layer.add_child(status_label)

	cooldown_label = Label.new()
	cooldown_label.position = Vector2(20, 18)
	cooldown_label.size = Vector2(390, 28)
	cooldown_label.add_theme_font_size_override("font_size", 16)
	cooldown_label.add_theme_color_override("font_color", Color(0.20, 0.13, 0.09))
	hud_layer.add_child(cooldown_label)

	objective_label = Label.new()
	objective_label.position = Vector2(390, 43)
	objective_label.size = Vector2(500, 30)
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.add_theme_font_size_override("font_size", 14)
	objective_label.add_theme_color_override("font_color", Color(0.20, 0.13, 0.09))
	hud_layer.add_child(objective_label)

	event_label = Label.new()
	event_label.position = Vector2(390, 88)
	event_label.size = Vector2(500, 42)
	event_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	event_label.add_theme_font_size_override("font_size", 20)
	event_label.add_theme_color_override("font_color", Color(0.80, 0.18, 0.10))
	hud_layer.add_child(event_label)

	_create_touch_controls()

	result_panel = Panel.new()
	result_panel.visible = false
	result_panel.position = Vector2(430, 250)
	result_panel.size = Vector2(420, 190)
	hud_layer.add_child(result_panel)

	result_label = Label.new()
	result_label.position = Vector2(20, 24)
	result_label.size = Vector2(380, 142)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", 24)
	result_panel.add_child(result_label)


func _handle_player_input() -> void:
	if player_pet == null or player_pet.defeated:
		return
	var dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		dir.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dir.x += 1.0
	dir += touch_move
	player_pet.desired_move = dir

	var mouse_dir = get_global_mouse_position() - player_pet.global_position
	if mouse_dir.length() > 8.0:
		player_pet.aim_direction = mouse_dir.normalized()
	elif dir.length() > 0.1:
		player_pet.aim_direction = dir.normalized()

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_key_pressed(KEY_J) or touch_attack_held:
		player_pet.try_attack()
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or Input.is_key_pressed(KEY_K) or touch_skill_held:
		player_pet.try_skill()
	if Input.is_key_pressed(KEY_E) or touch_drop_requested:
		player_pet.drop_or_throw_carried()
		touch_drop_requested = false


func _drive_ai(pet: Node, delta: float) -> void:
	if pet.defeated:
		return
	pet.ai_think_timer -= delta
	if pet.ai_think_timer <= 0.0:
		pet.ai_think_timer = rng.randf_range(0.12, 0.28)
		pet.ai_target_position = _choose_ai_target(pet)

	var to_target = pet.ai_target_position - pet.global_position
	pet.desired_move = to_target.normalized() if to_target.length() > 20.0 else Vector2.ZERO
	if pet.desired_move.length() > 0.1:
		pet.aim_direction = pet.desired_move

	var enemy := _nearest_enemy_pet(pet.global_position, pet.team, 210.0)
	if enemy != null:
		pet.aim_direction = (enemy.global_position - pet.global_position).normalized()
		if pet.global_position.distance_to(enemy.global_position) <= pet.attack_range:
			pet.try_attack()
		if pet.skill_timer <= 0.0 and _should_ai_skill(pet, enemy):
			pet.try_skill()

	if pet.carried_item != null and pet.carried_item.kind == "sock" and enemy != null and pet.global_position.distance_to(enemy.global_position) < 280.0:
		pet.aim_direction = (enemy.global_position - pet.global_position).normalized()
		pet.drop_or_throw_carried()


func _choose_ai_target(pet: Node) -> Vector2:
	if pet.carried_item != null:
		if pet.carried_item.kind == "boom":
			return bases[_other_team(pet.team)].global_position
		if pet.carried_item.kind == "repair":
			return bases[pet.team].global_position
		if pet.carried_item.kind == "sock":
			var carrier := _find_enemy_carrier(pet.team)
			if carrier != null:
				return carrier.global_position

	var enemy_carrier := _find_enemy_carrier(pet.team)
	if enemy_carrier != null:
		var danger_distance = enemy_carrier.global_position.distance_to(bases[pet.team].global_position)
		if pet.role == "defender" or danger_distance < 470.0:
			return enemy_carrier.global_position

	var allied_carrier := _find_allied_carrier(pet.team)
	if allied_carrier != null and pet.role == "escort":
		return allied_carrier.global_position + (allied_carrier.target_base.global_position - allied_carrier.global_position).normalized() * 45.0

	if pet.role == "defender":
		var repair := _closest_free_item(bases[pet.team].global_position, ["repair"])
		if bases[pet.team].durability <= 3 and repair != null:
			return repair.global_position
		return bases[pet.team].global_position + Vector2(115, 0) * (1 if pet.team == "cat" else -1)

	var boom := _closest_free_item(pet.global_position, ["boom"])
	if boom != null:
		return boom.global_position

	var useful := _closest_free_item(pet.global_position, ["shield", "speed", "sock", "repair"])
	if useful != null:
		return useful.global_position

	var nearest_enemy := _nearest_enemy_pet(pet.global_position, pet.team, 9999.0)
	if nearest_enemy != null:
		return nearest_enemy.global_position
	return Vector2(640, 360)


func _should_ai_skill(pet: Node, enemy: Node) -> bool:
	if pet.skill_type == "shield":
		return pet.carried_item != null or pet.global_position.distance_to(enemy.global_position) < 75.0
	if pet.skill_type == "pulse":
		return pet.global_position.distance_to(enemy.global_position) < 110.0
	if pet.skill_type == "sprint":
		return pet.carried_item != null or pet.global_position.distance_to(enemy.global_position) > 120.0
	return pet.global_position.distance_to(enemy.global_position) > 55.0


func pet_attack(attacker: Node) -> bool:
	var target := _nearest_enemy_pet(attacker.global_position, attacker.team, attacker.attack_range)
	if target != null:
		var dir = (target.global_position - attacker.global_position).normalized()
		target.take_damage(attacker.attack_damage, dir * 330.0, attacker)
		return true

	var item := _nearest_free_item(attacker.global_position, attacker.attack_range + 8.0)
	if item != null:
		var dir = attacker.aim_direction.normalized()
		if dir.length() < 0.1:
			dir = (item.global_position - attacker.global_position).normalized()
		item.kick(dir, 610.0)
		return true
	return false


func area_burst(source: Node, radius: float, damage: float, knock_force: float) -> void:
	for target in pets:
		if target.team == source.team or target.defeated:
			continue
		var distance = source.global_position.distance_to(target.global_position)
		if distance <= radius:
			var dir = (target.global_position - source.global_position).normalized()
			target.take_damage(damage, dir * knock_force, source)
	for item in items:
		if item.held_by == null and source.global_position.distance_to(item.global_position) <= radius:
			item.kick((item.global_position - source.global_position).normalized(), knock_force + 180.0)


func _process_dash_hits() -> void:
	for pet in pets:
		if pet.defeated or pet.dash_timer <= 0.0:
			continue
		for target in pets:
			if target.team == pet.team or target.defeated or pet.dash_hit_targets.has(target):
				continue
			if pet.global_position.distance_to(target.global_position) <= 52.0:
				pet.dash_hit_targets.append(target)
				var dir = (target.global_position - pet.global_position).normalized()
				target.take_damage(20.0, dir * 520.0, pet)
		for item in items:
			if item.held_by == null and pet.global_position.distance_to(item.global_position) <= 50.0:
				item.kick(pet.aim_direction, 780.0)


func _process_sock_hits() -> void:
	for item in items.duplicate():
		if item.kind != "sock" or item.projectile_time <= 0.0:
			continue
		for pet in pets:
			if pet.team == item.thrown_by_team or pet.defeated:
				continue
			if pet.global_position.distance_to(item.global_position) <= 34.0:
				var dir = (pet.global_position - item.global_position).normalized()
				pet.take_damage(5.0, dir * 260.0, null)
				pet.add_slow(2.2)
				_consume_item(item)
				break


func _process_item_pickups() -> void:
	for pet in pets:
		if pet.defeated or pet.carried_item != null:
			continue
		var closest := _nearest_free_item(pet.global_position, 36.0)
		if closest != null and closest.can_pick_up():
			var was_carry_item = closest.is_carry_item()
			closest.pickup(pet)
			if not was_carry_item:
				items.erase(closest)


func _process_deliveries() -> void:
	for pet in pets:
		if pet.defeated or pet.carried_item == null:
			continue
		var carried = pet.carried_item
		var home_base: BattleBase = bases[pet.team]
		var enemy_base: BattleBase = bases[_other_team(pet.team)]
		if carried.kind == "boom" and enemy_base.contains_point(pet.global_position):
			enemy_base.damage(1)
			_show_event("%s damaged the %s base." % [pet.display_name, enemy_base.team.capitalize()])
			_consume_item(carried)
			boom_respawn_timer = 2.0
		elif carried.kind == "repair" and home_base.contains_point(pet.global_position):
			if home_base.repair(1):
				_show_event("%s repaired the %s base." % [pet.display_name, home_base.team.capitalize()])
				_consume_item(carried)


func _process_item_bounds() -> void:
	for item in items:
		if item.held_by == null:
			item.global_position = clamp_to_map(item.global_position)


func _tick_spawners(delta: float) -> void:
	if boom_respawn_timer > 0.0:
		boom_respawn_timer -= delta
		if boom_respawn_timer <= 0.0 and _closest_free_item(Vector2(640, 360), ["boom"]) == null and _find_item_any("boom") == null:
			_spawn_item("boom", Vector2(640, 360))
			_show_event("Boom Snack respawned in the center.")

	aux_spawn_timer -= delta
	if aux_spawn_timer <= 0.0:
		aux_spawn_timer = rng.randf_range(5.0, 8.0)
		if _count_free_aux_items() < 5:
			var kinds := ["repair", "speed", "shield", "sock"]
			_spawn_item(kinds[rng.randi_range(0, kinds.size() - 1)], aux_spawn_points[rng.randi_range(0, aux_spawn_points.size() - 1)])


func _spawn_item(kind: String, pos: Vector2) -> Node:
	var item := ItemScript.new()
	item.setup(kind, pos)
	add_child(item)
	items.append(item)
	return item


func _consume_item(item: Node) -> void:
	if item == null:
		return
	if item.held_by != null and item.held_by.carried_item == item:
		item.held_by.carried_item = null
	items.erase(item)
	item.queue_free()


func _on_base_destroyed(base: BattleBase) -> void:
	var winner := _other_team(base.team)
	_finish_match(winner, "%s base destroyed" % base.team.capitalize())


func _finish_by_time() -> void:
	if bases["cat"].durability > bases["dog"].durability:
		_finish_match("cat", "Time up")
	elif bases["dog"].durability > bases["cat"].durability:
		_finish_match("dog", "Time up")
	else:
		_finish_match("draw", "Time up")


func _finish_match(winner: String, reason: String) -> void:
	if match_over:
		return
	match_over = true
	var reward := GameState.record_match(winner, bases["cat"].durability, bases["dog"].durability, elapsed)
	result_panel.visible = true
	var result := "DRAW"
	if winner == player_team:
		result = "VICTORY"
	elif winner != "draw":
		result = "DEFEAT"
	result_label.text = "%s\n%s\nReward +%d coins\nPress Enter to prep" % [result, reason, reward]


func update_hud() -> void:
	if score_label == null:
		return
	var time_seconds := int(match_time_left)
	score_label.text = "Cats %d / 5     Dogs %d / 5     %02d:%02d" % [
		bases["cat"].durability,
		bases["dog"].durability,
		int(time_seconds / 60.0),
		time_seconds % 60
	]
	if player_pet != null:
		var item_name = "None" if player_pet.carried_item == null else player_pet.carried_item.kind.capitalize()
		cooldown_label.text = "HP %d/%d   Skill %.1fs   Item %s   Coins %d" % [
			int(ceil(player_pet.hp)),
			int(ceil(player_pet.max_hp)),
			player_pet.skill_timer,
			item_name,
			GameState.coins
		]
	objective_label.text = "Carry Boom Snack to enemy base. Stop enemies carrying it to yours."
	event_label.text = last_event if event_timer > 0.0 else ""
	status_label.text = "Boom: damage enemy base   Repair: restore your base   Bell: speed   Shield: escort   Sock: throw to slow"


func _show_event(message: String) -> void:
	last_event = message
	event_timer = 2.8


func _create_touch_controls() -> void:
	touch_controls = Control.new()
	touch_controls.visible = _should_show_touch_controls()
	touch_controls.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_layer.add_child(touch_controls)

	var pad_size := Vector2(68, 52)
	_add_touch_button("UP", Vector2(90, 500), pad_size, func() -> void:
		touch_up_held = true
		_update_touch_move()
	, func() -> void:
		touch_up_held = false
		_update_touch_move()
	)
	_add_touch_button("DOWN", Vector2(90, 612), pad_size, func() -> void:
		touch_down_held = true
		_update_touch_move()
	, func() -> void:
		touch_down_held = false
		_update_touch_move()
	)
	_add_touch_button("LEFT", Vector2(18, 556), pad_size, func() -> void:
		touch_left_held = true
		_update_touch_move()
	, func() -> void:
		touch_left_held = false
		_update_touch_move()
	)
	_add_touch_button("RIGHT", Vector2(162, 556), pad_size, func() -> void:
		touch_right_held = true
		_update_touch_move()
	, func() -> void:
		touch_right_held = false
		_update_touch_move()
	)

	_add_touch_button("ATK", Vector2(1054, 530), Vector2(82, 58), func() -> void:
		touch_attack_held = true
	, func() -> void:
		touch_attack_held = false
	)
	_add_touch_button("SKL", Vector2(1150, 478), Vector2(82, 58), func() -> void:
		touch_skill_held = true
	, func() -> void:
		touch_skill_held = false
	)
	_add_touch_button("DROP", Vector2(1150, 598), Vector2(82, 58), func() -> void:
		touch_drop_requested = true
	, func() -> void:
		pass
	)


func _add_touch_button(text: String, pos: Vector2, size: Vector2, on_down: Callable, on_up: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.position = pos
	button.size = size
	button.modulate = Color(1, 1, 1, 0.78)
	button.add_theme_font_size_override("font_size", 15)
	button.button_down.connect(on_down)
	button.button_up.connect(on_up)
	touch_controls.add_child(button)


func _update_touch_move() -> void:
	touch_move = Vector2.ZERO
	if touch_up_held:
		touch_move.y -= 1.0
	if touch_down_held:
		touch_move.y += 1.0
	if touch_left_held:
		touch_move.x -= 1.0
	if touch_right_held:
		touch_move.x += 1.0


func _should_show_touch_controls() -> bool:
	return DisplayServer.is_touchscreen_available() or OS.has_feature("android") or OS.has_feature("ios") or OS.has_feature("mobile")


func clamp_to_map(point: Vector2) -> Vector2:
	return Vector2(
		clamp(point.x, MAP_RECT.position.x + 25.0, MAP_RECT.end.x - 25.0),
		clamp(point.y, MAP_RECT.position.y + 25.0, MAP_RECT.end.y - 25.0)
	)


func _draw_filled_rect(rect: Rect2, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		rect.position,
		rect.position + Vector2(rect.size.x, 0),
		rect.position + rect.size,
		rect.position + Vector2(0, rect.size.y),
	]), color)


func get_respawn_time(team: String) -> float:
	var own_base: BattleBase = bases[team]
	var other_base: BattleBase = bases[_other_team(team)]
	if own_base.durability < other_base.durability:
		return 2.2
	return 3.0


func _nearest_enemy_pet(origin: Vector2, team: String, max_distance: float) -> Node:
	var best: Node = null
	var best_distance := max_distance
	for pet in pets:
		if pet.team == team or pet.defeated:
			continue
		var distance := origin.distance_to(pet.global_position)
		if distance < best_distance:
			best_distance = distance
			best = pet
	return best


func _nearest_free_item(origin: Vector2, max_distance: float) -> Node:
	var best: Node = null
	var best_distance := max_distance
	for item in items:
		if item.held_by != null or not item.can_pick_up():
			continue
		var distance := origin.distance_to(item.global_position)
		if distance < best_distance:
			best_distance = distance
			best = item
	return best


func _closest_free_item(origin: Vector2, kinds: Array) -> Node:
	var best: Node = null
	var best_distance := 99999.0
	for item in items:
		if item.held_by != null or not item.can_pick_up() or not kinds.has(item.kind):
			continue
		var distance := origin.distance_to(item.global_position)
		if distance < best_distance:
			best_distance = distance
			best = item
	return best


func _find_item_any(kind: String) -> Node:
	for item in items:
		if item.kind == kind:
			return item
	return null


func _count_free_aux_items() -> int:
	var count := 0
	for item in items:
		if item.kind != "boom" and item.held_by == null:
			count += 1
	return count


func _find_enemy_carrier(team: String) -> Node:
	for pet in pets:
		if pet.team == team or pet.defeated or pet.carried_item == null:
			continue
		if pet.carried_item.kind == "boom":
			return pet
	return null


func _find_allied_carrier(team: String) -> Node:
	for pet in pets:
		if pet.team != team or pet.defeated or pet.carried_item == null:
			continue
		if pet.carried_item.kind == "boom":
			return pet
	return null


func _other_team(team: String) -> String:
	return "dog" if team == "cat" else "cat"
