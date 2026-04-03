extends Control

@onready var resume_button: Button = $VBoxContainer/ResumeButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var save_button: Button = $VBoxContainer/SaveButton
@onready var main_menu_button: Button = $VBoxContainer/MainMenuButton

func _ready() -> void:
    setup_buttons()
    visible = false
    process_mode = Node.PROCESS_MODE_ALWAYS
    
    GameManager.state_changed.connect(_on_state_changed)

func setup_buttons() -> void:
    resume_button.pressed.connect(_on_resume_pressed)
    settings_button.pressed.connect(_on_settings_pressed)
    save_button.pressed.connect(_on_save_pressed)
    main_menu_button.pressed.connect(_on_main_menu_pressed)

func _on_state_changed(new_state: GameState.State) -> void:
    visible = new_state == GameState.State.PAUSED

func _on_resume_pressed() -> void:
    GameManager.resume_game()

func _on_settings_pressed() -> void:
    pass

func _on_save_pressed() -> void:
    GameManager.save_game()

func _on_main_menu_pressed() -> void:
    GameManager.quit_to_menu()

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("pause"):
        if GameManager.game_state.is_state(GameState.State.PLAYING):
            GameManager.pause_game()
        elif GameManager.game_state.is_state(GameState.State.PAUSED):
            GameManager.resume_game()