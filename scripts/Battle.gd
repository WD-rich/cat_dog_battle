extends Node2D

const PetScript := preload("res://scripts/Pet.gd")
const BaseScript := preload("res://scripts/Base.gd")
const ItemScript := preload("res://scripts/Item.gd")
const GameDataScript := preload("res://scripts/GameData.gd")
const ARENA_TEXTURE := preload("res://assets/visuals/arena_living_room.svg")
const UI_FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")

const WORLD_SIZE := Vector2(2200, 1240)
const MAP_RECT := Rect2(60, 110, 2080, 1000)
const CENTER_POS := Vector2(1100, 620)
const CAT_BASE_POS := Vector2(180, 620)
const DOG_BASE_POS := Vector2(2020, 620)
const OPENING_GRACE_SECONDS := 4.0

var pets: Array = []
var items: Array = []
var bases := {}
var obstacle_rects: Array[Rect2] = []
var aux_spawn_points := [
	Vector2(1100, 300),
	Vector2(1100, 940),
	Vector2(720, 340),
	Vector2(1480, 340),
	Vector2(720, 900),
	Vector2(1480, 900),
	Vector2(520, 620),
	Vector2(1680, 620),
	Vector2(920, 500),
	Vector2(1280, 740),
	Vector2(360, 330),
	Vector2(1840, 910),
]

var player_pet: Node = null
var player_team := "cat"
var enemy_team := "dog"
var match_over := false
var match_time_limit := 240.0
var match_time_left := 240.0
var boom_respawn_timer := 0.0
var aux_spawn_timer := 4.0
var elapsed := 0.0
var last_event := ""
var event_timer := 0.0
var rng := RandomNumberGenerator.new()
var camera: Camera2D

var hud_layer: CanvasLayer
var score_label: Label
var status_label: Label
var cooldown_label: Label
var objective_label: Label
var event_label: Label
var touch_controls: Control
var result_panel: Panel
var result_label: Label
var guide_label: Label
var control_hint_back: ColorRect
var control_hint_label: Label

var touch_up_held := false
var touch_down_held := false
var touch_left_held := false
var touch_right_held := false
var touch_attack_held := false
var touch_skill_held := false
var touch_drop_requested := false
var touch_move := Vector2.ZERO
var drop_input_was_down := false
var attack_input_was_down := false
var skill_input_was_down := false
var attack_requested := false
var skill_requested := false
var drop_requested := false


func _ready() -> void:
	rng.randomize()
	player_team = GameState.player_team
	enemy_team = "dog" if player_team == "cat" else "cat"
	match_time_left = match_time_limit
	_create_map()
	_create_bases()
	_create_pets()
	_create_camera()
	_create_hud()
	_spawn_item("boom", CENTER_POS)
	_spawn_item("repair", Vector2(360, 330))
	_spawn_item("shield", Vector2(1100, 940))
	_spawn_item("speed", Vector2(1100, 300))
	_spawn_item("sock", Vector2(1680, 620))
	_show_event("开局保护 4 秒，先冲中场抢罐头炸弹！")
	update_hud()


func _unhandled_input(event: InputEvent) -> void:
	if match_over:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_J or event.physical_keycode == KEY_J:
			attack_requested = true
		elif event.keycode == KEY_K or event.physical_keycode == KEY_K:
			skill_requested = true
		elif event.keycode == KEY_E or event.physical_keycode == KEY_E:
			drop_requested = true
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			attack_requested = true
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			skill_requested = true


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
	_update_camera(delta)
	for pet in pets:
		if pet != player_pet:
			_drive_ai(pet, delta)

	_process_dash_hits()
	_process_sock_hits()
	_process_item_pickups()
	_process_deliveries()
	_process_item_bounds()
	_tick_spawners(delta)
	queue_redraw()
	update_hud()


