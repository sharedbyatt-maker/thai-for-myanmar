import 'dart:async';

import 'package:flutter/material.dart';

import '../data/phrase_repository.dart';
import '../learning/learning_progress.dart';
import '../models/phrase.dart';
import '../services/app_state.dart';
import '../services/thai_playback_service.dart';
import '../widgets/content_frame.dart';
import '../widgets/thai_playback_button.dart';

/// A task-based introduction: model, notice, build, listen, transfer, reflect.
/// Free speech is never automatically graded as pronunciation mastery.
class PracticalIntroScreen extends StatefulWidget {
  const PracticalIntroScreen({
    required this.repository,
    required this.appState,
    required this.playbackService,
    super.key,
  });
  final PhraseRepository repository;
  final AppState appState;
  final ThaiPlaybackService playbackService;
  static const lessonId = 'practical:introductions:v1';

  @override
  State<PracticalIntroScreen> createState() => _PracticalIntroScreenState();
}

class _PracticalIntroScreenState extends State<PracticalIntroScreen> {
  final _name = TextEditingController();
  final _scroll = ScrollController();
  late final String _style = widget.appState.politeStyle;
  int _step = 0;
  bool _busy = false;
  bool _heard = false;
  bool _reveal = false;
  bool _passed = false;
  bool _submitted = false;
  int _listeningMistakes = 0;
  String? _feedback;
  final List<int> _selected = [];
  final _listeningOptions = [
    'နာမည်ကို မေးတာ',
    'နေတဲ့နေရာကို မေးတာ',
    'ဈေးနှုန်းကို မေးတာ',
  ]..shuffle();
  bool _leaving = false;
  bool get _male => _style == 'male';
  String get _speaker => _male ? 'ผม' : 'ฉัน';
  String get _ending => _male ? 'ครับ' : 'ค่ะ';
  Phrase _phrase(String id) =>
      widget.repository.phrases.firstWhere((p) => p.id == id);
  List<String> get _answer => _step == 2
      ? [_speaker, 'ชื่อ', _name.text.trim(), _ending]
      : [_speaker, 'มาจาก', 'ประเทศไทย', _ending];
  // Fixed shuffled banks keep the task stable while feedback rebuilds.
  List<String> get _bank => _step == 2
      ? [_ending, _name.text.trim(), 'ชื่อ', _speaker]
      : ['เมียนมา', _ending, _speaker, 'มาจาก', 'ประเทศไทย'];

  @override
  void dispose() {
    _name.dispose();
    _scroll.dispose();
    unawaited(widget.playbackService.stop());
    super.dispose();
  }

