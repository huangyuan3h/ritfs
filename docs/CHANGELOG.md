# 文档更新日志

**记录架构和设计的重要变更**

---

## 版本历史

### v1.3 - 2026-04-03 (当前)

**文档结构重组**
- 创建分类文件夹：`architecture/`, `api/`, `integration/`, `guides/`, `specs/`
- 创建Agent专用导航：`AGENT_INDEX.md`
- 优化文档可读性和导航

**新增文档**
- `AGENT_INDEX.md` - Agent导航索引
- `VOICE_RECOGNITION.md` - 语音识别集成
- `TEXT_SYSTEM.md` - 文字显示系统

---

### v1.2 - 2026-04-03

**语音识别系统**
- 实现VoiceInputSystem
- Web Speech API集成
- 支持中文语音命令
- UI界面集成

**新增内容**
- Web导出原生语音识别
- 本地语音识别方案
- 命令映射系统
- VoiceGameIntegration

---

### v1.1 - 2026-04-03

**本地LLM集成**
- LocalLLMClient实现
- Ollama集成方案
- llama.cpp集成方案
- Phi-3-mini推荐模型

**新增文档**
- `LOCAL_LLM_INTEGRATION.md` - 详细集成方案
- `LOCAL_LLM_QUICKSTART.md` - 快速开始指南

**架构调整**
- LLMIntegration支持本地模式
- 添加Provider.LOCAL_OLLAMA
- 文字生成混合策略

---

### v1.0 - 2026-04-03 (初始)

**Agent-First架构**
- AgentState2D / AgentManager2D / AgentController2D
- HTTP Server (端口8080)
- WebSocket Server (端口8081)
- API端点实现

**核心系统**
- GameManager - 状态管理
- DialogueManager - 对话系统
- AudioManager - 音频管理
- SceneManager - 场景管理

**文档**
- `AGENT_ARCHITECTURE.md` - 架构设计
- `AGENT_FIRST_SUMMARY.md` - 完整总结
- `AGENT_API.md` - API使用指南
- `DEVELOPMENT.md` - 开发指南

---

## 未来计划

### v1.4 - 待定

**计划内容**
- 2D场景创建指南
- 美术资源规范
- 对话剧本格式
- Agent行为模式

**可能调整**
- 性能优化方案
- 多Agent协作系统
- 涌现叙事机制

---

### v2.0 - 远期

**重大变更可能**
- 3D模式支持（可选）
- Agent学习系统
- 人机深度协作
- 跨平台导出优化

---

## 变更类型标记

- ✅ **新增** - 新功能或新文档
- 🔄 **修改** - 架构或设计调整
- ⚠️ **弃用** - 不推荐使用的方案
- ❌ **移除** - 已删除的功能
- 🔧 **修复** - Bug修复或优化

---

## 文档维护原则

1. **版本标注**
   - 每个重要变更标注版本号
   - 维护更新日志

2. **向后兼容**
   - API变更保持向后兼容
   - 标注弃用而非直接移除

3. **Agent友好**
   - 文档结构清晰
   - 保持AGENT_INDEX更新
   - 提供迁移指南

4. **技术进步适应**
   - 允许少量架构调整
   - 记录调整原因
   - 提供升级路径

---

## Agent查询版本方法

### 查询当前文档版本

```bash
# 通过API查询（未来可能支持）
curl http://localhost:8080/api/system/version

# 当前通过文件查询
cat docs/CHANGELOG.md | grep "当前"
```

### 检查API兼容性

```bash
# 查询API版本信息（未来实现）
curl http://localhost:8080/api/system/info
```

---

## 重要变更通知

### 对Agent的影响

**v1.2 语音识别**
- ✅ Agent可以使用语音命令
- ✅ Web导出自动启用
- ⚠️ 本地导出需要额外配置

**v1.1 本地LLM**
- ✅ Agent可使用本地LLM
- ✅ 完全免费、隐私保护
- 🔄 LLMIntegration新增方法

**v1.0 Agent-First**
- ✅ Agent通过API完全控制
- ✅ 感知系统可用
- ✅ 动作执行可用

---

## 架构稳定性承诺

### 稳定部分（不易变更）
- Agent状态数据结构
- HTTP/WebSocket API端点
- Agent感知系统
- 动作执行机制

### 可能调整部分
- LLM集成细节
- 语音识别实现
- UI界面设计
- 性能优化策略

### 允许扩展部分
- 新Agent类型
- 新动作类型
- 新感知能力
- 新集成方案

---

**Agent友好提示：重大变更会在此记录，建议定期查阅。**

---

*"稳定的架构，灵活的扩展"*