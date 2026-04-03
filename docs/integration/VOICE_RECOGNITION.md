# 语音识别集成方案

## 概述

用户可以通过语音与游戏交互：
- 语音控制移动（"向左"、"向前"）
- 语音触发对话（"你好"、"确认"）
- 语音回答问题（直接说话）

---

## 方案对比

| 方案 | 成本 | 质量 | 实时性 | 平台支持 |
|------|------|------|--------|----------|
| **系统语音识别** | 免费 | ⭐⭐⭐ | ~200ms | 全平台 |
| **Web Speech API** | 免费 | ⭐⭐⭐⭐ | 实时 | Web导出 |
| **Whisper API** | 有费用 | ⭐⭐⭐⭐⭐ | ~500ms | 全平台 |
| **本地Whisper** | 免费 | ⭐⭐⭐⭐⭐ | ~300ms | 需安装 |

---

## 方案一：系统语音识别（推荐本地）

### macOS实现

macOS有内置的语音识别，可以通过脚本调用：

```gdscript
class_name VoiceRecognition
extends RefCounted

var recognition_enabled: bool = false
var listening: bool = false
var recognized_text: String = ""
var last_command_time: float = 0.0

signal command_recognized(command: String)
signal speech_to_text(text: String)

var command_mapping: Dictionary = {
    "向左": "move_left",
    "左": "move_left",
    "左走": "move_left",
    "向右": "move_right",
    "右": "move_right",
    "右走": "move_right",
    "向前": "move_forward",
    "前": "move_forward",
    "前进": "move_forward",
    "向后": "move_backward",
    "后": "move_backward",
    "后退": "move_backward",
    "停止": "stop",
    "停": "stop",
    "停住": "stop",
    "交互": "interact",
    "确认": "interact",
    "对话": "dialogue",
    "说话": "dialogue"
}

func start_listening() -> void:
    if not recognition_enabled:
        return
    
    listening = true
    
    if OS.get_name() == "macOS":
        start_macos_recognition()
    elif OS.get_name() == "Windows":
        start_windows_recognition()
    elif OS.get_name() == "Linux":
        start_linux_recognition()

func start_macos_recognition() -> void:
    # macOS使用Swift脚本调用语音识别
    var swift_script: String = '''
import Foundation
import Speech

let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
let request = SFSpeechURLRecognitionRequest(url: URL(fileURLWithPath: "/dev/stdin"))

recognizer?.recognitionTask(with: request) { result, error in
    if let result = result {
        print(result.bestTranscription.formattedString)
    }
}
'''
    
    # 实际实现需要更复杂的音频录制
    # 这里简化演示
    pass

func start_windows_recognition() -> void:
    # Windows PowerShell + SAPI
    var powershell_script: String = '''
Add-Type -AssemblyName System.Speech
$recognizer = New-Object System.Speech.Recognition.SpeechRecognitionEngine
$recognizer.SetInputToDefaultAudioDevice()
$grammar = New-Object System.Speech.Recognition.DictationGrammar
$recognizer.LoadGrammar($grammar)
$result = $recognizer.Recognize()
Write-Output $result.Text
'''
    
    OS.execute("powershell", ["-Command", powershell_script], false)

func start_linux_recognition() -> void:
    # Linux需要安装额外的工具（如vosk）
    pass

func stop_listening() -> void:
    listening = false

func process_recognized_text(text: String) -> void:
    recognized_text = text.lower()
    
    # 检查是否是命令
    for key in command_mapping:
        if recognized_text.contains(key):
            var command: String = command_mapping[key]
            command_recognized.emit(command)
            last_command_time = Time.get_ticks_msec() / 1000.0
            return
    
    # 否则作为普通文本
    speech_to_text.emit(text)

func set_enabled(enabled: bool) -> void:
    recognition_enabled = enabled

func get_last_command() -> String:
    return recognized_text

func get_time_since_last_command() -> float:
    return Time.get_ticks_msec() / 1000.0 - last_command_time
```

### 实际可行的本地方案

