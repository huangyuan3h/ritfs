extends Control

@onready var new_game_button: Button = $VBoxContainer/NewGameButton
@onready var continue_button: Button = $VBoxContainer/ContinueButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton

func _ready() -> void:
    setup_buttons()
    check_save_file()
    
    if not GameManager.has_save():
        continue_button.visible = false

func setup_buttons() -> void:
    new_game_button.pressed.connect(_on_new_game_pressed)
    continue_button.pressed.connect(_on_continue_pressed)
    settings_button.pressed.connect(_on_settings_pressed)
    quit_button.pressed.connect(_on_quit_pressed)

func check_save_file() -> void:
    continue_button.visible = GameManager.has_save()

func _on_new_game_pressed() -> void:
    GameManager.delete_save()
    GameManager.start_new_game()

func _on_continue_pressed() -> void:
    if GameManager.load_game():
        GameManager.change_state(GameState.State.PLAYING)
        GameManager.load_level(GameManager.game_state.current_level)

func _on_settings_pressed() -> void:
    pass

func _on_quit_pressed() -> void:
    get_tree().quit()