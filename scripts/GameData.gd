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
			"name": "Orange",
			"role": "Bruiser",
			"body_color": Color(1.0, 0.54, 0.23),
			"accent_color": Color(1.0, 0.82, 0.32),
			"hp": 120.0,
			"speed": 235.0,
			"attack_damage": 18.0,
			"attack_range": 62.0,
			"attack_cooldown": 0.56,
			"skill_type": "dash",
			"skill_cooldown": 4.8,
			"description": "A sturdy frontliner. Roll through fights and shove snacks forward.",
		},
		"calico_cat": {
			"key": "calico_cat",
			"name": "Calico",
			"role": "Runner",
			"body_color": Color(1.0, 0.78, 0.52),
			"accent_color": Color(0.37, 0.22, 0.16),
			"hp": 96.0,
			"speed": 290.0,
			"attack_damage": 15.0,
			"attack_range": 58.0,
			"attack_cooldown": 0.45,
			"skill_type": "sprint",
			"skill_cooldown": 5.0,
			"description": "Fast and slippery. Best at stealing snacks through side lanes.",
		},
		"ragdoll_cat": {
			"key": "ragdoll_cat",
			"name": "Ragdoll",
			"role": "Control",
			"body_color": Color(0.78, 0.86, 1.0),
			"accent_color": Color(0.43, 0.36, 0.56),
			"hp": 106.0,
			"speed": 240.0,
			"attack_damage": 13.0,
			"attack_range": 86.0,
			"attack_cooldown": 0.64,
			"skill_type": "pulse",
			"skill_cooldown": 5.8,
			"description": "A soft controller. Push enemies away to protect carriers.",
		},
		"shiba_dog": {
			"key": "shiba_dog",
			"name": "Shiba",
			"role": "Bruiser",
			"body_color": Color(0.94, 0.43, 0.18),
			"accent_color": Color(1.0, 0.89, 0.66),
			"hp": 112.0,
			"speed": 255.0,
			"attack_damage": 18.0,
			"attack_range": 64.0,
			"attack_cooldown": 0.54,
			"skill_type": "dash",
			"skill_cooldown": 4.6,
			"description": "Balanced and direct. Charge in, interrupt, and counterattack.",
		},
		"corgi_dog": {
			"key": "corgi_dog",
			"name": "Corgi",
			"role": "Guard",
			"body_color": Color(0.95, 0.67, 0.28),
			"accent_color": Color(0.98, 0.92, 0.78),
			"hp": 135.0,
			"speed": 220.0,
			"attack_damage": 16.0,
			"attack_range": 58.0,
			"attack_cooldown": 0.58,
			"skill_type": "shield",
			"skill_cooldown": 6.2,
			"description": "A compact guard. Shield up and escort snacks into danger.",
		},
		"husky_dog": {
			"key": "husky_dog",
			"name": "Husky",
			"role": "Runner",
			"body_color": Color(0.52, 0.65, 0.77),
			"accent_color": Color(0.94, 0.97, 1.0),
			"hp": 100.0,
			"speed": 286.0,
			"attack_damage": 14.0,
			"attack_range": 64.0,
			"attack_cooldown": 0.43,
			"skill_type": "sprint",
			"skill_cooldown": 5.1,
			"description": "Fast and chaotic. Great at surprise deliveries.",
		},
	}
	return all[key].duplicate()


static func pet_name(key: String) -> String:
	return pet_data(key).get("name", key)

