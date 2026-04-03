extends Control

@onready var wake_button: Button = $MenuContainer/WakeButton
@onready var return_button: Button = $MenuContainer/ReturnButton
@onready var exit_button: Button = $MenuContainer/ExitButton
@onready var version_label: Label = $Footer/VersionLabel
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var transition_overlay: ColorRect = $TransitionOverlay

var state_manager: Node = null

func _ready() -> void:
    state_manager = get_node_or_null("/root/GameStateManager")
    if state_manager == null:
        state_manager = preload("res://scripts/core/game_state_manager.gd").new()
        add_child(state_manager)
    
    setup_buttons()
    check_save_files()
    play_ambient_music()
    update_version_info()

func setup_buttons() -> void:
    wake_button.pressed.connect(_on_wake_pressed)
    return_button.pressed.connect(_on_return_pressed)
    exit_button.pressed.connect(_on_exit_pressed)

func check_save_files() -> void:
    return_button.disabled = not state_manager.has_save(1)
    
    if not state_manager.has_save(1):
        return_button.tooltip_text = "无记忆痕迹"

func play_ambient_music() -> void:
    AudioManager.play_music("res://assets/audio/music/menu_ambient.ogg")

func update_version_info() -> void:
    var config: ConfigFile = ConfigFile.new()
    if config.load("res://project.godot") == OK:
        var version: String = config.get_value("application", "config/version", "1.0.0")
        version_label.text = "v%s" % version

func _on_wake_pressed() -> void:
    if state_manager.has_save(1):
        show_confirmation_dialog(
            "发现记忆痕迹",
            "唤醒将清除现有记忆，是否继续？",
            start_new_game
        )
    else:
        start_new_game()

func _on_return_pressed() -> void:
    var saves: Array = state_manager.list_all_saves()
    
    if saves.is_empty():
        show_message_dialog("无记忆痕迹", "未找到保存的记忆痕迹。")
        return
    
    show_save_selection_dialog(saves)

func _on_exit_pressed() -> void:
    show_confirmation_dialog(
        "离开裂隙",
        "确定要离开吗？",
        func(): get_tree().quit()
    )

func start_new_game() -> void:
    state_manager.initialize_default_state()
    state_manager.save_game(1)
    
    play_wake_animation()

func load_selected_game(slot: int) -> void:
    if state_manager.load_game(slot):
        transition_to_game()
    else:
        show_message_dialog("加载失败", "无法读取记忆痕迹。")

func play_wake_animation() -> void:
    AudioManager.fade_out_music(1.0)
    
    animation_player.play("wake_sequence")
    
    yield(animation_player, "animation_finished")
    
    transition_to_game()

func transition_to_game() -> void:
    var scene_path: String = state_manager.get_state("game.current_scene", "res://scenes/levels/level_0.tscn")
    
    transition_overlay.visible = true
    transition_overlay.modulate.a = 0.0
    
    var tween: Tween = create_tween()
    tween.tween_property(transition_overlay, "modulate:a", 1.0, 1.0)
    
    yield(tween.finished)
    
    get_tree().change_scene_to_file(scene_path)

func show_confirmation_dialog(title: String, message: String, on_confirm: Callable) -> void:
    var dialog: ConfirmationDialog = ConfirmationDialog.new()
    dialog.dialog_text = message
    dialog.title = title
    
    dialog.confirmed.connect(on_confirm)
    
    add_child(dialog)
    dialog.popup_centered()
    
    yield(dialog, "visibility_changed")
    dialog.queue_free()

func show_message_dialog(title: String, message: String) -> void:
    var dialog: AcceptDialog = AcceptDialog.new()
    dialog.dialog_text = message
    dialog.title = title
    
    add_child(dialog)
    dialog.popup_centered()
    
    yield(dialog, "confirmed")
    dialog.queue_free()

func show_save_selection_dialog(saves: Array) -> void:
    var dialog: ConfirmationDialog = ConfirmationDialog.new()
    dialog.title = "选择记忆痕迹"
    
    var vbox: VBoxContainer = VBoxContainer.new()
    
    for save_info in saves:
        var button: Button = Button.new()
        button.text = "槽位 %d - 关卡 %d - %.1f小时" % [
            save_info.get("slot", 0),
            save_info.get("current_level", 0) + 1,
            save_info.get("play_time", 0) / 3600.0
        ]
        
        var slot: int = save_info.get("slot", 1)
        button.pressed.connect(func():
            dialog.hide()
            load_selected_game(slot)
        )
        
        vbox.add_child(button)
    
    dialog.add_child(vbox)
    dialog.get_ok_button().text = "取消"
    
    add_child(dialog)
    dialog.popup_centered()

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST:
        state_manager.autosave()
        get_tree().quit()