import 'package:flutter/material.dart';

import '../data/phrase_repository.dart';
import '../services/app_state.dart';
import '../services/thai_playback_service.dart';
import 'phrase_browser_screen.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({
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
    return PhraseBrowserScreen(
      repository: repository,
      appState: appState,
      playbackService: playbackService,
      title: 'စကားစုရှာရန်',
    );
  }
}
