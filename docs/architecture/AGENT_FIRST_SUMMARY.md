# Agent-First 2D 游戏架构 - 完整总结

## 项目概述

**裂隙之渊 (Rifts)** - 一款未来星际题材的2D游戏，所有关卡围绕"人性"展开，采用 **Agent-First** 架构设计。

核心理念：**游戏为平台，AI Agent为核心玩家**

## 已完成的核心系统

### 1. 游戏基础架构

#### 核心管理器
- **GameManager** - 游戏状态、存档、关卡管理
- **SceneManager** - 场景切换和加载
- **DialogueManager** - 对话系统（支持JSON数据）
- **AudioManager** - 音频管理（音乐/音效）

#### 游戏组件
- **LevelBase** - 关卡基类（2D版本待创建）
- **PlayerController** - 玩家控制器（需改为2D）
- **InteractiveObject** - 可交互物体（需改为2D）

#### UI系统
- **MainMenu** - 主菜单
- **PauseMenu** - 暂停菜单
- **DialogueUI** - 对话界面

### 2. Agent-First 架构

#### Agent 系统 (2D版本)
- **AgentState2D** - Agent状态数据（Vector2位置）
- **AgentManager2D** - Agent注册、感知、广播
- **AgentController2D** - 2D空间中的Agent实体

#### API 层
- **APIServer** - HTTP REST API（端口8080）
- **WebSocketServer** - 实时通信（端口8081）

#### AI 集成
- **LLMIntegration** - OpenAI/Anthropic/本地LLM集成
- **ContentGenerator** - 动态内容生成（TTS/图像/关卡）

## 技术栈

### 核心引擎
- **Godot 4.6** - 游戏引擎
- **GDScript** - 游戏逻辑
- **2D模式** - 更适合对话密集型和Agent交互

### API 支持
- **HTTP Server** - REST API端点
- **WebSocket** - 实时双向通信
- **JSON** - 数据交换格式

### AI 服务（可选集成）
- **OpenAI API** - LLM对话生成、TTS、图像生成
- **Anthropic API** - Claude对话生成
- **ElevenLabs API** - 高质量TTS
- **Stable Diffusion** - 图像生成

### 扩展能力
- **GDExtension** - Rust/C++高性能扩展
- **Web导出** - 原生支持JavaScript
- **本地模型** - 离线AI推理

## 支持的Agent类型

### 1. LLM Agent
- 大语言模型驱动决策
- 动态对话生成
- 情境理解和推理
- 需要外部API调用

### 2. Rule-based Agent
- 预定义行为规则
- 本地运行，无需外部API
- 适合简单NPC和测试

### 3. Hybrid Agent
- LLM + 规则系统结合
- 关键决策用规则，复杂场景用LLM
- 平衡成本和智能度

### 4. Human Agent
- 人类通过API观察和影响游戏
- 研究和协作模式
- 可以查看Agent视角

## Agent 能力

### 感知能力
- 2D空间位置感知
- 其他Agent检测（范围300像素）
- 环境变化观察
- 事件感知和记忆

### 行动能力
- **移动** - 移动到指定位置
- **交互** - 与游戏对象交互
- **对话** - 开始对话或选择对话选项
- **等待** - 暂停指定时间
- **观察** - 主动观察周围环境

### 认知能力
- 记忆系统（已知事实存储）
- 关系管理（Agent之间的关系值）
- 道德评分（决策影响道德分数）
- 对话历史记录

## API 端点

### HTTP REST API (端口: 8080)
- `GET /api/state` - 获取完整游戏状态
- `GET /api/agents` - 获取所有Agent信息
- `POST /api/agent/register` - 注册新Agent
- `POST /api/agent/action` - 请求Agent执行动作
- `POST /api/agent/perception` - 获取Agent感知数据
- `POST /api/event/broadcast` - 广播事件给所有Agent

### WebSocket API (端口: 8081)
- 实时双向通信
- Agent注册和身份验证
- 实时动作执行
- 持续感知更新
- 事件推送订阅

## 动态内容支持

### 语音合成 (TTS)
- **系统TTS** - 基础支持（有限）
- **ElevenLabs** - 高质量语音（需API）
- **OpenAI TTS** - 标准语音合成（需API）

### 图像生成
- **DALL-E** - OpenAI图像生成
- **Stable Diffusion** - 开源图像生成
- **动态加载** - 实时下载并加载到引擎

### 关卡生成
- **LLM生成** - AI生成关卡描述和叙事
- **程序化生成** - 规则驱动的关卡布局

### 对话生成
- **LLM动态生成** - 实时生成对话选项
- **模板生成** - 基础对话模板填充

