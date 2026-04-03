class_name LLMIntegration
extends RefCounted

enum Provider { OPENAI, ANTHROPIC, LOCAL, LOCAL_OLLAMA, CUSTOM }

var api_key: String = ""
var api_endpoint: String = ""
var provider: Provider = Provider.OPENAI
var model: String = "gpt-4"
var max_tokens: int = 500
var temperature: float = 0.7
var local_server_url: String = "http://localhost:11434"

var http_client: HTTPRequest = null
var request_queue: Array[Dictionary] = []
var is_processing: bool = false

signal response_received(request_id: String, response: String)
signal error_occurred(request_id: String, error: String)

func initialize(provider_type: Provider, key: String = "", endpoint: String = "", model_name: String = "") -> void:
    provider = provider_type
    api_key = key if provider in [Provider.OPENAI, Provider.ANTHROPIC] else ""
    api_endpoint = endpoint if not endpoint.is_empty() else get_default_endpoint()
    model = model_name if not model_name.is_empty() else get_default_model()

func initialize_local_ollama(server_url: String = "http://localhost:11434", model_name: String = "phi3:3.8b-mini-4k-instruct") -> void:
    provider = Provider.LOCAL_OLLAMA
    local_server_url = server_url
    api_endpoint = server_url + "/v1/chat/completions"
    model = model_name
    api_key = ""

func initialize_local_llama_cpp(server_url: String = "http://localhost:8082", model_name: String = "phi3") -> void:
    provider = Provider.LOCAL
    local_server_url = server_url
    api_endpoint = server_url + "/v1/chat/completions"
    model = model_name
    api_key = ""

func get_default_endpoint() -> String:
    match provider:
        Provider.OPENAI:
            return "https://api.openai.com/v1/chat/completions"
        Provider.ANTHROPIC:
            return "https://api.anthropic.com/v1/messages"
        Provider.LOCAL:
            return "http://localhost:8082/v1/chat/completions"
        Provider.LOCAL_OLLAMA:
            return local_server_url + "/v1/chat/completions"
        Provider.CUSTOM:
            return api_endpoint
    return ""

func get_default_model() -> String:
    match provider:
        Provider.OPENAI:
            return "gpt-4"
        Provider.ANTHROPIC:
            return "claude-3-opus-20240229"
        Provider.LOCAL:
            return "phi3"
        Provider.LOCAL_OLLAMA:
            return "phi3:3.8b-mini-4k-instruct"
        Provider.CUSTOM:
            return "default"
    return ""

func create_http_client() -> HTTPRequest:
    var client: HTTPRequest = HTTPRequest.new()
    return client

func generate_dialogue(context: Dictionary, prompt: String) -> String:
    var system_prompt: String = build_dialogue_prompt(context)
    var request_id: String = "dialogue_%d" % Time.get_ticks_msec()
    
    send_llm_request(request_id, system_prompt, prompt)
    
    return request_id

func generate_agent_response(agent_state: Dictionary, situation: String) -> String:
    var system_prompt: String = build_agent_prompt(agent_state)
    var request_id: String = "agent_%d" % Time.get_ticks_msec()
    
    send_llm_request(request_id, system_prompt, situation)
    
    return request_id

func generate_level_description(theme: String, difficulty: String) -> String:
    var system_prompt: String = "You are a level designer for a sci-fi game about human nature. Generate level descriptions in JSON format."
    var prompt: String = "Theme: %s, Difficulty: %s. Generate a level description with objectives, challenges, and narrative elements." % [theme, difficulty]
    var request_id: String = "level_%d" % Time.get_ticks_msec()
    
    send_llm_request(request_id, system_prompt, prompt)
    
    return request_id