  void _advance() {
    if (_busy) return;
    unawaited(widget.playbackService.stop());
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _step++;
      _heard = false;
      _reveal = false;
      _passed = false;
      _selected.clear();
      _feedback = null;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Future<void> _listen() async {
    if (_busy) return;
    if (widget.appState.audioVolume == 0) {
      setState(
        () => _feedback = 'ဆက်တင်မှာ အသံအတိုးအကျယ် မြှင့်ပြီး ပြန်စမ်းပါ။',
      );
      return;
    }
    setState(() {
      _busy = true;
      _feedback = null;
    });
    final step = _step;
    try {
      await widget.playbackService.setVolume(widget.appState.audioVolume);
      if (!mounted || step != _step) return;
      final result = await widget.playbackService.playThai(
        _phrase('intro_ask_name'),
        _style,
      );
      if (!mounted || step != _step) return;
      setState(() {
        _heard =
            result == ThaiPlaybackResult.audioAsset ||
            result == ThaiPlaybackResult.spoken;
        if (!_heard) {
          _feedback =
              'အသံမကြားရသေးပါ။ ပြန်နားထောင်ပါ။ စာသားကိုတော့ ဖွင့်ကြည့်နိုင်ပါတယ်။';
        }
      });
    } catch (_) {
      if (mounted && step == _step) {
        setState(() {
          _heard = false;
          _feedback = 'အသံဖွင့်မရသေးပါ။ ခဏစောင့်ပြီး ပြန်စမ်းပါ။';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _checkBuild() {
    final correct = _selected.map((i) => _bank[i]).join() == _answer.join();
    setState(() {
      _passed = correct;
      _feedback = correct
          ? (_step == 2
                ? 'ဝါကျအစီအစဉ် မှန်ပါတယ်။ နာမည်နေရာမှာ ကိုယ့်နာမည်ကို အစားထိုးသုံးနိုင်ပါတယ်။'
                : 'မှန်ပါတယ်။ နိုင်ငံအမည်ကို အခြေအနေအလိုက် ပြောင်းထည့်ပြီး ဝါကျအသစ် တည်ဆောက်နိုင်ပါတယ်။')
          : _step == 2
          ? 'ကိုယ့်ကိုရည်ညွှန်းတဲ့စကား → ชื่อ → နာမည် → ယဉ်ကျေးစကား အစဉ်လိုက် ပြန်စမ်းပါ။'
          : 'ဒီအခြေအနေမှာ သူငယ်ချင်းက ထိုင်းနိုင်ငံကပါ။ ประเทศไทย ကို ရွေးပြီး ကိုယ့်ကိုရည်ညွှန်းတဲ့စကား → มาจาก → နိုင်ငံ → ယဉ်ကျေးစကား အစဉ်လိုက် ပြန်စမ်းပါ။';
    });
  }

  Future<void> _finish() async {
    if (_busy || _submitted) return;
    setState(() => _busy = true);
    // Only a completed, unaided listening check contributes a review result.
    // Name construction and self-reported speech never certify pronunciation.
    await widget.appState.recordReview(
      'intro_ask_name',
      LearningMode.listening,
      _listeningMistakes == 0 ? 4 : 3,
    );
    await widget.appState.completePracticalLesson(
      PracticalIntroScreen.lessonId,
    );
    if (mounted) {
      setState(() {
        _submitted = true;
        _busy = false;
      });
    }
  }

  Widget _audio(String id, String role) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(role, style: Theme.of(context).textTheme.labelLarge),
          Text(
            _phrase(id).thaiFor(_style),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(_phrase(id).myanmar),
          ThaiPlaybackButton(
            phrase: _phrase(id),
            appState: widget.appState,
            playbackService: widget.playbackService,
            label: 'နမူနာအသံ နားထောင်မယ်',
          ),
        ],
      ),
    ),
  );

  Widget _buildSentence() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        _step == 2
            ? 'ကိုယ့်နာမည်နဲ့ မိတ်ဆက်မယ်'
            : 'အခု နိုင်ငံပြောတဲ့ ဝါကျကို ကိုယ်တိုင်တည်ဆောက်ပါ',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 12),
      Text(
        _step == 2
            ? 'အောက်ကစကားလုံးတွေကို အစဉ်လိုက်နှိပ်ပါ။ နာမည်ကို ကိုယ်ရေးထားတဲ့အတိုင်း ထည့်ပါမယ်။'
            : 'ဒီတစ်ခါ ထိုင်းနိုင်ငံကလာတဲ့ သူငယ်ချင်းတစ်ယောက်ရဲ့ နေရာကနေ ဖြေကြည့်ပါ။ “ဘယ်ကလာတာလဲ” မေးရင် ဘယ်လိုဖြေမလဲ။',
      ),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(16),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Text(
          _selected.isEmpty
              ? 'ဒီနေရာမှာ ဝါကျတည်ဆောက်မယ်'
              : _selected.map((i) => _bank[i]).join(' '),
          key: const ValueKey('practical-built-sentence'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < _bank.length; i++)
            OutlinedButton(
              key: ValueKey('practical-token-$i'),
              onPressed:
                  _passed ||
                      _selected.contains(i) ||
                      _selected.length >= _answer.length
                  ? null
                  : () => setState(() {
                      _selected.add(i);
                      _feedback = null;
                    }),
              child: Text(_bank[i]),
            ),
        ],
      ),
      TextButton(
        onPressed: _passed
            ? null
            : () => setState(() {
                _selected.clear();
                _feedback = null;
              }),
        child: const Text('အစီအစဉ် ပြန်ရွေးမယ်'),
      ),
      FilledButton(
        onPressed: _selected.length == _answer.length && !_passed
            ? _checkBuild
            : null,
        child: const Text('ဝါကျစစ်မယ်'),
      ),
      if (_passed) ...[
        const Text(
          'ဒါက စာသားဝါကျတည်ဆောက်မှုပါ။ ကိုယ့်အသံထွက်ကို အလိုအလျောက် မစစ်ထားပါ။',
        ),
        FilledButton(onPressed: _advance, child: const Text('ဆက်သင်မယ်')),
      ],
    ],
  );

  Future<void> _exit(bool didPop) async {
    if (didPop || _leaving) return;
    _leaving = true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('အခု နားမလား?'),
        content: const Text(
          'ဒီသင်ခန်းစာအလယ်က အဖြေတွေကို မသိမ်းရသေးပါ။ နောက်တစ်ခါ အစကနေ ပြန်သင်နိုင်ပါတယ်။',
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
    _leaving = false;
    if (mounted && leave == true) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _step == 0 || _submitted,
    onPopInvokedWithResult: (didPop, _) => unawaited(_exit(didPop)),
    child: Scaffold(
      appBar: AppBar(title: const Text('မိတ်ဆက်တတ်မယ်')),
      body: ContentFrame(
        child: ListView(
          controller: _scroll,
          padding: const EdgeInsets.all(20),
          children: [
            LinearProgressIndicator(value: _submitted ? 1 : _step / 6),
            const SizedBox(height: 16),
            Text('အဆင့် ${_step + 1} / 7'),
            const SizedBox(height: 16),
            if (_step == 0) ...[
              Text(
                'တွေ့တဲ့သူနဲ့ မိတ်ဆက်နိုင်ဖို့',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Text(
                'နာမည်မေးတာကို နားလည်၊ ကိုယ့်နာမည်နဲ့ နိုင်ငံကို ပြောပြီး တစ်ဖက်လူကို ပြန်မေးတတ်အောင် လေ့ကျင့်မယ်။',
              ),
              _audio('greet_hello', 'တွေ့ချိန် နှုတ်ဆက်မယ်'),
              _audio('intro_ask_name', 'တစ်ဖက်လူက မေးမယ်'),
              _audio(
                'intro_name',
                'ကိုယ့်နာမည် ထည့်ဖြေမယ် — … နေရာမှာ နာမည်ထည့်ပါ',
              ),
              FilledButton(
                onPressed: _advance,
                child: const Text('စကားလုံးပုံစံကို ကြည့်မယ်'),
              ),
            ] else if (_step == 1) ...[
              Text(
                'စာကြောင်းတစ်ကြောင်းကနေ ပုံစံကို ထုတ်ကြည့်မယ်',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                '$_speaker + ชื่อ + နာမည် + $_ending',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Text(
                'ชื่อ က နာမည်လို့ ဆိုလိုပါတယ်။ … နေရာမှာ ကိုယ့်နာမည် ပြောင်းထည့်ပါ။ စကားလုံးတစ်လုံးချင်းကြားမှာ ရှည်ရှည်မနားဘဲ နမူနာအသံအတိုင်း ဆက်ပြောကြည့်ပါ။',
              ),
              Text(
                _male
                    ? 'ဒီအကြိမ် ผม / ครับ ပုံစံ သုံးမယ်။'
                    : 'ဒီအကြိမ် ฉัน / ค่ะ ပုံစံ သုံးမယ်။',
              ),
              TextField(
                controller: _name,
                maxLength: 30,
                decoration: const InputDecoration(
                  labelText: 'ကိုယ်သုံးချင်တဲ့ နာမည်',
                  helperMaxLines: 3,
                  helperText: 'နာမည်ကို ဒီစက်မှာသာ သုံးမယ်။ အခြားသူဆီ မပို့ပါ။',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const Text(
                'နာမည်ကို မြန်မာ၊ ထိုင်း သို့မဟုတ် လက်တင်အက္ခရာနဲ့ ထည့်နိုင်ပါတယ်။ ဒီနာမည်ကို အသံဖတ်မပြပါ။',
              ),
              FilledButton(
                onPressed: _name.text.trim().isEmpty ? null : _advance,
                child: const Text('ကိုယ့်ဝါကျ တည်ဆောက်မယ်'),
              ),
            ] else if (_step == 2 || _step == 5)
              _buildSentence()
            else if (_step == 3) ...[
              Text(
                'စာမကြည့်ဘဲ မေးခွန်းကို နားလည်နိုင်လား?',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              FilledButton.icon(
                onPressed: _busy ? null : _listen,
                icon: const Icon(Icons.headphones),
                label: Text(
                  _busy ? 'နားထောင်နေပါတယ်…' : 'မေးခွန်း နားထောင်မယ်',
                ),
              ),
              if (_reveal) Text(_phrase('intro_ask_name').thaiFor(_style)),
              TextButton(
                onPressed: _busy || _reveal
                    ? null
                    : () => setState(() {
                        _reveal = true;
                        _heard = false;
                      }),
                child: const Text('စာသား အကူအညီ ကြည့်မယ်'),
              ),
              if (_reveal)
                const Text(
                  'အကူအညီကြည့်ထားပါတယ်။ စာဖျောက်ပြီး နောက်တစ်ကြိမ် နားထောင်မှ အဖြေစစ်နိုင်ပါမယ်။',
                ),
              if (_reveal)
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                          _reveal = false;
                          _heard = false;
                        }),
                  child: const Text('စာဖျောက်ပြီး ပြန်စမ်းမယ်'),
                ),
              for (final option in _listeningOptions)
                OutlinedButton(
                  onPressed: !_heard || _reveal || _busy || _passed
                      ? null
                      : () => setState(() {
                          _passed = option == 'နာမည်ကို မေးတာ';
                          if (!_passed) _listeningMistakes++;
                          _feedback = _passed
                              ? 'မှန်ပါတယ်။ ชื่อ က နာမည်ကို ဆိုလိုပါတယ်။'
                              : 'ဒီမေးခွန်းမှာ ชื่อ ပါတယ်။ နာမည်မေးတဲ့ပုံစံကို ပြန်နားထောင်ကြည့်ပါ။';
                        }),
                  child: Text(option),
                ),
              if (_passed)
                FilledButton(
                  onPressed: _advance,
                  child: const Text('စကားဝိုင်း ဆက်မယ်'),
                ),
            ] else if (_step == 4) ...[
              Text(
                'နာမည်ပြီးရင် နိုင်ငံကို မေးလာမယ်',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              _audio('intro_from_city', 'တစ်ဖက်လူ'),
              _audio('intro_myanmar', 'မြန်မာနိုင်ငံကလာသူရဲ့ အဖြေ'),
              Text(
                '$_speaker + มาจาก + နိုင်ငံ + $_ending',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Text(
                'มาจาก က … ကလာတယ် ဆိုတဲ့ အဓိပ္ပာယ်ပါ။ နာမည်ပြောတဲ့ ชื่อ ပုံစံနဲ့ မတူပါ။',
              ),
              const Text(
                'နိုင်ငံအမည်: เมียนมา = မြန်မာနိုင်ငံ၊ ประเทศไทย = ထိုင်းနိုင်ငံ။ နိုင်ငံနေရာကို ပြောင်းထည့်ပြီး ပြောကြည့်ပါ။',
              ),
              _audio('intro_nice_to_meet', 'တွေ့ရတာ ဝမ်းသာကြောင်း ပြောမယ်'),
              FilledButton(
                onPressed: _advance,
                child: const Text('အကူအညီမပါဘဲ ပြန်ဖြေမယ်'),
              ),
            ] else ...[
              Text(
                _submitted
                    ? 'မိတ်ဆက်လေ့ကျင့်မှု ပြီးပါပြီ'
                    : 'နောက်ဆုံး ကိုယ်တိုင် ပြောကြည့်မယ်',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text([_speaker, 'ชื่อ', _name.text.trim(), _ending].join()),
              Text(_phrase('intro_myanmar').thaiFor(_style)),
              Text(_phrase('intro_ask_name').thaiFor(_style)),
              const Text(
                'ကိုယ့်နာမည်နဲ့ မိတ်ဆက်ပါ။ ဘယ်ကလာလဲ ဖြေပါ။ ပြီးရင် တစ်ဖက်လူနာမည်ကို ပြန်မေးပါ။ အပေါ်ကစာကို မကြည့်ဘဲ တစ်ကြိမ် ထပ်ပြောကြည့်ပါ။',
              ),
              const Text(
                'ဒီအဆင့်က ကိုယ်တိုင်ပြောလေ့ကျင့်မှုပါ။ အသံထွက်မှန်ကန်ကြောင်း သို့မဟုတ် တကယ်ပြောတတ်ပြီးကြောင်း အလိုအလျောက် မစစ်ထားပါ။',
              ),
              if (!_submitted)
                FilledButton(
                  onPressed: _busy ? null : _finish,
                  child: const Text('လေ့ကျင့်ပြီးကြောင်း သိမ်းမယ်'),
                ),
              if (_submitted) ...[
                const Text(
                  'နာမည်မေးသံ နားလည်မှုကို မှတ်တမ်းတင်ထားပါတယ်။ ဒီသင်ခန်းစာကို နောက်နေ့ ပြန်စမ်းကြည့်ပါ။',
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('သင်ယူမှုဆီ ပြန်မယ်'),
                ),
              ],
            ],
            if (_feedback != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  _feedback!,
                  key: const ValueKey('practical-feedback'),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
