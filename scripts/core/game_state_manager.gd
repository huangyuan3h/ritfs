extends Node

const SAVE_DIR: String = "user://saves/"
const CURRENT_VERSION: String = "1.0.0"

var state: Dictionary = {}
var current_slot: int = 0
var is_dirty: bool = false

signal state_changed(path: String, value: Variant)
signal state_saved(slot: int)
signal state_loaded(slot: int)

func _ready() -> void:
    initialize_default_state()
    ensure_save_directory()

func initialize_default_state() -> void:
    state = {
        "meta": create_meta(),
        "game": create_default_game(),
        "player": create_default_player(),
        "progress": create_default_progress(),
        "narrative": create_default_narrative(),
        "choices": create_default_choices(),
        "agents": create_default_agents(),
        "settings": create_default_settings(),
        "world": create_default_world()
    }

func get_state(path: String = "", default: Variant = null) -> Variant:
    if path.is_empty():
        return state
    
    var keys: Array = path.split(".")
    var current: Variant = state
    
    for key in keys:
        if current is Dictionary and current.has(key):
            current = current[key]
        else:
            return default
    
    return current

func set_state(path: String, value: Variant) -> void:
    var keys: Array = path.split(".")
    var current: Dictionary = state
    
    for i in range(keys.size() - 1):
        var key: String = keys[i]
        if not current.has(key):
            current[key] = {}
        current = current[key]
    
    current[keys[-1]] = value
    is_dirty = true
    state_changed.emit(path, value)

func dispatch(action: String, payload: Dictionary = {}) -> void:
    match action:
        "PLAYER_MOVE":
            set_state("player.position", payload.get("position", [0, 0]))
        
        "PLAYER_MORAL_CHANGE":
            var current_score: float = get_state("player.moral_score", 0.0)
            set_state("player.moral_score", current_score + payload.get("delta", 0.0))
        
        "CHOICE_MAKE":
            add_choice_to_history(payload)
        
        "LEVEL_COMPLETE":
            complete_level(payload.get("level_id", 0))
        
        "ITEM_ADD":
            add_item_to_inventory(payload)
        
        "ITEM_REMOVE":
            remove_item_from_inventory(payload)
        
        "DIALOGUE_START":
            set_state("narrative.current_dialogue", payload.get("dialogue_id"))
        
        "DIALOGUE_END":
            set_state("narrative.current_dialogue", null)
            add_dialogue_to_history(payload)
        
        "RELATIONSHIP_UPDATE":
            update_relationship(payload.get("character_id"), payload.get("delta", 0.0))
        
        "FACT_LEARN":
            learn_fact(payload.get("fact_key"), payload.get("fact_value"))
        
        "WORLD_EVENT_TRIGGER":
            trigger_world_event(payload)
        
        "WORLD_STATE_UPDATE":
            update_world_state(payload.get("key"), payload.get("value"))
        
        "GAME_SAVE":
            save_game(payload.get("slot", 1))
        
        "GAME_LOAD":
            load_game(payload.get("slot", 1))
        
        "GAME_TIME_UPDATE":
            var current_time: float = get_state("game.game_time", 0.0)
            set_state("game.game_time", current_time + payload.get("delta", 0.0))
        
        "SCENE_CHANGE":
            set_state("game.current_scene", payload.get("scene"))
            set_state("game.current_state", payload.get("state", "PLAYING"))

func save_game(slot: int = 1) -> bool:
    update_meta()
    
    var file_path: String = SAVE_DIR + "slot_%03d.json" % slot
    var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
    
    if file == null:
        push_error("Failed to open save file: " + file_path)
        return false
    
    var json_string: String = JSON.stringify(state, "  ")
    file.store_string(json_string)
    file.close()
    
    current_slot = slot
    is_dirty = false
    state_saved.emit(slot)
    
    return true

func load_game(slot: int = 1) -> bool:
    var file_path: String = SAVE_DIR + "slot_%03d.json" % slot
    
    if not FileAccess.file_exists(file_path):
        push_error("Save file not found: " + file_path)
        return false
    
    var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
    
    if file == null:
        push_error("Failed to open save file: " + file_path)
        return false
    
    var json_string: String = file.get_as_text()
    file.close()
    
    var json: JSON = JSON.new()
    if json.parse(json_string) != OK:
        push_error("Failed to parse save file")
        return false
    
    state = json.data
    current_slot = slot
    is_dirty = false
    state_loaded.emit(slot)
    
    return true

