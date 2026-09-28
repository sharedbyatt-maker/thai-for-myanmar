import 'package:flutter_test/flutter_test.dart';
import 'package:thai_for_myanmar/services/speech_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'missing platform TTS plugin returns a safe unavailable result',
    () async {
      final result = await SpeechService().speakThai('สวัสดี');
      expect(result, SpeechResult.unavailable);
    },
  );
}
