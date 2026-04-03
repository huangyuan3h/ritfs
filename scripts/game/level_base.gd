class_name LevelBase
extends Node3D

@export var level_id: int = 0
@export var level_name: String = "Untitled Level"
@export var theme: String = ""
@export var moral_question: String = ""

var objectives_completed: Array[String] = []
var objectives_total: Array[String] = []

signal objective_completed(objective_id: String)
signal level_started()
signal level_finished()

func _ready() -> void:
    setup_level()
    start_level()

func setup_level() -> void:
    pass

func start_level() -> void:
    GameManager.change_state(GameState.State.PLAYING)
    level_started.emit()

func complete_objective(objective_id: String) -> void:
    if objective_id not in objectives_completed:
        objectives_completed.append(objective_id)
        objective_completed.emit(objective_id)
        
        if objectives_completed.size() == objectives_total.size():
            finish_level()

func register_objective(objective_id: String) -> void:
    if objective_id not in objectives_total:
        objectives_total.append(objective_id)

func finish_level() -> void:
    level_finished.emit()
    GameManager.complete_current_level()
    await get_tree().create_timer(2.0).timeout
    show_level_summary()

func show_level_summary() -> void:
    pass

func get_progress() -> float:
    if objectives_total.is_empty():
        return 0.0
    return float(objectives_completed.size()) / float(objectives_total.size())