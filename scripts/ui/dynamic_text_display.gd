class_name DynamicTextDisplay
extends Control

@onready var text_display: RichTextLabel = $PanelContainer/VBoxContainer/TextDisplay if has_node("PanelContainer/VBoxContainer/TextDisplay") else null
@onready var speaker_label: Label = $PanelContainer/VBoxContainer/SpeakerLabel if has_node("PanelContainer/VBoxContainer/SpeakerLabel") else null
@onready var choices_container: VBoxContainer = $PanelContainer/VBoxContainer/ChoicesContainer if has_node("PanelContainer/VBoxContainer/ChoicesContainer") else null
@onready var continue_hint: Label = $PanelContainer/VBoxContainer/ContinueHint if has_node("PanelContainer/VBoxContainer/ContinueHint") else null

var display_speed: float = 25.0
var current_text: String = ""
var displayed_chars: int = 0
var is_displaying: bool = false
var typewriter_sound_enabled: bool = true

signal text_display_complete()
signal choice_selected(choice_index: int)

func _ready() -> void:
    visible = false
    DialogueManager.dialogue_started.connect(_on_dialogue_started)
    DialogueManager.dialogue_line_displayed.connect(_on_line_displayed)
    DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

func _process(delta: float) -> void:
    if not is_displaying or text_display == null:
        return
    
    if displayed_chars < current_text.length():
        var chars_to_add: int = int(display_speed * delta)
        
        for i in range(chars_to_add):
            if displayed_chars >= current_text.length():
                break
            
            displayed_chars += 1
            text_display.text = current_text.substr(0, displayed_chars)
            
            if typewriter_sound_enabled and displayed_chars % 4 == 0:
                play_typewriter_click()
        
        if displayed_chars >= current_text.length():
            is_displaying = false
            text_display_complete.emit()

func display_text(text: String) -> void:
    current_text = text
    displayed_chars = 0
    is_displaying = true
    
    if text_display:
        text_display.text = ""
    
    if continue_hint:
        continue_hint.visible = false

func skip_to_end() -> void:
    if text_display and is_displaying:
        text_display.text = current_text
        displayed_chars = current_text.length()
        is_displaying = false
        text_display_complete.emit()

func _on_dialogue_started(_dialogue_id: String) -> void:
    visible = true

func _on_line_displayed(speaker: String, text: String, choices: Array) -> void:
    if speaker_label:
        speaker_label.text = speaker
    
    display_text(text)
    
    if choices_container:
        for child in choices_container.get_children():
            child.queue_free()
    
    if choices.is_empty():
        if continue_hint:
            continue_hint.visible = true
            continue_hint.text = "[按E继续]"
    else:
        if continue_hint:
            continue_hint.visible = false
        
        for i in range(choices.size()):
            var choice: Dictionary = choices[i]
            var choice_text: String = choice.get("text", "选项 %d" % (i + 1))
            
            var button: Button = Button.new()
            button.text = "[%d] %s" % [i + 1, choice_text]
            button.pressed.connect(_on_choice_button_pressed.bind(i))
            
            if choices_container:
                choices_container.add_child(button)

func _on_dialogue_ended() -> void:
    visible = false

func _on_choice_button_pressed(choice_index: int) -> void:
    choice_selected.emit(choice_index)
    DialogueManager.select_choice(choice_index)

func _input(event: InputEvent) -> void:
    if not visible:
        return
    
    if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
        if is_displaying:
            skip_to_end()
        else:
            if DialogueManager.is_active():
                DialogueManager.advance_dialogue()

func play_typewriter_click() -> void:
    if typewriter_sound_enabled:
        AudioManager.play_sfx("res://assets/audio/sfx/typewriter.wav")

func set_display_speed(speed: float) -> void:
    display_speed = clamp(speed, 10.0, 100.0)

func set_typewriter_sound(enabled: bool) -> void:
    typewriter_sound_enabled = enabled