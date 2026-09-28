import 'package:flutter/material.dart';

import 'data/phrase_repository.dart';
import 'screens/main_shell.dart';
import 'services/app_state.dart';
import 'services/speech_service.dart';
import 'theme/app_theme.dart';

class ThaiForMyanmarApp extends StatelessWidget {
  const ThaiForMyanmarApp({
    required this.repository,
    required this.appState,
    required this.speechService,
    super.key,
  });

  final PhraseRepository repository;
  final AppState appState;
  final SpeechService speechService;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final mode = switch (appState.themePreference) {
          'light' => ThemeMode.light,
          'dark' => ThemeMode.dark,
          _ => ThemeMode.system,
        };
        return MaterialApp(
          title: 'Thai for Myanmar',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: mode,
          home: MainShell(
            repository: repository,
            appState: appState,
            speechService: speechService,
          ),
        );
      },
    );
  }
}
