import 'package:flutter/material.dart';

import '../data/phrase_repository.dart';
import '../services/app_state.dart';
import '../services/thai_playback_service.dart';
import '../widgets/playful_components.dart';
import 'favorites_screen.dart';
import 'learning_progress_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    required this.repository,
    required this.appState,
    required this.playbackService,
    super.key,
  });
  final PhraseRepository repository;
  final AppState appState;
  final ThaiPlaybackService playbackService;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: appState,
    builder: (context, _) {
      void open(Widget page) => Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => page),
      );
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Center(child: ElephantBuddy(size: 120)),
          const SizedBox(height: 12),
          Text(
            'နေ့တိုင်း နည်းနည်း ပိုတတ်လာပြီ',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          Center(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                MetricPill(
                  icon: Icons.local_fire_department,
                  label: '${appState.learning.streak(DateTime.now())} ရက်ဆက်',
                ),
                MetricPill(
                  icon: Icons.check_circle,
                  label: '${appState.learning.totalReviews} ကြိမ် လေ့ကျင့်ပြီး',
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.favorite_rounded),
                  title: const Text('သိမ်းထားတာ'),
                  trailing: Text('${appState.favorites.length}'),
                  onTap: () => open(
                    FavoritesScreen(
                      repository: repository,
                      appState: appState,
                      playbackService: playbackService,
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.insights_rounded),
                  title: const Text('သင်ယူမှုမှတ်တမ်း'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => open(
                    LearningProgressScreen(
                      repository: repository,
                      appState: appState,
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.tune_rounded),
                  title: const Text('ဆက်တင်များ'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => open(
                    SettingsScreen(
                      repository: repository,
                      appState: appState,
                      playbackService: playbackService,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'အကောင့်မလိုပါ။ တိုးတက်မှုကို ဒီစက်မှာ သိမ်းထားပါတယ်။',
            textAlign: TextAlign.center,
          ),
        ],
      );
    },
  );
}
