import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thai_for_myanmar/app.dart';
import 'package:thai_for_myanmar/screens/everyday_screen.dart';
import 'package:thai_for_myanmar/data/phrase_repository.dart';
import 'package:thai_for_myanmar/services/app_state.dart';
import 'package:thai_for_myanmar/services/speech_service.dart';
import 'package:thai_for_myanmar/services/thai_audio_catalog.dart';
import 'package:thai_for_myanmar/services/thai_playback_service.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late PhraseRepository repository;

  setUpAll(() async {
    repository = await PhraseRepository.load(rootBundle);
  });

  if (kIsWeb) {
    testWidgets('responsive home and direct search render in Chrome', (
      tester,
    ) async {
      final state = AppState();
      await state.load();
      await state.setThemePreference('light');
      await tester.pumpWidget(
        ThaiForMyanmarApp(
          repository: repository,
          appState: state,
          playbackService: _playbackService(),
        ),
      );
      await tester.pumpAndSettle();
      final width =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;
      expect([390, 1280], contains(width.round()));
      expect(
        find.byType(width >= 1000 ? NavigationRail : NavigationBar),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await binding.takeScreenshot('${width.round()}-home');
      await tester.ensureVisible(find.text('စလေ့ကျင့်မယ်'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('စလေ့ကျင့်မယ်'));
      await tester.pumpAndSettle();
      await binding.takeScreenshot('${width.round()}-lesson');
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.record_voice_over_outlined));
      await tester.pumpAndSettle();
      await binding.takeScreenshot('${width.round()}-everyday');
      await tester.enterText(
        find.byKey(const ValueKey('everyday-search')),
        'ဗိုက်နာ',
      );
      await tester.pumpAndSettle();
      expect(find.text('1 ခုတွေ့သည်'), findsOneWidget);
      await binding.takeScreenshot('${width.round()}-inline-search');
      await tester.enterText(find.byKey(const ValueKey('everyday-search')), '');
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.route_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('home-search')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'ဗိုက်နာ');
      await tester.pumpAndSettle();
      expect(find.text('1 ခုတွေ့သည်'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await binding.takeScreenshot('${width.round()}-search');
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('အကြောင်းအရာ ပြောင်းရန်'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('အကြောင်းအရာ ပြောင်းရန်'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Daily life');
      await tester.pumpAndSettle();
      await tester.tap(find.text('နေ့စဉ်ဘဝ'));
      await tester.pumpAndSettle();
      expect(find.text('နေ့စဉ်ဘဝ'), findsWidgets);
      expect(tester.takeException(), isNull);
      await binding.takeScreenshot('${width.round()}-path-end');
    });
  }

  testWidgets('guided lesson completes and restores local learning progress', (
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
        playbackService: _playbackService(),
      ),
    );
    await _pumpUi(tester);
    await tester.ensureVisible(find.text('စလေ့ကျင့်မယ်'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('စလေ့ကျင့်မယ်'));
    await tester.pump(const Duration(milliseconds: 500));
    for (var index = 0; index < 5; index++) {
      await tester.ensureVisible(find.text('အဓိပ္ပာယ်ကြည့်မယ်'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('အဓိပ္ပာယ်ကြည့်မယ်'));
      await tester.pump();
      await tester.ensureVisible(find.text('မှတ်မိတယ်'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('မှတ်မိတယ်'));
      await tester.pump();
    }
    expect(find.text('ဒီအကြိမ် ပြီးပါပြီ'), findsOneWidget);
    expect(state.learning.totalReviews, 5);
    expect(state.learning.completedSessions, 1);
    expect(state.learning.completedLessons, hasLength(1));
    expect(find.text('+45 XP'), findsOneWidget);
    await tester.ensureVisible(find.text('နောက်သင်ခန်းစာ ဆက်မယ်'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // Await a queued settings save to drain the preceding review snapshots.
    await state.setDailyGoal(10);
    final restored = AppState();
    await restored.load();
    expect(restored.learning.totalReviews, 5);
    expect(restored.learning.reviewXp, 25);
    expect(restored.learning.completedLessons, state.learning.completedLessons);
    await tester.tap(find.text('နောက်သင်ခန်းစာ ဆက်မယ်'));
    await tester.pumpAndSettle();
    expect(find.text('ဒီအကြိမ် ပြီးပါပြီ'), findsNothing);
    expect(find.text('အဓိပ္ပာယ်ကြည့်မယ်'), findsOneWidget);
    expect(state.learning.totalReviews, 5);
    expect(tester.takeException(), isNull);
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
        playbackService: _playbackService(),
      ),
    );
    await _pumpUi(tester);
    expect(find.text('သင်ယူ'), findsWidgets);

    await tester.tap(find.byIcon(Icons.record_voice_over_outlined));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('ထိုင်းလူမျိုးကို ပြမယ်'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(EverydayScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('ထိုင်းလူမျိုးကို ပြမယ်'));
    await tester.pumpAndSettle();
    expect(find.text('အမြန်သုံး'), findsWidgets);
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