func _draw() -> void:
	if ARENA_TEXTURE != null:
		draw_texture_rect(ARENA_TEXTURE, Rect2(Vector2.ZERO, WORLD_SIZE), false)
		draw_rect(MAP_RECT, Color(0.26, 0.17, 0.11, 0.35), false, 5.0)
	else:
		_draw_filled_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color(0.99, 0.93, 0.78))
		_draw_filled_rect(MAP_RECT, Color(0.94, 0.84, 0.65))
		draw_rect(MAP_RECT, Color(0.26, 0.17, 0.11), false, 5.0)
		_draw_filled_rect(Rect2(Vector2(820, 440), Vector2(560, 360)), Color(0.86, 0.58, 0.45, 0.46))
		draw_rect(Rect2(Vector2(820, 440), Vector2(560, 360)), Color(0.51, 0.30, 0.22), false, 3.0)
		draw_circle(CENTER_POS, 80, Color(1.0, 0.82, 0.32, 0.22))
		draw_circle(CENTER_POS, 80, Color(0.63, 0.43, 0.14, 0.55), false, 3.0)

		for rect in obstacle_rects:
			_draw_filled_rect(rect, Color(0.64, 0.40, 0.28))
			draw_rect(rect, Color(0.24, 0.14, 0.09), false, 4.0)
			draw_line(rect.position + Vector2(8, 8), rect.position + rect.size - Vector2(8, 8), Color(0.78, 0.55, 0.38), 2.0)
	_draw_battle_guides()


