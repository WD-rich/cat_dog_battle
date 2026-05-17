extends Node

var player_team := "cat"
var difficulty := "normal"
var coins := 0
var last_match := {}


func start_match(team: String, selected_difficulty := "normal") -> void:
	player_team = team
	difficulty = selected_difficulty
	last_match = {}


func record_match(winner: String, cat_score: int, dog_score: int) -> void:
	last_match = {
		"winner": winner,
		"cat_score": cat_score,
		"dog_score": dog_score,
	}
	if winner == player_team:
		coins += 10
	else:
		coins += 3

