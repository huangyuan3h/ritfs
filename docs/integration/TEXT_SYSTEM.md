# 本地文字显示系统（替代TTS）

## 设计理念

**文字为主，语音可选增强**

### 核心方案
- 所有对话优先文字显示
- Agent生成文字内容
- 语音作为可选增强（系统TTS或API）
- 动态文字动画效果

---

## 实现方案

### 1. 动态文字显示系统

```gdscript
class_name DynamicTextDisplay
extends Control

@onready var text_display: RichTextLabel = $RichTextLabel

var display_speed: float = 30.0  # 字符/秒
var current_text: String = ""
var displayed_chars: int = 0
var is_displaying: bool = false

signal text_display_complete()

func display_text(text: String) -> void:
    current_text = text
    displayed_chars = 0
    is_displaying = true
    text_display.text = ""

func _process(delta: float) -> void:
    if not is_displaying:
        return
    
    if displayed_chars < current_text.length():
        displayed_chars += 1
        text_display.text = current_text.substr(0, displayed_chars)
        
        # 添加打字机效果
        if displayed_chars % 3 == 0:
            play_typewriter_sound()
    else:
        is_displaying = false
        text_display_complete.emit()

func play_typewriter_sound() -> void:
    AudioManager.play_sfx("res://assets/sfx/typewriter_click.wav")

func skip_to_end() -> void:
    text_display.text = current_text
    displayed_chars = current_text.length()
    is_displaying = false
    text_display_complete.emit()
```

### 2. 文字效果系统

```gdscript
class_name TextEffects
extends RefCounted

static func apply_effect(text: String, effect_type: String) -> String:
    match effect_type:
        "emphasis":
            return "[color=yellow]" + text + "[/color]"
        "warning":
            return "[color=red][b]" + text + "[/b][/color]"
        "thought":
            return "[i][color=gray]" + text + "[/color][/i]"
        "system":
            return "[color=cyan]" + text + "[/color]"
    return text

static func create_choice_text(choices: Array) -> String:
    var formatted: String = "\n\n[选择：]\n"
    for i in range(choices.size()):
        var choice: Dictionary = choices[i]
        formatted += "[%d] %s\n" % [i + 1, choice.get("text", "选项")]
    return formatted
```

### 3. 系统TTS集成（可选）

```gdscript
class_name SystemTTS
extends RefCounted

var tts_enabled: bool = false
var tts_speed: int = 150  # macOS say命令速度

func speak_text(text: String) -> void:
    if not tts_enabled:
        return
    
    # macOS系统TTS
    if OS.get_name() == "macOS":
        var command: String = 'say -r %d "%s"' % [tts_speed, text.replace('"', "'")]
        OS.execute(command, [], false)
    
    # Windows系统TTS（需要PowerShell）
    elif OS.get_name() == "Windows":
        var powershell_script: String = '''
        Add-Type -AssemblyName System.Speech
        $synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
        $synth.Speak("%s")
        ''' % text.replace('"', "'")
        OS.execute("powershell", ["-Command", powershell_script], false)
    
    # Linux系统TTS（需要espeak）
    elif OS.get_name() == "Linux":
        var command: String = 'espeak "%s"' % text.replace('"', "'")
        OS.execute(command, [], false)

func set_tts_enabled(enabled: bool) -> void:
    tts_enabled = enabled

func stop_speaking() -> void:
    if OS.get_name() == "macOS":
        OS.execute("killall", ["say"], false)
```

---

## Agent文字生成系统

### Agent生成对话文字

```gdscript
class_name AgentTextGenerator
extends RefCounted

var llm_integration: LLMIntegration = null
var text_cache: Dictionary = {}

func generate_dialogue_text(context: Dictionary) -> String:
    # 如果有LLM，动态生成
    if llm_integration:
        return await_llm_generation(context)
    
    # 否则用模板
    return generate_template_text(context)

func await_llm_generation(context: Dictionary) -> String:
    var request_id: String = llm_integration.generate_dialogue(context, "")
    
    # 等待LLM响应（异步）
    var response: String = await llm_integration.response_received
    
    # 解析JSON响应
    var json: JSON = JSON.new()
    if json.parse(response) == OK:
        var dialogue_data: Dictionary = json.data
        return dialogue_data.get("text", response)
    
    return response

func generate_template_text(context: Dictionary) -> String:
    var scene: String = context.get("scene", "未知场景")
    var agent_name: String = context.get("agent_name", "Agent")
    
    var templates: Array = [
        "在%s，我感受到了人性的矛盾..." % scene,
        "%s陷入了深深的思考..." % agent_name,
        "这个选择将改变一切...",
        "在裂隙之中，真相即将浮现..."
    ]
    
    return templates[randi() % templates.size()]

func cache_text(key: String, text: String) -> void:
    text_cache[key] = text

func get_cached_text(key: String) -> String:
    return text_cache.get(key, "")
```

---

## 对话UI设计（文字优先）

### 场景结构

