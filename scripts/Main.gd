extends Control

var difficulty := "normal"


func _ready() -> void:
	_build_menu()


func _build_menu() -> void:
	var background := ColorRect.new()
	background.color = Color(0.98, 0.91, 0.75)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var center := VBoxContainer.new()
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 18)
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.position = Vector2(-220, -230)
	center.custom_minimum_size = Vector2(440, 460)
	add_child(center)

	var title := Label.new()
	title.text = "CAT DOG BATTLE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color(0.19, 0.13, 0.10))
	center.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "3v3 Snack Siege Prototype"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 19)
	subtitle.add_theme_color_override("font_color", Color(0.38, 0.27, 0.21))
	center.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(1, 18)
	center.add_child(spacer)

	var cat_button := _make_button("Play Cats")
	cat_button.pressed.connect(func() -> void: _start("cat"))
	center.add_child(cat_button)

	var dog_button := _make_button("Play Dogs")
	dog_button.pressed.connect(func() -> void: _start("dog"))
	center.add_child(dog_button)

	var difficulty_button := _make_button("Difficulty: Normal")
	difficulty_button.pressed.connect(func() -> void:
		difficulty = "hard" if difficulty == "normal" else "normal"
		difficulty_button.text = "Difficulty: Hard" if difficulty == "hard" else "Difficulty: Normal"
	)
	center.add_child(difficulty_button)

	var rules := Label.new()
	rules.text = "Goal: steal Boom Snacks, deliver them to the enemy base, and defend your own."
	rules.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rules.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rules.add_theme_font_size_override("font_size", 16)
	rules.add_theme_color_override("font_color", Color(0.25, 0.18, 0.14))
	rules.custom_minimum_size = Vector2(440, 80)
	center.add_child(rules)

	var controls := Label.new()
	controls.text = "Move WASD / Arrow Keys   Attack J or LMB   Skill K or RMB   Drop/Throw E"
	controls.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.add_theme_font_size_override("font_size", 14)
	controls.add_theme_color_override("font_color", Color(0.42, 0.31, 0.25))
	controls.custom_minimum_size = Vector2(440, 64)
	center.add_child(controls)


func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(320, 54)
	button.add_theme_font_size_override("font_size", 22)
	return button


func _start(team: String) -> void:
	GameState.start_match(team, difficulty)
	get_tree().change_scene_to_file("res://scenes/Battle.tscn")

