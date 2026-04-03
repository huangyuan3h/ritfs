class_name LocalLLMClient
extends RefCounted

var server_url: String = "http://localhost:11434"
var http_client: HTTPRequest = null
var pending_requests: Dictionary = {}
var request_timeout: float = 30.0

signal response_received(request_id: String, response: String)
signal error_occurred(request_id: String, error: String)

func initialize(parent_node: Node, url: String = "http://localhost:11434") -> void:
    server_url = url
    http_client = HTTPRequest.new()
    parent_node.add_child(http_client)
    http_client.request_completed.connect(_on_request_completed)
    http_client.timeout = request_timeout

func check_server_health() -> bool:
    if http_client == null:
        return false
    
    var error: int = http_client.request(server_url + "/api/tags", [], HTTPClient.METHOD_GET)
    return error == OK

func send_chat_request(system_prompt: String, user_prompt: String, temperature: float = 0.7, max_tokens: int = 500) -> String:
    if http_client == null:
        return ""
    
    var request_id: String = "local_req_%d" % Time.get_ticks_msec()
    
    var body: Dictionary = {
        "model": "phi3:3.8b-mini-4k-instruct",
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt}
        ],
        "stream": false,
        "options": {
            "temperature": temperature,
            "num_predict": max_tokens
        }
    }
    
    var json_body: String = JSON.stringify(body)
    var headers: Array = ["Content-Type: application/json"]
    
    pending_requests[request_id] = {
        "timestamp": Time.get_ticks_msec(),
        "status": "pending"
    }
    
    var endpoint: String = server_url + "/v1/chat/completions"
    var error: int = http_client.request(endpoint, headers, HTTPClient.METHOD_POST, json_body)
    
    if error != OK:
        pending_requests.erase(request_id)
        error_occurred.emit(request_id, "HTTP request failed: %d" % error)
        return ""
    
    return request_id

func send_generation_request(prompt: String, temperature: float = 0.7, max_tokens: int = 500) -> String:
    if http_client == null:
        return ""
    
    var request_id: String = "local_gen_%d" % Time.get_ticks_msec()
    
    var body: Dictionary = {
        "model": "phi3:3.8b-mini-4k-instruct",
        "prompt": prompt,
        "stream": false,
        "options": {
            "temperature": temperature,
            "num_predict": max_tokens
        }
    }
    
    var json_body: String = JSON.stringify(body)
    var headers: Array = ["Content-Type: application/json"]
    
    pending_requests[request_id] = {
        "timestamp": Time.get_ticks_msec(),
        "status": "pending"
    }
    
    var endpoint: String = server_url + "/api/generate"
    var error: int = http_client.request(endpoint, headers, HTTPClient.METHOD_POST, json_body)
    
    if error != OK:
        pending_requests.erase(request_id)
        error_occurred.emit(request_id, "HTTP request failed: %d" % error)
        return ""
    
    return request_id

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
    var current_time: float = Time.get_ticks_msec() / 1000.0
    
    for request_id in pending_requests:
        var request_data: Dictionary = pending_requests[request_id]
        var request_age: float = current_time - request_data.get("timestamp", 0) / 1000.0
        
        if request_age > request_timeout:
            pending_requests.erase(request_id)
            error_occurred.emit(request_id, "Request timeout")
            continue
        
        if result != HTTPRequest.RESULT_SUCCESS:
            pending_requests.erase(request_id)
            error_occurred.emit(request_id, "Request failed: result %d" % result)
            continue
        
        if response_code != 200:
            pending_requests.erase(request_id)
            error_occurred.emit(request_id, "HTTP error: %d" % response_code)
            continue
        
        var response_text: String = body.get_string_from_utf8()
        var json: JSON = JSON.new()
        
        if json.parse(response_text) != OK:
            pending_requests.erase(request_id)
            error_occurred.emit(request_id, "JSON parse failed")
            continue
        
        var response_data: Dictionary = json.data
        var content: String = extract_content(response_data)
        
        pending_requests.erase(request_id)
        response_received.emit(request_id, content)
        break

func extract_content(response_data: Dictionary) -> String:
    if response_data.has("choices"):
        var choices: Array = response_data.get("choices", [])
        if not choices.is_empty():
            var message: Dictionary = choices[0].get("message", {})
            return message.get("content", "")
    
    if response_data.has("response"):
        return response_data.get("response", "")
    
    return ""

func set_server_url(url: String) -> void:
    server_url = url

func set_timeout(timeout_seconds: float) -> void:
    request_timeout = timeout_seconds
    if http_client:
        http_client.timeout = timeout_seconds

func get_pending_count() -> int:
    return pending_requests.size()

func clear_pending_requests() -> void:
    pending_requests.clear()

func list_available_models() -> Array[String]:
    var models: Array[String] = []
    
    if http_client == null:
        return models
    
    var error: int = http_client.request(server_url + "/api/tags", [], HTTPClient.METHOD_GET)
    
    if error != OK:
        return models
    
    return models