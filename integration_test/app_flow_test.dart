import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thai_for_myanmar/app.dart';
import 'package:thai_for_myanmar/data/phrase_repository.dart';
import 'package:thai_for_myanmar/services/app_state.dart';
import 'package:thai_for_myanmar/services/speech_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late PhraseRepository repository;

  setUpAll(() async {
    repository = await PhraseRepository.load(rootBundle);
  });

  testWidgets('Quick Speak searches, displays, and saves a phrase', (
    tester,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.clear();
    final state = AppState();
    await state.load();

    await tester.pumpWidget(
      ThaiForMyanmarApp(
        repository: repository,
        appState: state,
        speechService: SpeechService(),
      ),
    );
    await _pumpUi(tester);
    expect(find.text('ထိုင်းစကား လက်တွေ့သုံး'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.record_voice_over_outlined));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.text('အမြန်ပြောရန်'), findsOneWidget);
    final emergencyHelp = repository.phrases.singleWhere(
      (phrase) => phrase.id == 'emergency_help',
    );
    expect(
      find.text(emergencyHelp.thaiFor(state.politeStyle)),
      findsAtLeastNWidgets(1),
    );

    await tester.enterText(find.byType(TextField), 'ဗိုက်နာ');
    await _pumpUi(tester);
    expect(find.text('1 ခုတွေ့သည်'), findsOneWidget);

    final stomachResult = find.ancestor(
      of: find.text('ဗိုက်နာနေပါတယ်။'),
      matching: find.byType(ListTile),
    );
    expect(stomachResult, findsOneWidget);
    await tester.tap(stomachResult);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.text('ปวดท้องค่ะ'), findsWidgets);
    expect(find.textContaining('အသံထွက်'), findsWidgets);

    await tester.tap(find.byTooltip('အကြိုက်ဆုံးအဖြစ် သိမ်းရန်'));
    await _pumpUi(tester);
    expect(state.isFavorite('health_stomach'), isTrue);

    final restored = AppState();
    await restored.load();
    expect(restored.isFavorite('health_stomach'), isTrue);
  });
}

Future<void> _pumpUi(WidgetTester tester) async {
  await tester.pump();
}
