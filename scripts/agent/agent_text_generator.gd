class_name AgentTextGenerator
extends RefCounted

var llm_integration: LLMIntegration = null
var text_templates: Dictionary = {}
var generation_cache: Dictionary = {}

func initialize(llm: LLMIntegration) -> void:
    llm_integration = llm
    load_templates()

func load_templates() -> void:
    text_templates = {
        "intro": [
            "在裂隙之中，你将直面最真实的自己...",
            "每一次选择，都是人性的考验。",
            "裂隙之渊欢迎你，准备好探索内心的矛盾了吗？"
        ],
        "dilemma": [
            "此刻，你面临艰难的选择...",
            "道德与生存，你将如何抉择？",
            "这个决定将改变一切..."
        ],
        "warning": [
            "小心！前方危机重重。",
            "你的选择可能带来意想不到的后果。",
            "在裂隙中，真相并不总是美好..."
        ],
        "success": [
            "你做出了勇敢的决定。",
            "人性的光辉在裂隙中闪耀。",
            "你的选择展现了内心的力量。"
        ],
        "failure": [
            "选择的代价已然显现...",
            "人性在裂隙中挣扎。",
            "这个决定留下了深刻的痕迹..."
        ]
    }

func generate_dialogue_text(context: Dictionary) -> String:
    if llm_integration:
        return generate_with_llm(context)
    
    return generate_with_template(context)

func generate_with_llm(context: Dictionary) -> String:
    var prompt: String = build_llm_prompt(context)
    var request_id: String = llm_integration.generate_dialogue(context, prompt)
    
    return request_id

func build_llm_prompt(context: Dictionary) -> String:
    var scene: String = context.get("scene", "未知")
    var mood: String = context.get("mood", "neutral")
    var moral_question: String = context.get("moral_question", "")
    
    var prompt: String = "为'裂隙之渊'游戏生成对话文字。\n"
    prompt += "场景：%s\n" % scene
    prompt += "氛围：%s\n" % mood
    prompt += "道德主题：%s\n" % moral_question
    prompt += "\n生成简短、深刻的对话文字，探索人性矛盾。\n"
    prompt += "返回纯文字（不要JSON格式）。"
    
    return prompt

func generate_with_template(context: Dictionary) -> String:
    var template_type: String = context.get("type", "intro")
    var templates: Array = text_templates.get(template_type, text_templates["intro"])
    
    if templates.is_empty():
        return "..."
    
    var base_text: String = templates[randi() % templates.size()]
    
    var agent_name: String = context.get("agent_name", "")
    if not agent_name.is_empty():
        base_text = base_text.replace("你", agent_name)
    
    return base_text

func generate_choice_text(choices: Array) -> Array[String]:
    var formatted_choices: Array[String] = []
    
    for i in range(choices.size()):
        var choice: Dictionary = choices[i]
        var text: String = choice.get("text", "选项 %d" % (i + 1))
        formatted_choices.append("[%d] %s" % [i + 1, text])
    
    return formatted_choices

func apply_text_effect(text: String, effect: String) -> String:
    match effect:
        "emphasis":
            return "[color=yellow]" + text + "[/color]"
        "warning":
            return "[color=red][b]" + text + "[/b][/color]"
        "thought":
            return "[i][color=gray]" + text + "[/color][/i]"
        "system":
            return "[color=cyan]" + text + "[/color]"
        "moral_good":
            return "[color=green]" + text + "[/color]"
        "moral_bad":
            return "[color=orange]" + text + "[/color]"
    
    return text

func cache_generation(key: String, text: String) -> void:
    generation_cache[key] = {
        "text": text,
        "timestamp": Time.get_ticks_msec()
    }

func get_cached_generation(key: String) -> String:
    if generation_cache.has(key):
        return generation_cache[key]["text"]
    return ""

func generate_agent_response(agent_state: Dictionary, situation: String) -> String:
    if llm_integration:
        var request_id: String = llm_integration.generate_agent_response(agent_state, situation)
        return request_id
    
    var moral_score: float = agent_state.get("moral_score", 0.0)
    var response_type: String = "neutral"
    
    if moral_score > 20:
        response_type = "altruistic"
    elif moral_score < -20:
        response_type = "selfish"
    
    var responses: Dictionary = {
        "altruistic": [
            "为了他人，我愿意付出。",
            "团结才能克服裂隙。",
            "我的选择将为所有人带来希望。"
        ],
        "selfish": [
            "我必须保护自己。",
            "生存是第一要务。",
            "在裂隙中，唯有自己可信。"
        ],
        "neutral": [
            "这是一个复杂的选择。",
            "我需要更多时间思考。",
            "人性的矛盾在此显现..."
        ]
    }
    
    var agent_responses: Array = responses.get(response_type, responses["neutral"])
    return agent_responses[randi() % agent_responses.size()]

func generate_narrative_text(scene_data: Dictionary) -> String:
    var theme: String = scene_data.get("theme", "unknown")
    var event_type: String = scene_data.get("event_type", "discovery")
    
    var narratives: Dictionary = {
        "discovery": "在%s中，新的真相浮现..." % theme,
        "conflict": "裂隙中的矛盾愈发激烈...",
        "resolution": "选择后的涟漪开始扩散...",
        "mystery": "裂隙深处隐藏着未知的秘密..."
    }
    
    return narratives.get(event_type, "裂隙中的故事继续...")