## 游戏设计

### 人性主题关卡

每个关卡围绕一个核心人性矛盾：

1. **生存 vs 牺牲** - 氧气危机，资源分配
2. **真相 vs 安慰** - 历史真相，情感保护
3. **个人 vs 集体** - 个人利益与社区福祉
4. **过去 vs 未来** - 时间裂隙，改变历史

### Agent参与方式

- **道德选择投票** - Agent参与重要决策
- **剧情走向影响** - Agent行为改变叙事
- **环境交互** - Agent改变游戏世界
- **角色扮演** - Agent扮演NPC角色

## 开发路径

### Phase 1: 核心框架 ✅ (已完成)
- 游戏基础架构
- Agent管理系统
- API服务器
- 状态序列化

### Phase 2: 场景创建 🔄 (下一步)
- 在Godot中创建2D场景
- 主菜单场景
- 第一个测试关卡
- Agent测试场景

### Phase 3: Agent集成
- Python测试客户端
- LLM Agent连接
- 对话生成测试
- 感知系统验证

### Phase 4: 内容开发
- 对话剧本编写
- 关卡设计
- 美术资源添加
- 音效集成

### Phase 5: 高级功能
- 多Agent协作系统
- Agent学习机制
- 涌现叙事系统
- 人机协作模式

## 项目结构

```
rifts/
├── scripts/
│   ├── core/           # 核心数据结构
│   ├── managers/       # 全局管理器
│   ├── agent/          # Agent系统（2D版本）
│   ├── api/            # API服务器
│   ├── game/           # 游戏逻辑组件
│   └── ui/             # UI脚本
├── scenes/
│   ├── ui/             # UI场景（需创建）
│   └── levels/         # 关卡场景（需创建）
├── resources/
│   └── data/           # JSON数据文件
│       └── dialogues/  # 对话数据
├── AGENT_ARCHITECTURE.md  # 架构设计文档
├── AGENT_API.md          # API使用指南
├── DEVELOPMENT.md        # 开发指南
└── README.md             # 项目介绍
```

## 下一步操作

### 在 Godot 编辑器中完成

1. **创建2D场景**
   - main_menu.tscn（主菜单）
   - pause_menu.tscn（暂停菜单）
   - dialogue_ui.tscn（对话UI）
   - level_0.tscn（第一个关卡）

2. **添加节点**
   - AgentController2D节点
   - InteractiveObject2D节点
   - 导航和碰撞系统

3. **美术资源**
   - 角色 sprite
   - 环境 tileset
   - UI元素

### 测试 Agent API

```bash
# 启动游戏后测试API
curl http://localhost:8080/api/state

# 注册测试Agent
curl -X POST http://localhost:8080/api/agent/register \
  -H "Content-Type: application/json" \
  -d '{"agent_id":"test","agent_type":"RULE_BASED"}'

# 执行测试动作
curl -X POST http://localhost:8080/api/agent/action \
  -H "Content-Type: application/json" \
  -d '{"agent_id":"test","action":{"type":"move","target_position":[100,200]}}'
```

## 关键优势

1. **Agent优先设计** - 所有系统为Agent服务
2. **开放API** - 外部Agent轻松接入
3. **动态内容** - AI实时生成，永不重复
4. **人机协作** - 人类和AI共同叙事
5. **研究友好** - AI研究者测试平台
6. **可扩展** - 新Agent类型随时添加

## 技术限制

### 需要外部服务
- 高质量TTS（ElevenLabs/OpenAI）
- 图像生成（DALL-E/Stable Diffusion）
- LLM推理（OpenAI/Anthropic）

### Godot原生限制
- HTTP Server需手动实现（已完成）
- JavaScript仅Web导出支持
- 无内置TTS引擎

### 性能考虑
- Agent数量限制（建议≤100）
- API请求频率（建议≥1秒间隔）
- LLM调用延迟（需异步处理）

## 资源需求

### 最小配置
- Godot 4.6+
- Python客户端（可选）
- 外部AI API密钥（可选）

### 推荐配置
- OpenAI/Anthropic API
- ElevenLabs账号
- Stable Diffusion服务

## 文档索引

- **README.md** - 项目介绍
- **DEVELOPMENT.md** - 传统开发指南
- **AGENT_ARCHITECTURE.md** - Agent架构详解
- **AGENT_API.md** - API使用文档和示例
- **本文档** - 完整总结

## 许可和贡献

项目开源，欢迎AI研究者、游戏开发者、叙事设计师贡献。

---

*"在裂隙之中，Agent与人类共同探索人性的矛盾"*