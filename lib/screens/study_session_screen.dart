import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../data/phrase_repository.dart';
import '../learning/learning_progress.dart';
import '../learning/sentence_chunks.dart';
import '../models/phrase.dart';
import '../quiz/quiz_logic.dart';
import '../services/app_state.dart';
import '../services/thai_playback_service.dart';
import '../widgets/thai_playback_button.dart';

class StudySessionScreen extends StatefulWidget {
  const StudySessionScreen({
    required this.repository,
    required this.appState,
    required this.playbackService,
    required this.phrases,
    required this.mode,
    required this.title,
    this.lessonId,
    super.key,
  });
  final PhraseRepository repository;
  final AppState appState;
  final ThaiPlaybackService playbackService;
  final List<Phrase> phrases;
  final LearningMode mode;
  final String title;
  final String? lessonId;

  @override
  State<StudySessionScreen> createState() => _StudySessionScreenState();
}

class _StudySessionScreenState extends State<StudySessionScreen> {
  int _index = 0;
  bool _revealed = false;
  bool _answered = false;
  bool _finished = false;
  bool _heard = false;
  bool _audioBusy = false;
  bool _audioUnavailable = false;
  bool _showPronunciation = true;
  String? _selectedAnswer;
  final Map<String, int> _results = {};
  final List<int> _selectedChunks = [];
  List<int> _chunkOrder = [];
  List<Phrase> _options = [];
  int _mistakes = 0;
  String? _sentenceFeedback;
  late final String _politeStyle;
  final Set<String> _matched = {};
  final Map<String, int> _matchMistakes = {};
  String? _leftSelection;
  String? _rightSelection;
  late final List<Phrase> _rightOrder;

  Phrase get _phrase => widget.phrases[_index];

  @override
  void initState() {
    super.initState();
    _politeStyle = widget.appState.politeStyle;
    _rightOrder = List<Phrase>.from(widget.phrases)..shuffle();
    if (widget.phrases.isNotEmpty) _prepareQuestion();
  }

  void _prepareQuestion() {
    final candidates =
        widget.repository.phrases
            .where((item) => item.id != _phrase.id)
            .toList()
          ..shuffle();
    String label(Phrase phrase) => widget.mode == LearningMode.reverseMeaning
        ? phrase.thaiFor(_politeStyle)
        : phrase.myanmar;
    final seen = <String>{label(_phrase)};
    final distractors = candidates
        .where((item) => seen.add(label(item)))
        .take(3);
    _options = [_phrase, ...distractors]..shuffle();
    final chunks = sentenceChunks(_phrase, _politeStyle) ?? [];
    _chunkOrder = List<int>.generate(chunks.length, (index) => index)
      ..shuffle();
    _selectedChunks.clear();
    _revealed = false;
    _answered = false;
    _heard = false;
    _audioBusy = false;
    _audioUnavailable = false;
    _selectedAnswer = null;
    _mistakes = 0;
    _sentenceFeedback = null;
  }

  @override
  void dispose() {
    unawaited(widget.playbackService.stop());
    super.dispose();
  }

  void _record(Phrase phrase, int quality) {
    if (_results.containsKey(phrase.id)) return;
    _results[phrase.id] = quality;
    unawaited(widget.appState.recordReview(phrase.id, widget.mode, quality));
  }

  void _next() {
    if (_finished || !_answered) return;
    unawaited(widget.playbackService.stop());
    if (_index + 1 == widget.phrases.length) {
      _finish();
    } else {
      setState(() {
        _index++;
        _prepareQuestion();
      });
    }
  }

  void _rateFlashcard(int quality) {
    if (_finished || !_revealed) return;
    _revealed = false;
    _answered = true;
    _record(_phrase, quality);
    _next();
  }

  void _finish() {
    if (_finished) return;
    setState(() => _finished = true);
    unawaited(widget.playbackService.stop());
    unawaited(widget.appState.finishStudySession(lessonId: widget.lessonId));
    if (widget.mode == LearningMode.meaning ||
        widget.mode == LearningMode.reverseMeaning ||
        widget.mode == LearningMode.listening) {
      unawaited(widget.appState.recordQuizCompletion());
    }
  }

