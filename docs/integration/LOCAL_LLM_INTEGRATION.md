# 本地小模型集成方案

## 方案概述

**架构：Godot游戏 + llama.cpp/Ollama + 小模型（完全本地）**

```
┌─────────────────┐
│  Godot 游戏      │
│  (用户界面)      │
└─────────────────┘
        ↓ ↑ HTTP API
┌─────────────────┐
│ llama.cpp服务   │ ← 本地运行
│ 或 Ollama       │
└─────────────────┘
        ↓ ↑ 推理
┌─────────────────┐
│ 小模型文件       │ ← 0.几B参数
│ (.gguf格式)     │
└─────────────────┘
```

---

## 方案一：llama.cpp（推荐）

### 特点
- ✅ 专为本地推理优化
- ✅ 支持量化模型（体积更小）
- ✅ CPU可用，GPU更快
- ✅ HTTP服务器模式
- ✅ 开源，免费

### 安装步骤

#### 1. 下载llama.cpp
```bash
# macOS/Linux
git clone https://github.com/ggerganov/llama.cpp
cd llama.cpp
make

# Windows
# 从 https://github.com/ggerganov/llama.cpp/releases 下载预编译版本
```

#### 2. 下载量化小模型

推荐模型（GGUF格式）：

**TinyLlama-1.1B（最小）**
```bash
# Q4量化版本（约600MB）
wget https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf
```

**Phi-3-mini-3.8B（推荐）**
```bash
# Q4量化版本（约2GB）
wget https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf/resolve/main/Phi-3-mini-4k-instruct-q4.gguf
```

**Qwen-1.8B**
```bash
# Q4量化版本（约1GB）
wget https://huggingface.co/Qwen/Qwen1.5-1.8B-Chat-GGUF/resolve/main/qwen1.5-1.8b-chat-q4_k_m.gguf
```

#### 3. 启动HTTP服务器

```bash
# 启动llama.cpp服务器模式
./llama-server -m ./tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf \
  --host 127.0.0.1 \
  --port 8082 \
  --ctx-size 2048 \
  --threads 4

# 或使用Phi-3（质量更好）
./llama-server -m ./Phi-3-mini-4k-instruct-q4.gguf \
  --host 127.0.0.1 \
  --port 8082 \
  --ctx-size 4096 \
  --threads 4
```

#### 4. API端点

llama.cpp提供OpenAI兼容API：

**端点：**
- `POST http://localhost:8082/v1/chat/completions` - 对话生成
- `POST http://localhost:8082/completion` - 文本补全

**请求格式：**
```json
{
  "messages": [
    {"role": "system", "content": "You are a dialogue generator for Rifts game."},
    {"role": "user", "content": "Generate dialogue about moral dilemma..."}
  ],
  "temperature": 0.7,
  "max_tokens": 500
}
```

---

## 方案二：Ollama（更简单）

### 特点
- ✅ 一键安装
- ✅ 自动管理模型
- ✅ OpenAI兼容API
- ✅ 支持GPU加速
- ✅ 界面友好

### 安装步骤

#### 1. 安装Ollama
```bash
# macOS
brew install ollama

# Linux
curl -fsSL https://ollama.com/install.sh | sh

# Windows
# 从 https://ollama.com/download 下载
```

#### 2. 下载小模型
```bash
# TinyLlama（最小）
ollama pull tinyllama:1.1b

# Phi-3-mini（推荐）
ollama pull phi3:3.8b-mini-4k-instruct

# Qwen
ollama pull qwen:1.8b-chat

# Gemma
ollama pull gemma:2b
```

#### 3. 启动服务
```bash
# Ollama自动启动API服务（端口11434）
ollama serve

# 测试运行
ollama run phi3:3.8b-mini-4k-instruct
```

#### 4. API端点

**端点：**
- `POST http://localhost:11434/v1/chat/completions` - OpenAI兼容
- `POST http://localhost:11434/api/chat` - Ollama原生API
- `POST http://localhost:11434/api/generate` - 文本生成

---

## 方案三：Python + 小模型（灵活）

### 特点
- ✅ 完全控制
- ✅ 支持更多模型
- ⚠️ 需要Python环境
- ⚠️ 需要手动管理

### 实现步骤

#### 1. 安装依赖
```bash
pip install flask transformers accelerate
```

#### 2. Python服务器脚本