**问题：** Godot无法直接访问麦克风进行实时语音识别。

**解决方案：** 外部脚本 + 文件通信

创建Python辅助脚本：

```python
# voice_recognition_helper.py
import speech_recognition as sr
import json
import sys

def listen_and_recognize():
    recognizer = sr.Recognizer()
    
    with sr.Microphone() as source:
        print("正在监听...", flush=True)
        recognizer.adjust_for_ambient_noise(source)
        
        try:
            audio = recognizer.listen(source, timeout=5)
            
            # 使用系统识别（免费）
            text = recognizer.recognize_sphinx(audio, language="zh-CN")
            
            # 或使用Google（免费，但需要网络）
            # text = recognizer.recognize_google(audio, language="zh-CN")
            
            result = {"text": text, "success": True}
            print(json.dumps(result), flush=True)
            
        except sr.WaitTimeoutError:
            print(json.dumps({"text": "", "success": False, "error": "timeout"}), flush=True)
        except sr.UnknownValueError:
            print(json.dumps({"text": "", "success": False, "error": "unknown"}), flush=True)

if __name__ == "__main__":
    while True:
        listen_and_recognize()
```

Godot调用：

```gdscript
class_name VoiceRecognitionHelper
extends Node

var python_process: OS = null
var is_running: bool = false

signal speech_recognized(text: String)

func start() -> void:
    # 启动Python语音识别脚本
    var script_path: String = "res://scripts/helpers/voice_recognition_helper.py"
    OS.execute("python3", [script_path], false)
    is_running = true

func stop() -> void:
    if is_running:
        # 停止进程
        pass
    is_running = false

func _process(delta: float) -> void:
    if is_running:
        # 监听Python脚本的输出
        pass
```

---

## 方案二：Web Speech API（推荐Web导出）

Web导出时，可以使用浏览器原生API：

```gdscript
class_name WebSpeechRecognition
extends RefCounted

var recognition_enabled: bool = false
var is_web_export: bool = false

signal speech_recognized(text: String)

func initialize() -> void:
    # 检查是否是Web导出
    if OS.get_name() == "Web":
        is_web_export = true
        setup_web_recognition()

func setup_web_recognition() -> void:
    # JavaScript接口（Web导出可用）
    JavaScriptBridge.eval("""
    if ('webkitSpeechRecognition' in window) {
        var recognition = new webkitSpeechRecognition();
        recognition.continuous = true;
        recognition.interimResults = true;
        recognition.lang = 'zh-CN';
        
        recognition.onresult = function(event) {
            var text = event.results[event.results.length - 1][0].transcript;
            // 发送到Godot
            window.godotSpeechResult = text;
        };
        
        recognition.onerror = function(event) {
            console.error('Speech recognition error:', event.error);
        };
        
        window.startRecognition = function() {
            recognition.start();
        };
        
        window.stopRecognition = function() {
            recognition.stop();
        };
    }
    """)
    
    # 定义回调接口
    JavaScriptBridge.create_callback("getSpeechResult", self, "_on_speech_result")

func start_listening() -> void:
    if is_web_export:
        JavaScriptBridge.eval("window.startRecognition()")

func stop_listening() -> void:
    if is_web_export:
        JavaScriptBridge.eval("window.stopRecognition()")

func _on_speech_result(args: Array) -> void:
    var text: String = args[0]
    speech_recognized.emit(text)

func get_current_text() -> String:
    if is_web_export:
        return JavaScriptBridge.eval("window.godotSpeechResult || ''")
    return ""
```

---

## 方案三：Whisper API（高质量）

OpenAI Whisper质量最高，但有费用：

```gdscript
class_name WhisperRecognition
extends RefCounted

var api_key: String = ""
var api_endpoint: String = "https://api.openai.com/v1/audio/transcriptions"

signal transcription_ready(text: String)

func transcribe_audio(audio_file_path: String) -> void:
    # 需要先录制音频
    # 然后发送到Whisper API
    
    var headers: Array = [
        "Authorization: Bearer %s" % api_key
    ]
    
    # 发送音频文件
    # 这需要更复杂的实现
    pass

func set_api_key(key: String) -> void:
    api_key = key
```

