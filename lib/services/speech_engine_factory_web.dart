import 'speech_engine.dart';
import 'web_speech_engine.dart';

SpeechEngine createPlatformSpeechEngine() => WebSpeechEngine();