```
DialogueUI (Control)
├─ PanelContainer
│  ├─ VBoxContainer
│     ├─ SpeakerLabel (Label) - 说话者名字
│     ├─ TextDisplay (RichTextLabel) - 打字机效果显示
│     ├─ ChoicesContainer (VBoxContainer) - 选项按钮
│     └─ ContinueHint (Label) - "按E继续"
└─ SystemTTSButton (Button) - 可选语音按钮
```

### 功能特点

1. **打字机效果** - 文字逐字显示
2. **文字格式** - 颜色、加粗、斜体
3. **快速跳过** - 按键跳到完整文本
4. **历史记录** - 可查看对话历史
5. **可选语音** - 点击按钮播放系统TTS

---

## 预生成方案（推荐）

### 提前生成常用语音

```gdscript
class_name PreGeneratedVoice
extends RefCounted

var voice_cache: Dictionary = {}
var cache_path: String = "user://voice_cache/"

func pre_generate_common_phrases() -> void:
    var common_phrases: Array = [
        "欢迎来到裂隙之渊",
        "你的选择将改变一切",
        "在裂隙之中，直面你自己",
        "人性是最大的谜题"
    ]
    
    # 使用外部工具预生成（一次性）
    # 或使用系统TTS录制并保存
    
    for phrase in common_phrases:
        generate_and_cache(phrase)

func generate_and_cache(text: String) -> void:
    var file_id: String = "voice_%d.wav" % hash(text)
    var file_path: String = cache_path + file_id
    
    if not FileAccess.file_exists(file_path):
        # 使用系统TTS生成并保存
        # 这需要外部工具，游戏运行时不能直接录音
        
        pass
    
    voice_cache[text] = file_path

func play_cached_voice(text: String) -> void:
    if voice_cache.has(text):
        var file_path: String = voice_cache[text]
        AudioManager.play_sfx(file_path)
```

---

## 推荐实现方案

### 方案一：纯文字（最简单）

✅ **完全本地，无依赖**
- 打字机效果显示文字
- 文字格式和颜色
- Agent生成文字内容
- 无语音

### 方案二：文字 + 系统TTS（免费）

✅ **完全本地，免费**
- 文字为主
- 可选系统TTS按钮
- 用户点击播放语音
- 质量一般，但可用

### 方案三：文字 + 预生成语音（推荐）

✅ **高质量，半实时**
- 核心对话预生成高质量语音
- 其他对话纯文字
- 平衡质量和性能
- 需提前制作音频文件

### 方案四：文字 + API TTS（高质量）

⚠️ **需外部API，有成本**
- 文字显示（主）
- 高质量语音（可选）
- 需要API密钥和费用
- 实时生成，质量最好

---

## 最终建议

**文字为主，语音为可选增强**

### 必须实现
- ✅ 动态文字显示系统
- ✅ 打字机效果
- ✅ 文字格式化
- ✅ Agent文字生成
- ✅ 对话历史记录

### 可选增强
- ⚠️ 系统TTS按钮（简单本地）
- ⚠️ 预生成核心对话语音
- ⚠️ API TTS（高质量，有成本）

### Agent文字生成
- ✅ LLM生成对话文字（通过API）
- ✅ 文字模板填充（本地）
- ✅ 文字效果系统（本地）

---

## 代码示例

创建完整的文字显示系统：

```gdscript
# scripts/ui/dialogue_display_2d.gd
class_name DialogueDisplay2D
extends Control

@onready var speaker_label: Label = $Panel/SpeakerLabel
@onready var text_display: RichTextLabel = $Panel/TextDisplay
@onready var choices_container: VBoxContainer = $Panel/ChoicesContainer
@onready var tts_button: Button = $Panel/TTSButton

var system_tts: SystemTTS = SystemTTS.new()
var text_generator: AgentTextGenerator = AgentTextGenerator.new()

var display_speed: float = 25.0
var current_text: String = ""
var displayed_chars: int = 0
var is_displaying: bool = false

func _ready() -> void:
    tts_button.visible = system_tts.tts_enabled
    DialogueManager.dialogue_line_displayed.connect(_on_line_displayed)

func _on_line_displayed(speaker: String, text: String, choices: Array) -> void:
    speaker_label.text = speaker
    display_text(text)
    
    # TTS按钮功能
    tts_button.pressed.connect(func():
        system_tts.speak_text(text)
    )

func display_text(text: String) -> void:
    current_text = text
    displayed_chars = 0
    is_displaying = true
    text_display.text = ""
    
    # 清空选项
    for child in choices_container.get_children():
        child.queue_free()

func _process(delta: float) -> void:
    if not is_displaying:
        return
    
    var chars_to_add: int = int(display_speed * delta)
    
    for i in range(chars_to_add):
        if displayed_chars >= current_text.length():
            break
        
        displayed_chars += 1
        text_display.text = current_text.substr(0, displayed_chars)

    if displayed_chars >= current_text.length():
        is_displaying = false

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("interact"):
        if is_displaying:
            # 跳过打字机效果
            text_display.text = current_text
            displayed_chars = current_text.length()
            is_displaying = false
        else:
            DialogueManager.advance_dialogue()
```

---

**总结：文字为主是正确方向，语音只作为可选增强！**