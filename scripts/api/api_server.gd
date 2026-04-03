class_name APIServer
extends Node

var server: TCPServer = null
var connections: Array[StreamPeerTCP] = []
var is_running: bool = false
var port: int = 8080

var request_handlers: Dictionary = {}

signal server_started()
signal server_stopped()
signal request_received(method: String, path: String, body: String)

func _ready() -> void:
    register_default_handlers()

func start_server(server_port: int = 8080) -> bool:
    port = server_port
    server = TCPServer.new()
    
    if server.listen(port) != OK:
        push_error("Failed to start API server on port %d" % port)
        return false
    
    is_running = true
    server_started.emit()
    return true

func stop_server() -> void:
    if server:
        server.stop()
    
    for connection in connections:
        connection.disconnect_from_host()
    
    connections.clear()
    is_running = false
    server_stopped.emit()

func register_handler(path: String, handler: Callable) -> void:
    request_handlers[path] = handler

func register_default_handlers() -> void:
    register_handler("/api/state", handle_get_state)
    register_handler("/api/agents", handle_get_agents)
    register_handler("/api/agent/register", handle_register_agent)
    register_handler("/api/agent/action", handle_agent_action)
    register_handler("/api/agent/perception", handle_agent_perception)
    register_handler("/api/dialogue/generate", handle_dialogue_generate)
    register_handler("/api/event/broadcast", handle_broadcast_event)

func _process(delta: float) -> void:
    if not is_running:
        return
    
    if server.is_connection_available():
        var connection: StreamPeerTCP = server.take_connection()
        connections.append(connection)
    
    for connection in connections:
        if connection.get_status() == StreamPeerTCP.STATUS_CONNECTED:
            var available_bytes: int = connection.get_available_bytes()
            if available_bytes > 0:
                var data: String = connection.get_string(available_bytes)
                handle_request(connection, data)
    
    connections = connections.filter(func(conn): return conn.get_status() != StreamPeerTCP.STATUS_NONE)

func handle_request(connection: StreamPeerTCP, raw_request: String) -> void:
    var lines: Array = raw_request.split("\n")
    if lines.is_empty():
        return
    
    var first_line: String = lines[0]
    var parts: Array = first_line.split(" ")
    
    if parts.size() < 2:
        return
    
    var method: String = parts[0]
    var path: String = parts[1].split("?")[0]
    
    var body_start: int = raw_request.find("\r\n\r\n")
    var body: String = ""
    if body_start != -1:
        body = raw_request.substr(body_start + 4)
    
    request_received.emit(method, path, body)
    
    var response: Dictionary = route_request(method, path, body)
    send_response(connection, response)

func route_request(method: String, path: String, body: String) -> Dictionary:
    if request_handlers.has(path):
        var handler: Callable = request_handlers[path]
        return handler.call(method, body)
    
    return {
        "status": 404,
        "body": {"error": "Not Found", "path": path}
    }

func send_response(connection: StreamPeerTCP, response: Dictionary) -> void:
    var status: int = response.get("status", 200)
    var body_dict: Dictionary = response.get("body", {})
    var body_json: String = JSON.stringify(body_dict)
    
    var response_str: String = "HTTP/1.1 %d OK\r\n" % status
    response_str += "Content-Type: application/json\r\n"
    response_str += "Content-Length: %d\r\n" % body_json.length()
    response_str += "Connection: close\r\n"
    response_str += "\r\n"
    response_str += body_json
    
    connection.put_data(response_str.to_utf8_buffer())
    connection.disconnect_from_host()

func handle_get_state(method: String, body: String) -> Dictionary:
    if method != "GET":
        return {"status": 405, "body": {"error": "Method not allowed"}}
    
    var game_state: Dictionary = GameManager.game_state.to_dict()
    var agents_state: Dictionary = AgentManager2D.get_all_agents_state()
    
    return {
        "status": 200,
        "body": {
            "game_state": game_state,
            "agents": agents_state,
            "timestamp": Time.get_ticks_msec() / 1000.0
        }
    }

func handle_get_agents(method: String, body: String) -> Dictionary:
    if method != "GET":
        return {"status": 405, "body": {"error": "Method not allowed"}}
    
    return {
        "status": 200,
        "body": {
            "agents": AgentManager2D.get_all_agents_state(),
            "active_count": AgentManager2D.get_active_agents().size()
        }
    }

func handle_register_agent(method: String, body: String) -> Dictionary:
    if method != "POST":
        return {"status": 405, "body": {"error": "Method not allowed"}}
    
    var json: JSON = JSON.new()
    if json.parse(body) != OK:
        return {"status": 400, "body": {"error": "Invalid JSON"}}
    
    var data: Dictionary = json.data
    var agent_id: String = data.get("agent_id", "")
    var agent_type_str: String = data.get("agent_type", "RULE_BASED")
    var agent_name: String = data.get("agent_name", "")
    
    if agent_id.is_empty():
        return {"status": 400, "body": {"error": "Missing agent_id"}}
    
    var agent_type: AgentState2D.AgentType = AgentState2D.AgentType.keys().find(agent_type_str)
    
    if AgentManager2D.register_agent(agent_id, agent_type, agent_name):
        return {
            "status": 200,
            "body": {
                "success": true,
                "agent_id": agent_id,
                "message": "Agent registered successfully"
            }
        }
    else:
        return {"status": 400, "body": {"error": "Failed to register agent"}}

func handle_agent_action(method: String, body: String) -> Dictionary:
    if method != "POST":
        return {"status": 405, "body": {"error": "Method not allowed"}}
    
    var json: JSON = JSON.new()
    if json.parse(body) != OK:
        return {"status": 400, "body": {"error": "Invalid JSON"}}
    
    var data: Dictionary = json.data
    var agent_id: String = data.get("agent_id", "")
    var action: Dictionary = data.get("action", {})
    
    if agent_id.is_empty() or action.is_empty():
        return {"status": 400, "body": {"error": "Missing agent_id or action"}}
    
    AgentManager2D.request_agent_action(agent_id, action)
    
    return {
        "status": 200,
        "body": {
            "success": true,
            "message": "Action request sent to agent"
        }
    }

func handle_agent_perception(method: String, body: String) -> Dictionary:
    if method != "POST":
        return {"status": 405, "body": {"error": "Method not allowed"}}
    
    var json: JSON = JSON.new()
    if json.parse(body) != OK:
        return {"status": 400, "body": {"error": "Invalid JSON"}}
    
    var data: Dictionary = json.data
    var agent_id: String = data.get("agent_id", "")
    
    if agent_id.is_empty():
        return {"status": 400, "body": {"error": "Missing agent_id"}}
    
    var perception: Dictionary = AgentManager2D.get_agent_perception(agent_id)
    
    return {
        "status": 200,
        "body": {
            "agent_id": agent_id,
            "perception": perception
        }
    }

func handle_dialogue_generate(method: String, body: String) -> Dictionary:
    return {"status": 501, "body": {"error": "Not implemented - requires LLM integration"}}

func handle_broadcast_event(method: String, body: String) -> Dictionary:
    if method != "POST":
        return {"status": 405, "body": {"error": "Method not allowed"}}
    
    var json: JSON = JSON.new()
    if json.parse(body) != OK:
        return {"status": 400, "body": {"error": "Invalid JSON"}}
    
    var event: Dictionary = json.data
    AgentManager2D.broadcast_event(event)
    
    return {
        "status": 200,
        "body": {
            "success": true,
            "message": "Event broadcasted to agents"
        }
    }