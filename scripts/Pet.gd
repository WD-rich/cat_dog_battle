extends CharacterBody2D
class_name BattlePet

signal knocked_out(pet: BattlePet)
signal respawned(pet: BattlePet)

var battle: Node = null
var pet_key := "orange_cat"
var display_name := "Pet"
var team := "cat"
var role := "striker"
var is_player := false
var level := 1

var body_color := Color(1.0, 0.62, 0.26)
var accent_color := Color(1.0, 0.88, 0.44)
var max_hp := 100.0
var hp := 100.0
var move_speed := 250.0
var attack_damage := 18.0
var attack_range := 62.0
var attack_cooldown := 0.55
var skill_type := "dash"
var skill_cooldown_max := 5.0

var desired_move := Vector2.ZERO
var aim_direction := Vector2.RIGHT
var carried_item: Node = null
var home_base: Node = null
var target_base: Node = null

var attack_timer := 0.0
var skill_timer := 0.0
var shield_timer := 0.0
var speed_timer := 0.0
var slow_timer := 0.0
var dash_timer := 0.0
var respawn_timer := 0.0
var speed_multiplier := 1.0
var slow_multiplier := 1.0
var knock_velocity := Vector2.ZERO
var dash_velocity := Vector2.ZERO
var defeated := false
var dash_hit_targets: Array = []
var ai_target_position := Vector2.ZERO
var ai_think_timer := 0.0

var _shape: CollisionShape2D
var _name_label: Label
var _sprite: Sprite2D

const PET_TEXTURES := {
	"orange_cat": preload("res://assets/visuals/pet_orange_cat.svg"),
	"calico_cat": preload("res://assets/visuals/pet_calico_cat.svg"),
	"ragdoll_cat": preload("res://assets/visuals/pet_ragdoll_cat.svg"),
	"shiba_dog": preload("res://assets/visuals/pet_shiba_dog.svg"),
	"corgi_dog": preload("res://assets/visuals/pet_corgi_dog.svg"),
	"husky_dog": preload("res://assets/visuals/pet_husky_dog.svg"),
}


func setup(data: Dictionary, pet_team: String, player_controlled: bool, ai_role: String, pet_battle: Node) -> void:
	battle = pet_battle
	pet_key = data.get("key", pet_key)
	display_name = data.get("name", display_name)
	team = pet_team
	is_player = player_controlled
	role = ai_role
	body_color = data.get("body_color", body_color)
	accent_color = data.get("accent_color", accent_color)
	max_hp = data.get("hp", max_hp)
	hp = max_hp
	move_speed = data.get("speed", move_speed)
	attack_damage = data.get("attack_damage", attack_damage)
	attack_range = data.get("attack_range", attack_range)
	attack_cooldown = data.get("attack_cooldown", attack_cooldown)
	skill_type = data.get("skill_type", skill_type)
	skill_cooldown_max = data.get("skill_cooldown", skill_cooldown_max)


func apply_level(pet_level: int) -> void:
	level = max(1, pet_level)
	if level <= 1:
		return
	var bonus := float(level - 1)
	max_hp += bonus * 8.0
	hp = max_hp
	move_speed += bonus * 5.0
	attack_damage += bonus * 1.5


func _ready() -> void:
	_shape = CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 27.0
	_shape.shape = circle
	add_child(_shape)

	_sprite = Sprite2D.new()
	_sprite.texture = PET_TEXTURES.get(pet_key)
	_sprite.scale = Vector2(0.62, 0.62)
	_sprite.position = Vector2(0, 5)
	_sprite.visible = false
	add_child(_sprite)

	_name_label = Label.new()
	_name_label.text = display_name
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 12)
	_name_label.add_theme_color_override("font_color", Color(0.13, 0.09, 0.07))
	_name_label.position = Vector2(-58, -64)
	_name_label.size = Vector2(116, 20)
	add_child(_name_label)
	_update_label()


