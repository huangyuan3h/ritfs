# 主菜单场景创建指南（简化版）

## ⚠️ 当前限制

**我无法创建完整的Godot 4场景文件**，因为：
- 场景文件格式复杂
- 需要精确的UID和资源引用
- 3D节点需要材质和网格引用

---

## ✅ 推荐方案：在Godot编辑器中创建

### 步骤1：创建2D主菜单场景（简单版）

1. **打开Godot编辑器**
2. **创建新场景**：点击 `+` 或 `场景` → `新建场景`
3. **选择根节点**：`用户界面` → `Control`
4. **保存场景**：`scenes/ui/main_menu.tscn`

### 步骤2：添加UI节点

**节点结构：**
```
MainMenu (Control) ── 脚本：res://scripts/ui/main_menu_3d.gd
├─ ColorRect (背景)
├─ VBoxContainer (容器)
│  ├─ Label (标题："裂隙之渊")
│  ├─ Label (副标题："Rifts")
│  ├─ Control (间隔，高度50)
│  ├─ Button (唤醒)
│  ├─ Button (回归)
│  └─ Button (退出)
├─ Label (底部：版本号)
└─ ColorRect (转场遮罩，初始隐藏)
```

**操作步骤：**

1. **添加背景**：
   - 右键 `MainMenu` → `添加子节点` → `ColorRect`
   - 在检查器中设置：
     - Layout → Anchors Preset → Full Rect
     - Color → 深蓝色 `(0.05, 0.1, 0.15)`

2. **添加容器**：
   - 右键 `MainMenu` → `添加子节点` → `VBoxContainer`
   - 在检查器中设置：
     - Layout → Anchors Preset → Center
     - Alignment → Center

3. **添加标题**：
   - 右键 `VBoxContainer` → `添加子节点` → `Label`
   - Text: "裂隙之渊"
   - Font Size: 48

4. **添加按钮**：
   - 右键 `VBoxContainer` → `添加子节点` → `Button`
   - Text: "唤醒"
   - Name: "WakeButton"
   - 重复添加"回归"和"退出"按钮

5. **连接脚本**：
   - 选中 `MainMenu` 根节点
   - 在检查器中找到 `Script`
   - 点击下拉 → `加载` → 选择 `scripts/ui/main_menu_3d.gd`

### 步骤3：测试场景

1. **按F6运行当前场景**
2. **检查按钮是否工作**

---

## 方案二：使用我创建的简化场景

**我已经创建了一个简化的2D版本：**

`scenes/ui/main_menu.tscn`

**这是一个纯2D UI场景，应该可以打开。**

**步骤：**
1. 在Godot中打开 `scenes/ui/main_menu.tscn`
2. 如果报错，按上面的手动步骤创建

---

## 方案三：等待后续优化

**目前脚本已完成，场景需要手动创建。**

**脚本位置：**
- `scripts/ui/main_menu_3d.gd` - 主菜单逻辑
- `scripts/core/game_state_manager.gd` - 状态管理

**你只需要在编辑器中创建UI布局，然后连接脚本即可。**

---

## 快速验证脚本功能

如果场景无法创建，可以测试脚本：

1. **创建任意Control节点场景**
2. **添加3个Button子节点**
3. **命名为：WakeButton, ReturnButton, ExitButton**
4. **附加脚本：`scripts/ui/main_menu_3d.gd`**
5. **运行测试**

---

## 下一步建议

**优先级：**
1. ✅ **测试脚本逻辑** - 先确保功能正常
2. ⚠️ **创建UI布局** - 在编辑器中手动创建
3. ❌ **3D背景场景** - 后续再添加（可选）

**3D睡眠舱场景是锦上添花，核心功能在脚本中已实现。**

---

## 当前可用内容

### ✅ 已完成
- 状态管理系统（GameStateManager）
- 主菜单脚本逻辑（main_menu_3d.gd）
- 存档/读档功能
- 简化的UI场景文件（可能需要调整）

### ⚠️ 需要手动
- 在编辑器中创建UI布局
- 导入3D模型、音频等资源
- 配置动画

### 💡 建议
先用2D UI场景测试功能，确认无误后再添加3D背景。

---

**抱歉造成困扰！建议在Godot编辑器中手动创建场景，我会提供详细的操作指导。**