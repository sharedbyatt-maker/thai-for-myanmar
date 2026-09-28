import 'package:flutter/material.dart';

import '../data/phrase_repository.dart';
import '../services/app_state.dart';
import '../services/speech_service.dart';
import 'phrase_browser_screen.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({
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
    return PhraseBrowserScreen(
      repository: repository,
      appState: appState,
      speechService: speechService,
      title: 'စကားစုရှာရန်',
    );
  }
}
