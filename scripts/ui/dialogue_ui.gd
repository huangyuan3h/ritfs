class_name DialogueUI
extends Control

@onready var speaker_label: Label = $PanelContainer/VBoxContainer/SpeakerLabel
@onready var text_label: RichTextLabel = $PanelContainer/VBoxContainer/TextLabel
@onready var choices_container: VBoxContainer = $PanelContainer/VBoxContainer/ChoicesContainer
@onready var continue_hint: Label = $PanelContainer/VBoxContainer/ContinueHint

var typewriter_speed: float = 0.03
var is_typing: bool = false
var current_text: String = ""

func _ready() -> void:
    visible = false
    DialogueManager.dialogue_started.connect(_on_dialogue_started)
    DialogueManager.dialogue_line_displayed.connect(_on_line_displayed)
    DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

func _on_dialogue_started(_dialogue_id: String) -> void:
    visible = true

func _on_line_displayed(speaker: String, text: String, choices: Array) -> void:
    speaker_label.text = speaker
    current_text = text
    text_label.text = ""
    
    for child in choices_container.get_children():
        child.queue_free()
    
    if choices.is_empty():
        continue_hint.visible = true
        start_typewriter(text)
    else:
        continue_hint.visible = false
        display_choices(choices)

func display_choices(choices: Array) -> void:
    for i in range(choices.size()):
        var choice: Dictionary = choices[i]
        var button: Button = Button.new()
        button.text = choice.get("text", "Choice %d" % (i + 1))
        button.pressed.connect(_on_choice_selected.bind(i))
        choices_container.add_child(button)

func start_typewriter(text: String) -> void:
    is_typing = true
    for character in text:
        text_label.text += character
        await get_tree().create_timer(typewriter_speed).timeout
    is_typing = false

func _on_dialogue_ended() -> void:
    visible = false

func _on_choice_selected(choice_index: int) -> void:
    DialogueManager.select_choice(choice_index)

func _input(event: InputEvent) -> void:
    if not visible:
        return
    
    if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
        if is_typing:
            text_label.text = current_text
            is_typing = false
        else:
            DialogueManager.advance_dialogue()