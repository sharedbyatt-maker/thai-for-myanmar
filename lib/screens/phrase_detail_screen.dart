import 'package:flutter/material.dart';

import '../data/phrase_repository.dart';
import '../models/phrase.dart';
import '../services/app_state.dart';
import '../services/speech_service.dart';

class PhraseDetailScreen extends StatelessWidget {
  const PhraseDetailScreen({
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

  Future<void> _speak(BuildContext context) async {
    final result = await speechService.speakThai(
      phrase.thaiFor(appState.politeStyle),
    );
    if (result == SpeechResult.unavailable && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ဒီစက်မှာ ထိုင်းအသံဖတ်စနစ် မရနိုင်သေးပါ။')),
      );
    }
  }

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
                Icon(Icons.translate_rounded,
                    size: 40, color: colorScheme.primary),
                const SizedBox(height: 24),
                Text(
                  phrase.thaiFor(appState.politeStyle),
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontSize: 34, height: 1.55),
                ),
                const SizedBox(height: 20),
                Text(
                  phrase.myanmar,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => _speak(context),
                  icon: const Icon(Icons.volume_up_rounded),
                  label: const Text('ထိုင်းအသံ နားထောင်ရန်'),
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
    final isSensitive = phrase.tags.contains('high-risk') ||
        const {'health', 'hospital', 'pharmacy', 'documents'}
            .any(phrase.tags.contains);
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
                    phrase.thaiFor(appState.politeStyle),
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontSize: 30),
                  ),
                  const SizedBox(height: 18),
                  Text('မြန်မာလို',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 6),
                  Text(phrase.myanmar,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 18),
                  Text('အသံထွက်အနီးစပ်ဆုံး',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 6),
                  Text(phrase.pronunciation,
                      style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 18),
                  Text(phrase.english,
                      style: Theme.of(context).textTheme.bodyMedium),
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
          FilledButton.icon(
            onPressed: () => _speak(context),
            icon: const Icon(Icons.volume_up_rounded),
            label: const Text('ထိုင်းအသံ နားထောင်ရန်'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _showToSpeaker(context),
            icon: const Icon(Icons.open_in_full_rounded),
            label: const Text('ထိုင်းလူမျိုးကို ပြရန်'),
          ),
        ],
      ),
    );
  }
}