func _create_map() -> void:
	obstacle_rects = [
		Rect2(Vector2(420, 180), Vector2(270, 120)),
		Rect2(Vector2(1510, 180), Vector2(270, 120)),
		Rect2(Vector2(420, 935), Vector2(300, 130)),
		Rect2(Vector2(1480, 935), Vector2(300, 130)),
		Rect2(Vector2(820, 145), Vector2(560, 105)),
		Rect2(Vector2(820, 990), Vector2(560, 105)),
		Rect2(Vector2(840, 470), Vector2(170, 125)),
		Rect2(Vector2(1190, 645), Vector2(170, 125)),
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
	_add_base_label("猫窝", CAT_BASE_POS + Vector2(0, -132), Color(0.95, 0.30, 0.18))

	var dog_base := BaseScript.new()
	dog_base.setup("dog", DOG_BASE_POS)
	dog_base.destroyed.connect(_on_base_destroyed)
	add_child(dog_base)
	bases["dog"] = dog_base
	_add_base_label("狗窝", DOG_BASE_POS + Vector2(0, -132), Color(0.14, 0.42, 0.86))


func _add_base_label(text: String, pos: Vector2, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.position = pos + Vector2(-64, 0)
	label.size = Vector2(128, 32)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.z_index = 30
	label.add_theme_font_override("font", UI_FONT)
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(1.0, 0.95, 0.76, 0.96))
	label.add_theme_constant_override("outline_size", 6)
	add_child(label)


func _create_pets() -> void:
	var cat_keys := _team_lineup("cat")
	var dog_keys := _team_lineup("dog")
	_create_team("cat", cat_keys, CAT_BASE_POS + Vector2(240, 0))
	_create_team("dog", dog_keys, DOG_BASE_POS + Vector2(-240, 0))


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
	var offsets := [Vector2.ZERO, Vector2(120, -155), Vector2(120, 155)] if team == "cat" else [Vector2.ZERO, Vector2(-120, -155), Vector2(-120, 155)]
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


func _create_camera() -> void:
	camera = Camera2D.new()
	camera.enabled = true
	camera.limit_left = int(MAP_RECT.position.x)
	camera.limit_top = int(MAP_RECT.position.y)
	camera.limit_right = int(MAP_RECT.end.x)
	camera.limit_bottom = int(MAP_RECT.end.y)
	camera.position = player_pet.global_position if player_pet != null else CENTER_POS
	add_child(camera)
	camera.make_current()


func _update_camera(delta: float) -> void:
	if camera == null or player_pet == null:
		return
	var follow_speed = min(1.0, delta * 7.0)
	camera.global_position = camera.global_position.lerp(player_pet.global_position, follow_speed)


func _create_hud() -> void:
	hud_layer = CanvasLayer.new()
	add_child(hud_layer)

	var top_back := ColorRect.new()
	top_back.position = Vector2(12, 8)
	top_back.size = Vector2(1256, 72)
	top_back.color = Color(1.0, 0.95, 0.76, 0.72)
	hud_layer.add_child(top_back)

	score_label = Label.new()
	score_label.position = Vector2(424, 14)
	score_label.size = Vector2(432, 34)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_override("font", UI_FONT)
	score_label.add_theme_font_size_override("font_size", 24)
	score_label.add_theme_color_override("font_color", Color(0.15, 0.09, 0.06))
	score_label.add_theme_color_override("font_outline_color", Color(0.99, 0.91, 0.72, 0.86))
	score_label.add_theme_constant_override("outline_size", 4)
	hud_layer.add_child(score_label)

	var status_back := ColorRect.new()
	status_back.position = Vector2(22, 660)
	status_back.size = Vector2(1236, 38)
	status_back.color = Color(1.0, 0.94, 0.72, 0.72)
	hud_layer.add_child(status_back)

	status_label = Label.new()
	status_label.position = Vector2(34, 665)
	status_label.size = Vector2(1212, 30)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_override("font", UI_FONT)
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.add_theme_color_override("font_color", Color(0.21, 0.14, 0.10))
	status_label.add_theme_color_override("font_outline_color", Color(0.99, 0.91, 0.72, 0.86))
	status_label.add_theme_constant_override("outline_size", 4)
	hud_layer.add_child(status_label)

	cooldown_label = Label.new()
	cooldown_label.position = Vector2(20, 18)
	cooldown_label.size = Vector2(390, 28)
	cooldown_label.add_theme_font_override("font", UI_FONT)
	cooldown_label.add_theme_font_size_override("font_size", 16)
	cooldown_label.add_theme_color_override("font_color", Color(0.20, 0.13, 0.09))
	cooldown_label.add_theme_color_override("font_outline_color", Color(0.99, 0.91, 0.72, 0.86))
	cooldown_label.add_theme_constant_override("outline_size", 4)
	hud_layer.add_child(cooldown_label)

	objective_label = Label.new()
	objective_label.position = Vector2(390, 43)
	objective_label.size = Vector2(500, 30)
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.add_theme_font_override("font", UI_FONT)
	objective_label.add_theme_font_size_override("font_size", 14)
	objective_label.add_theme_color_override("font_color", Color(0.20, 0.13, 0.09))
	objective_label.add_theme_color_override("font_outline_color", Color(0.99, 0.91, 0.72, 0.86))
	objective_label.add_theme_constant_override("outline_size", 4)
	hud_layer.add_child(objective_label)

	event_label = Label.new()
	event_label.position = Vector2(390, 88)
	event_label.size = Vector2(500, 42)
	event_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	event_label.add_theme_font_override("font", UI_FONT)
	event_label.add_theme_font_size_override("font_size", 20)
	event_label.add_theme_color_override("font_color", Color(0.80, 0.18, 0.10))
	event_label.add_theme_color_override("font_outline_color", Color(0.99, 0.91, 0.72, 0.92))
	event_label.add_theme_constant_override("outline_size", 5)
	hud_layer.add_child(event_label)

	guide_label = Label.new()
	guide_label.position = Vector2(910, 82)
	guide_label.size = Vector2(330, 34)
	guide_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	guide_label.add_theme_font_override("font", UI_FONT)
	guide_label.add_theme_font_size_override("font_size", 20)
	guide_label.add_theme_color_override("font_color", Color(0.18, 0.11, 0.08))
	guide_label.add_theme_color_override("font_outline_color", Color(1.0, 0.93, 0.73, 0.95))
	guide_label.add_theme_constant_override("outline_size", 5)
	hud_layer.add_child(guide_label)

	control_hint_back = ColorRect.new()
	control_hint_back.position = Vector2(18, 92)
	control_hint_back.size = Vector2(386, 154)
	control_hint_back.color = Color(1.0, 0.96, 0.78, 0.82)
	hud_layer.add_child(control_hint_back)

	control_hint_label = Label.new()
	control_hint_label.position = Vector2(32, 104)
	control_hint_label.size = Vector2(358, 132)
	control_hint_label.add_theme_font_override("font", UI_FONT)
	control_hint_label.add_theme_font_size_override("font_size", 17)
	control_hint_label.add_theme_color_override("font_color", Color(0.20, 0.12, 0.08))
	control_hint_label.add_theme_color_override("font_outline_color", Color(1.0, 0.96, 0.78, 0.92))
	control_hint_label.add_theme_constant_override("outline_size", 3)
	control_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud_layer.add_child(control_hint_label)

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
	result_label.add_theme_font_override("font", UI_FONT)
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

	var attack_down := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_key_pressed(KEY_J) or touch_attack_held or attack_requested
	if attack_down:
		var attack_was_ready: bool = player_pet.attack_timer <= 0.0
		var attacked: bool = player_pet.try_attack()
		if not attack_input_was_down and attack_was_ready and not attacked:
			_show_event("J 键是拍打：贴近敌人或地上道具再按")
	attack_input_was_down = attack_down
	attack_requested = false
	var skill_down := Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or Input.is_key_pressed(KEY_K) or touch_skill_held or skill_requested
	if skill_down and (not skill_input_was_down or skill_requested):
		if not player_pet.try_skill():
			_show_event("K 键技能冷却中：还剩 %.1f 秒" % player_pet.skill_timer)
		touch_skill_held = false
	skill_input_was_down = skill_down
	skill_requested = false
	var drop_down := Input.is_key_pressed(KEY_E) or touch_drop_requested or drop_requested
	if drop_down and (not drop_input_was_down or drop_requested):
		if player_pet.carried_item == null:
			_show_event("还没拿道具：靠近道具会自动拾取")
		else:
			var dropped_kind: String = player_pet.carried_item.kind
			player_pet.drop_or_throw_carried()
			if dropped_kind == "sock":
				_show_event("E 键投出了臭袜子！")
			elif dropped_kind == "boom":
				_show_event("E 键已放下罐头炸弹")
			else:
				_show_event("E 键已放下%s" % _item_name(dropped_kind))
		touch_drop_requested = false
	drop_input_was_down = drop_down
	drop_requested = false


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
		var can_attack_enemy := not _is_opening_protected(pet, enemy)
		if can_attack_enemy and pet.global_position.distance_to(enemy.global_position) <= pet.attack_range:
			pet.try_attack()
		if can_attack_enemy and pet.skill_timer <= 0.0 and _should_ai_skill(pet, enemy):
			pet.try_skill()

	if pet.carried_item != null and pet.carried_item.kind == "sock" and enemy != null and pet.global_position.distance_to(enemy.global_position) < 280.0:
		pet.aim_direction = (enemy.global_position - pet.global_position).normalized()
		pet.drop_or_throw_carried()


func _choose_ai_target(pet: Node) -> Vector2:
	if elapsed < OPENING_GRACE_SECONDS and pet.team != player_team:
		var early_boom := _closest_free_item(pet.global_position, ["boom"])
		if early_boom != null:
			return early_boom.global_position
		return CENTER_POS + Vector2(150, -120) * (1 if pet.team == "cat" else -1)

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
		if pet.role == "defender" or danger_distance < 700.0:
			return enemy_carrier.global_position

	var allied_carrier := _find_allied_carrier(pet.team)
	if allied_carrier != null and pet.role == "escort":
		return allied_carrier.global_position + (allied_carrier.target_base.global_position - allied_carrier.global_position).normalized() * 45.0

	if pet.role == "defender":
		var repair := _closest_free_item(bases[pet.team].global_position, ["repair"])
		if bases[pet.team].durability <= 3 and repair != null:
			return repair.global_position
		return bases[pet.team].global_position + Vector2(220, 0) * (1 if pet.team == "cat" else -1)

	var boom := _closest_free_item(pet.global_position, ["boom"])
	if boom != null:
		return boom.global_position

	var useful := _closest_free_item(pet.global_position, ["shield", "speed", "sock", "repair"])
	if useful != null:
		return useful.global_position

	var nearest_enemy := _nearest_enemy_pet(pet.global_position, pet.team, 9999.0)
	if nearest_enemy != null:
		return nearest_enemy.global_position
	return CENTER_POS


func _should_ai_skill(pet: Node, enemy: Node) -> bool:
	if pet.skill_type == "shield":
		return pet.carried_item != null or pet.global_position.distance_to(enemy.global_position) < 75.0
	if pet.skill_type == "pulse":
		return pet.global_position.distance_to(enemy.global_position) < 110.0
	if pet.skill_type == "sprint":
		return pet.carried_item != null or pet.global_position.distance_to(enemy.global_position) > 120.0
	return pet.global_position.distance_to(enemy.global_position) > 55.0


func pet_attack(attacker: Node) -> bool:
	var range_bonus := 22.0 if attacker == player_pet else 12.0
	var target := _nearest_enemy_pet(attacker.global_position, attacker.team, attacker.attack_range + range_bonus)
	if target != null and not _is_opening_protected(attacker, target):
		var dir = (target.global_position - attacker.global_position).normalized()
		target.take_damage(attacker.attack_damage, dir * 330.0, attacker)
		_show_action_pop(target.global_position + Vector2(0, -48), "啪！", Color(1.0, 0.82, 0.22))
		return true

	var item := _nearest_free_item(attacker.global_position, attacker.attack_range + 28.0)
	if item != null:
		var dir = attacker.aim_direction.normalized()
		if dir.length() < 0.1:
			dir = (item.global_position - attacker.global_position).normalized()
		item.kick(dir, 610.0)
		_show_action_pop(item.global_position + Vector2(0, -34), "踢！", Color(1.0, 0.68, 0.18))
		return true
	return false


func get_assisted_throw_direction(pet: Node, fallback: Vector2) -> Vector2:
	var base_dir := fallback.normalized()
	if base_dir.length() < 0.1:
		base_dir = Vector2.RIGHT if pet.team == "cat" else Vector2.LEFT
	var best: Node = null
	var best_score := 99999.0
	for target in pets:
		if target.team == pet.team or target.defeated:
			continue
		if _is_opening_protected(pet, target):
			continue
		var offset: Vector2 = target.global_position - pet.global_position
		var distance := offset.length()
		if distance > 520.0 or distance < 1.0:
			continue
		var angle_penalty: float = abs(base_dir.angle_to(offset.normalized())) * 115.0
		var carrier_bonus: float = -90.0 if target.carried_item != null and target.carried_item.kind == "boom" else 0.0
		var score: float = distance + angle_penalty + carrier_bonus
		if score < best_score:
			best_score = score
			best = target
	if best != null:
		return (best.global_position - pet.global_position).normalized()
	return base_dir


func pet_skill_used(pet: Node) -> void:
	var skill := _skill_name(pet.skill_type)
	if pet == player_pet:
		_show_event("K 键释放：%s！" % skill)
	_show_action_pop(pet.global_position + Vector2(0, -58), skill, _skill_color(pet.skill_type))


func area_burst(source: Node, radius: float, damage: float, knock_force: float) -> void:
	for target in pets:
		if target.team == source.team or target.defeated:
			continue
		if _is_opening_protected(source, target):
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
			if _is_opening_protected(pet, target):
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
			if elapsed < OPENING_GRACE_SECONDS and pet == player_pet:
				continue
			if pet.global_position.distance_to(item.global_position) <= 42.0:
				var dir = (pet.global_position - item.global_position).normalized()
				pet.take_damage(5.0, dir * 260.0, null)
				pet.add_slow(2.2)
				_show_action_pop(pet.global_position + Vector2(0, -54), "臭袜子命中", Color(0.55, 0.86, 0.32))
				_consume_item(item)
				break


func _process_item_pickups() -> void:
	for pet in pets:
		if pet.defeated:
			continue
		if pet.carried_item != null:
			if pet.carried_item.kind != "boom":
				var nearby_boom := _closest_pickup_item(pet, ["boom"], 44.0)
				if nearby_boom != null:
					pet.carried_item.drop(pet.global_position - pet.aim_direction.normalized() * 42.0, 1.2)
					nearby_boom.pickup(pet)
					_show_event("%s 抢到罐头炸弹！" % pet.display_name)
			continue
		var closest := _best_pickup_item(pet, 42.0)
		if closest != null:
			var was_carry_item = closest.is_carry_item()
			if closest.pickup(pet):
				if closest.kind == "boom":
					_show_event("%s 抱起罐头炸弹，去拆%s！" % [pet.display_name, _base_name(_other_team(pet.team))])
				elif closest.kind == "repair":
					_show_event("%s 捡到胶带卷，回窝可修家。" % pet.display_name)
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
			_show_base_burst(enemy_base.global_position, enemy_base.team)
			_show_event("%s 炸了%s！" % [pet.display_name, _base_name(enemy_base.team)])
			_consume_item(carried)
			boom_respawn_timer = 2.0
		elif carried.kind == "repair" and home_base.contains_point(pet.global_position):
			if home_base.repair(1):
				_show_event("%s 修好了%s。" % [pet.display_name, _base_name(home_base.team)])
				_consume_item(carried)


func _process_item_bounds() -> void:
	for item in items:
		if item.held_by == null:
			item.global_position = clamp_to_map(item.global_position)


func _tick_spawners(delta: float) -> void:
	if boom_respawn_timer > 0.0:
		boom_respawn_timer -= delta
		if boom_respawn_timer <= 0.0 and _closest_free_item(CENTER_POS, ["boom"]) == null and _find_item_any("boom") == null:
			_spawn_item("boom", CENTER_POS)
			_show_event("罐头炸弹回到中场了！")

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
	_finish_match(winner, "%s被拆掉" % _base_name(base.team))


func _finish_by_time() -> void:
	if bases["cat"].durability > bases["dog"].durability:
		_finish_match("cat", "时间到")
	elif bases["dog"].durability > bases["cat"].durability:
		_finish_match("dog", "时间到")
	else:
		_finish_match("draw", "时间到")


func _finish_match(winner: String, reason: String) -> void:
	if match_over:
		return
	match_over = true
	var reward := GameState.record_match(winner, bases["cat"].durability, bases["dog"].durability, elapsed)
	result_panel.visible = true
	var result := "平局"
	if winner == player_team:
		result = "胜利"
	elif winner != "draw":
		result = "失败"
	result_label.text = "%s\n%s\n奖励 +%d 小鱼干\n按回车回准备页" % [result, reason, reward]


func update_hud() -> void:
	if score_label == null:
		return
	var time_seconds := int(match_time_left)
	score_label.text = "猫窝 %d/5    狗窝 %d/5    %02d:%02d" % [
		bases["cat"].durability,
		bases["dog"].durability,
		int(time_seconds / 60.0),
		time_seconds % 60
	]
	if player_pet != null:
		var item_name = "无" if player_pet.carried_item == null else _item_name(player_pet.carried_item.kind)
		cooldown_label.text = "血量 %d/%d   K技能 %s %.1fs   道具 %s   小鱼干 %d" % [
			int(ceil(player_pet.hp)),
			int(ceil(player_pet.max_hp)),
			_skill_name(player_pet.skill_type),
			player_pet.skill_timer,
			item_name,
			GameState.coins
		]
	if elapsed < OPENING_GRACE_SECONDS:
		var grace_left := int(ceil(OPENING_GRACE_SECONDS - elapsed))
		objective_label.text = "开局保护 %d 秒：冲向中场抢罐头炸弹" % grace_left
	else:
		objective_label.text = "带罐头炸弹进敌方窝，别让对面拆你家"
	event_label.text = last_event if event_timer > 0.0 else ""
	status_label.text = "J 拍打/踢道具｜K 释放技能｜E 使用手上道具｜罐头炸弹拆窝"
	if guide_label != null:
		guide_label.text = _guide_text()
	if control_hint_label != null:
		control_hint_label.text = _control_hint_text()
		var show_hint := elapsed < 28.0 or (player_pet != null and player_pet.carried_item != null)
		control_hint_label.visible = show_hint
		control_hint_back.visible = show_hint


func _show_event(message: String) -> void:
	last_event = message
	event_timer = 2.8


func _control_hint_text() -> String:
	if player_pet == null:
		return ""
	if player_pet.carried_item != null:
		if player_pet.carried_item.kind == "boom":
			return "你抱着罐头炸弹\n跑进敌方宠物窝 = 拆 1 格\nK 键：%s\nE 键：放下罐头炸弹" % _skill_name(player_pet.skill_type)
		if player_pet.carried_item.kind == "sock":
			return "你拿着臭袜子\nE 键：朝附近敌人投掷减速\nJ 键 / 左键：近身拍打\nK 键 / 右键：使用技能"
		if player_pet.carried_item.kind == "repair":
			return "你拿着胶带卷\n跑回自家宠物窝 = 修 1 格\nK 键：%s\nE 键：放下胶带卷" % _skill_name(player_pet.skill_type)
	return "操作提示\n移动：W A S D 键 / 方向键\nJ 键 / 鼠标左键：拍打敌人或踢道具\nK 键 / 鼠标右键：%s\nE 键：使用手上道具" % _skill_name(player_pet.skill_type)


func _guide_text() -> String:
	if player_pet == null:
		return ""
	var target: Vector2 = CENTER_POS
	var verb := "抢罐头炸弹"
	var carrier := _find_enemy_carrier(player_team)
	if player_pet.carried_item != null and player_pet.carried_item.kind == "boom":
		target = bases[enemy_team].global_position
		verb = "去炸%s" % _base_name(enemy_team)
	elif carrier != null:
		target = carrier.global_position
		verb = "拦截罐头炸弹"
	else:
		var boom := _find_item_any("boom")
		if boom != null:
			target = boom.global_position
	var dir: Vector2 = target - player_pet.global_position
	var arrow := "→"
	if abs(dir.y) > abs(dir.x):
		arrow = "↓" if dir.y > 0.0 else "↑"
	else:
		arrow = "→" if dir.x >= 0.0 else "←"
	return "%s %s" % [arrow, verb]


func _draw_battle_guides() -> void:
	if player_pet == null or match_over:
		return
	var target: Vector2 = CENTER_POS
	var guide_color := Color(1.0, 0.73, 0.20, 0.42)
	var carrier := _find_enemy_carrier(player_team)
	if player_pet.carried_item != null and player_pet.carried_item.kind == "boom":
		target = bases[enemy_team].global_position
		guide_color = Color(1.0, 0.38, 0.18, 0.46)
	elif carrier != null:
		target = carrier.global_position
		guide_color = Color(0.95, 0.12, 0.10, 0.46)
	else:
		var boom := _find_item_any("boom")
		if boom != null:
			target = boom.global_position
	var dir: Vector2 = target - player_pet.global_position
	if dir.length() < 24.0:
		return
	dir = dir.normalized()
	var start: Vector2 = player_pet.global_position + dir * 62.0
	var finish: Vector2 = player_pet.global_position + dir * 170.0
	draw_line(start, finish, guide_color, 9.0)
	var side := Vector2(-dir.y, dir.x)
	draw_colored_polygon(PackedVector2Array([
		finish + dir * 24.0,
		finish - dir * 18.0 + side * 18.0,
		finish - dir * 18.0 - side * 18.0,
	]), Color(guide_color.r, guide_color.g, guide_color.b, min(0.78, guide_color.a + 0.25)))


func show_hit_feedback(pos: Vector2, amount: int, target_team: String) -> void:
	var label := Label.new()
	label.text = "-%d" % amount
	label.z_index = 120
	label.position = pos + Vector2(-18, -76)
	label.size = Vector2(64, 28)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", UI_FONT)
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(1.0, 0.28, 0.16) if target_team == "dog" else Color(0.15, 0.45, 1.0))
	label.add_theme_color_override("font_outline_color", Color(1.0, 0.94, 0.74, 0.95))
	label.add_theme_constant_override("outline_size", 4)
	add_child(label)
	var tween := create_tween()
	tween.tween_property(label, "position", label.position + Vector2(0, -34), 0.45)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.45)
	tween.tween_callback(label.queue_free)


