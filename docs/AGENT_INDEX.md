# Agent 导航索引

**专为 AI Agent 设计的文档导航系统**

---

## 🎯 Agent 快速入门

### 我是Agent，我该如何开始？

**第一步：理解架构**
→ [Agent-First架构总览](architecture/AGENT_FIRST_SUMMARY.md)

**第二步：学习API**
→ [Agent API使用指南](api/AGENT_API.md)

**第三步：连接本地LLM（可选）**
→ [本地LLM快速开始](integration/LOCAL_LLM_QUICKSTART.md)

**第四步：使用语音交互（可选）**
→ [语音识别集成](integration/VOICE_RECOGNITION.md)

---

## 📚 文档分类

### 1. 架构设计 (`architecture/`)

**核心架构文档：**

- **[AGENT_FIRST_SUMMARY.md](architecture/AGENT_FIRST_SUMMARY.md)** ⭐ 推荐
  - 完整的Agent-First架构总结
  - 已实现系统列表
  - 技术栈详情
  - Agent类型说明

- **[AGENT_ARCHITECTURE.md](architecture/AGENT_ARCHITECTURE.md)
  - 架构层级设计
  - Agent接口定义
  - 数据格式规范
  - 开发路径规划

### 2. API文档 (`api/`)

**Agent与游戏交互接口：**

- **[AGENT_API.md](api/AGENT_API.md)** ⭐ 必读
  - HTTP REST API端点（端口8080）
  - WebSocket实时通信（端口8081）
  - Python客户端示例
  - JavaScript客户端示例
  - LLM Agent集成示例

### 3. 集成方案 (`integration/`)

**可选的高级功能：**

#### 本地LLM集成

- **[LOCAL_LLM_QUICKSTART.md](integration/LOCAL_LLM_QUICKSTART.md)** ⭐ 推荐
  - Ollama快速安装
  - Phi-3-mini模型下载
  - 立即可用方案

- **[LOCAL_LLM_INTEGRATION.md](integration/LOCAL_LLM_INTEGRATION.md)
  - 多种实现方案对比
  - llama.cpp集成
  - Python服务器方案
  - 性能数据

#### 语音识别

- **[VOICE_RECOGNITION.md](integration/VOICE_RECOGNITION.md)
  - Web Speech API（推荐）
  - 本地语音识别方案
  - 支持的命令列表
  - UI集成示例

#### 文字系统

- **[TEXT_SYSTEM.md](integration/TEXT_SYSTEM.md)
  - 动态文字显示
  - 打字机效果
  - 系统TTS（可选）
  - 文字生成策略

### 4. 开发指南 (`guides/`)

**传统开发流程（人类开发者）：**

- **[DEVELOPMENT.md](guides/DEVELOPMENT.md)
  - 已搭建的基础架构
  - 下一步操作指南
  - 场景创建步骤
  - 测试方法

---

## 🔍 Agent关键信息提取

### Agent状态数据结构

```json
{
  "agent_id": "string",
  "agent_name": "string",
  "agent_type": "LLM|RULE_BASED|HUMAN|HYBRID",
  "status": "IDLE|THINKING|ACTING|WAITING",
  "position": [x, y],
  "inventory": [],
  "active_objectives": [],
  "known_facts": {},
  "relationships": {},
  "moral_score": 0.0
}
```

### Agent动作类型

| 动作 | 参数 | 描述 |
|------|------|------|
| `move` | `target_position: [x, y]` | 移动到位置 |
| `interact` | `target_id: string` | 与对象交互 |
| `dialogue` | `dialogue_id: string` | 开始对话 |
| `wait` | `duration: float` | 等待时间 |
| `observe` | - | 观察环境 |

### Agent感知范围

- **感知半径：** 300像素（2D模式）
- **感知内容：**
  - 附近Agent列表
  - 距离和位置
  - Agent状态
  - 环境事件

---

## 💡 Agent最佳实践

### 1. Agent注册时机
- 游戏启动后立即注册
- 使用唯一agent_id

### 2. 动作执行频率
- 建议≥1秒间隔
- 避免过快请求导致性能问题

### 3. 感知系统使用
- 定期查询感知数据
- 根据感知调整行为

### 4. LLM集成优化
- 使用混合策略：模板+LLM
- 缓存常用生成结果
- 合理设置temperature（推荐0.7）

### 5. 语音命令处理
- 支持中文和英文命令
- 添加自定义命令映射
- 实时响应用户语音

---

## 🚀 Agent工作流程示例

### 简单Agent（Rule-based）

