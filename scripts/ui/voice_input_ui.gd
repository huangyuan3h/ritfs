class_name VoiceInputUI
extends Control

@onready var status_label: Label = $Panel/VBox/StatusLabel
@onready var transcript_label: Label = $Panel/VBox/TranscriptLabel
@onready var mic_button: Button = $Panel/VBox/MicButton
@onready var command_list_label: Label = $Panel/VBox/CommandListLabel

var voice_system: VoiceInputSystem = null
var is_listening: bool = false

func _ready() -> void:
    voice_system = VoiceInputSystem.new()
    add_child(voice_system)
    
    voice_system.voice_command_received.connect(_on_command_received)
    voice_system.voice_text_received.connect(_on_text_received)
    voice_system.recognition_status_changed.connect(_on_recognition_status_changed)
    
    mic_button.pressed.connect(_on_mic_button_pressed)
    
    update_ui()
    show_command_list()

func _on_mic_button_pressed() -> void:
    if not voice_system.is_available():
        show_unavailable_message()
        return
    
    if is_listening:
        voice_system.stop_voice_input()
    else:
        voice_system.start_voice_input()

func _on_command_received(command: String) -> void:
    transcript_label.text = "命令：%s" % command
    transcript_label.add_theme_color_override("font_color", Color.GREEN)

func _on_text_received(text: String) -> void:
    transcript_label.text = "识别：\"%s\"" % text
    transcript_label.add_theme_color_override("font_color", Color.WHITE)

func _on_recognition_status_changed(active: bool) -> void:
    is_listening = active
    update_ui()

func update_ui() -> void:
    if is_listening:
        mic_button.text = "停止识别"
        status_label.text = "正在监听..."
        status_label.add_theme_color_override("font_color", Color.YELLOW)
    else:
        mic_button.text = "开始语音"
        status_label.text = "点击按钮开始语音输入"
        status_label.add_theme_color_override("font_color", Color.WHITE)
    
    if not voice_system.is_available():
        mic_button.disabled = true
        status_label.text = "语音识别不可用（仅Web版支持）"
        status_label.add_theme_color_override("font_color", Color.RED)

func show_command_list() -> void:
    var commands: String = "支持的语音命令：\n"
    commands += "• 左 / 向左 - 向左移动\n"
    commands += "• 右 / 向右 - 向右移动\n"
    commands += "• 前 / 向前 - 向前移动\n"
    commands += "• 后 / 向后 - 向后移动\n"
    commands += "• 停 / 停止 - 停止移动\n"
    commands += "• 交互 / 确认 - 交互\n"
    commands += "• 对话 - 开始对话\n"
    
    command_list_label.text = commands

func show_unavailable_message() -> void:
    var popup: AcceptDialog = AcceptDialog.new()
    popup.dialog_text = """
语音识别当前仅支持Web版本。

在Web浏览器中运行游戏时，可以使用浏览器的语音识别功能。

或者，您可以手动安装：
1. Python + SpeechRecognition库
2. 本地Whisper模型

完全本地、免费、隐私保护。
"""
    add_child(popup)
    popup.popup_centered()
    await popup.confirmed
    popup.queue_free()

func get_voice_system() -> VoiceInputSystem:
    return voice_system