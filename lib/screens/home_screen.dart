import 'package:flutter/material.dart';

import '../data/phrase_repository.dart';
import '../models/phrase.dart';
import '../services/ad_slot.dart';
import '../services/app_state.dart';
import '../services/speech_service.dart';
import '../widgets/phrase_tile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.repository,
    required this.appState,
    required this.speechService,
    required this.onSelectTab,
    required this.onOpenPhrase,
    super.key,
  });

  final PhraseRepository repository;
  final AppState appState;
  final SpeechService speechService;
  final ValueChanged<int> onSelectTab;
  final ValueChanged<String> onOpenPhrase;

  @override
  Widget build(BuildContext context) {
    final daily = repository.phrases.firstWhere(
      (phrase) => phrase.id == 'question_slowly',
      orElse: () => repository.phrases.first,
    );
    final popular = repository.categories
        .where((category) => category.kind != 'learn')
        .take(4)
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      children: [
        Text(
          'ထိုင်းမှာ နေ့တိုင်းသုံးနိုင်တဲ့စကား',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(
          'မြန်မာလိုနားလည်၊ ထိုင်းလိုလက်တွေ့ပြောပါ။',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.record_voice_over_rounded,
                title: 'အမြန်ပြော',
                subtitle: 'စကားစုရှу',
                onTap: () => onSelectTab(3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                icon: Icons.menu_book_rounded,
                title: 'ဆက်လေ့လာ',
                subtitle: '${appState.learned.length} ခု ကြည့်ပြီး',
                onTap: () => onSelectTab(1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
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
          speechService: speechService,
        ),
        const SizedBox(height: 18),
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
              onPressed: () => onSelectTab(2),
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
                  Icon(Icons.auto_stories_rounded,
                      color: Theme.of(context).colorScheme.primary, size: 30),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('သင်ယူမှုမှတ်တမ်း',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 3),
                        Text('${appState.learned.length} / ${repository.phrases.length} စကားစု ကြည့်ပြီး'),
                      ],
                    ),
                  ),
                  Text('${(100 * appState.learned.length / repository.phrases.length).round()}%',
                      style: Theme.of(context).textTheme.titleLarge),
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
                  Text('မကြာသေးခင်က ဖွင့်ထားတာ',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 9),
                  PhraseTile(
                    phrase: recentPhrase,
                    repository: repository,
                    appState: appState,
                    speechService: speechService,
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
      color: Theme.of(context).colorScheme.secondaryContainer,
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
        TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}