func _physics_process(delta: float) -> void:
	_tick_timers(delta)

	if defeated:
		respawn_timer -= delta
		velocity = Vector2.ZERO
		if respawn_timer <= 0.0:
			_respawn()
		queue_redraw()
		return

	var speed := move_speed * speed_multiplier * slow_multiplier
	var intended := desired_move.normalized() * speed
	if dash_timer > 0.0:
		intended = dash_velocity
	velocity = intended + knock_velocity
	move_and_slide()

	knock_velocity = knock_velocity.move_toward(Vector2.ZERO, 900.0 * delta)
	if battle != null:
		global_position = battle.clamp_to_map(global_position)
	_update_visual_direction()
	queue_redraw()


func _tick_timers(delta: float) -> void:
	attack_timer = max(0.0, attack_timer - delta)
	skill_timer = max(0.0, skill_timer - delta)
	shield_timer = max(0.0, shield_timer - delta)
	speed_timer = max(0.0, speed_timer - delta)
	slow_timer = max(0.0, slow_timer - delta)
	dash_timer = max(0.0, dash_timer - delta)
	if speed_timer <= 0.0:
		speed_multiplier = 1.0
	if slow_timer <= 0.0:
		slow_multiplier = 1.0
	if dash_timer <= 0.0:
		dash_hit_targets.clear()


func try_attack() -> bool:
	if defeated or attack_timer > 0.0 or battle == null:
		return false
	attack_timer = attack_cooldown
	return battle.pet_attack(self)


func try_skill() -> bool:
	if defeated or skill_timer > 0.0 or battle == null:
		return false
	skill_timer = skill_cooldown_max

	if skill_type == "shield":
		add_shield(2.8)
		battle.area_burst(self, 72.0, 8.0, 280.0)
	elif skill_type == "pulse":
		battle.area_burst(self, 96.0, 16.0, 390.0)
	elif skill_type == "sprint":
		add_speed_boost(2.4)
		battle.area_burst(self, 54.0, 7.0, 260.0)
	else:
		var dir := aim_direction.normalized()
		if dir.length() < 0.1:
			dir = Vector2.RIGHT if team == "cat" else Vector2.LEFT
		dash_velocity = dir * 780.0
		dash_timer = 0.26
		dash_hit_targets.clear()
	return true


func take_damage(amount: float, impulse: Vector2, source: Node = null) -> void:
	if defeated:
		return
	var final_damage := amount
	var impulse_scale := 1.0
	if shield_timer > 0.0:
		final_damage *= 0.35
		impulse_scale = 0.35
	hp -= final_damage
	knock_velocity += impulse * impulse_scale
	if carried_item != null and shield_timer <= 0.0:
		carried_item.drop(global_position + impulse.normalized() * 24.0)
	if hp <= 0.0:
		_knock_out()
	queue_redraw()


func add_shield(duration: float) -> void:
	shield_timer = max(shield_timer, duration)
	queue_redraw()


func add_speed_boost(duration: float) -> void:
	speed_timer = max(speed_timer, duration)
	speed_multiplier = 1.45
	queue_redraw()


func add_slow(duration: float) -> void:
	slow_timer = max(slow_timer, duration)
	slow_multiplier = 0.52
	queue_redraw()


func drop_or_throw_carried() -> void:
	if carried_item == null:
		return
	if carried_item.kind == "sock":
		carried_item.throw_from(self, aim_direction)
	else:
		carried_item.drop(global_position + aim_direction.normalized() * 36.0, 0.7)


func _knock_out() -> void:
	defeated = true
	respawn_timer = battle.get_respawn_time(team) if battle != null else 3.0
	if carried_item != null:
		carried_item.drop(global_position)
	_shape.disabled = true
	modulate = Color(1, 1, 1, 0.48)
	knocked_out.emit(self)


func _respawn() -> void:
	defeated = false
	hp = max_hp
	_shape.disabled = false
	modulate = Color.WHITE
	if home_base != null:
		var offset := Vector2(90, 0) if team == "cat" else Vector2(-90, 0)
		global_position = home_base.global_position + offset.rotated(randf_range(-0.5, 0.5))
	respawned.emit(self)


func _update_label() -> void:
	if _name_label == null:
		return
	var prefix := "P " if is_player else ""
	var suffix := " Lv.%d" % level if is_player else ""
	_name_label.text = prefix + display_name + suffix


