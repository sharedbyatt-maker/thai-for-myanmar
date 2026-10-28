import 'package:flutter/material.dart';

import '../data/phrase_repository.dart';
import '../learning/learning_progress.dart';
import '../learning/study_catalog.dart';
import '../models/phrase.dart';
import '../services/ad_slot.dart';
import '../services/app_state.dart';
import '../services/thai_playback_service.dart';
import '../widgets/phrase_tile.dart';
import '../widgets/learning_dashboard.dart';
import '../widgets/polite_style_picker.dart';
import 'phrase_browser_screen.dart';
import 'study_session_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.repository,
    required this.appState,
    required this.playbackService,
    required this.onSelectTab,
    required this.onOpenPhrase,
    required this.onOpenProgress,
    required this.onSearch,
    required this.onFavorites,
    super.key,
  });

  final PhraseRepository repository;
  final AppState appState;
  final ThaiPlaybackService playbackService;
  final ValueChanged<int> onSelectTab;
  final ValueChanged<String> onOpenPhrase;
  final VoidCallback onOpenProgress;
  final VoidCallback onSearch;
  final VoidCallback onFavorites;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayIndex = DateTime.utc(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime.utc(2026)).inDays;
    final everyday = repository.phrases
        .where((p) => !p.tags.contains('high-risk'))
        .toList();
    final daily = everyday[dayIndex % everyday.length];
    final popular = repository.categories
        .where((category) => category.kind != 'learn')
        .take(4)
        .toList();
    void openToday() {
      final plan = StudyCatalog.todayPlan(
        repository,
        appState.learning,
        DateTime.now(),
      );
      if (plan.phrases.isEmpty) return;
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => StudySessionScreen(
            repository: repository,
            appState: appState,
            playbackService: playbackService,
            phrases: plan.phrases,
            mode: LearningMode.flashcard,
            title: 'ဒီနေ့ ၅ ခု',
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'THAI FOR MYANMAR',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'နေ့တိုင်းသုံးဖို့၊\nယုံကြည်မှုရှိရှိ ပြောဖို့',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'စကားစုရှာ၊ အသံနားထောင်၊ နည်းနည်းစီ လေ့ကျင့်ပါ။',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),
              Semantics(
                button: true,
                child: Material(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    key: const ValueKey('home-search'),
                    borderRadius: BorderRadius.circular(14),
                    onTap: onSearch,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'ဘာပြောချင်လဲ? ရှာကြည့်ပါ',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                          const Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide =
                constraints.maxWidth >= 360 &&
                MediaQuery.textScalerOf(context).scale(14) < 20;
            final actions = [
              _ActionCard(
                icon: Icons.record_voice_over_rounded,
                title: 'အမြန်ပြော',
                subtitle: 'ထိုင်းလို ပြပြီး နားထောင်ပါ',
                onTap: () => onSelectTab(3),
              ),
              _ActionCard(
                icon: Icons.favorite_border_rounded,
                title: 'သိမ်းထားတာ',
                subtitle: 'လိုတဲ့စကား ပြန်ရှာပါ',
                onTap: onFavorites,
              ),
            ];
            return wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: actions[0]),
                      const SizedBox(width: 12),
                      Expanded(child: actions[1]),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      actions[0],
                      const SizedBox(height: 10),
                      actions[1],
                    ],
                  );
          },
        ),
        const SizedBox(height: 16),
        PoliteStylePicker(appState: appState, playbackService: playbackService),
        const SizedBox(height: 24),
        _SectionTitle(
          title: 'ဒီနေ့သုံးကြည့်ပါ',
          actionLabel: 'အသေးစိတ်',
          onAction: () => onOpenPhrase(daily.id),
        ),
        const SizedBox(height: 10),
        PhraseTile(
          phrase: daily,
          repository: repository,
          appState: appState,
          playbackService: playbackService,
        ),
        const SizedBox(height: 24),
        LearningDashboard(
          appState: appState,
          plan: StudyCatalog.todayPlan(repository, appState.learning, now),
          onPractice: openToday,
          onProgress: onOpenProgress,
        ),
        const SizedBox(height: 16),
        AnimatedBuilder(
          animation: appState,
          builder: (context, _) => appState.learning.onboardingComplete
              ? const SizedBox.shrink()
              : Card(
                  child: ExpansionTile(
                    title: const Text('စလေ့လာမယ့်သူအတွက်'),
                    leading: const Icon(Icons.lightbulb_outline_rounded),
                    childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                    children: [
                      const Text(
                        '၁။ လေ့လာမှာ ၅ စကားစုစီ သင်ပါ။\n၂။ လေ့ကျင့်မှာ မှတ်မိသလား စမ်းပါ။\n၃။ မှားတဲ့စကားစုကို နောက်နေ့ ပြန်လေ့ကျင့်ပါ။',
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () {
                          appState.completeOnboarding();
                          onSelectTab(1);
                        },
                        child: const Text('စလေ့လာမယ်'),
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 24),
        _SectionTitle(
          title: 'လူသုံးများတဲ့ အခြေအနေများ',
          actionLabel: 'အားလုံးကြည့်ရန်',
          onAction: () => onSelectTab(2),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: popular.map((category) {
            return ActionChip(
              avatar: Text(category.icon),
              label: Text(category.my),
              onPressed: () => Navigator.push(
                context,
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
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        AnimatedBuilder(
          animation: appState,
          builder: (context, _) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_stories_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 30,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'သင်ယူမှုမှတ်တမ်း',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${appState.learned.length} / ${repository.phrases.length} စကားစု ကြည့်ပြီး',
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${(100 * appState.learned.length / repository.phrases.length).round()}%',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedBuilder(
          animation: appState,
          builder: (context, _) {
            Phrase? recentPhrase;
            for (final id in appState.recent) {
              for (final phrase in repository.phrases) {
                if (phrase.id == id) {
                  recentPhrase = phrase;
                  break;
                }
              }
              if (recentPhrase != null) break;
            }
            if (recentPhrase == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'မကြာသေးခင်က ဖွင့်ထားတာ',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 9),
                  PhraseTile(
                    phrase: recentPhrase,
                    repository: repository,
                    appState: appState,
                    playbackService: playbackService,
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        const AdBannerSlot(),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 26),
              const SizedBox(height: 10),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        Flexible(
          child: TextButton(
            onPressed: onAction,
            child: Text(actionLabel, textAlign: TextAlign.end),
          ),
        ),
      ],
    );
  }
}
