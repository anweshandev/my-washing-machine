import 'package:flutter_tts/flutter_tts.dart';

/// Singleton TTS service for speaking errors and status cues.
class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;
  bool enabled = true;

  Future<void> init() async {
    if (_initialized) return;
    await _tts.awaitSpeakCompletion(true);
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _initialized = true;
  }

  Future<void> speak(String text) async {
    if (!enabled) return;
    await init();
    try {
      await _tts.speak(text);
    } catch (_) {
      // Engine not bound yet — reset and retry once
      _initialized = false;
      try {
        await init();
        await _tts.speak(text);
      } catch (_) {}
    }
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}
