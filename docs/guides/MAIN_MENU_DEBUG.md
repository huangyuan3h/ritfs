# 主菜单快速调试指南

## 当前问题

**症状：** 点击"唤醒"后，场景停在 `yield(animation_player, "animation_finished")`，显示黑块。

**原因：** 
1. 脚本期待 AnimationPlayer 节点
2. 场景中没有动画播放器
3. `yield` 一直等待，无法继续

---

## ✅ 已修复

我已经修改了脚本：

### 改进1：跳过动画检查
```gdscript
# 如果没有AnimationPlayer，直接进入游戏
if not has_node("AnimationPlayer"):
    transition_to_game()
    return
```

### 改进2：安全的节点引用
```gdscript
# 使用 get_node_or_null 而不是直接引用
wake_button = get_node_or_null("VBoxContainer/WakeButton")
```

### 改进3：关卡不存在提示
```gdscript
# 如果关卡不存在，显示提示而不是崩溃
if ResourceLoader.exists(scene_path):
    get_tree().change_scene_to_file(scene_path)
else:
    show_message_dialog("关卡未找到", "第一关卡场景尚未创建")
```

---

## 🎮 现在测试

### 步骤1：重新加载脚本

1. **关闭Godot编辑器**
2. **重新打开项目**
3. **打开场景** `scenes/ui/main_menu.tscn`
4. **按F6运行**

### 步骤2：预期行为

**点击"唤醒"后：**
- ✅ 应该看到淡出过渡（0.5秒）
- ⚠️ 然后提示："关卡未找到"
  - 这是正常的，因为还没创建第一关卡

**点击"回归"后：**
- ✅ 应该提示："无记忆痕迹"
  - 这是正常的，因为还没有存档

**点击"退出"后：**
- ✅ 应该显示确认对话框

---

## 🚨 如果还有问题

### 检查控制台输出

在Godot编辑器底部，打开 **输出** 标签，查看：
```
MainMenu ready...
MainMenu initialized successfully
Transitioning to game...
```

如果看到错误，复制给我。

### 检查节点路径

在场景树中确认节点名称：
```
MainMenu (Control)
└─ VBoxContainer
   ├─ WakeButton ✓
   ├─ ReturnButton ✓
   └─ ExitButton ✓
```

**节点名称必须完全匹配！**

---

## 🎯 快速验证

### 测试1：基本按钮

**创建一个最简单的测试场景：**

1. **创建新场景**：Control
2. **添加3个Button**，命名为：
   - `WakeButton`
   - `ReturnButton`
   - `ExitButton`
3. **附加脚本**：`scripts/ui/main_menu_3d.gd`
4. **运行**

**如果这个能工作，说明脚本没问题，是场景节点路径的问题。**

---

## 💡 调试技巧

### 添加打印语句

在脚本中添加更多打印：
```gdscript
func _on_wake_pressed() -> void:
    print("=== Wake button pressed ===")
    # ... 其他代码
```

### 检查节点引用

在 `_ready()` 中打印节点：
```gdscript
func _ready() -> void:
    print("WakeButton: ", wake_button)
    print("ReturnButton: ", return_button)
    print("ExitButton: ", exit_button)
```

---

## 📊 下一步

### 确认基本功能后

1. ✅ 按钮可以点击
2. ✅ 对话框可以显示
3. ✅ 过渡效果正常

### 然后创建第一关卡

在Godot中创建占位符关卡：
1. **创建新场景**：Node2D
2. **添加Label**："Level 0 - 测试关卡"
3. **保存为**：`scenes/levels/level_0.tscn`

---

## 🎨 最终优化（可选）

### 添加动画播放器（可选）

**在场景中添加AnimationPlayer：**

1. **右键 MainMenu** → 添加子节点 → AnimationPlayer
2. **创建动画**：
   - 名称：`fade_in`
   - 时长：1.0秒
   - 轨道：`ColorRect:color:a`
   - 0.0秒：0.0
   - 1.0秒：1.0

### 添加背景图片（可选）

1. **添加TextureRect**（在ColorRect下面）
2. **设置Texture**：导入的背景图片
3. **Layout**：Full Rect

---

## 📝 总结

**核心问题：** 脚本期待某些节点，但场景中没有。

**解决方案：** 
1. 修改脚本，添加安全检查
2. 先测试基本功能
3. 后续再添加美术和动画

**现在应该可以正常运行了！如果还有问题，请告诉我控制台的完整错误信息。** 🚀