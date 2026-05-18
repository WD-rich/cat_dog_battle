extends Control

const GameDataScript := preload("res://scripts/GameData.gd")
const UI_FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const PET_TEXTURES := {
	"orange_cat": preload("res://assets/visuals/pet_orange_cat.svg"),
	"calico_cat": preload("res://assets/visuals/pet_calico_cat.svg"),
	"ragdoll_cat": preload("res://assets/visuals/pet_ragdoll_cat.svg"),
	"shiba_dog": preload("res://assets/visuals/pet_shiba_dog.svg"),
	"corgi_dog": preload("res://assets/visuals/pet_corgi_dog.svg"),
	"husky_dog": preload("res://assets/visuals/pet_husky_dog.svg"),
}

var difficulty := "normal"
var selected_team := "cat"
var selected_pet_key := "orange_cat"


func _ready() -> void:
	selected_team = GameState.player_team
	selected_pet_key = GameState.get_selected_pet(selected_team)
	_build_menu()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			_start(selected_team)


func _build_menu() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

	var background := ColorRect.new()
	background.color = Color(0.94, 0.95, 0.86)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var arena_preview := TextureRect.new()
	arena_preview.texture = preload("res://assets/visuals/arena_living_room.svg")
	arena_preview.set_anchors_preset(Control.PRESET_FULL_RECT)
	arena_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	arena_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	arena_preview.modulate = Color(1, 1, 1, 0.18)
	add_child(arena_preview)

	var cat_band := ColorRect.new()
	cat_band.color = Color(1.0, 0.44, 0.25, 0.18)
	cat_band.position = Vector2(0, 0)
	cat_band.size = Vector2(640, 720)
	add_child(cat_band)

	var dog_band := ColorRect.new()
	dog_band.color = Color(0.16, 0.50, 0.88, 0.18)
	dog_band.position = Vector2(640, 0)
	dog_band.size = Vector2(640, 720)
	add_child(dog_band)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_top", 34)
	margin.add_theme_constant_override("margin_bottom", 34)
	add_child(margin)

	var root := HBoxContainer.new()
	root.add_theme_constant_override("separation", 28)
	margin.add_child(root)

	var left_panel := PanelContainer.new()
	left_panel.custom_minimum_size = Vector2(560, 652)
	left_panel.add_theme_stylebox_override("panel", _panel_style(Color(1.0, 0.97, 0.86, 0.95), Color(0.92, 0.32, 0.18, 0.62)))
	root.add_child(left_panel)

	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 12)
	left_panel.add_child(left)

	var right_panel := PanelContainer.new()
	right_panel.custom_minimum_size = Vector2(596, 652)
	right_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.91, 0.97, 1.0, 0.93), Color(0.18, 0.43, 0.78, 0.58)))
	root.add_child(right_panel)

	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 13)
	right_panel.add_child(right)

	left.add_child(_make_label("猫狗大战", 50, Color(0.15, 0.08, 0.05), HORIZONTAL_ALIGNMENT_CENTER))
	left.add_child(_make_label("萌宠三对三拆窝赛", 22, Color(0.38, 0.20, 0.12), HORIZONTAL_ALIGNMENT_CENTER))
	left.add_child(_make_label("小鱼干 %d    已玩 %d 局" % [GameState.coins, GameState.matches_played], 18, Color(0.26, 0.15, 0.09), HORIZONTAL_ALIGNMENT_CENTER))

	var start_button := _make_button("开始拆窝")
	start_button.custom_minimum_size = Vector2(512, 70)
	start_button.add_theme_font_size_override("font_size", 30)
	start_button.add_theme_color_override("font_color", Color(1.0, 0.96, 0.86))
	start_button.add_theme_stylebox_override("normal", _button_style(Color(0.93, 0.35, 0.18)))
	start_button.add_theme_stylebox_override("hover", _button_style(Color(1.0, 0.45, 0.22)))
	start_button.add_theme_stylebox_override("pressed", _button_style(Color(0.73, 0.22, 0.13)))
	start_button.pressed.connect(func() -> void: _start(selected_team))
	left.add_child(start_button)

	left.add_child(_make_label("回车或空格也可以开始", 17, Color(0.35, 0.20, 0.12), HORIZONTAL_ALIGNMENT_CENTER))

	var team_row := HBoxContainer.new()
	team_row.add_theme_constant_override("separation", 10)
	left.add_child(team_row)

	var cat_button := _make_button("加入猫队")
	cat_button.toggle_mode = true
	cat_button.button_pressed = selected_team == "cat"
	cat_button.pressed.connect(func() -> void: _select_team("cat"))
	team_row.add_child(cat_button)

	var dog_button := _make_button("加入狗队")
	dog_button.toggle_mode = true
	dog_button.button_pressed = selected_team == "dog"
	dog_button.pressed.connect(func() -> void: _select_team("dog"))
	team_row.add_child(dog_button)

	left.add_child(_make_label("选择出战宠物", 22, Color(0.18, 0.10, 0.07), HORIZONTAL_ALIGNMENT_LEFT))

	for key in GameDataScript.team_pet_keys(selected_team):
		left.add_child(_make_pet_button(key))

	var difficulty_button := _make_button("难度：较难" if difficulty == "hard" else "难度：普通")
	difficulty_button.pressed.connect(func() -> void:
		difficulty = "hard" if difficulty == "normal" else "normal"
		difficulty_button.text = "难度：较难" if difficulty == "hard" else "难度：普通"
	)
	left.add_child(difficulty_button)

	var selected_data := GameDataScript.pet_data(selected_pet_key)
	var selected_level := GameState.get_pet_level(selected_pet_key)
	var selected_info := _make_label("%s  %d级  %s\n%s" % [
		selected_data.get("name", selected_pet_key),
		selected_level,
		selected_data.get("role", ""),
		selected_data.get("description", "")
	], 16, Color(0.31, 0.18, 0.11), HORIZONTAL_ALIGNMENT_LEFT)
	selected_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	selected_info.custom_minimum_size = Vector2(512, 70)
	left.add_child(selected_info)

	var upgrade_button := _make_button(_upgrade_text(selected_pet_key))
	upgrade_button.disabled = not GameState.can_upgrade(selected_pet_key)
	upgrade_button.pressed.connect(func() -> void:
		GameState.upgrade_pet(selected_pet_key)
		_build_menu()
	)
	left.add_child(upgrade_button)

	var preview_row := HBoxContainer.new()
	preview_row.add_theme_constant_override("separation", 18)
	right.add_child(preview_row)

	var avatar := TextureRect.new()
	avatar.texture = PET_TEXTURES.get(selected_pet_key)
	avatar.custom_minimum_size = Vector2(172, 172)
	avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_row.add_child(avatar)

	var preview_text := _make_label("今晚出战\n%s\n%s" % [
		selected_data.get("name", selected_pet_key),
		selected_data.get("description", "")
	], 20, Color(0.20, 0.11, 0.07), HORIZONTAL_ALIGNMENT_LEFT)
	preview_text.custom_minimum_size = Vector2(348, 172)
	preview_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_row.add_child(preview_text)

	right.add_child(_make_label("本局目标", 28, Color(0.18, 0.10, 0.07), HORIZONTAL_ALIGNMENT_LEFT))

	var rules := _make_label("1. 开局冲向客厅中场，抢到罐头炸弹。\n2. 抱着罐头炸弹闯进敌方宠物窝，拆掉一格耐久。\n3. 胶带卷只在自家受损时有用，罐头炸弹永远优先。\n4. 铃铛加速，抱枕盾护送，臭袜子可以丢出去减速。\n5. 先把对方宠物窝拆掉就赢。", 18, Color(0.25, 0.15, 0.10), HORIZONTAL_ALIGNMENT_LEFT)
	rules.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rules.custom_minimum_size = Vector2(540, 190)
	right.add_child(rules)

	var controls := _make_label("操作\n移动：W A S D 键或方向键\nJ 键 / 鼠标左键：拍打敌人，也能踢地上的道具\nK 键 / 鼠标右键：使用技能\nE 键：使用手上道具；臭袜子会投掷，罐头炸弹和胶带卷会放下", 17, Color(0.19, 0.27, 0.36), HORIZONTAL_ALIGNMENT_LEFT)
	controls.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controls.custom_minimum_size = Vector2(540, 150)
	right.add_child(controls)

	var result := _make_label("", 17, Color(0.24, 0.14, 0.09), HORIZONTAL_ALIGNMENT_LEFT)
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.custom_minimum_size = Vector2(540, 90)
	if GameState.last_match.is_empty():
		result.text = "还没有战绩。打一局后会获得小鱼干，用来给宠物升级。"
	else:
		var winner: String = GameState.last_match.get("winner", "draw")
		var reward: int = GameState.last_match.get("reward", 0)
		result.text = "上一局：%s\n奖励：+%d 小鱼干\n剩余耐久：猫窝 %d / 狗窝 %d" % [
			_winner_name(winner),
			reward,
			GameState.last_match.get("cat_score", 0),
			GameState.last_match.get("dog_score", 0)
		]
	right.add_child(result)


