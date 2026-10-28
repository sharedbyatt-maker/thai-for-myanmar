import 'dart:async';

import 'package:flutter/material.dart';

import '../services/app_state.dart';
import '../services/thai_playback_service.dart';

class PoliteStylePicker extends StatelessWidget {
  const PoliteStylePicker({
    required this.appState,
    required this.playbackService,
    super.key,
  });
  final AppState appState;
  final ThaiPlaybackService playbackService;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: appState,
    builder: (context, _) => Card(
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        leading: const Icon(Icons.voice_chat_outlined),
        title: const Text('ပြောသူရဲ့ ယဉ်ကျေးစကား'),
        subtitle: Text(
          appState.politeStyle == 'male'
              ? 'အမျိုးသား • ครับ'
              : 'အမျိုးသမီး • ค่ะ / คะ',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ကိုယ်ပြောမယ့်ပုံစံကို ရွေးပါ။ ထိုင်းစာနဲ့ နားထောင်မယ့်အသံ နှစ်ခုလုံး ပြောင်းပေးပါမယ်။',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final style in ['female', 'male'])
                ChoiceChip(
                  label: Text(
                    style == 'female'
                        ? 'အမျိုးသမီး (ค่ะ / คะ)'
                        : 'အမျိုးသား (ครับ)',
                  ),
                  selected: appState.politeStyle == style,
                  onSelected: (_) {
                    unawaited(playbackService.stop());
                    unawaited(appState.setPoliteStyle(style));
                  },
                ),
            ],
          ),
        ],
      ),
    ),
  );
}
