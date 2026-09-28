import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show EnginePhase;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thai_for_myanmar/app.dart';
import 'package:thai_for_myanmar/data/phrase_repository.dart';
import 'package:thai_for_myanmar/screens/main_shell.dart';
import 'package:thai_for_myanmar/services/app_state.dart';
import 'package:thai_for_myanmar/services/speech_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('home and Quick Speak render at a small, larger-text viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    tester.view.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.platformDispatcher.clearTextScaleFactorTestValue);

    final repository = await PhraseRepository.load(rootBundle);
    final appState = AppState();
    await appState.load();
    await tester.pumpWidget(
      ThaiForMyanmarApp(
        repository: repository,
        appState: appState,
        speechService: SpeechService(),
      ),
    );
    await _settle(tester);
    expect(find.text('ထိုင်းစကား လက်တွေ့သုံး'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final quickSpeakDestination = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.byIcon(Icons.record_voice_over_outlined),
    );
    await tester.tap(quickSpeakDestination);
    await _settle(tester);
    expect(find.text('အရေးပေါ်စကားစု'), findsOneWidget);
    expect(find.text('ช่วยด้วยค่ะ เป็นเหตุฉุกเฉิน'), findsAtLeastNWidgets(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('dark theme can be selected without blocking navigation', (
    tester,
  ) async {
    final repository = await PhraseRepository.load(rootBundle);
    final appState = AppState();
    await appState.load();
    await appState.setThemePreference('dark');
    await tester.pumpWidget(
      ThaiForMyanmarApp(
        repository: repository,
        appState: appState,
        speechService: SpeechService(),
      ),
    );
    await _settle(tester);
    expect(find.byType(MainShell), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 30),
  );
}