func has_save(slot: int = 1) -> bool:
    var file_path: String = SAVE_DIR + "slot_%03d.json" % slot
    return FileAccess.file_exists(file_path)

func delete_save(slot: int = 1) -> bool:
    var file_path: String = SAVE_DIR + "slot_%03d.json" % slot
    
    if FileAccess.file_exists(file_path):
        var error: int = DirAccess.remove_absolute(file_path)
        return error == OK
    
    return false

func get_save_info(slot: int = 1) -> Dictionary:
    if not has_save(slot):
        return {}
    
    var file_path: String = SAVE_DIR + "slot_%03d.json" % slot
    var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
    
    if file == null:
        return {}
    
    var json_string: String = file.get_as_text()
    file.close()
    
    var json: JSON = JSON.new()
    if json.parse(json_string) != OK:
        return {}
    
    var data: Dictionary = json.data
    
    return {
        "slot": slot,
        "created_at": data.get("meta", {}).get("created_at", "Unknown"),
        "updated_at": data.get("meta", {}).get("updated_at", "Unknown"),
        "play_time": data.get("meta", {}).get("play_time", 0),
        "current_level": data.get("progress", {}).get("current_level", 0),
        "moral_score": data.get("player", {}).get("moral_score", 0.0),
        "total_choices": data.get("choices", {}).get("total_choices", 0)
    }

func list_all_saves() -> Array[Dictionary]:
    var saves: Array[Dictionary] = []
    
    if not DirAccess.dir_exists_absolute(SAVE_DIR):
        return saves
    
    var dir: DirAccess = DirAccess.open(SAVE_DIR)
    dir.list_dir_begin()
    
    var file_name: String = dir.get_next()
    while file_name != "":
        if not dir.current_is_dir() and file_name.ends_with(".json"):
            var slot: int = file_name.replace("slot_", "").replace(".json", "").to_int()
            if slot > 0:
                saves.append(get_save_info(slot))
        file_name = dir.get_next()
    
    dir.list_dir_end()
    return saves

func update_meta() -> void:
    set_state("meta.updated_at", Time.get_datetime_string_from_system())
    set_state("meta.version", CURRENT_VERSION)
    
    var play_time: int = get_state("meta.play_time", 0)
    set_state("meta.play_time", play_time + 1)

func ensure_save_directory() -> void:
    if not DirAccess.dir_exists_absolute(SAVE_DIR):
        DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func create_meta() -> Dictionary:
    return {
        "version": CURRENT_VERSION,
        "created_at": Time.get_datetime_string_from_system(),
        "updated_at": Time.get_datetime_string_from_system(),
        "play_time": 0,
        "save_slot": 1
    }

func create_default_game() -> Dictionary:
    return {
        "current_scene": "main_menu",
        "current_state": "MENU",
        "difficulty": "NORMAL",
        "game_time": 0.0
    }

func create_default_player() -> Dictionary:
    return {
        "id": "player_001",
        "name": "旅行者",
        "position": [0.0, 0.0],
        "rotation": 0.0,
        "health": 100,
        "moral_score": 0.0,
        "inventory": []
    }

func create_default_progress() -> Dictionary:
    return {
        "current_level": 0,
        "unlocked_levels": [0],
        "completed_levels": [],
        "achievements": []
    }

func create_default_narrative() -> Dictionary:
    return {
        "current_dialogue": null,
        "dialogue_history": [],
        "known_facts": {},
        "relationships": {}
    }

func create_default_choices() -> Dictionary:
    return {
        "total_choices": 0,
        "moral_choices": {
            "altruistic": 0,
            "selfish": 0,
            "neutral": 0
        },
        "choice_history": []
    }

func create_default_agents() -> Dictionary:
    return {
        "active_agents": [],
        "agent_states": {}
    }

func create_default_settings() -> Dictionary:
    return {
        "audio": {
            "master_volume": 1.0,
            "music_volume": 0.7,
            "sfx_volume": 0.8,
            "voice_volume": 1.0
        },
        "graphics": {
            "quality": "HIGH",
            "vsync": true,
            "fullscreen": false
        },
        "controls": {
            "voice_enabled": false,
            "language": "zh-CN"
        }
    }

