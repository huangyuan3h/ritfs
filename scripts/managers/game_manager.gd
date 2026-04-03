extends Node

const SAVE_PATH: String = "user://savegame.dat"

var game_state: GameState = GameState.new()
var is_initialized: bool = false

signal state_changed(new_state: GameState.State)
signal level_completed(level_id: int)
signal game_saved()
signal game_loaded()

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    is_initialized = true

func _process(delta: float) -> void:
    if game_state.is_state(GameState.State.PLAYING):
        game_state.game_time += delta

func change_state(new_state: GameState.State) -> void:
    game_state.change_state(new_state)
    state_changed.emit(new_state)
    
    match new_state:
        GameState.State.PAUSED:
            get_tree().paused = true
        GameState.State.PLAYING:
            get_tree().paused = false

func start_new_game() -> void:
    game_state = GameState.new()
    change_state(GameState.State.PLAYING)
    load_level(0)

func load_level(level_id: int) -> void:
    if level_id not in game_state.unlocked_levels:
        push_error("Level %d is locked" % level_id)
        return
    
    game_state.current_level = level_id
    var level_path: String = "res://scenes/levels/level_%d.tscn" % level_id
    
    if ResourceLoader.exists(level_path):
        get_tree().change_scene_to_file(level_path)
    else:
        push_error("Level scene not found: %s" % level_path)

func complete_current_level() -> void:
    game_state.complete_level(game_state.current_level)
    level_completed.emit(game_state.current_level)

func save_game() -> bool:
    var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        push_error("Failed to open save file")
        return false
    
    var json_string: String = JSON.stringify(game_state.to_dict())
    file.store_string(json_string)
    file.close()
    
    game_saved.emit()
    return true

func load_game() -> bool:
    if not FileAccess.file_exists(SAVE_PATH):
        return false
    
    var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        push_error("Failed to open save file")
        return false
    
    var json_string: String = file.get_as_text()
    file.close()
    
    var json: JSON = JSON.new()
    if json.parse(json_string) != OK:
        push_error("Failed to parse save file")
        return false
    
    game_state.from_dict(json.data)
    game_loaded.emit()
    return true

func delete_save() -> void:
    if FileAccess.file_exists(SAVE_PATH):
        DirAccess.remove_absolute(SAVE_PATH)

func has_save() -> bool:
    return FileAccess.file_exists(SAVE_PATH)

func pause_game() -> void:
    change_state(GameState.State.PAUSED)

func resume_game() -> void:
    change_state(GameState.State.PLAYING)

func quit_to_menu() -> void:
    change_state(GameState.State.MENU)
    get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")