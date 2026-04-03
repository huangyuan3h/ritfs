# Rifts 开发指南

## 已搭建的基础架构

### 核心系统

1. **GameManager** - 全局游戏管理
   - 游戏状态管理（菜单/游戏中/暂停/对话）
   - 关卡进度管理
   - 玩家选择记录
   - 存档/读档功能

2. **SceneManager** - 场景管理
   - 场景切换
   - 场景加载回调

3. **DialogueManager** - 对话系统
   - 支持JSON格式的对话数据
   - 多分支选择对话
   - 选择后果记录

4. **AudioManager** - 音频管理
   - 背景音乐播放
   - 音效播放
   - 音量控制
   - 设置保存

### 游戏组件

- **LevelBase** - 关卡基类，管理关卡流程和目标
- **PlayerController** - 3D玩家控制器
- **InteractiveObject** - 可交互物体

### UI组件

- **MainMenu** - 主菜单（新游戏/继续/设置/退出）
- **PauseMenu** - 暂停菜单（ESC键呼出）
- **DialogueUI** - 对话界面

## 下一步操作（需要在Godot编辑器中完成）

### 1. 创建场景文件

在 `scenes/ui/` 创建：
- `main_menu.tscn` - 主菜单场景
- `pause_menu.tscn` - 暂停菜单场景
- `dialogue_ui.tscn` - 对话UI场景

在 `scenes/levels/` 创建：
- `level_0.tscn` - 第一个关卡

### 2. 场景配置步骤

**主菜单场景 (main_menu.tscn)**
```
结构：
Control (MainMenu.gd)
├─ VBoxContainer
   ├─ Label (标题："裂隙之渊")
   ├─ Button (NewGameButton - 新游戏)
   ├─ Button (ContinueButton - 继续)
   ├─ Button (SettingsButton - 设置)
   └─ Button (QuitButton - 退出)
```

**关卡场景 (level_0.tscn)**
```
结构：
Node3D (LevelBase.gd)
├─ DirectionalLight3D
├─ WorldEnvironment
├─ Player (PlayerController.gd)
│  └─ RayCast3D
├─ InteractiveObject (测试用)
└─ 其他关卡元素...
```

### 3. 设置输入映射

已在 project.godot 中配置：
- `move_forward` - W键
- `move_backward` - S键
- `move_left` - A键
- `move_right` - D键
- `interact` - E键
- `pause` - ESC键

### 4. 创建对话数据

在 `resources/data/dialogues/` 创建JSON文件：
```json
{
  "intro_dialogue": {
    "id": "intro_dialogue",
    "lines": [
      {
        "speaker": "???",
        "text": "在裂隙之中，你将直面最真实的自己...",
        "choices": []
      },
      {
        "speaker": "向导",
        "text": "欢迎来到裂隙之渊。每一个选择，都将揭示你内心的矛盾。",
        "choices": [
          {
            "text": "我准备好了",
            "id": "choice_ready",
            "next_dialogue": "tutorial"
          },
          {
            "text": "我还有疑问",
            "id": "choice_doubt",
            "next_dialogue": "explanation"
          }
        ]
      }
    ]
  }
}
```

## 游戏设计建议

### 人性主题关卡设计

每个关卡围绕一个核心人性矛盾：

**关卡1 - 生存 vs 牺牲**
- 场景：损坏的飞船，有限氧气
- 选择：自己独占资源 vs 与他人分享
- 后果：影响后续故事走向

**关卡2 - 真相 vs 安慰**
- 场景：发现隐藏的历史记录
- 选择：揭露真相 vs 保护他人情感
- 后果：改变NPC命运

**关卡3 - 个人 vs 集体**
- 场景：殖民地危机
- 选择：个人利益 vs 集体福祉
- 后果：影响整个社区

**关卡4 - 过去 vs 未来**
- 场景：时空裂隙
- 选择：改变过去 vs 接受现实
- 后果：深刻影响结局

### 玩法机制

1. **选择系统** - 每个选择记录并影响后续
2. **道德量表** - 隐藏的道德评分系统
3. **裂隙能量** - 特殊能力，但使用需付出代价
4. **记忆碎片** - 收集物，揭示故事背景

## 代码示例

### 创建新关卡

```gdscript
extends LevelBase

func setup_level() -> void:
    register_objective("reach_station")
    register_objective("find_data")
    register_objective("make_choice")
    
    # 添加关卡特定逻辑
```

### 创建可交互物体

```gdscript
# 在场景中创建一个InteractiveObject节点
# 附加脚本：

extends InteractiveObject

func interact() -> void:
    super.interact()
    DialogueManager.start_dialogue("terminal_access")
    complete_objective("find_data")
```

### 添加音效

```gdscript
AudioManager.play_music("res://assets/audio/ambient_space.ogg")
AudioManager.play_sfx("res://assets/audio/interaction_beep.ogg")
```

## 资源目录建议

```
assets/
├─ audio/
│  ├─ music/
│  └─ sfx/
├─ models/
│  └─ characters/
├─ textures/
│  └─ environments/
└─ fonts/
```

## 下一步开发重点

1. **创建基础场景** - 在Godot编辑器中创建UI和关卡场景
2. **美术资源** - 添加模型、贴图、音效
3. **第一个关卡** - 实现一个完整的可玩关卡原型
4. **对话内容** - 编写核心对话剧本
5. **测试迭代** - 测试玩法循环和选择系统

## 常用命令

检查脚本语法：
```bash
# 在Godot编辑器中检查所有GDScript文件
```

版本控制：
```bash
git add .
git commit -m "你的提交信息"
git push
```