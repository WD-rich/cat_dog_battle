extends RefCounted
class_name GameData


static func team_pet_keys(team: String) -> Array:
	if team == "cat":
		return ["orange_cat", "calico_cat", "ragdoll_cat"]
	return ["shiba_dog", "corgi_dog", "husky_dog"]


static func pet_data(key: String) -> Dictionary:
	var all := {
		"orange_cat": {
			"key": "orange_cat",
			"name": "橘猫",
			"role": "近战",
			"body_color": Color(1.0, 0.54, 0.23),
			"accent_color": Color(1.0, 0.82, 0.32),
			"hp": 120.0,
			"speed": 235.0,
			"attack_damage": 18.0,
			"attack_range": 62.0,
			"attack_cooldown": 0.56,
			"skill_type": "dash",
			"skill_cooldown": 4.8,
			"description": "血厚能冲，适合正面抢罐头炸弹、硬闯敌方窝。",
		},
		"calico_cat": {
			"key": "calico_cat",
			"name": "三花",
			"role": "快跑",
			"body_color": Color(1.0, 0.78, 0.52),
			"accent_color": Color(0.37, 0.22, 0.16),
			"hp": 96.0,
			"speed": 290.0,
			"attack_damage": 15.0,
			"attack_range": 58.0,
			"attack_cooldown": 0.45,
			"skill_type": "sprint",
			"skill_cooldown": 5.0,
			"description": "速度最快，适合绕路偷罐头炸弹、快速拆窝。",
		},
		"ragdoll_cat": {
			"key": "ragdoll_cat",
			"name": "布偶",
			"role": "控场",
			"body_color": Color(0.78, 0.86, 1.0),
			"accent_color": Color(0.43, 0.36, 0.56),
			"hp": 106.0,
			"speed": 240.0,
			"attack_damage": 13.0,
			"attack_range": 86.0,
			"attack_cooldown": 0.64,
			"skill_type": "pulse",
			"skill_cooldown": 5.8,
			"description": "能把敌人推开，适合保护抱罐头炸弹的队友。",
		},
		"shiba_dog": {
			"key": "shiba_dog",
			"name": "柴犬",
			"role": "近战",
			"body_color": Color(0.94, 0.43, 0.18),
			"accent_color": Color(1.0, 0.89, 0.66),
			"hp": 112.0,
			"speed": 255.0,
			"attack_damage": 18.0,
			"attack_range": 64.0,
			"attack_cooldown": 0.54,
			"skill_type": "dash",
			"skill_cooldown": 4.6,
			"description": "均衡直接，适合冲阵、打断和反抢。",
		},
		"corgi_dog": {
			"key": "corgi_dog",
			"name": "柯基",
			"role": "护卫",
			"body_color": Color(0.95, 0.67, 0.28),
			"accent_color": Color(0.98, 0.92, 0.78),
			"hp": 135.0,
			"speed": 220.0,
			"attack_damage": 16.0,
			"attack_range": 58.0,
			"attack_cooldown": 0.58,
			"skill_type": "shield",
			"skill_cooldown": 6.2,
			"description": "血量高，能开盾护送罐头炸弹进敌方窝。",
		},
		"husky_dog": {
			"key": "husky_dog",
			"name": "哈士奇",
			"role": "快跑",
			"body_color": Color(0.52, 0.65, 0.77),
			"accent_color": Color(0.94, 0.97, 1.0),
			"hp": 100.0,
			"speed": 286.0,
			"attack_damage": 14.0,
			"attack_range": 64.0,
			"attack_cooldown": 0.43,
			"skill_type": "sprint",
			"skill_cooldown": 5.1,
			"description": "跑得快、节奏乱，适合突然偷家。",
		},
	}
	return all[key].duplicate()


static func pet_name(key: String) -> String:
	return pet_data(key).get("name", key)
