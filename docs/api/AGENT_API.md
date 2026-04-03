# Agent API 使用指南

## API 端点

### HTTP REST API (端口: 8080)

#### 1. 获取游戏状态
```http
GET /api/state
```

响应:
```json
{
  "game_state": {
    "current_level": 0,
    "unlocked_levels": [0],
    "completed_levels": [],
    "player_choices": {}
  },
  "agents": {
    "agent_001": {
      "agent_id": "agent_001",
      "position": [x, y, z],
      "status": "IDLE"
    }
  },
  "timestamp": 1234567890.0
}
```

#### 2. 获取所有Agent
```http
GET /api/agents
```

响应:
```json
{
  "agents": { ... },
  "active_count": 5
}
```

#### 3. 注册新Agent
```http
POST /api/agent/register
Content-Type: application/json

{
  "agent_id": "my_agent_001",
  "agent_type": "LLM",
  "agent_name": "Claude Agent"
}
```

响应:
```json
{
  "success": true,
  "agent_id": "my_agent_001",
  "message": "Agent registered successfully"
}
```

#### 4. 请求Agent执行动作
```http
POST /api/agent/action
Content-Type: application/json

{
  "agent_id": "my_agent_001",
  "action": {
    "id": "action_001",
    "type": "move",
    "target_position": [10, 0, 5]
  }
}
```

动作类型:
- `move`: 移动到指定位置
- `interact`: 与对象交互
- `dialogue`: 开始对话
- `wait`: 等待指定时间
- `observe`: 观察周围环境

#### 5. 获取Agent感知数据
```http
POST /api/agent/perception
Content-Type: application/json

{
  "agent_id": "my_agent_001"
}
```

响应:
```json
{
  "agent_id": "my_agent_001",
  "perception": {
    "nearby_agents": [
      {
        "agent_id": "agent_002",
        "distance": 5.2,
        "position": [12, 0, 8]
      }
    ],
    "nearby_objects": [...],
    "visible_events": [...]
  }
}
```

#### 6. 广播事件
```http
POST /api/event/broadcast
Content-Type: application/json

{
  "type": "alarm",
  "position": [15, 0, 10],
  "message": "Emergency alert triggered"
}
```

### WebSocket API (端口: 8081)

实时双向通信，适合需要持续交互的Agent。

#### 连接
```javascript
ws://localhost:8081
```

#### 消息格式

**注册Agent:**
```json
{
  "type": "register",
  "agent_id": "websocket_agent",
  "agent_type": "LLM",
  "agent_name": "Real-time Agent"
}
```

**执行动作:**
```json
{
  "type": "action",
  "action": {
    "id": "move_to_target",
    "type": "move",
    "target_position": [5, 0, 3]
  }
}
```

**查询状态:**
```json
{
  "type": "query",
  "query_type": "state" // 或 "agents", "agent"
}
```

**获取感知:**
```json
{
  "type": "perception"
}
```

**接收事件:**
```json
{
  "type": "event",
  "data": {
    "event_type": "...",
    "position": [...],
    "details": {...}
  }
}
```

## Python 客户端示例

```python
import requests
import json

API_URL = "http://localhost:8080"

class RiftsAgent:
    def __init__(self, agent_id, agent_type="LLM"):
        self.agent_id = agent_id
        self.agent_type = agent_type
        self.register()
    
    def register(self):
        response = requests.post(
            f"{API_URL}/api/agent/register",
            json={
                "agent_id": self.agent_id,
                "agent_type": self.agent_type,
                "agent_name": f"Python Agent {self.agent_id}"
            }
        )
        return response.json()
    
    def get_state(self):
        response = requests.get(f"{API_URL}/api/state")
        return response.json()
    
    def move_to(self, x, y, z):
        response = requests.post(
            f"{API_URL}/api/agent/action",
            json={
                "agent_id": self.agent_id,
                "action": {
                    "id": "move_action",
                    "type": "move",
                    "target_position": [x, y, z]
                }
            }
        )
        return response.json()
    
    def get_perception(self):
        response = requests.post(
            f"{API_URL}/api/agent/perception",
            json={"agent_id": self.agent_id}
        )
        return response.json()
    
    def interact_with(self, target_id):
        response = requests.post(
            f"{API_URL}/api/agent/action",
            json={
                "agent_id": self.agent_id,
                "action": {
                    "id": "interact_action",
                    "type": "interact",
                    "target_id": target_id
                }
            }
        )
        return response.json()

# 使用示例
agent = RiftsAgent("python_agent_001")
state = agent.get_state()
perception = agent.get_perception()
agent.move_to(10, 0, 5)
```

## JavaScript 客户端示例

