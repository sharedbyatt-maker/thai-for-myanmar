import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thai_for_myanmar/app.dart';
import 'package:thai_for_myanmar/data/phrase_repository.dart';
import 'package:thai_for_myanmar/screens/main_shell.dart';
import 'package:thai_for_myanmar/screens/quick_speak_screen.dart';
import 'package:thai_for_myanmar/screens/phrase_detail_screen.dart';
import 'package:thai_for_myanmar/screens/phrase_issue_screen.dart';
import 'package:thai_for_myanmar/screens/settings_screen.dart';
import 'package:thai_for_myanmar/screens/speech_setup_screen.dart';
import 'package:thai_for_myanmar/services/app_state.dart';
import 'package:thai_for_myanmar/services/speech_service.dart';
import 'package:thai_for_myanmar/services/thai_audio_catalog.dart';
import 'package:thai_for_myanmar/services/thai_playback_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PhraseRepository repository;

  setUpAll(() async {
    repository = await PhraseRepository.load(rootBundle);
  });

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

    final appState = AppState();
    await appState.load();
    await tester.pumpWidget(
      ThaiForMyanmarApp(
        repository: repository,
        appState: appState,
        playbackService: _playbackService(),
      ),
    );
    await _pumpUi(tester);
    expect(find.text('ထိုင်းစကား လက်တွေ့သုံး'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final quickSpeakDestination = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.byIcon(Icons.record_voice_over_outlined),
    );
    await tester.tap(quickSpeakDestination);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      3,
    );
    expect(find.byType(QuickSpeakScreen), findsOneWidget);
    expect(find.text('အမြန်ပြောရန်'), findsOneWidget);
    final emergencyHelp = repository.phrases.singleWhere(
      (phrase) => phrase.id == 'emergency_help',
    );
    expect(
      find.text(emergencyHelp.thaiFor(appState.politeStyle)),
      findsAtLeastNWidgets(1),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('dark theme can be selected without blocking navigation', (
    tester,
  ) async {
    final appState = AppState();
    await appState.load();
    await appState.setThemePreference('dark');
    await tester.pumpWidget(
      ThaiForMyanmarApp(
        repository: repository,
        appState: appState,
        playbackService: _playbackService(),
      ),
    );
    await _pumpUi(tester);
    expect(find.byType(MainShell), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a phrase correction is saved and clearly marked unsent', (
    tester,
  ) async {
    final state = AppState();
    await state.load();
    await tester.pumpWidget(
      MaterialApp(
        home: PhraseDetailScreen(
          phrase: repository.phrases.firstWhere((p) => p.id == 'greet_hello'),
          repository: repository,
          appState: state,
          playbackService: _playbackService(),
        ),
      ),
    );
    await tester.ensureVisible(find.text('ဒီစကားစုမှာ အမှားထောက်ပြရန်'));
    await tester.tap(find.text('ဒီစကားစုမှာ အမှားထောက်ပြရန်'));
    await tester.pumpAndSettle();
    expect(find.byType(PhraseIssueScreen), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'အသံထွက်ကို စစ်ပေးပါ');
    await tester.ensureVisible(find.text('စက်ထဲ သိမ်းရန်'));
    await tester.tap(find.text('စက်ထဲ သိမ်းရန်'));
    await tester.pumpAndSettle();
    expect(state.phraseIssues, hasLength(1));
    expect(find.textContaining('Developer ဆီ မပို့ရသေးပါ'), findsOneWidget);
    expect(find.text('အမှားထောက်ပြချက် Copy လုပ်ရန်'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('voice test and saved correction list are visible in Settings', (
    tester,
  ) async {
    final state = AppState();
    await state.load();
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          appState: state,
          repository: repository,
          playbackService: _playbackService(),
        ),
      ),
    );
    await tester.ensureVisible(find.text('ထိုင်းအသံ စမ်းရန် / ပြင်ဆင်နည်း'));
    await tester.tap(find.text('ထိုင်းအသံ စမ်းရန် / ပြင်ဆင်နည်း'));
    await tester.pumpAndSettle();
    expect(find.byType(SpeechSetupScreen), findsOneWidget);
    expect(find.text('ထိုင်းအသံ စမ်းရန်'), findsWidgets);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('သိမ်းထားသော အမှားထောက်ပြချက်များ'));
    await tester.tap(find.text('သိမ်းထားသော အမှားထောက်ပြချက်များ'));
    await tester.pumpAndSettle();
    expect(find.byType(SavedPhraseIssuesScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpUi(WidgetTester tester) async {
  await tester.pump();
}

ThaiPlaybackService _playbackService() => ThaiPlaybackService(
  speechService: SpeechService(),
  catalog: ThaiAudioCatalog.empty(),
  assetPlayer: _NoopAssetPlayer(),
);

class _NoopAssetPlayer implements ThaiAudioAssetPlayer {
  @override
  Future<void> play(
    String assetPath, {
    required void Function() onStarted,
  }) async {
    onStarted();
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}
