import 'dart:async';

import 'package:flutter/material.dart';

import '../data/phrase_repository.dart';
import '../widgets/content_frame.dart';
import '../services/app_state.dart';
import '../services/thai_playback_service.dart';
import 'learn_screen.dart';
import 'everyday_screen.dart';
import 'profile_screen.dart';
import 'quiz_screen.dart';
import 'search_screen.dart';

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

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  final Set<int> _visitedTabs = {0};
  static const _labels = ['သင်ယူ', 'အမြန်သုံး', 'ပြန်လေ့ကျင့်', 'ကိုယ်ပိုင်'];
  static const _icons = [
    Icons.route_rounded,
    Icons.record_voice_over_outlined,
    Icons.replay_rounded,
    Icons.person_outline_rounded,
  ];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      unawaited(widget.playbackService.stop());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(widget.playbackService.stop());
    super.dispose();
  }

  void _select(int i) {
    if (i != _selectedIndex) unawaited(widget.playbackService.stop());
    setState(() {
      _selectedIndex = i;
      _visitedTabs.add(i);
    });
  }

  void _search() {
    unawaited(widget.playbackService.stop());
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => SearchScreen(
          repository: widget.repository,
          appState: widget.appState,
          playbackService: widget.playbackService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      LearnScreen(
        repository: widget.repository,
        appState: widget.appState,
        playbackService: widget.playbackService,
      ),
      EverydayScreen(
        repository: widget.repository,
        appState: widget.appState,
        playbackService: widget.playbackService,
        onSearch: _search,
      ),
      QuizScreen(
        repository: widget.repository,
        appState: widget.appState,
        playbackService: widget.playbackService,
      ),
      ProfileScreen(
        repository: widget.repository,
        appState: widget.appState,
        playbackService: widget.playbackService,
      ),
    ];
    final wide =
        MediaQuery.sizeOf(context).width >= 1000 &&
        MediaQuery.textScalerOf(context).scale(14) <= 20;
    final content = ContentFrame(
      child: IndexedStack(
        index: _selectedIndex,
        children: List.generate(
          pages.length,
          (i) => _visitedTabs.contains(i) ? pages[i] : const SizedBox.shrink(),
        ),
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.translate_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Flexible(child: Text(_labels[_selectedIndex])),
          ],
        ),
        actions: [
          IconButton(
            key: const ValueKey('home-search'),
            tooltip: 'စကားစုရှာရန်',
            onPressed: _search,
            icon: const Icon(Icons.search_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: wide
            ? Row(
                children: [
                  NavigationRail(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: _select,
                    labelType: NavigationRailLabelType.all,
                    groupAlignment: -.7,
                    destinations: List.generate(
                      4,
                      (i) => NavigationRailDestination(
                        icon: Icon(_icons[i]),
                        label: Text(_labels[i]),
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: content),
                ],
              )
            : content,
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              labelBehavior:
                  NavigationDestinationLabelBehavior.onlyShowSelected,
              selectedIndex: _selectedIndex,
              onDestinationSelected: _select,
              destinations: List.generate(
                4,
                (i) => NavigationDestination(
                  icon: Icon(_icons[i]),
                  label: _labels[i],
                ),
              ),
            ),
    );
  }
}
