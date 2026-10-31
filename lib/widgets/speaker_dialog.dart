import 'package:flutter/material.dart';

import '../models/phrase.dart';
import '../services/app_state.dart';
import '../services/thai_playback_service.dart';
import 'thai_playback_button.dart';

/// Keeps long translations and playback reachable on short or large-text screens.
class SpeakerDialog extends StatelessWidget {
  const SpeakerDialog({
    required this.phrase,
    required this.appState,
    required this.playbackService,
    super.key,
  });

  final Phrase phrase;
  final AppState appState;
  final ThaiPlaybackService playbackService;

  @override
  Widget build(BuildContext context) => Dialog.fullscreen(
    child: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton.filledTonal(
                        tooltip: 'ပိတ်ရန်',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.translate_rounded,
                      size: 40,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      phrase.thaiFor(appState.politeStyle),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontSize: 34, height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      phrase.myanmar,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    const SizedBox(height: 24),
                    ThaiPlaybackButton(
                      phrase: phrase,
                      appState: appState,
                      playbackService: playbackService,
                      label: 'ထိုင်းအသံ နားထောင်ရန်',
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
