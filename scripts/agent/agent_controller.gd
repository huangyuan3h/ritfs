class_name AgentController
extends Node3D

@export var agent_id: String = ""
@export var movement_speed: float = 3.0
@export var interaction_range: float = 2.0
@export var auto_act: bool = false

var agent_state: AgentState = null
var current_action: Dictionary = {}
var action_progress: float = 0.0

signal action_completed(action_id: String)
signal action_failed(action_id: String, reason: String)

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D if has_node("NavigationAgent3D") else null

func _ready() -> void:
    if agent_id.is_empty():
        agent_id = "agent_%d" % get_instance_id()
    
    initialize_agent_state()
    AgentManager.agent_action_requested.connect(_on_action_requested)

func initialize_agent_state() -> void:
    agent_state = AgentState.new()
    agent_state.agent_id = agent_id
    agent_state.agent_type = AgentState.AgentType.RULE_BASED
    agent_state.position = global_position
    
    AgentManager.register_agent(agent_id, agent_state.agent_type, agent_state.agent_name)

func _physics_process(delta: float) -> void:
    update_agent_position()
    
    if agent_state.has_pending_actions():
        execute_next_action(delta)
    
    if auto_act and not agent_state.has_pending_actions():
        decide_next_action()

func update_agent_position() -> void:
    agent_state.position = global_position
    agent_state.rotation = global_rotation

func execute_next_action(delta: float) -> void:
    if current_action.is_empty():
        current_action = agent_state.get_next_action()
        action_progress = 0.0
    
    if current_action.is_empty():
        return
    
    var action_type: String = current_action.get("type", "")
    
    match action_type:
        "move":
            execute_move_action(current_action, delta)
        "interact":
            execute_interact_action(current_action)
        "dialogue":
            execute_dialogue_action(current_action)
        "wait":
            execute_wait_action(current_action, delta)
        "observe":
            execute_observe_action(current_action)
        _:
            action_failed.emit(current_action.get("id", "unknown"), "Unknown action type")

func execute_move_action(action: Dictionary, delta: float) -> void:
    var target_position_data: Array = action.get("target_position", [0, 0, 0])
    var target_position: Vector3 = Vector3(target_position_data[0], target_position_data[1], target_position_data[2])
    
    if navigation_agent:
        navigation_agent.target_position = target_position
        
        if navigation_agent.is_navigation_finished():
            action_completed.emit(action.get("id", "move"))
            current_action = {}
            return
        
        var next_position: Vector3 = navigation_agent.get_next_path_position()
        var direction: Vector3 = (next_position - global_position).normalized()
        
        global_position += direction * movement_speed * delta
        agent_state.velocity = direction * movement_speed
    else:
        var direction: Vector3 = (target_position - global_position).normalized()
        var distance: float = global_position.distance_to(target_position)
        
        if distance < 0.5:
            action_completed.emit(action.get("id", "move"))
            current_action = {}
            agent_state.velocity = Vector3.ZERO
            return
        
        global_position += direction * movement_speed * delta
        agent_state.velocity = direction * movement_speed

func execute_interact_action(action: Dictionary) -> void:
    var target_id: String = action.get("target_id", "")
    
    var target_node: Node = get_tree().current_scene.find_child(target_id)
    if target_node == null:
        action_failed.emit(action.get("id", "interact"), "Target not found")
        current_action = {}
        return
    
    if target_node.has_method("interact"):
        target_node.interact()
        agent_state.total_interactions += 1
        action_completed.emit(action.get("id", "interact"))
    else:
        action_failed.emit(action.get("id", "interact"), "Target not interactive")
    
    current_action = {}

func execute_dialogue_action(action: Dictionary) -> void:
    var dialogue_id: String = action.get("dialogue_id", "")
    var choice_index: int = action.get("choice_index", -1)
    
    if not dialogue_id.is_empty():
        DialogueManager.start_dialogue(dialogue_id)
        agent_state.current_dialogue = dialogue_id
        action_completed.emit(action.get("id", "dialogue"))
    elif choice_index >= 0:
        DialogueManager.select_choice(choice_index)
        agent_state.current_dialogue = ""
        action_completed.emit(action.get("id", "dialogue_choice"))
    
    current_action = {}

func execute_wait_action(action: Dictionary, delta: float) -> void:
    var duration: float = action.get("duration", 1.0)
    action_progress += delta
    
    if action_progress >= duration:
        action_completed.emit(action.get("id", "wait"))
        current_action = {}
        action_progress = 0.0

func execute_observe_action(action: Dictionary) -> void:
    var perception: Dictionary = AgentManager.get_agent_perception(agent_id)
    agent_state.add_known_fact("observation_%d" % Time.get_ticks_msec(), perception)
    action_completed.emit(action.get("id", "observe"))
    current_action = {}

func decide_next_action() -> void:
    var perception: Dictionary = AgentManager.get_agent_perception(agent_id)
    
    if not perception.get("nearby_agents", []).is_empty():
        var nearby: Array = perception["nearby_agents"]
        if nearby.size() > 0:
            var nearest: Dictionary = nearby[0]
            var target_id: String = nearest.get("agent_id", "")
            
            if agent_state.relationships.get(target_id, 0.0) > 0:
                agent_state.queue_action({
                    "id": "approach_%s" % target_id,
                    "type": "move",
                    "target_position": nearest.get("position", [0, 0, 0])
                })
    
    if randf() < 0.1:
        agent_state.queue_action({
            "id": "random_observe",
            "type": "observe"
        })

func _on_action_requested(requested_agent_id: String, action: Dictionary) -> void:
    if requested_agent_id == agent_id:
        agent_state.queue_action(action)
        agent_state.status = AgentState.AgentStatus.ACTING

func force_action(action: Dictionary) -> void:
    agent_state.queue_action(action)

func stop_current_action() -> void:
    current_action = {}
    agent_state.action_queue.clear()
    agent_state.status = AgentState.AgentStatus.IDLE
    agent_state.velocity = Vector3.ZERO