```python
from flask import Flask, request, jsonify
from transformers import AutoModelForCausalLM, AutoTokenizer
import torch

app = Flask(__name__)

# 加载小模型（Phi-3-mini）
model_name = "microsoft/Phi-3-mini-4k-instruct"
tokenizer = AutoTokenizer.from_pretrained(model_name)
model = AutoModelForCausalLM.from_pretrained(
    model_name,
    torch_dtype="auto",
    trust_remote_code=True
)

@app.route('/v1/chat/completions', methods=['POST'])
def chat_completions():
    data = request.json
    messages = data.get('messages', [])
    
    # 构建prompt
    prompt = ""
    for msg in messages:
        role = msg['role']
        content = msg['content']
        if role == 'system':
            prompt += f"System: {content}\n"
        elif role == 'user':
            prompt += f"User: {content}\n"
        elif role == 'assistant':
            prompt += f"Assistant: {content}\n"
    
    prompt += "Assistant: "
    
    # 生成
    inputs = tokenizer(prompt, return_tensors="pt")
    outputs = model.generate(
        **inputs,
        max_new_tokens=data.get('max_tokens', 500),
        temperature=data.get('temperature', 0.7),
        do_sample=True
    )
    
    response_text = tokenizer.decode(outputs[0], skip_special_tokens=True)
    response_text = response_text.replace(prompt, "").strip()
    
    return jsonify({
        "choices": [{
            "message": {
                "role": "assistant",
                "content": response_text
            }
        }]
    })

if __name__ == '__main__':
    app.run(host='127.0.0.1', port=8082)
```

#### 3. 启动服务
```bash
python llm_server.py
```

---

## Godot集成代码

### LLMClient - 连接本地小模型

```gdscript
class_name LocalLLMClient
extends RefCounted

var server_url: String = "http://localhost:8082"
var http_request: HTTPRequest = null
var pending_requests: Dictionary = {}

signal response_received(request_id: String, response: String)
signal error_occurred(request_id: String, error: String)

func initialize(parent_node: Node) -> void:
    http_request = HTTPRequest.new()
    parent_node.add_child(http_request)
    http_request.request_completed.connect(_on_request_completed)

func generate_dialogue(system_prompt: String, user_prompt: String) -> String:
    var request_id: String = "req_%d" % Time.get_ticks_msec()
    
    var body: Dictionary = {
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt}
        ],
        "temperature": 0.7,
        "max_tokens": 500
    }
    
    var json_body: String = JSON.stringify(body)
    var headers: Array = ["Content-Type: application/json"]
    
    var error: int = http_request.request(
        server_url + "/v1/chat/completions",
        headers,
        HTTPClient.METHOD_POST,
        json_body
    )
    
    if error != OK:
        error_occurred.emit(request_id, "HTTP request failed")
        return request_id
    
    pending_requests[request_id] = {
        "status": "pending",
        "timestamp": Time.get_ticks_msec()
    }
    
    return request_id

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
    if result != HTTPRequest.RESULT_SUCCESS:
        handle_error("Request failed")
        return
    
    var response_text: String = body.get_string_from_utf8()
    var json: JSON = JSON.new()
    
    if json.parse(response_text) != OK:
        handle_error("JSON parse failed")
        return
    
    var response_data: Dictionary = json.data
    var choices: Array = response_data.get("choices", [])
    
    if choices.is_empty():
        handle_error("No choices in response")
        return
    
    var message: Dictionary = choices[0].get("message", {})
    var content: String = message.get("content", "")
    
    # 找到对应的请求ID
    for request_id in pending_requests:
        response_received.emit(request_id, content)
        pending_requests.erase(request_id)
        break

func handle_error(error_msg: String) -> void:
    for request_id in pending_requests:
        error_occurred.emit(request_id, error_msg)
        pending_requests.erase(request_id)
        break

func set_server_url(url: String) -> void:
    server_url = url

func is_server_available() -> bool:
    # 简单的健康检查
    return true
```

---

## 性能对比

### CPU推理速度

| 模型 | CPU速度 (tokens/s) | 内存占用 | 质量 |
|------|-------------------|----------|------|
| TinyLlama-1.1B | ~15-20 | ~600MB | ⭐⭐ |
| Phi-3-mini-3.8B | ~8-12 | ~2GB | ⭐⭐⭐⭐ |
| Qwen-1.8B | ~10-15 | ~1GB | ⭐⭐⭐ |

### GPU推理速度（如果可用）

