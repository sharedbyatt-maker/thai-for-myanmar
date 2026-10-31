import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../widgets/content_frame.dart';
import '../widgets/playful_components.dart';

import '../data/phrase_repository.dart';
import '../learning/learning_progress.dart';
import '../learning/learner_rank.dart';
import '../learning/study_catalog.dart';
import '../widgets/rank_card.dart';
import '../widgets/lesson_preview.dart';
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
    this.guided = false,
    super.key,
  });
  final PhraseRepository repository;
  final AppState appState;
  final ThaiPlaybackService playbackService;
  final List<Phrase> phrases;
  final LearningMode mode;
  final String title;
  final String? lessonId;
  final bool guided;

  @override
  State<StudySessionScreen> createState() => _StudySessionScreenState();
}

class _StudySessionScreenState extends State<StudySessionScreen> {
  int _index = 0;
  bool _revealed = false;
  bool _answered = false;
  bool _finished = false;
  bool _rankUp = false;
  late final int _startingXp;
  int _earnedXp = 0;
  bool _heard = false;
  bool _audioBusy = false;
  bool _audioUnavailable = false;
  bool _showPronunciation = false;
  bool _lessonPreviewOpen = false;
  bool _checking = false;
  bool _textFallback = false;
  bool _exitPromptOpen = false;
  int _audioGeneration = 0;
  int _actionGeneration = 0;
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
  bool get _guided => widget.guided && widget.mode == LearningMode.flashcard;
  bool get _listeningCheck => _guided && _checking && !_textFallback;
  bool get _reverseCheck =>
      !_guided && widget.mode == LearningMode.reverseMeaning;

  @override
  void initState() {
    super.initState();
    _startingXp = LearnerRank(widget.repository, widget.appState.learning).xp;
    _politeStyle = widget.appState.politeStyle;
    _rightOrder = List<Phrase>.from(widget.phrases)..shuffle();
    if (widget.phrases.isNotEmpty) _prepareQuestion();
  }

