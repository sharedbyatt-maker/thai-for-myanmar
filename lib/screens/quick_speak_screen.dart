import 'package:flutter/material.dart';

import '../data/phrase_repository.dart';
import '../models/phrase.dart';
import '../services/app_state.dart';
import '../services/speech_service.dart';

class QuickSpeakScreen extends StatefulWidget {
  const QuickSpeakScreen({
    required this.repository,
    required this.appState,
    required this.speechService,
    super.key,
  });

  final PhraseRepository repository;
  final AppState appState;
  final SpeechService speechService;

  @override
  State<QuickSpeakScreen> createState() => _QuickSpeakScreenState();
}

class _QuickSpeakScreenState extends State<QuickSpeakScreen> {
  final _controller = TextEditingController();
  String _query = '';
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    final emergency = widget.repository.inCategory('emergency');
    _selectedId = emergency.isEmpty ? null : emergency.first.id;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Phrase? get _selectedPhrase {
    for (final phrase in widget.repository.phrases) {
      if (phrase.id == _selectedId) return phrase;
    }
    return null;
  }

  void _select(Phrase phrase) {
    FocusManager.instance.primaryFocus?.unfocus();
    _controller.clear();
    setState(() {
      _query = '';
      _selectedId = phrase.id;
    });
    widget.appState.remember(phrase.id);
    widget.appState.markLearned(phrase.id);
  }

  Future<void> _speak(Phrase phrase) async {
    final result = await widget.speechService.speakThai(
      phrase.thaiFor(widget.appState.politeStyle),
    );
    if (result == SpeechResult.unavailable && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ဒီစက်မှာ အသုံးပြုနိုင်တဲ့ ထိုင်းအသံမရှိပါ။ စကားစုကို ထိုင်းစကားပြောသူထံ ပြပေးပါ။'),
        ),
      );
    }
  }

  void _showToSpeaker(Phrase phrase) {
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
                  size: 42,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 26),
                Text(
                  phrase.thaiFor(widget.appState.politeStyle),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: 34,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  phrase.myanmar,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => _speak(phrase),
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
    final results = widget.repository.search(_query).take(12).toList();
    final emergency = widget.repository.inCategory('emergency');
    final selected = _selectedPhrase;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      children: [
        Text(
          'ပြချင်တဲ့ အဓိပ္ပာယ်ကို ရှာပါ',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 5),
        const Text(
          'ထိုင်းစာကြောင်းကို အသံဖတ်ပြနိုင်သလို ထိုင်းစကားပြောသူကိုလည်း ပြနိုင်ပါတယ်။',
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _controller,
          onChanged: (value) => setState(() => _query = value),
          decoration: InputDecoration(
            hintText: 'ဥပမာ - ဗိုက်နာ၊ လစာ၊ ဆေးရုံ',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'ဖျက်ရန်',
                    onPressed: () {
                      _controller.clear();
                      setState(() => _query = '');
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        ),
        const SizedBox(height: 14),
        if (selected != null && _query.trim().isEmpty)
          _PhraseBoard(
            phrase: selected,
            appState: widget.appState,
            onSpeak: () => _speak(selected),
            onShow: () => _showToSpeaker(selected),
          ),
        if (_query.trim().isEmpty) ...[
          const SizedBox(height: 18),
          Text(
            'အရေးပေါ်စကားစု',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...emergency.map(
            (phrase) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _PhraseChoice(
                phrase: phrase,
                selected: phrase.id == _selectedId,
                appState: widget.appState,
                onTap: () => _select(phrase),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'လူသုံးများတဲ့ စကားစု',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...widget.repository.phrases
              .where(
                (phrase) => const {
                  'question_slowly',
                  'food_not_spicy',
                  'money_price',
                  'health_stomach',
                }.contains(phrase.id),
              )
              .map(
                (phrase) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _PhraseChoice(
                    phrase: phrase,
                    selected: phrase.id == _selectedId,
                    appState: widget.appState,
                    onTap: () => _select(phrase),
                  ),
                ),
              ),
        ] else ...[
          const SizedBox(height: 8),
          Text(
            '${results.length} ခုတွေ့သည်',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          if (results.isEmpty)
            const Padding(
              padding: EdgeInsets.all(18),
              child: Text('မတွေ့ပါ။ အခြားစကားလုံးနဲ့ ရှာကြည့်ပါ။'),
            ),
          ...results.map(
            (phrase) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _PhraseChoice(
                phrase: phrase,
                selected: phrase.id == _selectedId,
                appState: widget.appState,
                onTap: () => _select(phrase),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PhraseBoard extends StatelessWidget {
  const _PhraseBoard({
    required this.phrase,
    required this.appState,
    required this.onSpeak,
    required this.onShow,
  });

  final Phrase phrase;
  final AppState appState;
  final VoidCallback onSpeak;
  final VoidCallback onShow;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'ပြရန် အသင့်',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                AnimatedBuilder(
                  animation: appState,
                  builder: (context, _) => IconButton(
                    tooltip: appState.isFavorite(phrase.id)
                        ? 'သိမ်းထားမှု ဖြုတ်ရန်'
                        : 'အကြိုက်ဆုံးအဖြစ် သိမ်းရန်',
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
            const SizedBox(height: 8),
            Semantics(
              label: 'ထိုင်းစာကြောင်း: ${phrase.thaiFor(appState.politeStyle)}',
              child: Text(
                phrase.thaiFor(appState.politeStyle),
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(fontSize: 28, height: 1.5),
              ),
            ),
            const SizedBox(height: 9),
            Text(
              phrase.myanmar,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 5),
            Text(
              'အသံထွက် - ${phrase.pronunciation}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (phrase.tags.contains('high-risk')) ...[
              const SizedBox(height: 8),
              Text(
                'အရေးကြီးကိစ္စတွင် ကျွမ်းကျင်သူ သို့မဟုတ် စကားပြန်နဲ့ အချက်အလက်ကို အတည်ပြုပါ။',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 9,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: onSpeak,
                  icon: const Icon(Icons.volume_up_rounded),
                  label: const Text('အသံထွက်'),
                ),
                OutlinedButton.icon(
                  onPressed: onShow,
                  icon: const Icon(Icons.open_in_full_rounded),
                  label: const Text('ထိုင်းလူမျိုးကို ပြရန်'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PhraseChoice extends StatelessWidget {
  const _PhraseChoice({
    required this.phrase,
    required this.selected,
    required this.appState,
    required this.onTap,
  });

  final Phrase phrase;
  final bool selected;
  final AppState appState;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: selected ? Theme.of(context).colorScheme.secondaryContainer : null,
      child: ListTile(
        onTap: onTap,
        title: Text(
          phrase.thaiFor(appState.politeStyle),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          phrase.myanmar,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: selected ? const Icon(Icons.check_circle_rounded) : null,
      ),
    );
  }
}
