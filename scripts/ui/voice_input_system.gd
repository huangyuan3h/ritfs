class_name VoiceInputSystem
extends Node

enum RecognitionMode { DISABLED, WEB_NATIVE, PYTHON_HELPER, LOCAL_WHISPER, API_WHISPER }

var current_mode: RecognitionMode = RecognitionMode.DISABLED
var is_listening: bool = false
var recognized_text: String = ""
var last_command_time: float = 0.0

signal voice_command_received(command: String)
signal voice_text_received(text: String)
signal recognition_status_changed(is_active: bool)

var command_mapping: Dictionary = {
    "左": "move_left",
    "向左": "move_left",
    "左走": "move_left",
    "右": "move_right",
    "向右": "move_right",
    "右走": "move_right",
    "前": "move_forward",
    "向前": "move_forward",
    "前进": "move_forward",
    "后": "move_backward",
    "向后": "move_backward",
    "后退": "move_backward",
    "停": "stop",
    "停止": "stop",
    "停住": "stop",
    "交互": "interact",
    "确认": "interact",
    "对话": "dialogue",
    "说话": "dialogue",
    "你好": "greet",
    "取消": "cancel"
}

func _ready() -> void:
    detect_best_mode()

func detect_best_mode() -> void:
    if OS.get_name() == "Web":
        current_mode = RecognitionMode.WEB_NATIVE
        setup_web_recognition()
    else:
        current_mode = RecognitionMode.DISABLED

func setup_web_recognition() -> void:
    if not OS.has_feature("web"):
        return
    
    JavaScriptBridge.eval("""
    if ('webkitSpeechRecognition' in window || 'SpeechRecognition' in window) {
        var SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
        var recognition = new SpeechRecognition();
        recognition.continuous = false;
        recognition.interimResults = false;
        recognition.lang = 'zh-CN';
        
        recognition.onresult = function(event) {
            var text = event.results[0][0].transcript;
            window.godotVoiceText = text;
        };
        
        recognition.onerror = function(event) {
            console.error('Voice error:', event.error);
            window.godotVoiceError = event.error;
        };
        
        recognition.onend = function() {
            window.godotVoiceListening = false;
        };
        
        window.godotStartVoice = function() {
            window.godotVoiceListening = true;
            window.godotVoiceText = '';
            window.godotVoiceError = '';
            recognition.start();
        };
        
        window.godotStopVoice = function() {
            recognition.stop();
        };
        
        window.godotGetVoiceText = function() {
            return window.godotVoiceText || '';
        };
        
        window.godotIsVoiceListening = function() {
            return window.godotVoiceListening || false;
        };
    } else {
        console.error('Speech recognition not supported');
        window.godotVoiceSupported = false;
    }
    """)

func start_voice_input() -> void:
    if current_mode == RecognitionMode.DISABLED:
        push_warning("Voice recognition not available")
        return
    
    is_listening = true
    recognition_status_changed.emit(true)
    
    if current_mode == RecognitionMode.WEB_NATIVE:
        JavaScriptBridge.eval("window.godotStartVoice()")

func stop_voice_input() -> void:
    is_listening = false
    recognition_status_changed.emit(false)
    
    if current_mode == RecognitionMode.WEB_NATIVE:
        JavaScriptBridge.eval("window.godotStopVoice()")

func _process(delta: float) -> void:
    if current_mode == RecognitionMode.WEB_NATIVE and is_listening:
        check_web_voice_result()

func check_web_voice_result() -> void:
    var text: String = JavaScriptBridge.eval("window.godotGetVoiceText()")
    
    if not text.is_empty() and text != recognized_text:
        recognized_text = text
        process_voice_input(text)
    
    var listening_status: bool = JavaScriptBridge.eval("window.godotIsVoiceListening()")
    
    if not listening_status and is_listening:
        is_listening = false
        recognition_status_changed.emit(false)

func process_voice_input(text: String) -> void:
    var lower_text: String = text.lower()
    
    for key in command_mapping:
        if lower_text.contains(key):
            var command: String = command_mapping[key]
            voice_command_received.emit(command)
            execute_game_command(command)
            last_command_time = Time.get_ticks_msec() / 1000.0
            return
    
    voice_text_received.emit(text)

func execute_game_command(command: String) -> void:
    match command:
        "move_left":
            simulate_input("move_left", true)
        "move_right":
            simulate_input("move_right", true)
        "move_forward":
            simulate_input("move_forward", true)
        "move_backward":
            simulate_input("move_backward", true)
        "stop":
            release_all_movement()
        "interact":
            simulate_input("interact", true)
            await get_tree().create_timer(0.2).timeout
            simulate_input("interact", false)
        "dialogue":
            start_voice_dialogue()
        "greet":
            pass
        "cancel":
            simulate_input("pause", true)
            await get_tree().create_timer(0.2).timeout
            simulate_input("pause", false)

func simulate_input(action: String, pressed: bool) -> void:
    var event: InputEventAction = InputEventAction.new()
    event.action = action
    event.pressed = pressed
    Input.parse_input_event(event)

func release_all_movement() -> void:
    simulate_input("move_left", false)
    simulate_input("move_right", false)
    simulate_input("move_forward", false)
    simulate_input("move_backward", false)

func start_voice_dialogue() -> void:
    DialogueManager.start_dialogue("voice_interaction")

func get_last_recognized_text() -> String:
    return recognized_text

func get_time_since_last_command() -> float:
    return Time.get_ticks_msec() / 1000.0 - last_command_time

func set_mode(mode: RecognitionMode) -> void:
    current_mode = mode

func get_mode_name() -> String:
    return RecognitionMode.keys()[current_mode]

func is_available() -> bool:
    return current_mode != RecognitionMode.DISABLED

func add_custom_command(trigger_phrase: String, action: String) -> void:
    command_mapping[trigger_phrase.lower()] = action