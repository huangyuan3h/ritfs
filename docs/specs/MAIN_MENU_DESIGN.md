# 主菜单设计文档

## 场景概述

**主菜单界面**是玩家进入游戏的第一印象，结合3D真实场景与交互界面。

---

## 视觉设计

### 背景：3D睡眠舱场景

**场景构成：**
```
主菜单场景 (MainMenu3D.tscn)
├─ WorldEnvironment        # 环境设置
│  └─ Sky (太空背景)
├─ DirectionalLight3D      # 主光源
├─ SleepChamber            # 睡眠舱模型
│  ├─ ChamberBody          # 舱体
│  ├─ ChamberDoor          # 舱门（可动画）
│  └─ Character            # 沉睡的角色
├─ Camera3D                # 摄像机
└─ Particles               # 环境粒子效果
   ├─ Dust                 # 灰尘粒子
   └─ LightBeams           # 光束效果
```

**视觉氛围：**
- 冷色调（蓝、青、白）
- 微弱的环境光
- 睡眠舱内发光效果
- 太空舱内部细节
- 悬浮粒子营造深度感

**摄像机视角：**
- 初始：远景，看到完整睡眠舱
- 悬停：缓慢推进，聚焦舱内
- 动态：微微摇晃，营造真实感

---

### UI界面设计

**布局结构：**
```
MainMenuUI (Control)
├─ BackgroundOverlay       # 半透明遮罩
├─ TitleContainer          # 标题区域
│  ├─ GameTitle            # "裂隙之渊"
│  └─ SubTitle             # "Rifts"
├─ MenuContainer           # 菜单选项
│  ├─ WakeButton           # 唤醒（新游戏）
│  ├─ ReturnButton         # 回归（读取存档）
│  └─ ExitButton           # 退出
└─ Footer                  # 底部信息
   ├─ Version              # 版本号
   └─ Copyright            # 版权信息
```

**视觉风格：**
- 极简科幻风格
- 半透明玻璃效果（Frost Glass）
- 发光边缘（Glow Border）
- 悬停动画（Hover Animation）
- 点击音效（Sound Feedback）

---

## 菜单选项

### 1. 唤醒（新游戏）

**功能：**
- 开始全新游戏
- 清除旧存档（可选）
- 触发唤醒过场动画

**交互流程：**
```
点击"唤醒"
  ↓
询问确认（如果有旧存档）
  ↓
初始化新游戏状态
  ↓
播放过场动画（睡眠舱打开）
  ↓
进入第一关卡
```

**视觉反馈：**
- 按钮发光增强
- 音效："系统启动"
- 屏幕渐黑过渡

---

### 2. 回归（读取存档）

**功能：**
- 读取已保存的游戏进度
- 完全恢复游戏状态
- 继续上次的游戏

**交互流程：**
```
点击"回归"
  ↓
检测存档文件
  ├─ 有存档
  │   └─ 显示存档信息
  │       └─ 确认读取
  │           └─ 恢复状态
  │               └─ 进入游戏
  └─ 无存档
      └─ 提示"无记忆痕迹"
          └─ 返回菜单
```

**存档显示：**
```
┌────────────────────────────┐
│ 记忆痕迹 #001              │
├────────────────────────────┤
│ 关卡：第3关 - 真相之裂隙   │
│ 时间：2026-04-03 20:30    │
│ 道德值：+15 (利他倾向)    │
│ 选择次数：42              │
│                            │
│ [确认读取]   [取消]        │
└────────────────────────────┘
```

---

### 3. 退出

**功能：**
- 退出游戏应用

**交互流程：**
```
点击"退出"
  ↓
确认对话框
  ├─ 确认 → 关闭游戏
  └─ 取消 → 返回菜单
```

---

## 过场动画：睡眠舱打开

### 动画序列

**阶段1：系统唤醒（2秒）**
```
画面：睡眠舱特写
音效：系统启动声、哔哔声
视觉：舱内灯光闪烁
文字："系统启动中..."
```

**阶段2：舱门开启（3秒）**
```
画面：舱门缓慢打开
音效：气压释放声、机械声
视觉：蒸汽喷出、光线射入
动画：舱门滑动、镜头推进
```

**阶段3：角色苏醒（2秒）**
```
画面：角色睁眼
音效：呼吸声、心跳声
视觉：角色轻微移动
文字："在裂隙中苏醒..."
```