func _show_action_pop(pos: Vector2, text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.z_index = 125
	label.position = pos + Vector2(-60, -18)
	label.size = Vector2(120, 32)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", UI_FONT)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.20, 0.12, 0.08, 0.95))
	label.add_theme_constant_override("outline_size", 4)
	add_child(label)
	var tween := create_tween()
	tween.tween_property(label, "position", label.position + Vector2(0, -28), 0.38)
	tween.parallel().tween_property(label, "scale", Vector2(1.10, 1.10), 0.18)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.38)
	tween.tween_callback(label.queue_free)


func _show_base_burst(pos: Vector2, team: String) -> void:
	var boom_color := Color(1.0, 0.38, 0.10) if team == "dog" else Color(0.12, 0.48, 1.0)
	for i in range(3):
		var ring := Line2D.new()
		ring.closed = true
		ring.width = 8.0 - i * 1.4
		ring.default_color = Color(boom_color.r, boom_color.g, boom_color.b, 0.78 - i * 0.12)
		ring.points = _circle_points(58.0 + i * 20.0, 32)
		ring.position = pos
		ring.z_index = 110
		ring.scale = Vector2(0.28, 0.28)
		add_child(ring)
		var ring_tween := create_tween()
		ring_tween.tween_property(ring, "scale", Vector2(1.0 + i * 0.18, 1.0 + i * 0.18), 0.34 + i * 0.08)
		ring_tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.34 + i * 0.08)
		ring_tween.tween_callback(ring.queue_free)

	var label := Label.new()
	label.text = "砰！拆窝"
	label.position = pos + Vector2(-84, -138)
	label.size = Vector2(168, 42)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.z_index = 120
	label.add_theme_font_override("font", UI_FONT)
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", boom_color)
	label.add_theme_color_override("font_outline_color", Color(1.0, 0.95, 0.76, 0.96))
	label.add_theme_constant_override("outline_size", 6)
	add_child(label)
	var label_tween := create_tween()
	label_tween.tween_property(label, "position", label.position + Vector2(0, -44), 0.64)
	label_tween.parallel().tween_property(label, "modulate:a", 0.0, 0.64)
	label_tween.tween_callback(label.queue_free)


