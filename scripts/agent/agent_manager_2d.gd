extends Node

const MAX_AGENTS: int = 100

var agents: Dictionary = {}
var active_agents: Array[String] = []

signal agent_registered(agent_id: String)
signal agent_unregistered(agent_id: String)
signal agent_action_requested(agent_id: String, action: Dictionary)
signal agent_perception_updated(agent_id: String, perception: Dictionary)

func register_agent(agent_id: String, agent_type: AgentState2D.AgentType = AgentState2D.AgentType.RULE_BASED, agent_name: String = "") -> bool:
    if agents.has(agent_id):
        push_error("Agent already registered: %s" % agent_id)
        return false
    
    if agents.size() >= MAX_AGENTS:
        push_error("Maximum agents limit reached")
        return false
    
    var new_agent: AgentState2D = AgentState2D.new()
    new_agent.agent_id = agent_id
    new_agent.agent_type = agent_type
    new_agent.agent_name = agent_name if not agent_name.is_empty() else "Agent_%s" % agent_id
    
    agents[agent_id] = new_agent
    active_agents.append(agent_id)
    
    agent_registered.emit(agent_id)
    return true

func unregister_agent(agent_id: String) -> void:
    if not agents.has(agent_id):
        return
    
    agents.erase(agent_id)
    active_agents.erase(agent_id)
    agent_unregistered.emit(agent_id)

func get_agent(agent_id: String) -> AgentState2D:
    return agents.get(agent_id, null)

func get_all_agents() -> Dictionary:
    return agents.duplicate()

func get_active_agents() -> Array[String]:
    return active_agents.duplicate()

func update_agent_position(agent_id: String, new_position: Vector2) -> void:
    var agent: AgentState2D = get_agent(agent_id)
    if agent:
        agent.position = new_position

func update_agent_status(agent_id: String, new_status: AgentState2D.AgentStatus) -> void:
    var agent: AgentState2D = get_agent(agent_id)
    if agent:
        agent.status = new_status

func request_agent_action(agent_id: String, action: Dictionary) -> void:
    if not agents.has(agent_id):
        push_error("Agent not found: %s" % agent_id)
        return
    
    agent_action_requested.emit(agent_id, action)

func get_agent_perception(agent_id: String) -> Dictionary:
    var agent: AgentState2D = get_agent(agent_id)
    if not agent:
        return {}
    
    var perception: Dictionary = {
        "agent_id": agent_id,
        "position": [agent.position.x, agent.position.y],
        "nearby_agents": [],
        "nearby_objects": [],
        "visible_events": [],
        "environment": {}
    }
    
    for other_id in active_agents:
        if other_id == agent_id:
            continue
        
        var other_agent: AgentState2D = agents[other_id]
        var distance: float = agent.position.distance_to(other_agent.position)
        
        if distance <= agent.perception_range:
            perception["nearby_agents"].append({
                "agent_id": other_id,
                "distance": distance,
                "position": [other_agent.position.x, other_agent.position.y],
                "status": AgentState2D.AgentStatus.keys()[other_agent.status]
            })
    
    agent_perception_updated.emit(agent_id, perception)
    return perception

func broadcast_event(event: Dictionary) -> void:
    var event_type: String = event.get("type", "")
    var event_position: Vector2 = Vector2.ZERO
    
    var pos_data: Array = event.get("position", [0, 0])
    event_position = Vector2(pos_data[0], pos_data[1])
    
    for agent_id in active_agents:
        var agent: AgentState2D = agents[agent_id]
        var distance: float = agent.position.distance_to(event_position)
        
        if distance <= agent.perception_range:
            agent.add_known_fact("event_%d" % Time.get_ticks_msec(), event)

func get_all_agents_state() -> Dictionary:
    var states: Dictionary = {}
    for agent_id in agents:
        states[agent_id] = agents[agent_id].to_dict()
    return states

func update_all_agents(delta: float) -> void:
    for agent_id in active_agents:
        var agent: AgentState2D = agents[agent_id]
        if agent.status == AgentState2D.AgentStatus.ACTING:
            agent.last_action_time += delta

func _process(delta: float) -> void:
    update_all_agents(delta)