**阶段4：场景过渡（1秒）**
```
画面：淡出到白色
音效：渐强音效
转场：加载第一关卡
```

---

## 状态管理：Redux风格

### 核心理念

**单一状态树 (Single Source of Truth)**

所有游戏状态存储在一个巨大的JSON对象中，类似于Redux的store。

### 状态结构

```json
{
  "meta": {
    "version": "1.0.0",
    "created_at": "2026-04-03T20:30:00Z",
    "updated_at": "2026-04-03T20:45:00Z",
    "play_time": 3600,
    "save_slot": 1
  },
  
  "game": {
    "current_scene": "level_3",
    "current_state": "PLAYING",
    "difficulty": "NORMAL",
    "game_time": 1234.56
  },
  
  "player": {
    "id": "player_001",
    "name": "旅行者",
    "position": [100.5, 200.3],
    "rotation": 45.0,
    "health": 100,
    "moral_score": 15.5,
    "inventory": [
      {
        "id": "item_key_001",
        "name": "裂隙钥匙",
        "count": 1,
        "metadata": {}
      }
    ]
  },
  
  "progress": {
    "current_level": 3,
    "unlocked_levels": [0, 1, 2, 3],
    "completed_levels": [0, 1, 2],
    "achievements": ["first_choice", "moral_balance"]
  },
  
  "narrative": {
    "current_dialogue": null,
    "dialogue_history": [
      {
        "dialogue_id": "intro_001",
        "timestamp": 123.45,
        "choices": ["choice_a", "choice_b"],
        "selected": "choice_a"
      }
    ],
    "known_facts": {
      "character_alice_met": true,
      "secret_revealed": false
    },
    "relationships": {
      "alice": 75.5,
      "bob": -10.2
    }
  },
  
  "choices": {
    "total_choices": 42,
    "moral_choices": {
      "altruistic": 25,
      "selfish": 12,
      "neutral": 5
    },
    "choice_history": [
      {
        "id": "choice_001",
        "scenario": "oxygen_crisis",
        "choice": "share_oxygen",
        "moral_impact": 5.0,
        "timestamp": 456.78
      }
    ]
  },
  
  "agents": {
    "active_agents": ["agent_alice", "agent_bob"],
    "agent_states": {
      "agent_alice": {
        "id": "agent_alice",
        "position": [150.0, 180.5],
        "status": "IDLE",
        "moral_score": 20.3
      }
    }
  },
  
  "settings": {
    "audio": {
      "master_volume": 0.8,
      "music_volume": 0.6,
      "sfx_volume": 0.7,
      "voice_volume": 1.0
    },
    "graphics": {
      "quality": "HIGH",
      "vsync": true,
      "fullscreen": false
    },
    "controls": {
      "voice_enabled": true,
      "language": "zh-CN"
    }
  },
  
  "world": {
    "time_of_day": 0.75,
    "weather": "clear",
    "active_events": ["event_storm_approaching"],
    "world_state": {
      "station_power": 75,
      "oxygen_level": 90,
      "temperature": 22.5
    }
  }
}
```

---

## 存档系统实现

### 文件结构

```
user://
├─ saves/
│  ├─ slot_001.json         # 存档槽1
│  ├─ slot_002.json         # 存档槽2
│  ├─ slot_003.json         # 存档槽3
│  └─ autosave.json         # 自动存档
├─ settings/
│  └─ config.json           # 全局设置
└─ cache/
   └─ temp.json             # 临时缓存
```

### 状态管理类

