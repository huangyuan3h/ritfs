extends Node

var current_dialogue: Dictionary = {}
var current_line_index: int = 0
var is_dialogue_active: bool = false

signal dialogue_started(dialogue_id: String)
signal dialogue_line_displayed(speaker: String, text: String, choices: Array)
signal dialogue_ended()

var dialogues: Dictionary = {}

func _ready() -> void:
    load_dialogues()

func load_dialogues() -> void:
    var dialogue_path: String = "res://resources/data/dialogues/"
    var dir: DirAccess = DirAccess.open(dialogue_path)
    
    if dir == null:
        return
    
    dir.list_dir_begin()
    var file_name: String = dir.get_next()
    
    while file_name != "":
        if not dir.current_is_dir() and file_name.ends_with(".json"):
            var file: FileAccess = FileAccess.open(dialogue_path + file_name, FileAccess.READ)
            if file:
                var json: JSON = JSON.new()
                if json.parse(file.get_as_text()) == OK:
                    var dialogue_data: Dictionary = json.data
                    dialogues.merge(dialogue_data)
                file.close()
        file_name = dir.get_next()
    
    dir.list_dir_end()

func start_dialogue(dialogue_id: String) -> void:
    if not dialogues.has(dialogue_id):
        push_error("Dialogue not found: %s" % dialogue_id)
        return
    
    current_dialogue = dialogues[dialogue_id]
    current_line_index = 0
    is_dialogue_active = true
    
    GameManager.change_state(GameState.State.DIALOGUE)
    dialogue_started.emit(dialogue_id)
    
    display_current_line()

func display_current_line() -> void:
    if current_dialogue.is_empty():
        end_dialogue()
        return
    
    var lines: Array = current_dialogue.get("lines", [])
    
    if current_line_index >= lines.size():
        end_dialogue()
        return
    
    var current_line: Dictionary = lines[current_line_index]
    var speaker: String = current_line.get("speaker", "Unknown")
    var text: String = current_line.get("text", "")
    var choices: Array = current_line.get("choices", [])
    
    dialogue_line_displayed.emit(speaker, text, choices)

func advance_dialogue() -> void:
    if not is_dialogue_active:
        return
    
    current_line_index += 1
    display_current_line()

func select_choice(choice_index: int) -> void:
    if not is_dialogue_active:
        return
    
    var lines: Array = current_dialogue.get("lines", [])
    var current_line: Dictionary = lines[current_line_index]
    var choices: Array = current_line.get("choices", [])
    
    if choice_index < 0 or choice_index >= choices.size():
        return
    
    var selected_choice: Dictionary = choices[choice_index]
    var choice_id: String = selected_choice.get("id", "")
    var next_dialogue: String = selected_choice.get("next_dialogue", "")
    var consequence: String = selected_choice.get("consequence", "")
    
    if not choice_id.is_empty():
        GameManager.game_state.record_choice(choice_id, true)
    
    if not consequence.is_empty():
        apply_consequence(consequence)
    
    if not next_dialogue.is_empty():
        start_dialogue(next_dialogue)
    else:
        advance_dialogue()

func apply_consequence(consequence_id: String) -> void:
    pass

func end_dialogue() -> void:
    current_dialogue = {}
    current_line_index = 0
    is_dialogue_active = false
    
    dialogue_ended.emit()
    GameManager.change_state(GameState.State.PLAYING)

func is_active() -> bool:
    return is_dialogue_active