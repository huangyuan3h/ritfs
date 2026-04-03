class_name SystemTTS
extends RefCounted

var tts_enabled: bool = false
var tts_speed: int = 175
var tts_voice: String = ""

func speak_text(text: String) -> void:
    if not tts_enabled:
        return
    
    var clean_text: String = text.replace('"', "'").replace("\n", " ")
    
    if OS.get_name() == "macOS":
        speak_macos(clean_text)
    elif OS.get_name() == "Windows":
        speak_windows(clean_text)
    elif OS.get_name() == "Linux":
        speak_linux(clean_text)

func speak_macos(text: String) -> void:
    var voice_arg: String = tts_voice if not tts_voice.is_empty() else ""
    var command: String = "say"
    var args: Array = []
    
    if not voice_arg.is_empty():
        args.append("-v")
        args.append(voice_arg)
    
    args.append("-r")
    args.append(str(tts_speed))
    args.append(text)
    
    OS.execute(command, args, false)

func speak_windows(text: String) -> void:
    var script: String = '''
Add-Type -AssemblyName System.Speech
$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
$synth.Rate = %d
$synth.Speak("%s")
''' % [tts_speed / 25 - 5, text]
    
    OS.execute("powershell", ["-Command", script], false)

func speak_linux(text: String) -> void:
    var command: String = "espeak"
    var args: Array = ["-s", str(tts_speed), text]
    
    OS.execute(command, args, false)

func stop_speaking() -> void:
    if OS.get_name() == "macOS":
        OS.execute("killall", ["say"], false)
    elif OS.get_name() == "Windows":
        var script: String = '''
Add-Type -AssemblyName System.Speech
$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
$synth.SpeakAsyncCancelAll()
'''
        OS.execute("powershell", ["-Command", script], false)

func set_tts_enabled(enabled: bool) -> void:
    tts_enabled = enabled

func set_speed(speed: int) -> void:
    tts_speed = clamp(speed, 50, 300)

func set_voice(voice_name: String) -> void:
    tts_voice = voice_name

func get_available_voices() -> Array[String]:
    var voices: Array[String] = []
    
    if OS.get_name() == "macOS":
        var output: Array = []
        OS.execute("say", ["-v", "?"], output)
        
        for line in output:
            var parts: Array = line.split(" ")
            if parts.size() > 0:
                voices.append(parts[0])
    
    return voices

func is_tts_available() -> bool:
    if OS.get_name() == "macOS":
        return true
    elif OS.get_name() == "Windows":
        return true
    elif OS.get_name() == "Linux":
        var output: Array = []
        OS.execute("which", ["espeak"], output)
        return output.size() > 0 and not output[0].is_empty()
    
    return false