func create_default_world() -> Dictionary:
    return {
        "time_of_day": 0.5,
        "weather": "clear",
        "active_events": [],
        "world_state": {}
    }

func add_choice_to_history(choice_data: Dictionary) -> void:
    var history: Array = get_state("choices.choice_history", [])
    history.append({
        "id": choice_data.get("id", "choice_%d" % history.size()),
        "scenario": choice_data.get("scenario"),
        "choice": choice_data.get("choice"),
        "moral_impact": choice_data.get("moral_impact", 0.0),
        "timestamp": get_state("game.game_time", 0.0)
    })
    set_state("choices.choice_history", history)
    
    var total: int = get_state("choices.total_choices", 0)
    set_state("choices.total_choices", total + 1)
    
    var moral_type: String = choice_data.get("moral_type", "neutral")
    var moral_key: String = "choices.moral_choices.%s" % moral_type
    var moral_count: int = get_state(moral_key, 0)
    set_state(moral_key, moral_count + 1)

func complete_level(level_id: int) -> void:
    var completed: Array = get_state("progress.completed_levels", [])
    if level_id not in completed:
        completed.append(level_id)
        set_state("progress.completed_levels", completed)
    
    var unlocked: Array = get_state("progress.unlocked_levels", [])
    var next_level: int = level_id + 1
    if next_level not in unlocked:
        unlocked.append(next_level)
        set_state("progress.unlocked_levels", unlocked)
    
    set_state("progress.current_level", level_id + 1)

func add_item_to_inventory(item_data: Dictionary) -> void:
    var inventory: Array = get_state("player.inventory", [])
    var item_id: String = item_data.get("id", "")
    
    for item in inventory:
        if item.get("id") == item_id:
            item["count"] = item.get("count", 1) + item_data.get("count", 1)
            return
    
    inventory.append(item_data)
    set_state("player.inventory", inventory)

func remove_item_from_inventory(item_data: Dictionary) -> bool:
    var inventory: Array = get_state("player.inventory", [])
    var item_id: String = item_data.get("id", "")
    var count_to_remove: int = item_data.get("count", 1)
    
    for i in range(inventory.size()):
        var item: Dictionary = inventory[i]
        if item.get("id") == item_id:
            var current_count: int = item.get("count", 1)
            if current_count <= count_to_remove:
                inventory.remove_at(i)
            else:
                item["count"] = current_count - count_to_remove
            
            set_state("player.inventory", inventory)
            return true
    
    return false

func add_dialogue_to_history(dialogue_data: Dictionary) -> void:
    var history: Array = get_state("narrative.dialogue_history", [])
    history.append({
        "dialogue_id": dialogue_data.get("dialogue_id"),
        "timestamp": get_state("game.game_time", 0.0),
        "choices": dialogue_data.get("choices", []),
        "selected": dialogue_data.get("selected")
    })
    set_state("narrative.dialogue_history", history)

func update_relationship(character_id: String, delta: float) -> void:
    var relationships: Dictionary = get_state("narrative.relationships", {})
    if not relationships.has(character_id):
        relationships[character_id] = 0.0
    relationships[character_id] = clamp(relationships[character_id] + delta, -100.0, 100.0)
    set_state("narrative.relationships", relationships)

func learn_fact(fact_key: String, fact_value: Variant) -> void:
    var facts: Dictionary = get_state("narrative.known_facts", {})
    facts[fact_key] = fact_value
    set_state("narrative.known_facts", facts)

func trigger_world_event(event_data: Dictionary) -> void:
    var events: Array = get_state("world.active_events", [])
    events.append(event_data.get("event_id"))
    set_state("world.active_events", events)

func update_world_state(key: String, value: Variant) -> void:
    var world_state: Dictionary = get_state("world.world_state", {})
    world_state[key] = value
    set_state("world.world_state", world_state)

func autosave() -> void:
    var autosave_path: String = SAVE_DIR + "autosave.json"
    
    update_meta()
    
    var file: FileAccess = FileAccess.open(autosave_path, FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(state, "  "))
        file.close()

func quick_save() -> void:
    save_game(0)

func quick_load() -> bool:
    return load_game(0)