  Future<void> _listen() async {
    if (_finished || widget.phrases.isEmpty) return;
    if (widget.appState.audioVolume == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ဆက်တင်မှာ ထိုင်းအသံ အတိုးအကျယ်ကို မြှင့်ပြီးမှ စမ်းပါ။',
          ),
        ),
      );
      return;
    }
    if (_audioBusy) {
      await widget.playbackService.stop();
      return;
    }
    final phrase = _phrase;
    final phraseId = phrase.id;
    setState(() {
      _audioBusy = true;
      _audioUnavailable = false;
    });
    await widget.playbackService.setVolume(widget.appState.audioVolume);
    if (!mounted || _finished || _phrase.id != phraseId) return;
    final result = await widget.playbackService.playThai(phrase, _politeStyle);
    if (!mounted || _finished || _phrase.id != phraseId) return;
    setState(() {
      _audioBusy = false;
      _heard =
          _heard ||
          result == ThaiPlaybackResult.spoken ||
          result == ThaiPlaybackResult.audioAsset;
      _audioUnavailable = result == ThaiPlaybackResult.unavailable;
    });
  }

  void _answer(Phrase option) {
    if (_answered || (widget.mode == LearningMode.listening && !_heard)) return;
    final correct = QuizLogic.isCorrect(_phrase, option);
    setState(() {
      _selectedAnswer = option.id;
      _answered = true;
    });
    _record(_phrase, correct ? 5 : 2);
  }

  void _checkSentence() {
    if (_answered) return;
    final chunks = sentenceChunks(_phrase, _politeStyle)!;
    final correct =
        _selectedChunks.map((i) => chunks[i]).join() ==
        _phrase.thaiFor(_politeStyle);
    setState(() {
      if (correct) {
        _answered = true;
        _sentenceFeedback = 'မှန်ပါတယ်။';
      } else {
        _mistakes++;
        _sentenceFeedback = 'အစီအစဉ်ကို ပြန်စမ်းကြည့်ပါ။';
      }
    });
    if (correct) _record(_phrase, max(2, 5 - _mistakes));
  }

  void _match(String id, bool left) {
    if (_matched.contains(id)) return;
    setState(() {
      if (left) {
        _leftSelection = id;
      } else {
        _rightSelection = id;
      }
      if (_leftSelection != null && _rightSelection != null) {
        if (_leftSelection == _rightSelection) {
          final phrase = widget.phrases.firstWhere((p) => p.id == id);
          _matched.add(id);
          _record(phrase, max(2, 5 - (_matchMistakes[id] ?? 0)));
          _sentenceFeedback = 'မှန်ပါတယ်။';
        } else {
          final key = _leftSelection!;
          _matchMistakes[key] = (_matchMistakes[key] ?? 0) + 1;
          _sentenceFeedback = 'မကိုက်သေးပါ။ ပြန်ရွေးပါ။';
        }
        _leftSelection = null;
        _rightSelection = null;
      }
    });
    if (_matched.length == widget.phrases.length) _finish();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) unawaited(widget.playbackService.stop());
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: [
            IconButton(
              tooltip: 'အသံထွက်စာ ပြ/ဖျောက်',
              onPressed: () =>
                  setState(() => _showPronunciation = !_showPronunciation),
              icon: Icon(
                _showPronunciation ? Icons.subtitles : Icons.subtitles_off,
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: widget.phrases.isEmpty
                  ? const Center(child: Text('ဒီပုံစံအတွက် စကားစု မရှိသေးပါ။'))
                  : _finished
                  ? _summary(context)
                  : widget.mode == LearningMode.matching
                  ? _matching(context)
                  : _question(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _question(BuildContext context) {
    final listening = widget.mode == LearningMode.listening;
    final reverse = widget.mode == LearningMode.reverseMeaning;
    final flashcard = widget.mode == LearningMode.flashcard;
    final sentence = widget.mode == LearningMode.sentence;
    final thai = _phrase.thaiFor(_politeStyle);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        LinearProgressIndicator(value: _index / widget.phrases.length),
        const SizedBox(height: 8),
        Text('${_index + 1} / ${widget.phrases.length}'),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  listening
                      ? 'အသံနားထောင်ပြီး အဓိပ္ပာယ်ရွေးပါ'
                      : sentence
                      ? 'စာကြောင်းအပိုင်းတွေကို အစီအစဉ်တကျ စီပါ'
                      : flashcard
                      ? 'နားထောင်၊ မှတ်မိသလား စမ်းကြည့်ပါ'
                      : reverse
                      ? 'ထိုင်းအဖြေကို ရွေးပါ'
                      : 'မြန်မာအဓိပ္ပာယ်ကို ရွေးပါ',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 18),
                if ((!listening && !reverse) || _answered) ...[
                  if (flashcard && _showPronunciation) ...[
                    Text(
                      _phrase.pronunciation,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (!sentence || _answered)
                    Text(
                      thai,
                      style: flashcard
                          ? Theme.of(context).textTheme.titleLarge
                          : Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                  if (_showPronunciation &&
                      !flashcard &&
                      (!sentence || _answered)) ...[
                    const SizedBox(height: 12),
                    Text(
                      'အသံထွက်အနီးစပ်ဆုံး — ${_phrase.pronunciation}',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
                if (sentence || (reverse && !_answered))
                  Text(
                    _phrase.myanmar,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                const SizedBox(height: 16),
                if (listening)
                  FilledButton.icon(
                    onPressed: _listen,
                    icon: Icon(_audioBusy ? Icons.stop : Icons.headphones),
                    label: Text(_audioBusy ? 'ရပ်ရန်' : 'အသံနားထောင်ရန်'),
                  )
                else if (!reverse || _answered)
                  ThaiPlaybackButton(
                    phrase: _phrase,
                    appState: widget.appState,
                    playbackService: widget.playbackService,
                    label: 'ထိုင်းအသံ နားထောင်ရန်',
                  ),
                if (_audioUnavailable) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'ဒီစက်မှာ ထိုင်းအသံ မရသေးပါ။ ပြန်စမ်းပါ သို့မဟုတ် စာကတ်နဲ့ လေ့ကျင့်ပါ။',
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => StudySessionScreen(
                            repository: widget.repository,
                            appState: widget.appState,
                            playbackService: widget.playbackService,
                            phrases: widget.phrases,
                            mode: LearningMode.flashcard,
                            title: 'စာကတ်လေ့ကျင့်ရန်',
                          ),
                        ),
                      );
                    },
                    child: const Text('စာကတ်နဲ့ လေ့ကျင့်မယ်'),
                  ),
                ],
                if (_revealed || _answered) ...[
                  const Divider(height: 32),
                  Text(
                    _phrase.myanmar,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(_phrase.english, textAlign: TextAlign.center),
                  if (_phrase.note != null) ...[
                    const SizedBox(height: 8),
                    Text(_phrase.note!),
                  ],
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (flashcard) ...[
          if (!_revealed)
            FilledButton(
              onPressed: () => setState(() => _revealed = true),
              child: const Text('အဓိပ္ပာယ်ကြည့်မယ်'),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => _rateFlashcard(2),
                  child: const Text('ပြန်လေ့ကျင့်မယ်'),
                ),
                FilledButton.tonal(
                  onPressed: () => _rateFlashcard(4),
                  child: const Text('မှတ်မိတယ်'),
                ),
                FilledButton(
                  onPressed: () => _rateFlashcard(5),
                  child: const Text('လွယ်ပါတယ်'),
                ),
              ],
            ),
        ] else if (sentence) ...[
          _sentenceBuilder(context),
        ] else ...[
          ..._options.map((option) {
            final correct = option.id == _phrase.id;
            final selected = option.id == _selectedAnswer;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                color: !_answered
                    ? null
                    : correct
                    ? Theme.of(context).colorScheme.primaryContainer
                    : selected
                    ? Theme.of(context).colorScheme.errorContainer
                    : null,
                child: ListTile(
                  title: Text(
                    reverse ? option.thaiFor(_politeStyle) : option.myanmar,
                  ),
                  subtitle: reverse && _showPronunciation
                      ? Text(option.pronunciation)
                      : null,
                  trailing: _answered && correct
                      ? const Icon(Icons.check_circle)
                      : null,
                  enabled: !listening || _heard,
                  onTap: _answered ? null : () => _answer(option),
                ),
              ),
            );
          }),
          if (listening && !_heard && !_audioUnavailable)
            const Text('အသံပြီးဆုံးအောင် နားထောင်ပြီးမှ အဖြေရွေးနိုင်ပါတယ်။'),
        ],
        if (_answered && !flashcard) ...[
          const SizedBox(height: 12),
          Text(
            _results[_phrase.id]! >= 3
                ? 'မှန်ပါတယ်။'
                : 'ဒီစကားစုကို ပြန်လေ့ကျင့်ပေးမယ်။',
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _next,
            child: Text(
              _index + 1 == widget.phrases.length
                  ? 'ရလဒ်ကြည့်မယ်'
                  : 'နောက်တစ်ခု',
            ),
          ),
        ],
      ],
    );
  }

  Widget _sentenceBuilder(BuildContext context) {
    final chunks = sentenceChunks(_phrase, _politeStyle)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('ရွေးထားတဲ့အပိုင်းကို နှိပ်ပြီး ပြန်ဖယ်နိုင်ပါတယ်။'),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_selectedChunks.isEmpty)
                  const Text('ဒီနေရာမှာ စာကြောင်းဆောက်ပါ'),
                ..._selectedChunks.map(
                  (index) => InputChip(
                    label: Text(chunks[index].trim()),
                    onDeleted: _answered
                        ? null
                        : () => setState(() => _selectedChunks.remove(index)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _chunkOrder
              .map(
                (index) => ActionChip(
                  label: Text(chunks[index].trim()),
                  onPressed: _answered || _selectedChunks.contains(index)
                      ? null
                      : () => setState(() => _selectedChunks.add(index)),
                ),
              )
              .toList(),
        ),
        if (_sentenceFeedback != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(_sentenceFeedback!),
          ),
        if (!_answered) ...[
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _selectedChunks.length != chunks.length
                ? null
                : _checkSentence,
            child: const Text('အဖြေစစ်မယ်'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _answered = true;
                _revealed = true;
              });
              _record(_phrase, 2);
            },
            child: const Text('အဖြေကြည့်ပြီး ပြန်လေ့ကျင့်မယ်'),
          ),
        ],
      ],
    );
  }

  Widget _matching(BuildContext context) => ListView(
    padding: const EdgeInsets.all(18),
    children: [
      Text(
        'ထိုင်းစာနဲ့ မြန်မာအဓိပ္ပာယ်ကို တွဲပါ',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 8),
      Text('${_matched.length} / ${widget.phrases.length} တွဲပြီး'),
      if (_sentenceFeedback != null) Text(_sentenceFeedback!),
      const SizedBox(height: 16),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: widget.phrases
                  .map((phrase) => _matchCard(context, phrase, true))
                  .toList(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              children: _rightOrder
                  .map((phrase) => _matchCard(context, phrase, false))
                  .toList(),
            ),
          ),
        ],
      ),
    ],
  );

  Widget _matchCard(BuildContext context, Phrase phrase, bool left) {
    final done = _matched.contains(phrase.id);
    final selected = left
        ? _leftSelection == phrase.id
        : _rightSelection == phrase.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        color: done
            ? Theme.of(context).colorScheme.primaryContainer
            : selected
            ? Theme.of(context).colorScheme.secondaryContainer
            : null,
        child: InkWell(
          onTap: done ? null : () => _match(phrase.id, left),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Text(left ? phrase.thaiFor(_politeStyle) : phrase.myanmar),
                if (left && _showPronunciation) ...[
                  const SizedBox(height: 8),
                  Text(
                    phrase.pronunciation,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (done) const Icon(Icons.check_circle),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _summary(BuildContext context) {
    final correct = _results.values.where((q) => q >= 3).length;
    final difficult = widget.phrases
        .where((p) => (_results[p.id] ?? 5) < 4)
        .toList();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(
          Icons.emoji_events,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'ဒီအကြိမ် ပြီးပါပြီ',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'မှတ်မိ / မှန် $correct ခု • စုစုပေါင်း ${_results.length} ခု',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),
        if (difficult.isNotEmpty) ...[
          const Text('ပြန်လေ့ကျင့်သင့်တဲ့ စကားစုများ'),
          ...difficult.map(
            (phrase) => ListTile(
              title: Text(phrase.myanmar),
              subtitle: Text(phrase.thaiFor(_politeStyle)),
            ),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute<void>(
                builder: (_) => StudySessionScreen(
                  repository: widget.repository,
                  appState: widget.appState,
                  playbackService: widget.playbackService,
                  phrases: difficult,
                  mode: LearningMode.flashcard,
                  title: 'ခက်တဲ့စကားစု ပြန်လေ့ကျင့်ရန်',
                ),
              ),
            ),
            child: const Text('ဒီစကားစုတွေ ပြန်လေ့ကျင့်မယ်'),
          ),
          const SizedBox(height: 12),
        ],
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ပြီးပါပြီ'),
        ),
      ],
    );
  }
}
