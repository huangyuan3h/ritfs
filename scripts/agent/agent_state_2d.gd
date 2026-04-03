class_name AgentState2D
extends RefCounted

enum AgentType { LLM, RULE_BASED, HUMAN, HYBRID }
enum AgentStatus { IDLE, THINKING, ACTING, WAITING }

var agent_id: String = ""
var agent_name: String = ""
var agent_type: AgentType = AgentType.RULE_BASED
var status: AgentStatus = AgentStatus.IDLE

var position: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO

var inventory: Array[String] = []
var active_objectives: Array[String] = []
var completed_objectives: Array[String] = []
var known_facts: Dictionary = {}
var relationships: Dictionary = {}

var current_dialogue: String = ""
var dialogue_history: Array[Dictionary] = []
var action_queue: Array[Dictionary] = []

var perception_range: float = 300.0

var last_action_time: float = 0.0
var total_interactions: int = 0
var moral_score: float = 0.0

func to_dict() -> Dictionary:
    return {
        "agent_id": agent_id,
        "agent_name": agent_name,
        "agent_type": AgentType.keys()[agent_type],
        "status": AgentStatus.keys()[status],
        "position": [position.x, position.y],
        "velocity": [velocity.x, velocity.y],
        "inventory": inventory,
        "active_objectives": active_objectives,
        "completed_objectives": completed_objectives,
        "known_facts": known_facts,
        "relationships": relationships,
        "current_dialogue": current_dialogue,
        "perception_range": perception_range,
        "last_action_time": last_action_time,
        "total_interactions": total_interactions,
        "moral_score": moral_score
    }

func from_dict(data: Dictionary) -> void:
    agent_id = data.get("agent_id", "")
    agent_name = data.get("agent_name", "Unknown Agent")
    agent_type = AgentType.keys().find(data.get("agent_type", "RULE_BASED"))
    status = AgentStatus.keys().find(data.get("status", "IDLE"))
    
    var pos_data: Array = data.get("position", [0, 0])
    position = Vector2(pos_data[0], pos_data[1])
    
    var vel_data: Array = data.get("velocity", [0, 0])
    velocity = Vector2(vel_data[0], vel_data[1])
    
    inventory = data.get("inventory", [])
    active_objectives = data.get("active_objectives", [])
    completed_objectives = data.get("completed_objectives", [])
    known_facts = data.get("known_facts", {})
    relationships = data.get("relationships", {})
    current_dialogue = data.get("current_dialogue", "")
    perception_range = data.get("perception_range", 300.0)
    last_action_time = data.get("last_action_time", 0.0)
    total_interactions = data.get("total_interactions", 0)
    moral_score = data.get("moral_score", 0.0)

func add_known_fact(fact_key: String, fact_value: Variant) -> void:
    known_facts[fact_key] = fact_value

func update_relationship(target_id: String, delta: float) -> void:
    if not relationships.has(target_id):
        relationships[target_id] = 0.0
    relationships[target_id] = clamp(relationships[target_id] + delta, -100.0, 100.0)

func queue_action(action: Dictionary) -> void:
    action_queue.append(action)

func get_next_action() -> Dictionary:
    if action_queue.is_empty():
        return {}
    return action_queue.pop_front()

func has_pending_actions() -> bool:
    return not action_queue.is_empty()

func add_dialogue_entry(speaker: String, message: String) -> void:
    dialogue_history.append({
        "speaker": speaker,
        "message": message,
        "timestamp": Time.get_ticks_msec() / 1000.0
    })