class_name InteractiveObject
extends Area3D

@export var object_name: String = "Interactive Object"
@export var interaction_text: String = "Press E to interact"
@export var is_enabled: bool = true
@export var one_time_use: bool = false

var has_been_used: bool = false

signal interacted(player: Node)
signal interaction_enabled()
signal interaction_disabled()

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func interact() -> void:
    if not is_enabled:
        return
    
    if one_time_use and has_been_used:
        return
    
    has_been_used = true
    interacted.emit(get_tree().get_first_node_in_group("player"))

func enable_interaction() -> void:
    is_enabled = true
    interaction_enabled.emit()

func disable_interaction() -> void:
    is_enabled = false
    interaction_disabled.emit()

func _on_body_entered(body: Node) -> void:
    if body.is_in_group("player"):
        pass

func _on_body_exited(body: Node) -> void:
    if body.is_in_group("player"):
        pass