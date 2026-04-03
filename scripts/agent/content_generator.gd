class_name ContentGenerator
extends RefCounted

enum ContentType { TTS, IMAGE, LEVEL, DIALOGUE }

var tts_provider: String = "system"
var image_provider: String = ""
var llm_integration: LLMIntegration = null

var generated_content_cache: Dictionary = {}
var download_queue: Array[Dictionary] = []

signal content_generated(content_type: ContentType, content_id: String, content: Variant)
signal content_ready(content_type: ContentType, content_id: String)

func initialize(llm: LLMIntegration) -> void:
    llm_integration = llm

func generate_tts(text: String, voice_id: String = "default") -> String:
    var content_id: String = "tts_%d" % Time.get_ticks_msec()
    
    if tts_provider == "system":
        return generate_system_tts(content_id, text)
    elif tts_provider == "elevenlabs":
        return generate_elevenlabs_tts(content_id, text, voice_id)
    elif tts_provider == "openai":
        return generate_openai_tts(content_id, text, voice_id)
    
    return content_id

func generate_system_tts(content_id: String, text: String) -> String:
    pass
    
    content_generated.emit(ContentType.TTS, content_id, null)
    return content_id

func generate_elevenlabs_tts(content_id: String, text: String, voice_id: String) -> String:
    pass
    
    return content_id

func generate_openai_tts(content_id: String, text: String, voice_id: String) -> String:
    pass
    
    return content_id

func generate_image(prompt: String, style: String = "sci-fi", size: String = "512x512") -> String:
    var content_id: String = "img_%d" % Time.get_ticks_msec()
    
    if image_provider == "openai":
        return generate_dalle_image(content_id, prompt, size)
    elif image_provider == "stability":
        return generate_stable_diffusion_image(content_id, prompt, style, size)
    elif image_provider == "local":
        return generate_local_image(content_id, prompt, style)
    
    return content_id

func generate_dalle_image(content_id: String, prompt: String, size: String) -> String:
    pass
    
    return content_id

func generate_stable_diffusion_image(content_id: String, prompt: String, style: String, size: String) -> String:
    pass
    
    return content_id

func generate_local_image(content_id: String, prompt: String, style: String) -> String:
    pass
    
    return content_id

func generate_level(level_theme: String, difficulty: String) -> String:
    var content_id: String = "level_%d" % Time.get_ticks_msec()
    
    if llm_integration:
        llm_integration.generate_level_description(level_theme, difficulty)
        return content_id
    
    var level_data: Dictionary = generate_procedural_level(level_theme, difficulty)
    content_generated.emit(ContentType.LEVEL, content_id, level_data)
    
    return content_id

func generate_procedural_level(theme: String, difficulty: String) -> Dictionary:
    var level_data: Dictionary = {
        "theme": theme,
        "difficulty": difficulty,
        "layout": [],
        "objects": [],
        "objectives": [],
        "narrative_elements": []
    }
    
    var obstacle_count: int = 5 if difficulty == "easy" else 10 if difficulty == "medium" else 15
    
    for i in range(obstacle_count):
        level_data["objects"].append({
            "type": "obstacle",
            "position": [randf_range(-20, 20), 0, randf_range(-20, 20)],
            "variant": "barrier"
        })
    
    level_data["objectives"].append({
        "id": "main_objective",
        "description": "Complete the %s challenge" % theme,
        "type": "reach_goal"
    })
    
    level_data["narrative_elements"].append({
        "type": "dialogue_trigger",
        "position": [0, 0, 5],
        "dialogue_id": "level_intro_%s" % theme.to_lower()
    })
    
    return level_data

func generate_dialogue(context: Dictionary) -> String:
    var content_id: String = "dialogue_%d" % Time.get_ticks_msec()
    
    if llm_integration:
        var prompt: String = "Generate dialogue for the current situation based on game context."
        llm_integration.generate_dialogue(context, prompt)
        return content_id
    
    var dialogue_data: Dictionary = generate_template_dialogue(context)
    content_generated.emit(ContentType.DIALOGUE, content_id, dialogue_data)
    
    return content_id

func generate_template_dialogue(context: Dictionary) -> Dictionary:
    var scene: String = context.get("scene", "Unknown")
    var mood: String = context.get("mood", "neutral")
    
    var dialogue_data: Dictionary = {
        "id": "generated_dialogue_%d" % Time.get_ticks_msec(),
        "lines": []
    }
    
    dialogue_data["lines"].append({
        "speaker": "System",
        "text": "Welcome to %s. Your actions here will shape your journey." % scene,
        "choices": [
            {"text": "I'm ready to face the challenge", "id": "choice_ready", "next_dialogue": ""},
            {"text": "I need more time to think", "id": "choice_delay", "next_dialogue": ""}
        ]
    })
    
    return dialogue_data

func load_generated_image(content_id: String, image_url: String) -> void:
    download_queue.append({
        "content_id": content_id,
        "url": image_url,
        "type": ContentType.IMAGE
    })

func cache_content(content_type: ContentType, content_id: String, content: Variant) -> void:
    generated_content_cache[content_id] = {
        "type": content_type,
        "content": content,
        "timestamp": Time.get_ticks_msec()
    }

func get_cached_content(content_id: String) -> Variant:
    if generated_content_cache.has(content_id):
        return generated_content_cache[content_id]["content"]
    return null

func clear_cache() -> void:
    generated_content_cache.clear()