func _circle_points(radius: float, steps: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(steps):
		var angle := TAU * float(i) / float(steps)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points


func _create_touch_controls() -> void:
	touch_controls = Control.new()
	touch_controls.visible = _should_show_touch_controls()
	touch_controls.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_layer.add_child(touch_controls)

	var pad_size := Vector2(68, 52)
	_add_touch_button("上", Vector2(90, 500), pad_size, func() -> void:
		touch_up_held = true
		_update_touch_move()
	, func() -> void:
		touch_up_held = false
		_update_touch_move()
	)
	_add_touch_button("下", Vector2(90, 612), pad_size, func() -> void:
		touch_down_held = true
		_update_touch_move()
	, func() -> void:
		touch_down_held = false
		_update_touch_move()
	)
	_add_touch_button("左", Vector2(18, 556), pad_size, func() -> void:
		touch_left_held = true
		_update_touch_move()
	, func() -> void:
		touch_left_held = false
		_update_touch_move()
	)
	_add_touch_button("右", Vector2(162, 556), pad_size, func() -> void:
		touch_right_held = true
		_update_touch_move()
	, func() -> void:
		touch_right_held = false
		_update_touch_move()
	)

	_add_touch_button("攻击", Vector2(1034, 530), Vector2(102, 58), func() -> void:
		touch_attack_held = true
	, func() -> void:
		touch_attack_held = false
	)
	_add_touch_button("技能", Vector2(1150, 478), Vector2(96, 58), func() -> void:
		touch_skill_held = true
	, func() -> void:
		touch_skill_held = false
	)
	_add_touch_button("丢弃", Vector2(1150, 598), Vector2(96, 58), func() -> void:
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
	button.add_theme_font_override("font", UI_FONT)
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
	return false


func clamp_to_map(point: Vector2) -> Vector2:
	return Vector2(
		clamp(point.x, MAP_RECT.position.x + 25.0, MAP_RECT.end.x - 25.0),
		clamp(point.y, MAP_RECT.position.y + 25.0, MAP_RECT.end.y - 25.0)
	)


func _is_opening_protected(attacker: Node, target: Node) -> bool:
	return elapsed < OPENING_GRACE_SECONDS and target == player_pet and attacker != null and attacker.team != player_team


func _item_name(kind: String) -> String:
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


func _skill_name(skill_type: String) -> String:
	if skill_type == "dash":
		return "冲刺"
	if skill_type == "sprint":
		return "加速"
	if skill_type == "pulse":
		return "推开"
	if skill_type == "shield":
		return "护盾"
	return "冲刺"


func _skill_color(skill_type: String) -> Color:
	if skill_type == "dash":
		return Color(1.0, 0.66, 0.18)
	if skill_type == "sprint":
		return Color(1.0, 0.88, 0.20)
	if skill_type == "pulse":
		return Color(0.78, 0.52, 1.0)
	if skill_type == "shield":
		return Color(0.34, 0.74, 1.0)
	return Color(1.0, 0.82, 0.22)


func _base_name(team: String) -> String:
	return "猫窝" if team == "cat" else "狗窝"


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


func _best_pickup_item(pet: Node, max_distance: float) -> Node:
	var best: Node = null
	var best_score := -99999.0
	for item in items:
		if item.held_by != null or not item.can_pick_up():
			continue
		var distance: float = pet.global_position.distance_to(item.global_position)
		if distance > max_distance:
			continue
		var priority := _pickup_priority(pet, item)
		if priority < 0:
			continue
		var score: float = priority - distance * 0.02
		if score > best_score:
			best_score = score
			best = item
	return best


func _closest_pickup_item(pet: Node, kinds: Array, max_distance: float) -> Node:
	var best: Node = null
	var best_distance := max_distance
	for item in items:
		if not kinds.has(item.kind) or item.held_by != null or not item.can_pick_up():
			continue
		if _pickup_priority(pet, item) < 0:
			continue
		var distance: float = pet.global_position.distance_to(item.global_position)
		if distance < best_distance:
			best_distance = distance
			best = item
	return best


func _pickup_priority(pet: Node, item: Node) -> float:
	if item.kind == "repair":
		var home_base: BattleBase = bases[pet.team]
		if home_base.durability >= home_base.max_durability:
			return -1.0
		return 55.0
	if item.kind == "boom":
		return 120.0
	if item.kind == "shield":
		return 85.0
	if item.kind == "speed":
		return 80.0
	if item.kind == "sock":
		return 60.0
	return 20.0


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
