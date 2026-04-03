extends Node

var voice_input: VoiceInputSystem = null
var llm_client: LocalLLMClient = null
var text_generator: AgentTextGenerator = null

signal player_voice_interaction(text: String, response: String)

func _ready() -> void:
    voice_input = VoiceInputSystem.new()
    add_child(voice_input)
    
    llm_client = LocalLLMClient.new()
    llm_client.initialize(self, "http://localhost:11434")
    
    text_generator = AgentTextGenerator.new()
    text_generator.initialize(null)
    
    voice_input.voice_text_received.connect(_on_player_voice)

func _on_player_voice(text: String) -> void:
    if text.is_empty():
        return
    
    generate_ai_response_to_voice(text)

func generate_ai_response_to_voice(player_text: String) -> void:
    var context: Dictionary = {
        "scene": GameManager.game_state.current_level,
        "player_input": player_text,
        "type": "voice_interaction"
    }
    
    if llm_client:
        var system_prompt: String = "你是裂隙之渊游戏中的AI助手。玩家通过语音与你交流。"
        var user_prompt: String = "玩家说：\"%s\"\n请生成合适的回应。" % player_text
        
        var request_id: String = llm_client.send_chat_request(system_prompt, user_prompt)
        
        llm_client.response_received.connect(func(id, response):
            if id == request_id:
                handle_ai_response(player_text, response)
        , CONNECT_ONE_SHOT)
    else:
        var template_response: String = text_generator.generate_with_template(context)
        handle_ai_response(player_text, template_response)

func handle_ai_response(player_text: String, ai_response: String) -> void:
    player_voice_interaction.emit(player_text, ai_response)
    
    DialogueManager.start_dialogue("voice_response")
    
    await get_tree().create_timer(0.5).timeout
    
    DialogueManager.dialogue_line_displayed.emit("AI", ai_response, [])

func execute_voice_command(command: String) -> void:
    voice_input.process_voice_input(command)

func is_voice_available() -> bool:
    return voice_input.is_available()

func start_voice_mode() -> void:
    voice_input.start_voice_input()

func stop_voice_mode() -> void:
    voice_input.stop_voice_input()

func add_custom_voice_command(trigger: String, action: String) -> void:
    voice_input.add_custom_command(trigger, action)