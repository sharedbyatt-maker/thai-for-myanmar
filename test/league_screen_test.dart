import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thai_for_myanmar/screens/league_screen.dart';
import 'package:thai_for_myanmar/services/league_service.dart';

class FakeLeague implements LeagueGateway {
  bool ready = true;
  final auth = StreamController<bool>.broadcast();
  @override
  Stream<bool> get authChanges => auth.stream;
  int googleLaunches = 0;
  bool launchSucceeds = true;
  @override
  Future<bool> signInWithGoogle() async {
    googleLaunches++;
    return launchSucceeds;
  }

  bool loggedIn = true;
  bool joined = true;
  int daily = 0;
  int submissions = 0;
  bool failSubmit = false;
  int joins = 0;
  @override
  bool get signedIn => loggedIn;
  @override
  Future<bool> initialize() async => ready;
  @override
  Future<void> signOut() async {
    loggedIn = false;
  }

  @override
  Future<void> join(String alias, int avatar) async {
    joins++;
    joined = true;
  }

  @override
  Future<void> leave() async {
    joined = false;
  }

  @override
  Future<Map<String, dynamic>> board() async => joined
      ? {
          'joined': true,
          'tier': 0,
          'daily_points': daily,
          'ends_at': '2026-11-01T17:00:00Z',
          'rows': [
            {
              'rank': 1,
              'alias': 'Mya',
              'avatar': 0,
              'points': 25,
              'mine': false,
            },
            {'rank': 2, 'alias': 'Ko', 'avatar': 1, 'points': 15, 'mine': true},
          ],
        }
      : {'joined': false};
  @override
  Future<Map<String, dynamic>> beginRound() async => {
    'id': 'round-1',
    'questions': [
      {
        'thai': 'สวัสดีค่ะ',
        'options': ['မင်္ဂလာပါ', 'ကျေးဇူး'],
      },
      {
        'thai': 'ขอบคุณค่ะ',
        'options': ['မင်္ဂလာပါ', 'ကျေးဇူး'],
      },
    ],
  };
  @override
  Future<Map<String, dynamic>> submit(String id, List<int> choices) async {
    expect(id, 'round-1');
    expect(choices, [0, 1]);
    submissions++;
    if (failSubmit) {
      failSubmit = false;
      throw Exception('offline');
    }
    return {
      'earned': 10,
      'bonus': 0,
      'correct': 2,
      'total': 2,
      'answers': [
        {'correct': true, 'answer': 0},
        {'correct': true, 'answer': 1},
      ],
    };
  }
}

void main() {
  testWidgets('League is honest when shared backend is unavailable', (
    tester,
  ) async {
    final api = FakeLeague()..ready = false;
    await tester.pumpWidget(MaterialApp(home: LeagueScreen(gateway: api)));
    await tester.pumpAndSettle();
    expect(find.text('League ကို ဖွင့်ရန် ပြင်ဆင်နေပါတယ်။'), findsOneWidget);
    expect(find.textContaining('Bronze'), findsNothing);
    expect(api.joins, 0);
  });
  testWidgets('sign-in is opt-in and does not invent competitors', (
    tester,
  ) async {
    final api = FakeLeague()..loggedIn = false;
    await tester.pumpWidget(MaterialApp(home: LeagueScreen(gateway: api)));
    await tester.pumpAndSettle();
    expect(find.text('Google နဲ့ ဝင်မယ်'), findsOneWidget);
    expect(find.text('Email'), findsNothing);
    expect(find.text('Account အသစ်ဖွင့်မယ်'), findsNothing);
    expect(find.textContaining('Mya'), findsNothing);
    expect(api.joins, 0);
  });
  testWidgets('OAuth launch does not imply login; auth event restores board', (
    tester,
  ) async {
    final api = FakeLeague()..loggedIn = false;
    addTearDown(api.auth.close);
    await tester.pumpWidget(MaterialApp(home: LeagueScreen(gateway: api)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('league-google-sign-in')));
    await tester.pumpAndSettle();
    expect(api.googleLaunches, 1);
    expect(find.textContaining('Mya'), findsNothing);
    api.loggedIn = true;
    api.auth.add(true);
    await tester.pumpAndSettle();
    expect(find.textContaining('Mya'), findsOneWidget);
    api.loggedIn = false;
    api.auth.add(false);
    await tester.pumpAndSettle();
    expect(find.textContaining('Mya'), findsNothing);
    expect(find.text('Google နဲ့ ဝင်မယ်'), findsOneWidget);
  });
  testWidgets('failed Google launch can be retried', (tester) async {
    final api = FakeLeague()
      ..loggedIn = false
      ..launchSucceeds = false;
    addTearDown(api.auth.close);
    await tester.pumpWidget(MaterialApp(home: LeagueScreen(gateway: api)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('league-google-sign-in')));
    await tester.pumpAndSettle();
    expect(find.text('Google ဖွင့်မရသေးပါ။ ပြန်စမ်းပါ။'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('league-google-sign-in')));
    await tester.pumpAndSettle();
    expect(api.googleLaunches, 2);
  });
  testWidgets(
    'real board fits small large-text screen and respects daily cap',
    (tester) async {
      tester.view.physicalSize = const Size(320, 760);
      tester.view.devicePixelRatio = 1;
      tester.view.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.platformDispatcher.clearTextScaleFactorTestValue);
      final api = FakeLeague()..daily = 100;
      await tester.pumpWidget(MaterialApp(home: LeagueScreen(gateway: api)));
      await tester.pumpAndSettle();
      expect(find.text('ဒီအပတ် · 2 / 20 ယောက်'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('မနက်ဖြန် ပြန်လေ့ကျင့်မယ်'),
        200,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'မနက်ဖြန် ပြန်လေ့ကျင့်မယ်'),
            )
            .onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('join validates alias before sending profile', (tester) async {
    final api = FakeLeague()..joined = false;
    await tester.pumpWidget(MaterialApp(home: LeagueScreen(gateway: api)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ဒီနာမည်နဲ့ ပါဝင်မယ်'));
    await tester.pumpAndSettle();
    expect(api.joins, 0);
    expect(find.text('နာမည်ပြောင် အနည်းဆုံး ၂ လုံး ထည့်ပါ။'), findsOneWidget);
  });
  testWidgets(
    'only acknowledged score is shown and a failed submit can retry',
    (tester) async {
      final api = FakeLeague()..failSubmit = true;
      await tester.pumpWidget(
        MaterialApp(
          home: LeagueRoundScreen(gateway: api, round: await api.beginRound()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('+10 မှတ်'), findsNothing);
      await tester.tap(find.text('မင်္ဂလာပါ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ဆက်မယ်'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ကျေးဇူး'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('အမှတ်စစ်မယ်'));
      await tester.pumpAndSettle();
      expect(find.text('+10 မှတ်'), findsNothing);
      expect(find.textContaining('အမှတ်မသိမ်းရသေးပါ'), findsOneWidget);
      await tester.tap(find.text('အမှတ်စစ်မယ်'));
      await tester.pumpAndSettle();
      expect(find.text('+10 မှတ်'), findsOneWidget);
      expect(api.submissions, 2);
      expect(tester.takeException(), isNull);
    },
  );
}
