extends Node

var player_team := "cat"
var difficulty := "normal"
var coins := 0
var last_match := {}
var matches_played := 0

var selected_pets := {
	"cat": "orange_cat",
	"dog": "shiba_dog",
}

var pet_levels := {
	"orange_cat": 1,
	"calico_cat": 1,
	"ragdoll_cat": 1,
	"shiba_dog": 1,
	"corgi_dog": 1,
	"husky_dog": 1,
}


func start_match(team: String, selected_difficulty := "normal", pet_key := "") -> void:
	player_team = team
	difficulty = selected_difficulty
	if pet_key != "":
		select_pet(team, pet_key)
	last_match = {}


func select_pet(team: String, pet_key: String) -> void:
	selected_pets[team] = pet_key


func get_selected_pet(team: String) -> String:
	return selected_pets.get(team, "orange_cat" if team == "cat" else "shiba_dog")


func get_pet_level(pet_key: String) -> int:
	return int(pet_levels.get(pet_key, 1))


func get_upgrade_cost(pet_key: String) -> int:
	var level := get_pet_level(pet_key)
	if level >= 3:
		return -1
	return level * 10


func can_upgrade(pet_key: String) -> bool:
	var cost := get_upgrade_cost(pet_key)
	return cost > 0 and coins >= cost


func upgrade_pet(pet_key: String) -> bool:
	if not can_upgrade(pet_key):
		return false
	var cost := get_upgrade_cost(pet_key)
	coins -= cost
	pet_levels[pet_key] = get_pet_level(pet_key) + 1
	return true


func record_match(winner: String, cat_score: int, dog_score: int, duration: float) -> int:
	var reward := 4
	if winner == player_team:
		reward = 12
	elif winner == "draw":
		reward = 6
	coins += reward
	matches_played += 1
	last_match = {
		"winner": winner,
		"cat_score": cat_score,
		"dog_score": dog_score,
		"duration": duration,
		"reward": reward,
	}
	return reward