func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(250, 48)
	button.add_theme_font_override("font", UI_FONT)
	button.add_theme_font_size_override("font_size", 19)
	button.add_theme_color_override("font_color", Color(1.0, 0.96, 0.86))
	button.add_theme_stylebox_override("normal", _button_style(Color(0.40, 0.34, 0.25)))
	button.add_theme_stylebox_override("hover", _button_style(Color(0.52, 0.42, 0.28)))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.30, 0.24, 0.18)))
	return button


func _make_label(text: String, font_size: int, color: Color, alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = alignment
	label.add_theme_font_override("font", UI_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(1.0, 0.93, 0.74, 0.62))
	label.add_theme_constant_override("outline_size", 2)
	return label


func _panel_style(color: Color, border_color := Color(0.28, 0.17, 0.10, 0.42)) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = border_color
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 22
	style.content_margin_bottom = 22
	return style


func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _make_pet_button(key: String) -> Button:
	var data := GameDataScript.pet_data(key)
	var button := _make_button("%s  %d级  %s" % [
		data.get("name", key),
		GameState.get_pet_level(key),
		data.get("role", "")
	])
	button.icon = PET_TEXTURES.get(key)
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(512, 46)
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
		return "已满级"
	return "升级选中宠物  花费 %d 小鱼干" % cost


func _winner_name(winner: String) -> String:
	if winner == "cat":
		return "猫队胜"
	if winner == "dog":
		return "狗队胜"
	return "平局"


func _select_team(team: String) -> void:
	selected_team = team
	selected_pet_key = GameState.get_selected_pet(team)
	_build_menu()


func _start(team: String) -> void:
	GameState.start_match(team, difficulty, selected_pet_key)
	get_tree().change_scene_to_file("res://scenes/Battle.tscn")
