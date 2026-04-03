# Agent-First 架构设计

## 核心理念

**游戏即平台，AI Agent 为核心玩家**

传统游戏：玩家 → 游戏 → 反馈
Agent-First：AI Agent → API网关 → 游戏引擎 → 动态内容 → 反馈

## 架构层级

```
┌─────────────────────────────────────────────┐
│          AI Agents (外部/内部)               │
│   - LLM Agent (OpenAI/Claude/本地模型)      │
│   - 规则AI (游戏内NPC)                       │
│   - 人类玩家 (通过API观察和影响)             │
└─────────────────────────────────────────────┘
                    ↓ ↑
┌─────────────────────────────────────────────┐
│            API Gateway Layer                │
│   - HTTP REST API (查询/控制)               │
│   - WebSocket (实时通信)                    │
│   - Agent Protocol (标准化通信)             │
└─────────────────────────────────────────────┘
                    ↓ ↑
┌─────────────────────────────────────────────┐
│          Game Engine Layer (Godot)          │
│   - State Manager (游戏状态序列化)          │
│   - Action Executor (动作执行引擎)          │
│   - Perception System (环境感知)            │
│   - Event Bus (事件系统)                    │
└─────────────────────────────────────────────┘
                    ↓ ↑
┌─────────────────────────────────────────────┐
│       Dynamic Content Layer (可选)          │
│   - TTS Service (语音合成)                   │
│   - Image Generator (图像生成)              │
│   - Level Generator (关卡生成)              │
│   - Dialogue Generator (对话生成)           │
└─────────────────────────────────────────────┘
```

## Agent 接口设计

### 1. 观察接口（Observation）

Agent 可以观察游戏状态：
- 当前场景信息
- 可见对象和实体
- 对话历史
- 任务状态
- 玩家选择历史

### 2. 动作接口（Action）

Agent 可以执行动作：
- 移动到位置
- 与对象交互
- 选择对话选项
- 使用技能/物品
- 触发事件

### 3. 感知接口（Perception）

Agent 获得感知数据：
- 视野范围（2D/3D空间）
- 听觉事件
- 环境变化
- 其他Agent行为

### 4. 决策接口（Decision）

Agent 参与决策：
- 道德选择投票
- 关卡生成建议
- 剧情走向影响

## 数据格式

### Agent 消息格式

```json
{
  "agent_id": "agent_001",
  "timestamp": 1234567890,
  "type": "observation|action|perception|decision",
  "data": {
    // 具体数据
  }
}
```

### 游戏状态格式

```json
{
  "scene": "level_0",
  "agents": [
    {
      "id": "agent_001",
      "position": [x, y, z],
      "state": "idle",
      "inventory": [],
      "objectives": []
    }
  ],
  "world": {
    "time": 123.45,
    "weather": "clear",
    "events": []
  },
  "dialogues": {
    "active": null,
    "history": []
  }
}
```

## 支持的 AI 能力

### 1. LLM 集成
- **用途**：动态对话生成、剧情分支、NPC行为
- **方式**：HTTP API调用外部服务
- **支持**：OpenAI API, Anthropic API, 本地LLM

### 2. TTS（文字转语音）
- **用途**：动态语音、旁白、角色对话
- **方式**：外部API（ElevenLabs, Azure TTS, OpenAI TTS）
- **本地**：系统TTS（有限支持）

### 3. 图像生成
- **用途**：动态纹理、角色立绘、环境贴图
- **方式**：Stable Diffusion API, DALL-E API
- **加载**：动态下载并加载到引擎

### 4. 关卡生成
- **用途**：程序化生成关卡
- **方式**：AI生成关卡数据，Godot动态实例化
- **格式**：JSON关卡描述 → Godot场景

### 5. JavaScript 执行
- **用途**：动态脚本、自定义逻辑
- **方式**：
  - Web导出：原生支持JS
  - 原生：需要GDExtension或外部服务
  - 推荐：使用Lua或自定义脚本系统

## 技术栈选择

### 核心（必须）
- **Godot 4.x** - 游戏引擎
- **GDScript** - 游戏逻辑
- **HTTP/WebSocket** - API通信

### AI 服务（可选）
- **OpenAI API** - LLM对话生成
- **ElevenLabs API** - 高质量TTS
- **Stable Diffusion API** - 图像生成
- **本地模型** - 离线AI能力

### 扩展（可选）
- **GDExtension (Rust)** - 高性能扩展
- **Python绑定** - 数据科学和AI
- **TensorFlow Lite** - 本地推理

## 场景支持

### 2D 模式
- ✅ 更简单的Agent感知
- ✅ 更快的渲染和计算
- ✅ 适合对话密集型游戏
- ✅ 更适合原型开发

### 3D 模式
- ✅ 更丰富的空间信息
- ✅ 沉浸式体验
- ⚠️ 更复杂的导航和感知
- ⚠️ 更高的资源需求

### 建议
**混合模式**：3D场景 + 2D UI + Agent API
- 3D用于视觉表现
- 2D用于界面和对话
- API用于Agent交互

## 开发优先级

### Phase 1: 核心 API
1. HTTP Server（API端点）
2. WebSocket Server（实时通信）
3. State Manager（状态序列化）
4. Action Executor（动作执行）

### Phase 2: Agent 集成
1. Agent Interface（标准化接口）
2. Perception System（感知系统）
3. Event System（事件总线）
4. LLM Integration（对话生成）

### Phase 3: 动态内容
1. TTS Integration（语音合成）
2. Image Generation（图像生成）
3. Dynamic Loading（动态资源加载）
4. Level Generator（关卡生成）

### Phase 4: 高级功能
1. Multi-Agent System（多Agent协作）
2. Learning System（Agent学习）
3. Emergent Narrative（涌现叙事）
4. Player-AI Collaboration（人机协作）

## 示例：Agent 驱动的对话系统

```
1. 玩家进入对话
2. 游戏发送状态给LLM Agent
3. LLM生成动态对话选项
4. Agent/玩家选择
5. 选择影响游戏状态
6. 状态变化触发新事件
7. Agent感知事件并响应
```

## 关键优势

1. **动态内容**：AI实时生成，永不重复
2. **个性化**：根据玩家/Agent行为定制体验
3. **可扩展**：新Agent类型随时接入
4. **研究友好**：AI研究者可以测试Agent
5. **人机协作**：人类和AI共同创造叙事