```gdscript
class_name GameStateManager
extends RefCounted

const SAVE_DIR: String = "user://saves/"
const CURRENT_VERSION: String = "1.0.0"

var state: Dictionary = {}
var current_slot: int = 0
var is_dirty: bool = false

signal state_changed(path: String, value: Variant)
signal state_saved(slot: int)
signal state_loaded(slot: int)

func _init() -> void:
    initialize_default_state()
    ensure_save_directory()

func initialize_default_state() -> void:
    state = {
        "meta": create_meta(),
        "game": create_default_game(),
        "player": create_default_player(),
        "progress": create_default_progress(),
        "narrative": create_default_narrative(),
        "choices": create_default_choices(),
        "agents": create_default_agents(),
        "settings": create_default_settings(),
        "world": create_default_world()
    }

func get_state(path: String = "", default: Variant = null) -> Variant:
    if path.is_empty():
        return state
    
    var keys: Array = path.split(".")
    var current: Variant = state
    
    for key in keys:
        if current is Dictionary and current.has(key):
            current = current[key]
        else:
            return default
    
    return current

func set_state(path: String, value: Variant) -> void:
    var keys: Array = path.split(".")
    var current: Dictionary = state
    
    for i in range(keys.size() - 1):
        var key: String = keys[i]
        if not current.has(key):
            current[key] = {}
        current = current[key]
    
    current[keys[-1]] = value
    is_dirty = true
    state_changed.emit(path, value)

func dispatch(action: String, payload: Dictionary = {}) -> void:
    match action:
        "PLAYER_MOVE":
            set_state("player.position", payload.get("position", [0, 0]))
        
        "PLAYER_MORAL_CHANGE":
            var current_score: float = get_state("player.moral_score", 0.0)
            set_state("player.moral_score", current_score + payload.get("delta", 0.0))
        
        "CHOICE_MAKE":
            add_choice_to_history(payload)
        
        "LEVEL_COMPLETE":
            complete_level(payload.get("level_id", 0))
        
        "ITEM_ADD":
            add_item_to_inventory(payload)
        
        "DIALOGUE_START":
            set_state("narrative.current_dialogue", payload.get("dialogue_id"))
        
        "DIALOGUE_END":
            set_state("narrative.current_dialogue", null)
            add_dialogue_to_history(payload)
        
        "RELATIONSHIP_UPDATE":
            update_relationship(payload.get("character_id"), payload.get("delta", 0.0))
        
        "WORLD_EVENT_TRIGGER":
            trigger_world_event(payload)
        
        "GAME_SAVE":
            save_game(payload.get("slot", 1))
        
        "GAME_LOAD":
            load_game(payload.get("slot", 1))

func save_game(slot: int = 1) -> bool:
    update_meta()
    
    var file_path: String = SAVE_DIR + "slot_%03d.json" % slot
    var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
    
    if file == null:
        push_error("Failed to open save file: " + file_path)
        return false
    
    var json_string: String = JSON.stringify(state, "  ")
    file.store_string(json_string)
    file.close()
    
    current_slot = slot
    is_dirty = false
    state_saved.emit(slot)
    
    return true

func load_game(slot: int = 1) -> bool:
    var file_path: String = SAVE_DIR + "slot_%03d.json" % slot
    
    if not FileAccess.file_exists(file_path):
        push_error("Save file not found: " + file_path)
        return false
    
    var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
    
    if file == null:
        push_error("Failed to open save file: " + file_path)
        return false
    
    var json_string: String = file.get_as_text()
    file.close()
    
    var json: JSON = JSON.new()
    if json.parse(json_string) != OK:
        push_error("Failed to parse save file")
        return false
    
    state = json.data
    current_slot = slot
    is_dirty = false
    state_loaded.emit(slot)
    
    return true

func has_save(slot: int = 1) -> bool:
    var file_path: String = SAVE_DIR + "slot_%03d.json" % slot
    return FileAccess.file_exists(file_path)

func delete_save(slot: int = 1) -> bool:
    var file_path: String = SAVE_DIR + "slot_%03d.json" % slot
    
    if FileAccess.file_exists(file_path):
        var error: int = DirAccess.remove_absolute(file_path)
        return error == OK
    
    return false

func get_save_info(slot: int = 1) -> Dictionary:
    if not has_save(slot):
        return {}
    
    var file_path: String = SAVE_DIR + "slot_%03d.json" % slot
    var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
    
    if file == null:
        return {}
    
    var json_string: String = file.get_as_text()
    file.close()
    
    var json: JSON = JSON.new()
    if json.parse(json_string) != OK:
        return {}
    
    var data: Dictionary = json.data
    
    return {
        "slot": slot,
        "created_at": data.get("meta", {}).get("created_at", "Unknown"),
        "updated_at": data.get("meta", {}).get("updated_at", "Unknown"),
        "play_time": data.get("meta", {}).get("play_time", 0),
        "current_level": data.get("progress", {}).get("current_level", 0),
        "moral_score": data.get("player", {}).get("moral_score", 0.0),
        "total_choices": data.get("choices", {}).get("total_choices", 0)
    }

func update_meta() -> void:
    set_state("meta.updated_at", Time.get_datetime_string_from_system())
    set_state("meta.version", CURRENT_VERSION)

func ensure_save_directory() -> void:
    if not DirAccess.dir_exists_absolute(SAVE_DIR):
        DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func create_meta() -> Dictionary:
    return {
        "version": CURRENT_VERSION,
        "created_at": Time.get_datetime_string_from_system(),
        "updated_at": Time.get_datetime_string_from_system(),
        "play_time": 0,
        "save_slot": 1
    }

func create_default_game() -> Dictionary:
    return {
        "current_scene": "main_menu",
        "current_state": "MENU",
        "difficulty": "NORMAL",
        "game_time": 0.0
    }

func create_default_player() -> Dictionary:
    return {
        "id": "player_001",
        "name": "旅行者",
        "position": [0.0, 0.0],
        "rotation": 0.0,
        "health": 100,
        "moral_score": 0.0,
        "inventory": []
    }

func create_default_progress() -> Dictionary:
    return {
        "current_level": 0,
        "unlocked_levels": [0],
        "completed_levels": [],
        "achievements": []
    }

func create_default_narrative() -> Dictionary:
    return {
        "current_dialogue": null,
        "dialogue_history": [],
        "known_facts": {},
        "relationships": {}
    }

func create_default_choices() -> Dictionary:
    return {
        "total_choices": 0,
        "moral_choices": {
            "altruistic": 0,
            "selfish": 0,
            "neutral": 0
        },
        "choice_history": []
    }

func create_default_agents() -> Dictionary:
    return {
        "active_agents": [],
        "agent_states": {}
    }

func create_default_settings() -> Dictionary:
    return {
        "audio": {
            "master_volume": 1.0,
            "music_volume": 0.7,
            "sfx_volume": 0.8,
            "voice_volume": 1.0
        },
        "graphics": {
            "quality": "HIGH",
            "vsync": true,
            "fullscreen": false
        },
        "controls": {
            "voice_enabled": false,
            "language": "zh-CN"
        }
    }

func create_default_world() -> Dictionary:
    return {
        "time_of_day": 0.5,
        "weather": "clear",
        "active_events": [],
        "world_state": {}
    }

func add_choice_to_history(choice_data: Dictionary) -> void:
    var history: Array = get_state("choices.choice_history", [])
    history.append({
        "id": choice_data.get("id", "choice_%d" % history.size()),
        "scenario": choice_data.get("scenario"),
        "choice": choice_data.get("choice"),
        "moral_impact": choice_data.get("moral_impact", 0.0),
        "timestamp": get_state("game.game_time", 0.0)
    })
    set_state("choices.choice_history", history)
    
    var total: int = get_state("choices.total_choices", 0)
    set_state("choices.total_choices", total + 1)

func complete_level(level_id: int) -> void:
    var completed: Array = get_state("progress.completed_levels", [])
    if level_id not in completed:
        completed.append(level_id)
        set_state("progress.completed_levels", completed)
    
    var unlocked: Array = get_state("progress.unlocked_levels", [])
    var next_level: int = level_id + 1
    if next_level not in unlocked:
        unlocked.append(next_level)
        set_state("progress.unlocked_levels", unlocked)

func add_item_to_inventory(item_data: Dictionary) -> void:
    var inventory: Array = get_state("player.inventory", [])
    inventory.append(item_data)
    set_state("player.inventory", inventory)

func add_dialogue_to_history(dialogue_data: Dictionary) -> void:
    var history: Array = get_state("narrative.dialogue_history", [])
    history.append({
        "dialogue_id": dialogue_data.get("dialogue_id"),
        "timestamp": get_state("game.game_time", 0.0),
        "choices": dialogue_data.get("choices", []),
        "selected": dialogue_data.get("selected")
    })
    set_state("narrative.dialogue_history", history)

func update_relationship(character_id: String, delta: float) -> void:
    var relationships: Dictionary = get_state("narrative.relationships", {})
    if not relationships.has(character_id):
        relationships[character_id] = 0.0
    relationships[character_id] = clamp(relationships[character_id] + delta, -100.0, 100.0)
    set_state("narrative.relationships", relationships)

func trigger_world_event(event_data: Dictionary) -> void:
    var events: Array = get_state("world.active_events", [])
    events.append(event_data.get("event_id"))
    set_state("world.active_events", events)
```

