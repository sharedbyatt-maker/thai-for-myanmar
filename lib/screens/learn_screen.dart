import 'package:flutter/material.dart';

import '../data/phrase_repository.dart';
import '../services/app_state.dart';
import '../services/thai_playback_service.dart';
import 'phrase_browser_screen.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({
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
    final categories = repository.categories
        .where((category) => category.kind != 'situation')
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      children: [
        Text(
          'သင်ချင်တဲ့အကြောင်းအရာကို ရွေးပါ',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 5),
        const Text('နှုတ်ဆက်စကားကနေ နေ့စဉ်အသုံးအနှုန်းအထိ။'),
        const SizedBox(height: 14),
        ...categories.map(
          (category) => Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Card(
              child: ListTile(
                minVerticalPadding: 12,
                leading: Text(
                  category.icon,
                  style: const TextStyle(fontSize: 26),
                ),
                title: Text(
                  category.my,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Text(category.th),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PhraseBrowserScreen(
                      repository: repository,
                      appState: appState,
                      playbackService: playbackService,
                      title: category.my,
                      categoryId: category.id,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
