import 'package:flutter/material.dart';

import '../data/phrase_repository.dart';
import '../models/phrase.dart';
import '../services/app_state.dart';
import '../services/speech_service.dart';
import '../screens/phrase_detail_screen.dart';

class PhraseTile extends StatelessWidget {
  const PhraseTile({
    required this.phrase,
    required this.repository,
    required this.appState,
    required this.speechService,
    super.key,
  });

  final Phrase phrase;
  final PhraseRepository repository;
  final AppState appState;
  final SpeechService speechService;

  void _open(BuildContext context) {
    appState.remember(phrase.id);
    appState.markLearned(phrase.id);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PhraseDetailScreen(
          phrase: phrase,
          repository: repository,
          appState: appState,
          speechService: speechService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final category = repository.categoryFor(phrase.categoryId);
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                button: true,
                label: '${phrase.thai}. ${phrase.myanmar}',
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _open(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (category != null)
                          Text(
                            category.my,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: colors.primary),
                          ),
                        const SizedBox(height: 3),
                        Text(
                          phrase.thai,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          phrase.myanmar,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: appState,
              builder: (context, _) {
                final favorite = appState.isFavorite(phrase.id);
                return IconButton(
                  tooltip: favorite
                      ? 'သိမ်းထားမှု ဖြုတ်ရန်'
                      : 'အကြိုက်ဆုံးအဖြစ် သိမ်းရန်',
                  onPressed: () => appState.toggleFavorite(phrase.id),
                  icon: Icon(
                    favorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: favorite ? colors.error : null,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