---

## 方案四：本地Whisper（最佳平衡）

使用whisper.cpp或本地Whisper模型：

### 安装whisper.cpp

```bash
git clone https://github.com/ggerganov/whisper.cpp
cd whisper.cpp
make

# 下载模型（推荐small，质量好）
./models/download-ggml-model.sh small
```

### 启动服务

```bash
./whisper-server -m models/ggml-small.bin --port 8083
```

### Godot集成

```gdscript
class_name LocalWhisperRecognition
extends RefCounted

var server_url: String = "http://localhost:8083"
var audio_recorder: AudioStreamRecorder = null

signal transcription_ready(text: String)

func initialize() -> void:
    # 初始化音频录制
    audio_recorder = AudioStreamRecorder.new()
    audio_recorder.format = AudioStreamRecorder.FORMAT_16_BITS
    
func start_recording() -> void:
    audio_recorder.recording_active = true

func stop_recording_and_transcribe() -> void:
    audio_recorder.recording_active = false
    
    var audio_data: PackedByteArray = audio_recorder.get_recording_data()
    
    # 发送到本地Whisper服务器
    send_to_whisper_server(audio_data)

func send_to_whisper_server(audio_data: PackedByteArray) -> void:
    var http: HTTPRequest = HTTPRequest.new()
    
    # 需要编码为WAV格式
    # 然后发送POST请求
    
    pass
```

---

## 推荐实现方案

### 混合策略

```gdscript
class_name VoiceInputSystem
extends Node

enum RecognitionMode { DISABLED, SYSTEM, WEB, WHISHER_API, LOCAL_WHISHER }

var current_mode: RecognitionMode = RecognitionMode.DISABLED
var web_recognition: WebSpeechRecognition = null
var system_recognition: VoiceRecognition = null

signal voice_command_received(command: String)
signal voice_text_received(text: String)

var command_mapping: Dictionary = {
    "左": "move_left",
    "左走": "move_left",
    "向左": "move_left",
    "右": "move_right",
    "右走": "move_right",
    "向右": "move_right",
    "前": "move_forward",
    "前进": "move_forward",
    "向前": "move_forward",
    "后": "move_backward",
    "后退": "move_backward",
    "向后": "move_backward",
    "停": "stop",
    "停止": "stop",
    "交互": "interact",
    "对话": "dialogue",
    "你好": "hello",
    "确认": "confirm",
    "取消": "cancel"
}

func _ready() -> void:
    initialize_best_mode()

func initialize_best_mode() -> void:
    if OS.get_name() == "Web":
        current_mode = RecognitionMode.WEB
        web_recognition = WebSpeechRecognition.new()
        web_recognition.initialize()
        web_recognition.speech_recognized.connect(_on_speech_recognized)
    
    else:
        # 检查是否有本地Whisper
        if check_local_whisper_available():
            current_mode = RecognitionMode.LOCAL_WHISHER
        else:
            current_mode = RecognitionMode.SYSTEM
            system_recognition = VoiceRecognition.new()
            system_recognition.set_enabled(true)

func check_local_whisper_available() -> bool:
    # 检查本地Whisper服务是否运行
    return false

func start_voice_input() -> void:
    match current_mode:
        RecognitionMode.WEB:
            web_recognition.start_listening()
        RecognitionMode.SYSTEM:
            system_recognition.start_listening()
        RecognitionMode.LOCAL_WHISHER:
            pass

func stop_voice_input() -> void:
    match current_mode:
        RecognitionMode.WEB:
            web_recognition.stop_listening()
        RecognitionMode.SYSTEM:
            system_recognition.stop_listening()

func _on_speech_recognized(text: String) -> void:
    process_voice_input(text)

func process_voice_input(text: String) -> void:
    var lower_text: String = text.lower()
    
    # 检查命令
    for key in command_mapping:
        if lower_text.contains(key):
            var command: String = command_mapping[key]
            voice_command_received.emit(command)
            execute_command(command)
            return
    
    # 否则作为文本输入
    voice_text_received.emit(text)

func execute_command(command: String) -> void:
    match command:
        "move_left":
            Input.action_press("move_left")
        "move_right":
            Input.action_press("move_right")
        "move_forward":
            Input.action_press("move_forward")
        "move_backward":
            Input.action_press("move_backward")
        "stop":
            Input.action_release("move_left")
            Input.action_release("move_right")
            Input.action_release("move_forward")
            Input.action_release("move_backward")
        "interact":
            Input.action_press("interact")
        "dialogue":
            DialogueManager.start_dialogue("voice_dialogue")

func set_mode(mode: RecognitionMode) -> void:
    current_mode = mode

func get_mode_name() -> String:
    return RecognitionMode.keys()[current_mode]
```