func _draw() -> void:
	var alpha := 0.52 if defeated else 1.0
	var outline := Color(0.17, 0.10, 0.08, alpha)
	var body := Color(body_color.r, body_color.g, body_color.b, alpha)
	var accent := Color(accent_color.r, accent_color.g, accent_color.b, alpha)
	var has_sprite := _sprite != null and _sprite.texture != null

	draw_circle(Vector2(4, 12), 30, Color(0, 0, 0, 0.16 * alpha))

	if has_sprite:
		draw_texture_rect(_sprite.texture, Rect2(Vector2(-43, -48), Vector2(86, 86)), false, Color(1, 1, 1, alpha))
	else:
		if team == "cat":
			draw_polygon(PackedVector2Array([Vector2(-25, -18), Vector2(-17, -42), Vector2(-3, -21)]), PackedColorArray([body, body, body]))
			draw_polygon(PackedVector2Array([Vector2(25, -18), Vector2(17, -42), Vector2(3, -21)]), PackedColorArray([body, body, body]))
			draw_polyline(PackedVector2Array([Vector2(-25, -18), Vector2(-17, -42), Vector2(-3, -21)]), outline, 3.0)
			draw_polyline(PackedVector2Array([Vector2(25, -18), Vector2(17, -42), Vector2(3, -21)]), outline, 3.0)
		else:
			draw_polygon(PackedVector2Array([Vector2(-22, -22), Vector2(-43, -30), Vector2(-37, 12), Vector2(-18, 9)]), PackedColorArray([accent, accent, accent, accent]))
			draw_polygon(PackedVector2Array([Vector2(22, -22), Vector2(43, -30), Vector2(37, 12), Vector2(18, 9)]), PackedColorArray([accent, accent, accent, accent]))
			draw_polyline(PackedVector2Array([Vector2(-22, -22), Vector2(-43, -30), Vector2(-37, 12), Vector2(-18, 9)]), outline, 3.0)
			draw_polyline(PackedVector2Array([Vector2(22, -22), Vector2(43, -30), Vector2(37, 12), Vector2(18, 9)]), outline, 3.0)

		draw_circle(Vector2.ZERO, 29, body)
		draw_circle(Vector2.ZERO, 29, outline, false, 3.0)
		draw_circle(Vector2(-10, -5), 4, outline)
		draw_circle(Vector2(10, -5), 4, outline)
		draw_circle(Vector2(0, 5), 3, outline)
		draw_arc(Vector2(0, 10), 10, 0.15, PI - 0.15, 18, outline, 2.0)

	if is_player:
		draw_circle(Vector2.ZERO, 35, Color(1.0, 0.95, 0.30, 0.32), false, 4.0)

	if shield_timer > 0.0:
		draw_circle(Vector2.ZERO, 38, Color(0.40, 0.70, 1.0, 0.28), false, 5.0)

	var bar_width := 58.0
	var hp_ratio := clamp(hp / max_hp, 0.0, 1.0)
	_draw_filled_rect(Rect2(Vector2(-bar_width / 2.0, -54), Vector2(bar_width, 7)), Color(0.18, 0.11, 0.09, 0.85))
	_draw_filled_rect(Rect2(Vector2(-bar_width / 2.0 + 1, -53), Vector2((bar_width - 2) * hp_ratio, 5)), Color(0.30, 0.95, 0.38))

	if carried_item != null:
		draw_line(Vector2(0, -28), Vector2(0, -40), outline, 2.0)


func _draw_filled_rect(rect: Rect2, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		rect.position,
		rect.position + Vector2(rect.size.x, 0),
		rect.position + rect.size,
		rect.position + Vector2(0, rect.size.y),
	]), color)


func _update_visual_direction() -> void:
	if _sprite == null:
		return
	var facing := 1.0
	if aim_direction.x < -0.1:
		facing = -1.0
	elif aim_direction.x > 0.1:
		facing = 1.0
	_sprite.scale.x = abs(_sprite.scale.x) * facing
