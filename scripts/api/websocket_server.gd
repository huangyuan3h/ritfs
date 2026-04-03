class_name WebSocketServer
extends Node

var server: WebSocketMultiplayerPeer = null
var is_running: bool = false
var port: int = 8081

var clients: Dictionary = {}

signal server_started()
signal client_connected(client_id: int)
signal client_disconnected(client_id: int)
signal message_received(client_id: int, message: String)

func _ready() -> void:
    pass

func start_server(server_port: int = 8081) -> bool:
    port = server_port
    server = WebSocketMultiplayerPeer.new()
    
    if server.create_server(port) != OK:
        push_error("Failed to start WebSocket server on port %d" % port)
        return false
    
    is_running = true
    server_started.emit()
    return true

func stop_server() -> void:
    if server:
        server.close()
    
    clients.clear()
    is_running = false

func _process(delta: float) -> void:
    if not is_running:
        return
    
    server.poll()
    
    if server.get_connection_status() == WebSocketMultiplayerPeer.CONNECTION_CONNECTED:
        while server.get_available_packet_count() > 0:
            var packet: PackedByteArray = server.get_packet()
            var sender_id: int = server.get_packet_sender()
            var message: String = packet.get_string_from_utf8()
            
            message_received.emit(sender_id, message)
            handle_message(sender_id, message)

func handle_message(client_id: int, message: String) -> void:
    var json: JSON = JSON.new()
    if json.parse(message) != OK:
        send_error(client_id, "Invalid JSON format")
        return
    
    var data: Dictionary = json.data
    var msg_type: String = data.get("type", "")
    
    match msg_type:
        "register":
            handle_register(client_id, data)
        "action":
            handle_action(client_id, data)
        "query":
            handle_query(client_id, data)
        "perception":
            handle_perception(client_id, data)
        _:
            send_error(client_id, "Unknown message type: %s" % msg_type)

func handle_register(client_id: int, data: Dictionary) -> void:
    var agent_id: String = data.get("agent_id", "")
    var agent_type_str: String = data.get("agent_type", "RULE_BASED")
    var agent_name: String = data.get("agent_name", "")
    
    if agent_id.is_empty():
        send_error(client_id, "Missing agent_id")
        return
    
    clients[client_id] = agent_id
    
    var agent_type: AgentState.AgentType = AgentState.AgentType.keys().find(agent_type_str)
    AgentManager.register_agent(agent_id, agent_type, agent_name)
    
    send_message(client_id, {
        "type": "register_success",
        "agent_id": agent_id,
        "client_id": client_id
    })

func handle_action(client_id: int, data: Dictionary) -> void:
    var agent_id: String = clients.get(client_id, "")
    if agent_id.is_empty():
        send_error(client_id, "Agent not registered")
        return
    
    var action: Dictionary = data.get("action", {})
    if action.is_empty():
        send_error(client_id, "Missing action data")
        return
    
    AgentManager.request_agent_action(agent_id, action)
    
    send_message(client_id, {
        "type": "action_ack",
        "agent_id": agent_id,
        "action": action
    })

func handle_query(client_id: int, data: Dictionary) -> void:
    var query_type: String = data.get("query_type", "state")
    
    var response: Dictionary = {}
    
    match query_type:
        "state":
            response = {
                "type": "state_response",
                "data": GameManager.game_state.to_dict()
            }
        "agents":
            response = {
                "type": "agents_response",
                "data": AgentManager.get_all_agents_state()
            }
        "agent":
            var target_id: String = data.get("agent_id", "")
            var agent: AgentState = AgentManager.get_agent(target_id)
            if agent:
                response = {
                    "type": "agent_response",
                    "data": agent.to_dict()
                }
            else:
                send_error(client_id, "Agent not found")
                return
        _:
            send_error(client_id, "Unknown query type")
            return
    
    send_message(client_id, response)

func handle_perception(client_id: int, data: Dictionary) -> void:
    var agent_id: String = clients.get(client_id, "")
    if agent_id.is_empty():
        send_error(client_id, "Agent not registered")
        return
    
    var perception: Dictionary = AgentManager.get_agent_perception(agent_id)
    
    send_message(client_id, {
        "type": "perception_response",
        "agent_id": agent_id,
        "perception": perception
    })

func send_message(client_id: int, message: Dictionary) -> void:
    var message_json: String = JSON.stringify(message)
    var packet: PackedByteArray = message_json.to_utf8_buffer()
    server.put_packet(packet, client_id)

func send_error(client_id: int, error_message: String) -> void:
    send_message(client_id, {
        "type": "error",
        "message": error_message
    })

func broadcast_message(message: Dictionary) -> void:
    for client_id in clients:
        send_message(client_id, message)

func broadcast_event(event: Dictionary) -> void:
    broadcast_message({
        "type": "event",
        "data": event
    })

func get_connected_clients() -> int:
    return clients.size()