```javascript
// WebSocket 客户端
class RiftsWebSocketAgent {
  constructor(agentId) {
    this.agentId = agentId;
    this.ws = new WebSocket('ws://localhost:8081');
    this.ws.onopen = () => this.register();
    this.ws.onmessage = (event) => this.handleMessage(event.data);
  }
  
  register() {
    this.ws.send(JSON.stringify({
      type: 'register',
      agent_id: this.agentId,
      agent_type: 'LLM',
      agent_name: 'JavaScript Agent'
    }));
  }
  
  moveTo(x, y, z) {
    this.ws.send(JSON.stringify({
      type: 'action',
      action: {
        id: 'move_action',
        type: 'move',
        target_position: [x, y, z]
      }
    }));
  }
  
  getPerception() {
    this.ws.send(JSON.stringify({
      type: 'perception'
    }));
  }
  
  handleMessage(data) {
    const message = JSON.parse(data);
    console.log('Received:', message);
    
    if (message.type === 'event') {
      this.handleEvent(message.data);
    }
  }
  
  handleEvent(event) {
    console.log('Event:', event);
  }
}

// 使用
const agent = new RiftsWebSocketAgent('js_agent_001');
```

## LLM Agent 集成示例

```python
from openai import OpenAI

client = OpenAI(api_key="your-api-key")

def generate_agent_action(agent_state, perception):
    prompt = f"""
    You are an AI agent in a game about human nature.
    Your state: {json.dumps(agent_state)}
    Your perception: {json.dumps(perception)}
    
    Decide your next action based on your moral score and objectives.
    Return JSON: {{"action_type": "...", "parameters": {...}, "reasoning": "..."}}
    """
    
    response = client.chat.completions.create(
        model="gpt-4",
        messages=[{"role": "user", "content": prompt}]
    )
    
    action = json.loads(response.choices[0].message.content)
    return action

# Agent循环
agent = RiftsAgent("llm_agent_001")
while True:
    state = agent.get_state()
    perception = agent.get_perception()
    
    action = generate_agent_action(
        state['agents'][agent.agent_id],
        perception['perception']
    )
    
    agent.execute_action(action)
    time.sleep(1)
```

## 动态内容生成

### TTS (文字转语音)
```python
# 通过外部API
response = requests.post(
    "https://api.elevenlabs.io/v1/text-to-speech/voice_id",
    headers={"xi-api-key": "your-key"},
    json={"text": "Welcome to Rifts"}
)
audio_url = response.json()['audio_url']

# 在游戏中加载
requests.post(f"{API_URL}/api/audio/load", json={"url": audio_url})
```

### 图像生成
```python
# OpenAI DALL-E
response = client.images.generate(
    model="dall-e-3",
    prompt="Sci-fi character standing in a rift",
    size="1024x1024"
)
image_url = response.data[0].url

# 在游戏中加载
requests.post(f"{API_URL}/api/image/load", json={"url": image_url})
```

### 对话生成
```python
# 使用LLM生成动态对话
context = {
    "scene": "abandoned_station",
    "mood": "tense",
    "characters": ["Agent_001", "NPC_Survivor"]
}

prompt = "Generate dialogue for this scene exploring moral dilemma of sharing resources."

response = client.chat.completions.create(
    model="gpt-4",
    messages=[
        {"role": "system", "content": "You are dialogue generator for Rifts game."},
        {"role": "user", "content": prompt}
    ]
)

dialogue_data = json.loads(response.choices[0].message.content)
```

## 测试API

### 启动服务器
游戏运行时自动启动API服务器（端口8080和8081）。

### 测试请求
```bash
# 获取游戏状态
curl http://localhost:8080/api/state

# 注册Agent
curl -X POST http://localhost:8080/api/agent/register \
  -H "Content-Type: application/json" \
  -d '{"agent_id":"test_agent","agent_type":"RULE_BASED"}'

# 执行动作
curl -X POST http://localhost:8080/api/agent/action \
  -H "Content-Type: application/json" \
  -d '{"agent_id":"test_agent","action":{"type":"move","target_position":[5,0,3]}}'
```

## Agent类型

### 1. LLM Agent
- 使用大语言模型决策
- 需要调用外部API（OpenAI, Anthropic等）
- 适合复杂决策和对话生成

### 2. Rule-based Agent
- 预定义规则和逻辑
- 本地运行，无需外部API
- 适合简单行为和测试

### 3. Hybrid Agent
- 结合LLM和规则系统
- 关键决策用规则，复杂场景用LLM
- 平衡成本和智能

### 4. Human Agent
- 人类玩家通过API观察和影响游戏
- 可以查看Agent视角
- 研究和协作模式

## 最佳实践

1. **Agent注册时机**: 游戏启动后立即注册
2. **动作频率**: 建议1秒间隔，避免过快请求
3. **感知范围**: 合理设置perception_range（默认10米）
4. **错误处理**: 监听action_failed信号
5. **资源管理**: 及时清理不活跃Agent
6. **状态同步**: 定期查询游戏状态保持同步

## 下一步

- 添加更多API端点（关卡生成、语音合成等）
- 实现Agent之间的协作系统
- 添加学习系统（Agent记忆和优化）
- 实现人机协作模式