```python
# 1. 注册Agent
requests.post(API + "/api/agent/register", json={
    "agent_id": "simple_agent",
    "agent_type": "RULE_BASED"
})

# 2. 定期获取感知
perception = requests.post(API + "/api/agent/perception", json={
    "agent_id": "simple_agent"
}).json()

# 3. 根据规则执行动作
if len(perception["nearby_agents"]) > 0:
    # 移动到最近的Agent
    target = perception["nearby_agents"][0]["position"]
    requests.post(API + "/api/agent/action", json={
        "agent_id": "simple_agent",
        "action": {"type": "move", "target_position": target}
    })
```

### LLM Agent

```python
# 1. 注册LLM Agent
requests.post(API + "/api/agent/register", json={
    "agent_id": "llm_agent",
    "agent_type": "LLM"
})

# 2. 获取游戏状态和感知
state = requests.get(API + "/api/state").json()
perception = requests.post(API + "/api/agent/perception", json={
    "agent_id": "llm_agent"
}).json()

# 3. 使用LLM生成决策
prompt = f"""
Current state: {state}
Perception: {perception}

Decide your next action based on your moral score and objectives.
Return JSON: {"action_type": "...", "parameters": {...}}
"""

response = openai.chat.completions.create(
    model="gpt-4",
    messages=[{"role": "user", "content": prompt}]
)

action = json.loads(response.choices[0].message.content)

# 4. 执行LLM生成的动作
requests.post(API + "/api/agent/action", json={
    "agent_id": "llm_agent",
    "action": action
})
```

---

## 📊 技术决策参考

### 本地LLM vs 外部API

| 特性 | 本地LLM | 外部API |
|------|---------|---------|
| 成本 | ✅ 免费 | ⚠️ 有费用 |
| 隐私 | ✅ 完全本地 | ⚠️ 数据外传 |
| 速度 | ⚠️ 8-15 t/s | ✅ 30+ t/s |
| 质量 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| 推荐 | 测试/隐私敏感 | 生产/高质量需求 |

### 语音识别方案

| 平台 | 推荐方案 |
|------|---------|
| Web导出 | Web Speech API ⭐ |
| 本地导出 | Python + SpeechRecognition |
| 高质量 | Whisper API |

---

## 🔄 文档更新机制

### 版本追踪
- 所有架构文档标注版本号
- 重要变更记录在更新日志
- Agent可查询文档版本

### 更新历史
- **v1.0** - 初始Agent-First架构
- **v1.1** - 添加本地LLM集成
- **v1.2** - 添加语音识别系统
- **当前** - 文档结构重组

---

## 📞 Agent求助指南

### 遇到问题时

1. **查阅对应文档**
   - 架构问题 → `architecture/`
   - API问题 → `api/`
   - 集成问题 → `integration/`

2. **检查常见问题**
   - API端口是否开放（8080/8081）
   - 本地LLM服务是否运行（11434）
   - Agent是否正确注册

3. **测试基础功能**
   ```bash
   curl http://localhost:8080/api/state
   curl http://localhost:11434/api/tags
   ```

---

## 🎮 Agent角色建议

### 探索型Agent
- 重点使用感知系统
- 频繁观察环境变化
- 记录发现的事实

### 社交型Agent
- 关注relationships数据
- 主动与其他Agent交互
- 维护道德评分

### 决策型Agent
- 结合LLM进行深度思考
- 权衡道德选择
- 影响剧情走向

---

## 📝 Agent可以做什么

### ✅ 可以
- 查询游戏完整状态
- 观察周围环境（感知）
- 执行游戏动作
- 与其他Agent交互
- 参与对话选择
- 记录决策历史
- 影响道德评分

### ⚠️ 需要权限
- 修改游戏全局状态
- 创建新关卡
- 修改其他Agent状态

### ❌ 不能
- 直接修改游戏代码
- 绕过API访问引擎内部
- 强制改变玩家选择

---

## 🚦 Agent状态监控

### 查询Agent状态
```bash
curl http://localhost:8080/api/agents
```

### 监控Agent性能
- 动作执行频率
- LLM生成耗时
- 感知数据大小

---

## 🎯 Agent下一步建议

1. **熟悉API** → 阅读 `api/AGENT_API.md`
2. **安装LLM** → 参考 `integration/LOCAL_LLM_QUICKSTART.md`
3. **编写客户端** → 使用Python/JavaScript示例
4. **测试交互** → 注册Agent并执行动作
5. **优化策略** → 调整决策算法和参数

---

**Agent友好提示：文档持续更新，建议定期查阅本索引获取最新信息。**

---

*"Agent与人类共同创造裂隙之渊的故事"*