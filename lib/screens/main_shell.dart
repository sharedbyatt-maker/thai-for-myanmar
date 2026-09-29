import 'dart:async';

import 'package:flutter/material.dart';

import '../data/phrase_repository.dart';
import '../services/app_state.dart';
import '../services/thai_playback_service.dart';
import 'favorites_screen.dart';
import 'home_screen.dart';
import 'learn_screen.dart';
import 'phrase_detail_screen.dart';
import 'quick_speak_screen.dart';
import 'quiz_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'situations_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    required this.repository,
    required this.appState,
    required this.playbackService,
    super.key,
  });

  final PhraseRepository repository;
  final AppState appState;
  final ThaiPlaybackService playbackService;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  final Set<int> _visitedTabs = <int>{0};

  static const _titles = <String>[
    'ထိုင်းစကား လက်တွေ့သုံး',
    'သင်ခန်းစာများ',
    'အခြေအနေအလိုက်',
    'အမြန်ပြောရန်',
    'လေ့ကျင့်ခန်း',
  ];

  void _selectTab(int index) {
    if (index != _selectedIndex) unawaited(widget.playbackService.stop());
    setState(() {
      _selectedIndex = index;
      _visitedTabs.add(index);
    });
  }

  void _openPhrase(String phraseId) {
    final matching = widget.repository.phrases.where(
      (item) => item.id == phraseId,
    );
    final phrase = matching.isEmpty ? null : matching.first;
    if (phrase == null) return;
    unawaited(widget.playbackService.stop());
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PhraseDetailScreen(
          phrase: phrase,
          repository: widget.repository,
          appState: widget.appState,
          playbackService: widget.playbackService,
        ),
      ),
    );
  }

  void _openSearch() {
    unawaited(widget.playbackService.stop());
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SearchScreen(
          repository: widget.repository,
          appState: widget.appState,
          playbackService: widget.playbackService,
        ),
      ),
    );
  }

  void _openFavorites() {
    unawaited(widget.playbackService.stop());
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FavoritesScreen(
          repository: widget.repository,
          appState: widget.appState,
          playbackService: widget.playbackService,
        ),
      ),
    );
  }

  void _openSettings() {
    unawaited(widget.playbackService.stop());
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(appState: widget.appState),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(
        repository: widget.repository,
        appState: widget.appState,
        playbackService: widget.playbackService,
        onSelectTab: _selectTab,
        onOpenPhrase: _openPhrase,
      ),
      LearnScreen(
        repository: widget.repository,
        appState: widget.appState,
        playbackService: widget.playbackService,
      ),
      SituationsScreen(
        repository: widget.repository,
        appState: widget.appState,
        playbackService: widget.playbackService,
      ),
      QuickSpeakScreen(
        repository: widget.repository,
        appState: widget.appState,
        playbackService: widget.playbackService,
      ),
      QuizScreen(repository: widget.repository, appState: widget.appState),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          IconButton(
            tooltip: 'စကားစုရှာရန်',
            onPressed: _openSearch,
            icon: const Icon(Icons.search_rounded),
          ),
          IconButton(
            tooltip: 'သိမ်းထားသော စကားစုများ',
            onPressed: _openFavorites,
            icon: const Icon(Icons.favorite_border_rounded),
          ),
          IconButton(
            tooltip: 'ဆက်တင်များ',
            onPressed: _openSettings,
            icon: const Icon(Icons.tune_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: IndexedStack(
              index: _selectedIndex,
              children: List<Widget>.generate(
                pages.length,
                (index) => _visitedTabs.contains(index)
                    ? pages[index]
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'ပင်မ',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: 'လေ့လာ',
          ),
          NavigationDestination(
            icon: Icon(Icons.place_outlined),
            selectedIcon: Icon(Icons.place_rounded),
            label: 'အခြေအနေ',
          ),
          NavigationDestination(
            icon: Icon(Icons.record_voice_over_outlined),
            selectedIcon: Icon(Icons.record_voice_over_rounded),
            label: 'အမြန်ပြော',
          ),
          NavigationDestination(
            icon: Icon(Icons.quiz_outlined),
            selectedIcon: Icon(Icons.quiz_rounded),
            label: 'လေ့ကျင့်',
          ),
        ],
      ),
    );
  }
}
