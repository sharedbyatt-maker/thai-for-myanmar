import 'package:flutter/material.dart';

import 'thai_playback_button.dart';

import '../data/phrase_repository.dart';
import '../models/phrase.dart';
import '../services/app_state.dart';
import '../services/thai_playback_service.dart';
import '../screens/phrase_detail_screen.dart';

class PhraseTile extends StatelessWidget {
  const PhraseTile({
    required this.phrase,
    required this.repository,
    required this.appState,
    required this.playbackService,
    super.key,
  });

  final Phrase phrase;
  final PhraseRepository repository;
  final AppState appState;
  final ThaiPlaybackService playbackService;

  void _open(BuildContext context) {
    appState.remember(phrase.id);
    appState.markLearned(phrase.id);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PhraseDetailScreen(
          phrase: phrase,
          repository: repository,
          appState: appState,
          playbackService: playbackService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) => Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  button: true,
                  label:
                      '${phrase.myanmar}. ${phrase.thaiFor(appState.politeStyle)}. အသေးစိတ်ကြည့်ရန်',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _open(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            phrase.myanmar,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            phrase.thaiFor(appState.politeStyle),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: colors.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ThaiPlaybackButton(
                    phrase: phrase,
                    appState: appState,
                    playbackService: playbackService,
                    label: 'ထိုင်းအသံ နားထောင်ရန်',
                    compact: true,
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
            ],
          ),
        ),
      ),
    );
  }
}