---

## 主菜单实现

### 主菜单脚本

```gdscript
extends Control

@onready var wake_button: Button = $MenuContainer/WakeButton
@onready var return_button: Button = $MenuContainer/ReturnButton
@onready var exit_button: Button = $MenuContainer/ExitButton
@onready var confirmation_dialog: ConfirmationDialog = $ConfirmationDialog

var game_state: GameStateManager = GameStateManager.new()

func _ready() -> void:
    setup_buttons()
    check_save_files()
    play_ambient_effects()

func setup_buttons() -> void:
    wake_button.pressed.connect(_on_wake_pressed)
    return_button.pressed.connect(_on_return_pressed)
    exit_button.pressed.connect(_on_exit_pressed)

func check_save_files() -> void:
    return_button.disabled = not game_state.has_save(1)

func play_ambient_effects() -> void:
    AudioManager.play_music("res://assets/audio/music/menu_ambient.ogg")

func _on_wake_pressed() -> void:
    if game_state.has_save(1):
        show_confirmation(
            "发现记忆痕迹",
            "唤醒将清除现有记忆，是否继续？",
            start_new_game
        )
    else:
        start_new_game()

func _on_return_pressed() -> void:
    var save_info: Dictionary = game_state.get_save_info(1)
    
    if save_info.is_empty():
        show_message("无记忆痕迹", "未找到保存的记忆。")
        return
    
    show_save_info_dialog(save_info)

func _on_exit_pressed() -> void:
    show_confirmation(
        "离开裂隙",
        "确定要离开吗？",
        func(): get_tree().quit()
    )

func start_new_game() -> void:
    game_state.initialize_default_state()
    game_state.dispatch("GAME_SAVE", {"slot": 1})
    
    GameStateManager = game_state
    
    play_wake_animation()

func load_game() -> void:
    if game_state.load_game(1):
        GameStateManager = game_state
        transition_to_scene(game_state.get_state("game.current_scene"))
    else:
        show_message("加载失败", "无法读取记忆痕迹。")

func play_wake_animation() -> void:
    AudioManager.fade_out_music(1.0)
    
    var animation_player: AnimationPlayer = $AnimationPlayer
    animation_player.play("wake_sequence")
    
    await animation_player.animation_finished
    
    transition_to_scene("res://scenes/levels/level_0.tscn")

func transition_to_scene(scene_path: String) -> void:
    var transition: ColorRect = $TransitionOverlay
    transition.visible = true
    
    var tween: Tween = create_tween()
    tween.tween_property(transition, "modulate:a", 1.0, 1.0)
    
    await tween.finished
    get_tree().change_scene_to_file(scene_path)

func show_confirmation(title: String, message: String, on_confirm: Callable) -> void:
    confirmation_dialog.dialog_text = message
    confirmation_dialog.title = title
    
    confirmation_dialog.confirmed.connect(on_confirm, CONNECT_ONE_SHOT)
    confirmation_dialog.popup_centered()

func show_message(title: String, message: String) -> void:
    var dialog: AcceptDialog = AcceptDialog.new()
    dialog.dialog_text = message
    dialog.title = title
    
    add_child(dialog)
    dialog.popup_centered()
    
    await dialog.confirmed
    dialog.queue_free()

func show_save_info_dialog(save_info: Dictionary) -> void:
    var dialog: ConfirmationDialog = ConfirmationDialog.new()
    
    var info_text: String = """
记忆痕迹 #%03d

关卡：第%d关
时间：%s
游戏时长：%.1f小时
道德值：%.1f
选择次数：%d

是否读取此记忆？
""" % [
        save_info.get("slot", 1),
        save_info.get("current_level", 0) + 1,
        save_info.get("updated_at", "Unknown"),
        save_info.get("play_time", 0) / 3600.0,
        save_info.get("moral_score", 0.0),
        save_info.get("total_choices", 0)
    ]
    
    dialog.dialog_text = info_text
    dialog.title = "记忆痕迹"
    
    dialog.confirmed.connect(load_game, CONNECT_ONE_SHOT)
    
    add_child(dialog)
    dialog.popup_centered()
```

---

## 下一步实现

1. **在Godot中创建主菜单场景**
   - 添加3D背景节点
   - 创建UI布局
   - 配置动画

2. **导入资源**
   - 睡眠舱模型（GLTF/FBX）
   - 角色模型
   - 音效和音乐
   - 粒子效果

3. **测试存档系统**
   - 测试保存/加载
   - 验证状态恢复
   - 测试多个存档槽

---

*"在裂隙的边界，记忆等待被唤醒"*