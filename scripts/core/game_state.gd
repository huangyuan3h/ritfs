class_name GameState
extends RefCounted

enum State { MENU, PLAYING, PAUSED, CUTSCENE, DIALOGUE }

var current_state: State = State.MENU
var previous_state: State = State.MENU

var current_level: int = 0
var unlocked_levels: Array[int] = [0]
var completed_levels: Array[int] = []

var player_choices: Dictionary = {}
var game_time: float = 0.0

func change_state(new_state: State) -> void:
    previous_state = current_state
    current_state = new_state

func is_state(state: State) -> bool:
    return current_state == state

func complete_level(level_id: int) -> void:
    if level_id not in completed_levels:
        completed_levels.append(level_id)
    if level_id + 1 not in unlocked_levels:
        unlocked_levels.append(level_id + 1)

func record_choice(choice_id: String, choice_value: Variant) -> void:
    player_choices[choice_id] = choice_value

func get_choice(choice_id: String, default: Variant = null) -> Variant:
    return player_choices.get(choice_id, default)

func to_dict() -> Dictionary:
    return {
        "current_level": current_level,
        "unlocked_levels": unlocked_levels,
        "completed_levels": completed_levels,
        "player_choices": player_choices,
        "game_time": game_time
    }

func from_dict(data: Dictionary) -> void:
    current_level = data.get("current_level", 0)
    unlocked_levels = data.get("unlocked_levels", [0])
    completed_levels = data.get("completed_levels", [])
    player_choices = data.get("player_choices", {})
    game_time = data.get("game_time", 0.0)