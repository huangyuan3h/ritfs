# 主菜单场景创建指南

## 自动创建的场景文件

我已经为你创建了 `scenes/ui/main_menu_3d.tscn` 基础场景文件。

---

## 需要在Godot编辑器中完成的步骤

### 1. 打开场景

1. 打开Godot编辑器
2. 在文件系统中找到 `scenes/ui/main_menu_3d.tscn`
3. 双击打开

### 2. 添加环境背景

**WorldEnvironment节点：**
1. 选中 `WorldEnvironment`
2. 在检查器中找到 `Environment`
3. 点击 `<空>` → `新建 Environment`
4. 展开 Environment：
   - **Background Mode**: `Sky`
   - **Sky**: 点击 → `新建 Sky`
   - 展开 Sky：
     - **Sky Material**: `新建 ProceduralSkyMaterial`

**调整天空颜色：**
- ProceduralSkyMaterial → Sky Top Color: 深蓝色 `#0a1628`
- ProceduralSkyMaterial → Sky Horizon Color: 蓝黑色 `#1a2a3a`
- ProceduralSkyMaterial → Ground Bottom Color: 黑色 `#000000`

### 3. 替换睡眠舱占位符

**当前是简单的CSG几何体，需要替换：**

1. 删除 `SleepChamberPlaceholder` 下的所有子节点
2. 导入睡眠舱3D模型：
   - 将 `sleep_chamber.glb` 拖入 `assets/models/`
   - 拖拽模型到场景中
3. 调整位置和缩放

**或者保留占位符，用简单几何体：**
- 选中 `ChamberBody`（CSGBox3D）
- 在检查器中调整 `Material`：
  - 点击 Material → `新建 StandardMaterial3D`
  - Albedo Color: 深灰蓝 `#2a3a4a`
  - Metallic: 0.7
  - Roughness: 0.3

### 4. 配置粒子效果

**GPUParticles3D：**
1. 选中 `GPUParticles3D`
2. 在检查器中：
   - **Amount**: 200
   - **Lifetime**: 8.0
   - **Explosiveness**: 0.0
   - **Randomness**: 0.5
3. 点击 `Process Material` → `新建 ParticleProcessMaterial`
4. 展开 ParticleProcessMaterial：
   - **Emission Shape**: `Box`
   - **Extents**: `(10, 5, 10)`
   - **Direction**: `(0, 0, 0)`
   - **Initial Velocity Min**: 0.1
   - **Initial Velocity Max**: 0.3
   - **Gravity**: `(0, 0, 0)`
   - **Scale Min**: 0.02
   - **Scale Max**: 0.05

### 5. 创建唤醒动画

**AnimationPlayer：**
1. 选中 `AnimationPlayer`
2. 点击 `Animation` → `新建`
3. 命名为 `wake_sequence`
4. 设置时长为 `8` 秒

**添加轨道：**

**相机推进动画（0-5秒）：**
```
轨道：Camera3D:position
0.0s: (0, 1, 5)    # 远景
5.0s: (0, 1, 2)    # 特写
```

**舱门打开动画（2-5秒）：**
```
轨道：SleepChamberPlaceholder/ChamberDoor:position:x
2.0s: 1.01
5.0s: 2.5
```

**光线增强动画（0-8秒）：**
```
轨道：DirectionalLight3D:light_energy
0.0s: 0.5
8.0s: 1.5
```

**转场淡出（7-8秒）：**
```
轨道：MainMenuUI/TransitionOverlay:modulate:a
7.0s: 0.0
8.0s: 1.0
```

### 6. 美化UI样式

**主题设置（可选）：**

1. 创建新资源：`Theme`
2. 保存为 `assets/themes/main_menu_theme.tres`
3. 配置样式：
   - **Button**: 
     - 正常状态：深色背景 `#1a2a3a`
     - 悬停状态：亮色边框
     - 点击状态：发光效果
   - **Label**:
     - 字体：Sci-fi风格字体
     - 颜色：白色/青色

**应用到UI：**
- 选中 `MainMenuUI`
- 在检查器中设置 `Theme` 为刚创建的主题

### 7. 音效占位符

**需要导入的音频文件：**

```
assets/audio/
├─ music/
│  └─ menu_ambient.ogg      # 背景音乐
└─ sfx/
   ├─ system_boot.ogg       # 系统启动
   ├─ door_open.ogg         # 舱门打开
   ├─ steam_release.ogg     # 蒸汽释放
   └─ breath.ogg            # 呼吸声
```

**临时解决方案：**
- 如果没有音频文件，脚本会报错但不影响运行
- 或者注释掉音频相关代码

---

## 快速测试场景

### 不导入任何资源，直接测试

1. **打开场景** `scenes/ui/main_menu_3d.tscn`
2. **按F6运行当前场景**
3. **测试按钮**：
   - 点击"唤醒" → 检查是否有错误
   - 点击"回归" → 应该显示"无记忆痕迹"
   - 点击"退出" → 应该弹出确认框

**预期效果：**
- ✅ 显示UI界面
- ✅ 按钮可以点击
- ✅ 背景是CSG几何体（占位符）
- ⚠️ 没有音乐和音效
- ⚠️ 没有动画（需要手动配置）

---

## 导入外部资源步骤

### 1. 下载或创建资源

**3D模型（推荐免费资源）：**
- Sketchfab: https://sketchfab.com
- Turbosquid: https://www.turbosquid.com
- Mixamo: https://www.mixamo.com (角色动画)

**音频资源：**
- Freesound: https://freesound.org
- Zapsplat: https://www.zapsplat.com

### 2. 导入到Godot

**步骤：**
1. 将资源文件拖入 `assets/` 文件夹
2. Godot自动导入
3. 调整导入设置（如需要）

**推荐格式：**
- 3D模型: `.glb` 或 `.gltf`
- 音频: `.ogg` 或 `.wav`
- 贴图: `.png` 或 `.jpg`

---

## 完整场景层级（最终版）

```
MainMenu3D (Node3D)
│
├─ WorldEnvironment
│  └─ Environment (Sky + 后处理)
│
├─ DirectionalLight3D (主光源)
│
├─ Camera3D (动画相机)
│
├─ SleepChamber (GLTF模型)
│  ├─ ChamberBody
│  ├─ ChamberDoor (可动画)
│  └─ Character (角色)
│
├─ GPUParticles3D (灰尘粒子)
│
├─ AnimationPlayer (唤醒动画)
│
└─ MainMenuUI (Control)
   ├─ BackgroundOverlay (半透明背景)
   ├─ TitleContainer (标题)
   │  ├─ GameTitle
   │  └─ SubTitle
   ├─ MenuContainer (菜单)
   │  ├─ WakeButton
   │  ├─ ReturnButton
   │  └─ ExitButton
   ├─ Footer (底部信息)
   │  └─ VersionLabel
   └─ TransitionOverlay (转场遮罩)
```

---

## 常见问题

### Q: 场景打开后报错？
A: 检查脚本路径是否正确，脚本文件是否存在。

### Q: 按钮没有反应？
A: 检查 `main_menu_3d.gd` 中的节点路径是否正确。

### Q: 没有声音？
A: 需要导入音频文件到 `assets/audio/` 目录。

### Q: CSG几何体显示不正常？
A: CSG用于快速原型，建议替换为正式的3D模型。

---

## 下一步

1. **测试当前场景** - 确认基本功能
2. **导入资源** - 模型、音频、贴图
3. **配置动画** - 唤醒序列动画
4. **美化UI** - 添加主题和样式
5. **音效集成** - 连接音频系统

---

**提示：先用占位符测试，确认功能正常后再导入正式资源！**