---

## 用户界面集成

### UI提示

```gdscript
class_name VoiceInputUI
extends Control

@onready var status_label: Label = $StatusLabel
@onready var transcript_label: Label = $TranscriptLabel
@onready var mic_button: Button = $MicButton

var voice_system: VoiceInputSystem = null
var is_listening: bool = false

func _ready() -> void:
    voice_system = VoiceInputSystem.new()
    add_child(voice_system)
    
    voice_system.voice_command_received.connect(_on_command_received)
    voice_system.voice_text_received.connect(_on_text_received)
    
    mic_button.pressed.connect(_on_mic_button_pressed)
    
    update_status()

func _on_mic_button_pressed() -> void:
    if is_listening:
        voice_system.stop_voice_input()
        is_listening = false
        mic_button.text = "开始语音"
        status_label.text = "语音识别已停止"
    else:
        voice_system.start_voice_input()
        is_listening = true
        mic_button.text = "停止语音"
        status_label.text = "正在监听..."

func _on_command_received(command: String) -> void:
    transcript_label.text = "命令：%s" % command

func _on_text_received(text: String) -> void:
    transcript_label.text = "识别：%s" % text

func update_status() -> void:
    status_label.text = "模式：%s" % voice_system.get_mode_name()
```

---

## 测试命令

### 支持的语音命令

| 中文命令 | 英文命令 | 动作 |
|---------|---------|------|
| 左 / 向左 / 左走 | left / go left | 向左移动 |
| 右 / 向右 / 右走 | right / go right | 向右移动 |
| 前 / 向前 / 前进 | forward / go forward | 向前移动 |
| 后 / 向后 / 后退 | back / backward | 向后移动 |
| 停 / 停止 | stop / halt | 停止移动 |
| 交互 / 确认 | interact / confirm | 交互 |
| 对话 / 说话 | dialogue / talk | 开始对话 |
| 你好 | hello | 问好 |
| 取消 | cancel | 取消操作 |

---

## 实际可行性

### ✅ Web导出（最可行）
- 浏览器原生Web Speech API
- 完全免费、实时、高质量
- 中文支持良好
- 用户只需点击按钮

### ⚠️ 本地导出（较复杂）
- 需要Python辅助脚本
- 或系统命令行工具
- 实现复杂度较高
- 质量中等

### 💰 外部API（最简单但收费）
- OpenAI Whisper API
- 质量最高（⭐⭐⭐⭐⭐）
- 有费用
- 需要API密钥

---

## 最终建议

### 推荐方案

**Web导出：** Web Speech API（免费、实时、高质量）

**本地导出：** 
- 简单方案：Python + SpeechRecognition（免费）
- 高级方案：本地Whisper（免费、高质量）
- 或者：外部API（付费、最简单）

**混合策略：**
1. Web导出自动用Web Speech API
2. 本地导出检测可用方案
3. 用户可选配置

---

## 下一步实现

1. Web Speech API测试（优先）
2. Python辅助脚本（本地）
3. UI集成
4. 命令映射优化

---

**总结：完全可行！Web导出用原生API，本地用Python脚本或Whisper**