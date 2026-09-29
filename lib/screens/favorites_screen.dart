import 'package:flutter/material.dart';

import '../data/phrase_repository.dart';
import '../services/app_state.dart';
import '../services/thai_playback_service.dart';
import '../widgets/phrase_tile.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({
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
    return Scaffold(
      appBar: AppBar(title: const Text('သိမ်းထားသော စကားစုများ')),
      body: AnimatedBuilder(
        animation: appState,
        builder: (context, _) {
          final phrases = repository.phrases
              .where((phrase) => appState.isFavorite(phrase.id))
              .toList();
          if (phrases.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.favorite_border_rounded,
                      size: 46,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'သိမ်းထားတာ မရှိသေးပါဘူး။',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'စကားစုဘေးက နှလုံးပုံကိုနှိပ်ပြီး သိမ်းထားနိုင်ပါတယ်။',
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: phrases.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) => PhraseTile(
              phrase: phrases[index],
              repository: repository,
              appState: appState,
              playbackService: playbackService,
            ),
          );
        },
      ),
    );
  }
}
