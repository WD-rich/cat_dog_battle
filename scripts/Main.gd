extends Control

const GameDataScript := preload("res://scripts/GameData.gd")

var difficulty := "normal"
var selected_team := "cat"
var selected_pet_key := "orange_cat"


func _ready() -> void:
	selected_team = GameState.player_team
	selected_pet_key = GameState.get_selected_pet(selected_team)
	_build_menu()


func _build_menu() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

	var background := ColorRect.new()
	background.color = Color(0.97, 0.89, 0.72)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var root := HBoxContainer.new()
	root.add_theme_constant_override("separation", 32)
	root.set_anchors_preset(Control.PRESET_CENTER)
	root.position = Vector2(-520, -285)
	root.custom_minimum_size = Vector2(1040, 570)
	add_child(root)

	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 14)
	left.custom_minimum_size = Vector2(470, 570)
	root.add_child(left)

	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 12)
	right.custom_minimum_size = Vector2(530, 570)
	root.add_child(right)

	var title := Label.new()
	title.text = "CAT DOG BATTLE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color(0.19, 0.13, 0.10))
	left.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Vertical Slice: 3v3 Snack Siege"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 19)
	subtitle.add_theme_color_override("font_color", Color(0.38, 0.27, 0.21))
	left.add_child(subtitle)

	var status := Label.new()
	status.text = "Coins: %d     Matches: %d" % [GameState.coins, GameState.matches_played]
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.add_theme_font_size_override("font_size", 18)
	status.add_theme_color_override("font_color", Color(0.24, 0.16, 0.11))
	left.add_child(status)

	var prep := Label.new()
	prep.text = "Prep Phase"
	prep.add_theme_font_size_override("font_size", 25)
	prep.add_theme_color_override("font_color", Color(0.18, 0.11, 0.08))
	left.add_child(prep)

	var team_row := HBoxContainer.new()
	team_row.add_theme_constant_override("separation", 10)
	left.add_child(team_row)

	var cat_button := _make_button("Cats")
	cat_button.toggle_mode = true
	cat_button.button_pressed = selected_team == "cat"
	cat_button.pressed.connect(func() -> void: _select_team("cat"))
	team_row.add_child(cat_button)

	var dog_button := _make_button("Dogs")
	dog_button.toggle_mode = true
	dog_button.button_pressed = selected_team == "dog"
	dog_button.pressed.connect(func() -> void: _select_team("dog"))
	team_row.add_child(dog_button)

	var pet_title := Label.new()
	pet_title.text = "Choose Your Pet"
	pet_title.add_theme_font_size_override("font_size", 21)
	pet_title.add_theme_color_override("font_color", Color(0.18, 0.11, 0.08))
	left.add_child(pet_title)

	for key in GameDataScript.team_pet_keys(selected_team):
		left.add_child(_make_pet_button(key))

	var difficulty_button := _make_button("Difficulty: Hard" if difficulty == "hard" else "Difficulty: Normal")
	difficulty_button.pressed.connect(func() -> void:
		difficulty = "hard" if difficulty == "normal" else "normal"
		difficulty_button.text = "Difficulty: Hard" if difficulty == "hard" else "Difficulty: Normal"
	)
	left.add_child(difficulty_button)

	var selected_data := GameDataScript.pet_data(selected_pet_key)
	var selected_level := GameState.get_pet_level(selected_pet_key)
	var selected_info := Label.new()
	selected_info.text = "%s  Lv.%d  %s\n%s" % [
		selected_data.get("name", selected_pet_key),
		selected_level,
		selected_data.get("role", ""),
		selected_data.get("description", "")
	]
	selected_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	selected_info.add_theme_font_size_override("font_size", 16)
	selected_info.add_theme_color_override("font_color", Color(0.28, 0.19, 0.13))
	selected_info.custom_minimum_size = Vector2(470, 76)
	left.add_child(selected_info)

	var upgrade_button := _make_button(_upgrade_text(selected_pet_key))
	upgrade_button.disabled = not GameState.can_upgrade(selected_pet_key)
	upgrade_button.pressed.connect(func() -> void:
		GameState.upgrade_pet(selected_pet_key)
		_build_menu()
	)
	left.add_child(upgrade_button)

	var start_button := _make_button("Start 3v3 Match")
	start_button.custom_minimum_size = Vector2(440, 58)
	start_button.add_theme_font_size_override("font_size", 24)
	start_button.pressed.connect(func() -> void: _start(selected_team))
	left.add_child(start_button)

	var slice_title := Label.new()
	slice_title.text = "Playable Loop"
	slice_title.add_theme_font_size_override("font_size", 27)
	slice_title.add_theme_color_override("font_color", Color(0.18, 0.11, 0.08))
	right.add_child(slice_title)

	var rules := Label.new()
	rules.text = "1. Spawn into a 3v3 living-room arena.\n2. Grab the Boom Snack from the center.\n3. Carry it into the enemy base to damage it.\n4. Use Repair Cans, Bells, Shields, and Socks to turn fights.\n5. Destroy the enemy base before your own base falls."
	rules.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rules.add_theme_font_size_override("font_size", 18)
	rules.add_theme_color_override("font_color", Color(0.25, 0.18, 0.14))
	rules.custom_minimum_size = Vector2(520, 160)
	right.add_child(rules)

	var controls := Label.new()
	controls.text = "Controls\nMove: WASD / Arrow Keys\nAttack: J / Left Mouse\nSkill: K / Right Mouse\nDrop or Throw: E"
	controls.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controls.add_theme_font_size_override("font_size", 17)
	controls.add_theme_color_override("font_color", Color(0.42, 0.31, 0.25))
	controls.custom_minimum_size = Vector2(520, 120)
	right.add_child(controls)

	var result := Label.new()
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.add_theme_font_size_override("font_size", 17)
	result.add_theme_color_override("font_color", Color(0.24, 0.16, 0.11))
	result.custom_minimum_size = Vector2(520, 90)
	if GameState.last_match.is_empty():
		result.text = "No match yet. Start a round and return here for coins and upgrade choices."
	else:
		var winner: String = GameState.last_match.get("winner", "draw")
		var reward: int = GameState.last_match.get("reward", 0)
		result.text = "Last Match: %s\nReward: +%d coins\nBase HP: Cats %d / Dogs %d" % [
			winner.capitalize(),
			reward,
			GameState.last_match.get("cat_score", 0),
			GameState.last_match.get("dog_score", 0)
		]
	right.add_child(result)


func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(220, 48)
	button.add_theme_font_size_override("font_size", 19)
	return button


func _make_pet_button(key: String) -> Button:
	var data := GameDataScript.pet_data(key)
	var button := _make_button("%s  Lv.%d  %s" % [
		data.get("name", key),
		GameState.get_pet_level(key),
		data.get("role", "")
	])
	button.custom_minimum_size = Vector2(440, 46)
	button.toggle_mode = true
	button.button_pressed = selected_pet_key == key
	button.pressed.connect(func() -> void:
		selected_pet_key = key
		GameState.select_pet(selected_team, selected_pet_key)
		_build_menu()
	)
	return button


func _upgrade_text(key: String) -> String:
	var cost := GameState.get_upgrade_cost(key)
	if cost < 0:
		return "Max Level Reached"
	return "Upgrade Selected Pet  Cost %d" % cost


func _select_team(team: String) -> void:
	selected_team = team
	selected_pet_key = GameState.get_selected_pet(team)
	_build_menu()


func _start(team: String) -> void:
	GameState.start_match(team, difficulty, selected_pet_key)
	get_tree().change_scene_to_file("res://scenes/Battle.tscn")
