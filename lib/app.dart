import 'package:flutter/material.dart';

import 'data/phrase_repository.dart';
import 'screens/main_shell.dart';
import 'services/app_state.dart';
import 'services/thai_playback_service.dart';
import 'theme/app_theme.dart';

class ThaiForMyanmarApp extends StatelessWidget {
  const ThaiForMyanmarApp({
    required this.repository,
    required this.appState,
    required this.playbackService,
    super.key,
  });

  final PhraseRepository repository;
  final AppState appState;
  final ThaiPlaybackService playbackService;

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
            playbackService: playbackService,
          ),
        );
      },
    );
  }
}