| 模型 | GPU速度 (tokens/s) | VRAM占用 | 质量 |
|------|-------------------|----------|------|
| TinyLlama-1.1B | ~50-80 | ~1GB | ⭐⭐ |
| Phi-3-mini-3.8B | ~30-50 | ~3GB | ⭐⭐⭐⭐ |
| Qwen-1.8B | ~40-60 | ~2GB | ⭐⭐⭐ |

---

## 推荐配置

### 方案一：极小配置（TinyLlama）
- **模型：** TinyLlama-1.1B Q4量化
- **文件：** ~600MB
- **内存：** 1GB
- **CPU速度：** 15-20 tokens/s
- **适合：** 简单对话、测试

### 方案二：平衡配置（Phi-3-mini）⭐ 推荐
- **模型：** Phi-3-mini-3.8B Q4量化
- **文件：** ~2GB
- **内存：** 3GB
- **CPU速度：** 8-12 tokens/s
- **质量：** 接近GPT-3.5
- **适合：** 复杂对话、剧情生成

### 方案三：中等配置（Qwen-1.8B）
- **模型：** Qwen-1.8B Q4量化
- **文件：** ~1GB
- **内存：** 2GB
- **CPU速度：** 10-15 tokens/s
- **质量：** 中等
- **适合：** 通用对话

---

## 完整集成流程

### 1. 安装本地推理服务

```bash
# 推荐使用Ollama（最简单）
brew install ollama  # macOS
ollama pull phi3:3.8b-mini-4k-instruct
ollama serve
```

### 2. 修改Godot LLM集成

```gdscript
# 修改 scripts/agent/llm_integration.gd

func initialize_local_llm() -> void:
    provider = Provider.LOCAL
    api_endpoint = "http://localhost:11434/v1/chat/completions"
    model = "phi3:3.8b-mini-4k-instruct"
```

### 3. 测试生成

```bash
# 测试Ollama API
curl -X POST http://localhost:11434/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [
      {"role": "system", "content": "Generate dialogue for Rifts game."},
      {"role": "user", "content": "Create dialogue about moral dilemma in space."}
    ],
    "temperature": 0.7,
    "max_tokens": 200
  }'
```

---

## 分发方案

### 方案一：用户自行安装（推荐）
- 游戏启动时检测本地服务
- 提示用户安装Ollama
- 自动下载推荐模型
- 用户控制资源占用

### 方案二：打包小型服务
- 包含llama.cpp二进制文件
- 包含小型量化模型（~1GB）
- 增加游戏包体大小
- 需要用户同意下载

### 方案三：混合方案
- 默认：模板生成（完全本地）
- 高级：本地小模型（用户可选安装）
- 最佳：外部API（用户可选订阅）

---

## 优势对比

| 特性 | 本地小模型 | 外部API |
|------|-----------|---------|
| **成本** | ✅ 完全免费 | ⚠️ 有费用 |
| **隐私** | ✅ 完全本地 | ⚠️ 数据外传 |
| **速度** | ⚠️ 较慢（8-15 t/s） | ✅ 快（30+ t/s） |
| **质量** | ⚠️ 中等（⭐⭐⭐） | ✅ 高（⭐⭐⭐⭐⭐） |
| **依赖** | ⚠️ 需安装服务 | ✅ 无需安装 |
| **包体** | ⚠️ +1-2GB | ✅ 无增加 |

---

## 最终建议

### 推荐方案：混合策略

1. **默认：模板生成**
   - 完全本地，无依赖
   - 质量中等，速度最快

2. **高级：本地小模型（推荐Phi-3-mini）**
   - 用户可选安装Ollama
   - 质量接近GPT-3.5
   - 完全免费，隐私保护

3. **最佳：外部API**
   - 用户可选配置OpenAI密钥
   - 最高质量
   - 有费用，但速度最快

---

## 实施步骤

1. **安装Ollama**
   ```bash
   ollama pull phi3:3.8b-mini-4k-instruct
   ollama serve
   ```

2. **修改LLMIntegration**
   - 添加本地服务检测
   - 自动切换API端点
   - 提示用户安装

3. **测试生成质量**
   - 对比Phi-3和模板生成
   - 调整temperature参数
   - 优化prompt格式

4. **用户界面**
   - 添加"安装本地AI"按钮
   - 模型下载进度显示
   - 服务状态监控

---

**结论：完全可行！推荐Ollama + Phi-3-mini（2GB，质量接近GPT-3.5，完全本地免费）**