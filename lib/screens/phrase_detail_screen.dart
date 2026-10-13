import 'package:flutter/material.dart';

import '../data/phrase_repository.dart';
import '../learning/learning_progress.dart';
import '../models/phrase.dart';
import '../services/app_state.dart';
import '../services/thai_playback_service.dart';
import '../widgets/thai_playback_button.dart';
import 'phrase_issue_screen.dart';
import 'study_session_screen.dart';

class PhraseDetailScreen extends StatelessWidget {
  const PhraseDetailScreen({
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

  void _showToSpeaker(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog<void>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: SafeArea(
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
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  phrase.thaiFor(appState.politeStyle),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: 34,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  phrase.myanmar,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final category = repository.categoryFor(phrase.categoryId);
    final isEmergency = phrase.tags.contains('emergency');
    final isSensitive =
        phrase.tags.contains('high-risk') ||
        const {
          'health',
          'hospital',
          'pharmacy',
          'documents',
        }.any(phrase.tags.contains);
    return Scaffold(
      appBar: AppBar(
        title: Text(category?.my ?? 'စကားစု'),
        actions: [
          AnimatedBuilder(
            animation: appState,
            builder: (context, _) => IconButton(
              tooltip: appState.isFavorite(phrase.id)
                  ? 'အကြိုက်ဆုံးမှ ဖယ်ရန်'
                  : 'အကြိုက်ဆုံးသိမ်းရန်',
              onPressed: () => appState.toggleFavorite(phrase.id),
              icon: Icon(
                appState.isFavorite(phrase.id)
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          if (isEmergency)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: const Padding(
                padding: EdgeInsets.all(14),
                child: Text(
                  'အရေးပေါ်အကူအညီလိုပါက ဒေသခံအရေးပေါ်ဝန်ဆောင်မှုကို ချက်ချင်းဆက်သွယ်ပါ။ ဒီစကားစုကို ပြသပြီး အနီးအနားရှိသူထံ အကူအညီတောင်းနိုင်ပါတယ်။',
                ),
              ),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'မြန်မာလို ပြောချင်တာ',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    phrase.myanmar,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'အသံထွက်အနီးစပ်ဆုံး',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    phrase.pronunciation,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const Divider(height: 32),
                  Text(
                    'ထိုင်းစာ',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    phrase.thaiFor(appState.politeStyle),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    phrase.english,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (phrase.note != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      phrase.note!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isSensitive) ...[
            const SizedBox(height: 12),
            Text(
              'ကျန်းမာရေး၊ ဥပဒေ၊ အလုပ်စာချုပ်ဆိုင်ရာ အရေးကြီးကိစ္စတွေမှာ ဒီစကားစုကို ဆက်သွယ်ရေးအကူအညီအဖြစ်သာ သုံးပါ။ ကျွမ်းကျင်သူ သို့မဟုတ် စကားပြန်နဲ့ အချက်အလက်ကို အတည်ပြုပါ။',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 20),
          ThaiPlaybackButton(
            phrase: phrase,
            appState: appState,
            playbackService: playbackService,
            label: 'ထိုင်းအသံ နားထောင်ရန်',
          ),
          const SizedBox(height: 8),
          Text(
            'အသံထွက်စာက အနီးစပ်ဆုံး လမ်းညွှန်သာဖြစ်ပါတယ်။ အသံမရရင် ဆက်တင်က ထိုင်းအသံ စမ်းရန်ကို ဖွင့်ကြည့်ပါ။',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => StudySessionScreen(
                  repository: repository,
                  appState: appState,
                  playbackService: playbackService,
                  phrases: [phrase],
                  mode: LearningMode.flashcard,
                  title: 'ဒီစကားစုကို လေ့ကျင့်ရန်',
                ),
              ),
            ),
            icon: const Icon(Icons.school_outlined),
            label: const Text('ဒီစကားစုကို လေ့ကျင့်မယ်'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _showToSpeaker(context),
            icon: const Icon(Icons.open_in_full_rounded),
            label: const Text('ထိုင်းလူမျိုးကို ပြရန်'),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) =>
                    PhraseIssueScreen(phrase: phrase, appState: appState),
              ),
            ),
            icon: const Icon(Icons.report_outlined),
            label: const Text('ဒီစကားစုမှာ အမှားထောက်ပြရန်'),
          ),
        ],
      ),
    );
  }
}
