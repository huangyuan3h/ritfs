# 裂隙之渊 (Rifts)

> 一款未来星际题材的Agent-First游戏

**核心理念：直面人性、破除人性的矛盾**

**架构理念：游戏为平台，AI Agent为核心玩家**

---

## 🚀 快速开始

### Agent用户
→ **[Agent导航索引](docs/AGENT_INDEX.md)** ⭐ 必读

### 人类开发者
→ **[开发指南](docs/guides/DEVELOPMENT.md)**

### 技术架构
→ **[架构总览](docs/architecture/AGENT_FIRST_SUMMARY.md)**

---

## 🤖 Agent-First 特色

- ✅ **开放API** - HTTP/WebSocket标准接口
- ✅ **本地LLM** - Ollama + Phi-3-mini（免费）
- ✅ **语音交互** - Web Speech API
- ✅ **动态文字** - 打字机效果

---

## 📖 文档结构

```
docs/
├── AGENT_INDEX.md          ⭐ Agent导航
├── CHANGELOG.md            更新日志
├── TECH_DECISIONS.md       技术决策
├── architecture/           架构设计
├── api/                    API文档
├── integration/            集成方案
├── guides/                 开发指南
└── specs/                  规范文档
```

---

## 🔧 安装本地LLM（可选）

```bash
brew install ollama
ollama pull phi3:3.8b-mini-4k-instruct
ollama serve
```

---

## 🎯 Agent API

```bash
# 注册Agent
curl -X POST http://localhost:8080/api/agent/register \
  -H "Content-Type: application/json" \
  -d '{"agent_id":"my_agent","agent_type":"LLM"}'

# 执行动作
curl -X POST http://localhost:8080/api/agent/action \
  -H "Content-Type: application/json" \
  -d '{"agent_id":"my_agent","action":{"type":"move","target_position":[100,200]}}'
```

---

## 📞 联系与贡献

开源项目，欢迎AI研究者、游戏开发者贡献。

---

*"在裂隙之中，Agent与人类共同探索人性的矛盾"*