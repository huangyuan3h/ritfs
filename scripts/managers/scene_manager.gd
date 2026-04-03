extends Node

var current_scene: Node = null
var loading_scene: bool = false

signal scene_loaded(scene: Node)
signal scene_unloaded(scene: Node)

func _ready() -> void:
    current_scene = get_tree().current_scene

func change_scene(scene_path: String) -> void:
    if loading_scene:
        return
    
    loading_scene = true
    
    if current_scene:
        scene_unloaded.emit(current_scene)
    
    get_tree().change_scene_to_file(scene_path)
    await get_tree().tree_changed
    
    current_scene = get_tree().current_scene
    loading_scene = false
    scene_loaded.emit(current_scene)

func change_scene_to(scene: PackedScene) -> void:
    if loading_scene:
        return
    
    loading_scene = true
    
    if current_scene:
        scene_unloaded.emit(current_scene)
    
    get_tree().change_scene_to_packed(scene)
    await get_tree().tree_changed
    
    current_scene = get_tree().current_scene
    loading_scene = false
    scene_loaded.emit(current_scene)

func reload_current_scene() -> void:
    if current_scene:
        get_tree().reload_current_scene()

func get_current_scene() -> Node:
    return current_scene