func build_dialogue_prompt(context: Dictionary) -> String:
    var scene: String = context.get("scene", "Unknown location")
    var mood: String = context.get("mood", "neutral")
    var characters: Array = context.get("characters", [])
    var history: Array = context.get("dialogue_history", [])
    
    var prompt: String = "You are generating dialogue for a sci-fi game 'Rifts' exploring human nature.\n"
    prompt += "Scene: %s\n" % scene
    prompt += "Mood: %s\n" % mood
    prompt += "Characters involved: %s\n" % str(characters)
    
    if not history.is_empty():
        prompt += "Recent dialogue history:\n"
        for entry in history:
            prompt += "- %s: %s\n" % [entry.get("speaker", "?"), entry.get("message", "?")]
    
    prompt += "\nGenerate dialogue that explores moral dilemmas and human contradictions. "
    prompt += "Provide choices that challenge the player's values.\n"
    prompt += "Format response as JSON with: {speaker, text, choices[{text, id, consequence}]}"
    
    return prompt

func build_agent_prompt(agent_state: Dictionary) -> String:
    var agent_name: String = agent_state.get("agent_name", "Unknown")
    var agent_type: String = agent_state.get("agent_type", "RULE_BASED")
    var moral_score: float = agent_state.get("moral_score", 0.0)
    var objectives: Array = agent_state.get("active_objectives", [])
    
    var prompt: String = "You are %s, an AI agent in a game about human nature.\n" % agent_name
    prompt += "Your moral alignment score: %.2f (negative = selfish, positive = altruistic)\n" % moral_score
    prompt += "Your current objectives: %s\n" % str(objectives)
    prompt += "\nRespond to the situation based on your character and values. "
    prompt += "Make decisions that align with your moral score.\n"
    prompt += "Format response as JSON with: {thought, action, dialogue}"
    
    return prompt

func send_llm_request(request_id: String, system_prompt: String, user_prompt: String) -> void:
    var request_data: Dictionary = {
        "request_id": request_id,
        "system_prompt": system_prompt,
        "user_prompt": user_prompt,
        "status": "pending"
    }
    
    request_queue.append(request_data)
    
    if not is_processing:
        process_next_request()

func process_next_request() -> void:
    if request_queue.is_empty():
        is_processing = false
        return
    
    is_processing = true
    var request: Dictionary = request_queue[0]
    request_queue.remove_at(0)
    
    var headers: Array = []
    var body: Dictionary = {}
    
    match provider:
        Provider.OPENAI, Provider.LOCAL:
            headers = ["Content-Type: application/json", "Authorization: Bearer %s" % api_key]
            body = {
                "model": model,
                "messages": [
                    {"role": "system", "content": request["system_prompt"]},
                    {"role": "user", "content": request["user_prompt"]}
                ],
                "max_tokens": max_tokens,
                "temperature": temperature
            }
        Provider.ANTHROPIC:
            headers = ["Content-Type: application/json", "x-api-key: %s" % api_key, "anthropic-version: 2023-06-01"]
            body = {
                "model": model,
                "system": request["system_prompt"],
                "messages": [{"role": "user", "content": request["user_prompt"]}],
                "max_tokens": max_tokens
            }
    
    send_http_request(request["request_id"], body, headers)

func send_http_request(request_id: String, body: Dictionary, headers: Array) -> void:
    pass

func parse_response(request_id: String, response_json: String) -> void:
    var json: JSON = JSON.new()
    if json.parse(response_json) != OK:
        error_occurred.emit(request_id, "Failed to parse JSON response")
        process_next_request()
        return
    
    var response_data: Dictionary = json.data
    var content: String = ""
    
    match provider:
        Provider.OPENAI, Provider.LOCAL:
            var choices: Array = response_data.get("choices", [])
            if choices.is_empty():
                error_occurred.emit(request_id, "No choices in response")
                process_next_request()
                return
            content = choices[0].get("message", {}).get("content", "")
        
        Provider.ANTHROPIC:
            content = response_data.get("content", [{}])[0].get("text", "")
    
    if content.is_empty():
        error_occurred.emit(request_id, "Empty response content")
    else:
        response_received.emit(request_id, content)
    
    process_next_request()

func set_temperature(value: float) -> void:
    temperature = clamp(value, 0.0, 2.0)

func set_max_tokens(value: int) -> void:
    max_tokens = clamp(value, 50, 4000)