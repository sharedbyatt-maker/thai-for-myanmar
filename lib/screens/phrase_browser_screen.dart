import 'package:flutter/material.dart';

import '../data/phrase_repository.dart';
import '../services/app_state.dart';
import '../services/speech_service.dart';
import '../widgets/phrase_tile.dart';

class PhraseBrowserScreen extends StatefulWidget {
  const PhraseBrowserScreen({
    required this.repository,
    required this.appState,
    required this.speechService,
    required this.title,
    this.categoryId,
    super.key,
  });

  final PhraseRepository repository;
  final AppState appState;
  final SpeechService speechService;
  final String title;
  final String? categoryId;

  @override
  State<PhraseBrowserScreen> createState() => _PhraseBrowserScreenState();
}

class _PhraseBrowserScreenState extends State<PhraseBrowserScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phrases = widget.repository.search(
      _query,
      categoryId: widget.categoryId,
    );
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'မြန်မာ၊ ထိုင်း၊ အင်္ဂလိပ်လို ရှာရန်',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'ဖျက်ရန်',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
          ),
          Expanded(
            child: phrases.isEmpty
                ? const _EmptySearch()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: phrases.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) => PhraseTile(
                      phrase: phrases[index],
                      repository: widget.repository,
                      appState: widget.appState,
                      speechService: widget.speechService,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 44, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text('ဒီစကားစုကို မတွေ့ပါဘူး။',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 5),
            const Text('အခြားစကားလုံးနဲ့ ထပ်ရှာကြည့်ပါ။',
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