  void _prepareQuestion() {
    _audioGeneration++;
    _checking = false;
    _textFallback = false;
    _buildOptions();
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

  void _buildOptions() {
    final candidates =
        widget.repository.phrases
            .where((item) => item.id != _phrase.id)
            .toList()
          ..shuffle();
    String label(Phrase phrase) =>
        (widget.mode == LearningMode.reverseMeaning || _reverseCheck)
        ? phrase.thaiFor(_politeStyle)
        : phrase.myanmar;
    final seen = <String>{label(_phrase)};
    final distractors = candidates
        .where((item) => seen.add(label(item)))
        .take(3);
    _options = [_phrase, ...distractors]..shuffle();
  }

  @override
  void dispose() {
    unawaited(widget.playbackService.stop());
    super.dispose();
  }

  void _record(Phrase phrase, int quality) {
    if (_results.containsKey(phrase.id)) return;
    // A correct quiz answer is Good, not the learner's explicit Easy rating.
    final calibrated =
        quality == 5 && (_guided || widget.mode != LearningMode.flashcard)
        ? 4
        : quality;
    _results[phrase.id] = calibrated;
    unawaited(widget.appState.recordReview(phrase.id, widget.mode, calibrated));
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
    final before = LearnerRank(
      widget.repository,
      widget.appState.learning,
    ).level;
    unawaited(widget.appState.finishStudySession(lessonId: widget.lessonId));
    _rankUp =
        LearnerRank(widget.repository, widget.appState.learning).level > before;
    _earnedXp =
        LearnerRank(widget.repository, widget.appState.learning).xp -
        _startingXp;
    if (widget.mode == LearningMode.meaning ||
        widget.mode == LearningMode.reverseMeaning ||
        widget.mode == LearningMode.listening) {
      unawaited(widget.appState.recordQuizCompletion());
    }
  }

  Future<void> _listen({bool slow = false}) async {
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
    final generation = ++_audioGeneration;
    setState(() {
      _audioBusy = true;
      _audioUnavailable = false;
    });
    await widget.playbackService.setVolume(widget.appState.audioVolume);
    if (!mounted ||
        _finished ||
        _phrase.id != phraseId ||
        generation != _audioGeneration) {
      return;
    }
    final result = await widget.playbackService.playThai(
      phrase,
      _politeStyle,
      speed: slow ? .8 : 1,
    );
    if (!mounted ||
        _finished ||
        _phrase.id != phraseId ||
        generation != _audioGeneration) {
      return;
    }
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
    if (_answered ||
        ((widget.mode == LearningMode.listening || _listeningCheck) &&
            !_heard)) {
      return;
    }
    final correct = QuizLogic.isCorrect(_phrase, option);
    setState(() {
      _selectedAnswer = option.id;
      _answered = true;
    });
    if (_guided) {
      if (correct) {
        _record(_phrase, _mistakes == 0 ? 5 : 3);
      } else {
        _mistakes++;
      }
    } else {
      _record(_phrase, correct ? 5 : 2);
    }
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
    final active =
        !_finished &&
        widget.phrases.isNotEmpty &&
        (_index > 0 ||
            _revealed ||
            _answered ||
            _checking ||
            _matched.isNotEmpty);
    return PopScope(
      canPop: !active,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) unawaited(widget.playbackService.stop());
        if (!didPop && !_exitPromptOpen) unawaited(_confirmExit());
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
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
        body: ContentFrame(
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: widget.phrases.isEmpty
                    ? const Center(
                        child: Text('ဒီပုံစံအတွက် စကားစု မရှိသေးပါ။'),
                      )
                    : _finished
                    ? _summary(context)
                    : widget.mode == LearningMode.matching
                    ? _matching(context)
                    : _guided
                    ? _guidedQuestion(context)
                    : _question(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmExit() async {
    _exitPromptOpen = true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ဒီအကြိမ် နားမလား?'),
        content: const Text(
          'ဖြေပြီးသား စကားစုတွေကို သိမ်းထားပါတယ်။ သင်ခန်းစာပြီးဆုကိုတော့ အားလုံးပြီးမှ ရပါမယ်။',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ဆက်သင်မယ်'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('အခု နားမယ်'),
          ),
        ],
      ),
    );
    _exitPromptOpen = false;
    if (mounted && leave == true) Navigator.pop(context);
  }

  void _beginCheck() {
    _audioGeneration++;
    unawaited(widget.playbackService.stop());
    setState(() {
      _checking = true;
      _heard = false;
      _audioBusy = false;
      _audioUnavailable = false;
      _selectedAnswer = null;
      _buildOptions();
    });
  }

  void _guidedPrimary() {
    if (!_checking) {
      if (!_revealed) {
        setState(() => _revealed = true);
      } else {
        _beginCheck();
      }
    } else if (!_answered) {
      if (_selectedAnswer == null) return;
      _answer(_options.firstWhere((p) => p.id == _selectedAnswer));
    } else if (_selectedAnswer == _phrase.id) {
      _next();
    } else {
      setState(() {
        _answered = false;
        _selectedAnswer = null;
        _options.shuffle();
      });
    }
  }

  Widget _guidedQuestion(BuildContext context) {
    final actionGeneration = _actionGeneration;
    final colors = Theme.of(context).colorScheme;
    final passed = _answered && _selectedAnswer == _phrase.id;
    final canHear = !_reverseCheck || _answered;
    final canChoose = !_listeningCheck || _heard;
    final showThai = (!_reverseCheck && !_listeningCheck) || _answered;
    final prompt = !_checking
        ? 'နားထောင်ပြီး လေ့လာပါ'
        : _listeningCheck
        ? 'ကြားတဲ့စကားရဲ့ အဓိပ္ပာယ်ကို ရွေးပါ'
        : _reverseCheck
        ? 'ထိုင်းလို ဘယ်လိုပြောမလဲ?'
        : 'အဓိပ္ပာယ်ကို ရွေးပါ';
    final primary = !_checking
        ? (_revealed ? 'စမ်းဖြေမယ်' : 'အဓိပ္ပာယ်ကြည့်မယ်')
        : !_answered
        ? 'အဖြေစစ်မယ်'
        : !passed
        ? 'ပြန်စမ်းမယ်'
        : _index + 1 == widget.phrases.length
        ? 'ရလဒ်ကြည့်မယ်'
        : 'နောက်စကားစု';
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value:
                          (_index * 2 + (_checking ? 1 : 0)) /
                          (widget.phrases.length * 2),
                      minHeight: 9,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('${_index + 1} / ${widget.phrases.length}'),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            key: ValueKey('guided-$_index-$_checking'),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const ElephantBuddy(size: 42),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        prompt,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Chip(label: Text(_checking ? 'စမ်းဖြေ' : 'လေ့လာ')),
                  ],
                ),
                const SizedBox(height: 12),
                Card(
                  color: colors.primaryContainer.withValues(alpha: .5),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      children: [
                        if (canHear) ...[
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              FilledButton.icon(
                                key: const ValueKey('guided-audio'),
                                onPressed: () => unawaited(_listen()),
                                icon: Icon(
                                  _audioBusy
                                      ? Icons.stop_rounded
                                      : Icons.volume_up_rounded,
                                  size: 30,
                                ),
                                label: Text(
                                  _audioBusy ? 'အသံရပ်မယ်' : 'နားထောင်မယ်',
                                ),
                              ),
                              OutlinedButton.icon(
                                key: const ValueKey('guided-slow-audio'),
                                onPressed: _audioBusy
                                    ? null
                                    : () => unawaited(_listen(slow: true)),
                                icon: const Icon(
                                  Icons.slow_motion_video_rounded,
                                ),
                                label: const Text('ဖြည်းဖြည်း'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                        if (showThai)
                          Text(
                            _phrase.thaiFor(_politeStyle),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  height: 1.5,
                                ),
                          ),
                        if (_reverseCheck && !_answered)
                          Text(
                            _phrase.myanmar,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        if (_listeningCheck && !_answered) ...[
                          Icon(
                            Icons.graphic_eq_rounded,
                            size: 54,
                            color: colors.primary,
                          ),
                          Text(
                            _heard
                                ? 'ပြန်နားထောင်လို့ ရပါတယ်'
                                : 'အသံကို အရင်နားထောင်ပါ',
                            textAlign: TextAlign.center,
                          ),
                        ],
                        if (!_checking || _answered) ...[
                          if (_showPronunciation)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                _phrase.pronunciation,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: colors.primary),
                              ),
                            ),
                          TextButton.icon(
                            onPressed: () => setState(
                              () => _showPronunciation = !_showPronunciation,
                            ),
                            icon: const Icon(
                              Icons.subtitles_outlined,
                              size: 18,
                            ),
                            label: Text(
                              _showPronunciation
                                  ? 'အသံထွက်စာ ဖျောက်မယ်'
                                  : 'အသံထွက်စာ ကြည့်မယ်',
                            ),
                          ),
                        ],
                        if (!_checking && _revealed) ...[
                          const Divider(height: 28),
                          Text(
                            _phrase.myanmar,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if ((!_checking && _revealed) || _answered)
                  ExpansionTile(
                    title: const Text('အသုံးပြုပုံ ကြည့်မယ်'),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      if (_phrase.note != null) Text(_phrase.note!),
                      Text(_phrase.english),
                    ],
                  ),
                if (_audioUnavailable) ...[
                  const SizedBox(height: 12),
                  const Text('အသံမရသေးပါ။ ထပ်နားထောင်နိုင်ပါတယ်။'),
                  if (_listeningCheck)
                    TextButton.icon(
                      onPressed: () => setState(() {
                        _textFallback = true;
                        _audioUnavailable = false;
                      }),
                      icon: const Icon(Icons.article_outlined),
                      label: const Text('စာနဲ့ ဆက်လေ့ကျင့်မယ်'),
                    ),
                ],
                if (_checking) ...[
                  const SizedBox(height: 16),
                  ..._options.asMap().entries.map((entry) {
                    final p = entry.value;
                    final selected = p.id == _selectedAnswer;
                    final correct = p.id == _phrase.id;
                    final feedbackColor = _answered && correct
                        ? colors.primary
                        : _answered && selected
                        ? colors.error
                        : selected
                        ? colors.primary
                        : colors.outlineVariant;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Semantics(
                        selected: selected,
                        child: OutlinedButton(
                          key: ValueKey('guided-option-${p.id}'),
                          style: OutlinedButton.styleFrom(
                            alignment: Alignment.centerLeft,
                            side: BorderSide(
                              color: feedbackColor,
                              width: selected || (_answered && correct) ? 2 : 1,
                            ),
                            backgroundColor: selected
                                ? feedbackColor.withValues(alpha: .1)
                                : colors.surface,
                            padding: const EdgeInsets.all(16),
                          ),
                          onPressed: _answered || !canChoose
                              ? null
                              : () => setState(() => _selectedAnswer = p.id),
                          child: Row(
                            children: [
                              Text(
                                '${entry.key + 1}',
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  _reverseCheck
                                      ? p.thaiFor(_politeStyle)
                                      : p.myanmar,
                                  style: TextStyle(
                                    color: colors.onSurface,
                                    fontSize: 17,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                              if (_answered && correct)
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: colors.primary,
                                )
                              else if (selected)
                                Icon(
                                  _answered
                                      ? Icons.cancel_rounded
                                      : Icons.radio_button_checked,
                                  color: feedbackColor,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
        Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .4,
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(top: BorderSide(color: colors.outlineVariant)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_answered) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        passed
                            ? Icons.check_circle_rounded
                            : Icons.lightbulb_rounded,
                        color: passed ? colors.primary : colors.error,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          passed
                              ? (_mistakes == 0
                                    ? 'မှန်ပါတယ်။ ကောင်းလိုက်တာ!'
                                    : 'အခု မှန်သွားပြီ။')
                              : 'မှတ်ထားပါ — ${_phrase.thaiFor(_politeStyle)}\n${_phrase.myanmar}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                LiftButton(
                  key: const ValueKey('guided-primary'),
                  label: primary,
                  icon: _checking
                      ? Icons.arrow_forward_rounded
                      : _revealed
                      ? Icons.psychology_rounded
                      : Icons.visibility_rounded,
                  onPressed:
                      _checking &&
                          !_answered &&
                          (_selectedAnswer == null || !canChoose)
                      ? null
                      : () {
                          if (actionGeneration != _actionGeneration) return;
                          _actionGeneration++;
                          _guidedPrimary();
                        },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _question(BuildContext context) {
    final listening = widget.mode == LearningMode.listening;
    final reverse = widget.mode == LearningMode.reverseMeaning;
    final flashcard = widget.mode == LearningMode.flashcard;
    final sentence = widget.mode == LearningMode.sentence;
    final colors = Theme.of(context).colorScheme;
    final thai = _phrase.thaiFor(_politeStyle);
    final prompt = listening
        ? 'နားထောင်ပြီး ရွေးပါ'
        : sentence
        ? 'ဝါကျကို စီပါ'
        : flashcard
        ? 'နားထောင်ပြီး မှတ်မိကြည့်ပါ'
        : reverse
        ? 'ထိုင်းအဖြေကို ရွေးပါ'
        : 'အဓိပ္ပာယ်ကို ရွေးပါ';
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: _index / widget.phrases.length,
                  minHeight: 10,
                ),
              ),
              const SizedBox(width: 16),
              Text('${_index + 1} / ${widget.phrases.length}'),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            key: ValueKey('question-$_index'),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
              Text(
                prompt,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (listening)
                Center(
                  child: FilledButton(
                    onPressed: _listen,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _audioBusy
                              ? Icons.stop_rounded
                              : Icons.headphones_rounded,
                          size: 42,
                        ),
                        const SizedBox(height: 8),
                        Text(_audioBusy ? 'ရပ်ရန်' : 'အသံနားထောင်ရန်'),
                      ],
                    ),
                  ),
                )
              else if (!reverse || _answered)
                ThaiPlaybackButton(
                  phrase: _phrase,
                  appState: widget.appState,
                  playbackService: widget.playbackService,
                  label: 'ထိုင်းအသံ နားထောင်ရန်',
                  hero: true,
                ),
              const SizedBox(height: 24),
              if ((!listening && !reverse && !sentence) || _answered)
                Text(
                  thai,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.5,
                  ),
                ),
              if (sentence || (reverse && !_answered))
                Text(
                  _phrase.myanmar,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              if (_showPronunciation &&
                  (!listening || _answered) &&
                  (!reverse || _answered))
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _phrase.pronunciation,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.primary),
                  ),
                ),
              if (flashcard && !_revealed)
                TextButton.icon(
                  onPressed: () =>
                      setState(() => _showPronunciation = !_showPronunciation),
                  icon: const Icon(Icons.subtitles_outlined, size: 18),
                  label: Text(
                    _showPronunciation
                        ? 'အသံထွက်စာ ဖျောက်မယ်'
                        : 'အသံထွက်စာ ကြည့်မယ်',
                  ),
                ),
              if (_revealed || _answered) ...[
                const SizedBox(height: 18),
                Card(
                  color: colors.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Text(
                      _phrase.myanmar,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
                ExpansionTile(
                  title: const Text('ရှင်းလင်းချက်'),
                  tilePadding: EdgeInsets.zero,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(_phrase.english),
                          if (_phrase.note != null) Text(_phrase.note!),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              if (_audioUnavailable) ...[
                const SizedBox(height: 12),
                const Text('အသံမရသေးပါ။ ထပ်စမ်းပါ သို့မဟုတ် စာကတ်သုံးပါ။'),
                TextButton(
                  onPressed: () => Navigator.pushReplacement(
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
                  ),
                  child: const Text('စာကတ်နဲ့ လေ့ကျင့်မယ်'),
                ),
              ],
              const SizedBox(height: 20),
              if (sentence) _sentenceBuilder(context),
              if (!flashcard && !sentence)
                ..._options.asMap().entries.map((entry) {
                  final option = entry.value;
                  final correct = option.id == _phrase.id;
                  final selected = option.id == _selectedAnswer;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      color: !_answered
                          ? null
                          : correct
                          ? colors.primaryContainer
                          : selected
                          ? colors.errorContainer
                          : null,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          radius: 15,
                          backgroundColor: colors.surfaceContainerHighest,
                          child: Text(
                            '${entry.key + 1}',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                        title: Text(
                          reverse
                              ? option.thaiFor(_politeStyle)
                              : option.myanmar,
                        ),
                        trailing: _answered && correct
                            ? const Icon(Icons.check_circle_rounded)
                            : null,
                        enabled: !listening || _heard,
                        onTap: _answered ? null : () => _answer(option),
                      ),
                    ),
                  );
                }),
              if (listening && !_heard && !_audioUnavailable)
                const Text('အရင် နားထောင်ပါ။', textAlign: TextAlign.center),
            ],
          ),
        ),
        if (flashcard || _answered)
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .45,
            ),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(top: BorderSide(color: colors.outlineVariant)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (flashcard && !_revealed)
                    LiftButton(
                      label: 'အဓိပ္ပာယ်ကြည့်မယ်',
                      icon: Icons.visibility_rounded,
                      onPressed: () => setState(() => _revealed = true),
                    )
                  else if (flashcard)
                    Wrap(
                      alignment: WrapAlignment.center,
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
                    )
                  else ...[
                    Text(
                      _results[_phrase.id]! >= 3
                          ? 'မှန်ပါတယ်။'
                          : 'ဒီစကားစုကို ပြန်လေ့ကျင့်ပေးမယ်။',
                      style: TextStyle(
                        color: _results[_phrase.id]! >= 3
                            ? colors.primary
                            : colors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LiftButton(
                      label: _index + 1 == widget.phrases.length
                          ? 'ရလဒ်ကြည့်မယ်'
                          : 'နောက်တစ်ခု',
                      onPressed: _next,
                    ),
                  ],
                ],
              ),
            ),
          ),
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
    final nextLessons = StudyCatalog.lessons(widget.repository).where(
      (lesson) =>
          !widget.appState.learning.completedLessons.contains(lesson.id),
    );
    final nextLesson = nextLessons.isEmpty ? null : nextLessons.first;
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
          _rankUp ? '🎉 Rank တက်သွားပါပြီ!' : 'ဒီအကြိမ် ပြီးပါပြီ',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          _guided
              ? 'ပထမအကြိမ်မှန် ${_results.values.where((q) => q >= 4).length} ခု • သင်ပြီး ${_results.length} ခု'
              : 'မှတ်မိ / မှန် $correct ခု • စုစုပေါင်း ${_results.length} ခု',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Center(
          child: Chip(
            avatar: const Icon(Icons.bolt_rounded),
            label: Text('+$_earnedXp XP'),
          ),
        ),
        if (_earnedXp == 0)
          const Text(
            'ဒီတစ်ကြိမ် XP ထပ်မရပေမယ့် လေ့ကျင့်မှုကို မှတ်တမ်းတင်ထားပါတယ်။',
            textAlign: TextAlign.center,
          ),
        RankCard(repository: widget.repository, appState: widget.appState),
        const SizedBox(height: 16),
        if (widget.lessonId != null && nextLesson != null) ...[
          FilledButton.icon(
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('နောက်သင်ခန်းစာ ဆက်မယ်'),
            onPressed: () async {
              if (_lessonPreviewOpen) return;
              _lessonPreviewOpen = true;
              final size = MediaQuery.sizeOf(context);
              final start = await showLessonPreview(
                context: context,
                lesson: nextLesson,
                completed: false,
                anchor: Rect.fromCenter(
                  center: Offset(size.width / 2, size.height / 2),
                  width: 0,
                  height: 0,
                ),
              );
              _lessonPreviewOpen = false;
              if (!context.mounted || start != true) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => StudySessionScreen(
                    repository: widget.repository,
                    appState: widget.appState,
                    playbackService: widget.playbackService,
                    phrases: nextLesson.phrases,
                    mode: LearningMode.flashcard,
                    title: '${nextLesson.category.my} · ${nextLesson.number}',
                    lessonId: nextLesson.id,
                    guided: true,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
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
        if (widget.mode == LearningMode.flashcard) ...[
          LiftButton(
            label: 'နားထောင်ပြီး ပြန်စမ်းမယ်',
            icon: Icons.headphones_rounded,
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute<void>(
                builder: (_) => StudySessionScreen(
                  repository: widget.repository,
                  appState: widget.appState,
                  playbackService: widget.playbackService,
                  phrases: widget.phrases,
                  mode: LearningMode.listening,
                  title: 'နားထောင်ပြီးရွေး',
                ),
              ),
            ),
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
