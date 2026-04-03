class_name PlayerController
extends CharacterBody3D

@export var move_speed: float = 5.0
@export var rotation_speed: float = 10.0
@export var interaction_range: float = 3.0

var can_move: bool = true
var interaction_target: Node = null

signal interacted_with(target: Node)
signal movement_started()
signal movement_stopped()

@onready var ray_cast: RayCast3D = $RayCast3D if has_node("RayCast3D") else null

func _physics_process(delta: float) -> void:
    if not can_move:
        return
    
    handle_movement(delta)
    handle_interaction()

func handle_movement(delta: float) -> void:
    var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
    var direction: Vector3 = Vector3(input_dir.x, 0, input_dir.y).normalized()
    
    if direction != Vector3.ZERO:
        var target_rotation: Quaternion = Quaternion.LookRotation(direction, Vector3.UP)
        quaternion = quaternion.slerp(target_rotation, rotation_speed * delta)
        
        velocity.x = direction.x * move_speed
        velocity.z = direction.z * move_speed
        
        movement_started.emit()
    else:
        velocity.x = move_toward(velocity.x, 0, move_speed)
        velocity.z = move_toward(velocity.z, 0, move_speed)
        
        movement_stopped.emit()
    
    move_and_slide()

func handle_interaction() -> void:
    if Input.is_action_just_pressed("interact"):
        attempt_interaction()

func attempt_interaction() -> void:
    var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
    var from: Vector3 = global_position
    var to: Vector3 = from + (-global_basis.z * interaction_range)
    
    var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to)
    query.collision_mask = 2
    
    var result: Dictionary = space_state.intersect_ray(query)
    
    if not result.is_empty():
        var collider: Node = result.get("collider")
        if collider.has_method("interact"):
            collider.interact()
            interacted_with.emit(collider)