import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../learning/course_catalog.dart';
import '../learning/review_card.dart';
import '../services/app_state.dart';
import '../services/thai_playback_service.dart';

class CourseLessonScreen extends StatefulWidget {
  const CourseLessonScreen({
    required this.course,
    required this.unit,
    required this.lesson,
    required this.appState,
    required this.playbackService,
    super.key,
  });
  final CourseCatalog course;
  final CourseUnit unit;
  final CourseLesson lesson;
  final AppState appState;
  final ThaiPlaybackService playbackService;
  @override
  State<CourseLessonScreen> createState() => _CourseLessonScreenState();
}

class _CourseLessonScreenState extends State<CourseLessonScreen> {
  late final String _style;
  late final List<Map<String, dynamic>> _steps;
  int _index = 0, _generation = 0, _attempts = 0, _replays = 0;
  bool _heard = false,
      _busy = false,
      _text = false,
      _hint = false,
      _answered = false,
      _correct = false,
      _finished = false,
      _memoryRecorded = false;
  bool _showThai = false;
  bool _moving = false;
  final _name = TextEditingController();
  String? _selected;
  String? _feedback;
  List<CourseLine> _options = [];
  List<int> _order = [], _selectedParts = [];
  Map<String, dynamic> get _step => _steps[_index];
  CourseLine? get _line => widget.course.lines[_step['line']];
  String get _kind => _step['kind'] as String;
  String get _lessonId => widget.lesson.id;

  @override
  void initState() {
    super.initState();
    _style = widget.appState.politeStyle;
    final now = DateTime.now();
    final due =
        widget.appState.learning.course.memory.entries
            .where(
              (e) =>
                  e.value.isDue(now) && widget.course.lines.containsKey(e.key),
            )
            .toList()
          ..sort((a, b) => a.value.due.compareTo(b.value.due));
    // Stable base steps retain resume positions; review is inserted only on a fresh run.
    final cursor = widget.appState.learning.course.cursors[_lessonId] ?? 0;
    _steps = [
      if (cursor == 0)
        ...due
            .take(2)
            .map(
              (e) => <String, dynamic>{
                'kind': 'choice',
                'line': e.key,
                'review': true,
              },
            ),
      ...widget.lesson.steps,
    ];
    _index = min(cursor, _steps.length - 1);
    _prepare();
  }

  Set<String> _known() {
    final ids = <String>{};
    for (final u in widget.course.units) {
      for (final lesson in u.lessons) {
        if (lesson.id == _lessonId ||
            widget.appState.learning.course.completed.containsKey(lesson.id)) {
          final steps = lesson.id == _lessonId
              ? _steps.take(_index + 1)
              : lesson.steps;
          for (final s in steps) {
            if (s['kind'] == 'teach' || s['kind'] == 'notice') {
              if (s['line'] is String) ids.add(s['line'] as String);
            }
          }
        }
      }
    }
    return ids;
  }

  void _prepare() {
    _generation++;
    _attempts = 0;
    _replays = 0;
    _heard = false;
    _busy = false;
    _text = false;
    _hint = false;
    _answered = false;
    _correct = false;
    _memoryRecorded = false;
    _selected = null;
    _feedback = null;
    _selectedParts = [];
    final line = _line;
    if (line != null) {
      final unit = widget.course.units.firstWhere(
        (u) => u.models.contains(line.id),
        orElse: () => widget.unit,
      );
      final known = _known()..add(line.id);
      _options =
          widget.course
              .choices(unit, line)
              .where((v) => known.contains(v.id))
              .toList()
            ..shuffle();
      _order = List.generate(line.parts(_style).length, (i) => i)..shuffle();
    }
  }

  Future<void> _play(CourseLine line) async {
    if (_busy ||
        widget.appState.audioVolume == 0 ||
        !widget.playbackService.hasBundledAudio(line.phrase(_style), _style)) {
      return;
    }
    final generation = _generation;
    setState(() => _busy = true);
    await widget.playbackService.setVolume(widget.appState.audioVolume);
    if (!mounted || generation != _generation) return;
    final result = await widget.playbackService.playThai(
      line.phrase(_style),
      _style,
    );
    if (!mounted || generation != _generation) return;
    setState(() {
      _busy = false;
      if (result == ThaiPlaybackResult.audioAsset) {
        _heard = true;
        _replays++;
      } else {
        _feedback = 'အသံမရသေးပါ။ စာသားနဲ့ ဆက်လေ့ကျင့်နိုင်ပါတယ်။';
      }
    });
  }

  void _check() {
    if (_answered || _line == null) return;
    if (_kind == 'choice' && (_selected == null || (!_heard && !_text))) return;
    final parts = _line!.parts(_style);
    if (_kind == 'build' && _selectedParts.length != parts.length) return;
    final correct = _kind == 'build'
        ? List.generate(parts.length, (i) => i).join(',') ==
              _selectedParts.join(',')
        : _selected == _line!.id;
    _attempts++;
    widget.appState.learning.course.event({
      'lesson': _lessonId,
      'line': _line!.id,
      'kind': _kind,
      'at': DateTime.now().toUtc().toIso8601String(),
      'correct': correct,
      'firstAttempt': _attempts == 1,
      'attempt': _attempts,
      'assisted': _hint || _text,
      'listened': _heard && !_text,
      'replays': _replays,
    });
    if (_kind == 'choice' && _heard && !_text && !_hint && !_memoryRecorded) {
      final memory = widget.appState.learning.course.memory;
      memory[_line!.id] =
          (memory[_line!.id] ?? ReviewCard.initial(DateTime.now())).review(
            correct ? 4 : 2,
            DateTime.now(),
          );
      _memoryRecorded = true;
    }
    unawaited(widget.appState.saveCourse());
    setState(() {
      _answered = true;
      _correct = correct;
      _feedback = correct
          ? (_text ? 'စာသားလေ့ကျင့်မှု မှန်ပါတယ်။' : 'မှန်ပါတယ်။')
          : 'မကိုက်သေးပါ။ အပိုင်းတွေကို ပြန်ကြည့်ပြီး စမ်းပါ။';
    });
  }

  Future<void> _next() async {
    if (_busy || _moving || _finished) return;
    _moving = true;
    unawaited(widget.playbackService.stop());
    if (_index + 1 == _steps.length) {
      widget.appState.learning.course.finish(_lessonId, DateTime.now());
      await widget.appState.saveCourse();
      if (mounted) {
        setState(() {
          _finished = true;
          _moving = false;
          _generation++;
        });
      }
      return;
    }
    // Persist the base-step position, not the temporary inserted-review offset.
    final reviewCount = _steps.where((s) => s['review'] == true).length;
    widget.appState.learning.course.cursors[_lessonId] = max(
      0,
      _index + 1 - reviewCount,
    );
    await widget.appState.saveCourse();
    if (mounted) {
      setState(() {
        _moving = false;
        _index++;
        _prepare();
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _generation++;
    unawaited(widget.playbackService.stop());
    super.dispose();
  }

  Widget _audio(CourseLine line) {
    final ready = widget.playbackService.hasBundledAudio(
      line.phrase(_style),
      _style,
    );
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        FilledButton.tonalIcon(
          key: ValueKey('course-audio-${line.id}'),
          onPressed: !ready || _busy || widget.appState.audioVolume == 0
              ? null
              : () => _play(line),
          icon: Icon(_busy ? Icons.hourglass_top : Icons.volume_up_rounded),
          label: Text(ready ? 'နားထောင်မယ်' : 'အသံထည့်ရန် ကျန်'),
        ),
        if (widget.appState.audioVolume == 0)
          const Text('ဆက်တင်မှာ အသံအတိုးအကျယ် မြှင့်ပါ။'),
      ],
    );
  }

  Widget _lineCard(CourseLine line, {bool partsOnly = false}) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(line.scene, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          if (!partsOnly) ...[
            Text(
              line.thai(_style),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            Text(line.myFor(_style), textAlign: TextAlign.center),
            const SizedBox(height: 14),
            _audio(line),
          ],
          if (line.parts(_style).isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text('စကားလုံးအပိုင်းတွေ'),
            const SizedBox(height: 6),
            for (final id in line.parts(_style))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${widget.course.lines[id]!.thai(_style)} · ${widget.course.lines[id]!.my}',
                      ),
                    ),
                    IconButton(
                      tooltip: 'အပိုင်းအသံ',
                      onPressed:
                          widget.playbackService.hasBundledAudio(
                                widget.course.lines[id]!.phrase(_style),
                                _style,
                              ) &&
                              !_busy
                          ? () => _play(widget.course.lines[id]!)
                          : null,
                      icon: const Icon(Icons.volume_up_outlined),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final line = _line;
    final interactive = _kind == 'choice' || _kind == 'build';
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title),
        actions: [
          IconButton(
            tooltip: 'ထိုင်းစာ ပြ/ဖျောက်',
            onPressed: () => setState(() {
              _showThai = !_showThai;
              if (_kind == 'choice' && _showThai) _hint = true;
            }),
            icon: const Icon(Icons.subtitles_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: _finished
                ? _summary()
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                        child: LinearProgressIndicator(
                          value: _index / _steps.length,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          '${_index + 1} / ${_steps.length}${_step['review'] == true ? ' · ပြန်လေ့ကျင့်' : ''}',
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          key: ValueKey('course-step-$_index'),
                          padding: const EdgeInsets.all(20),
                          children: [
                            if (_kind == 'teach' || _kind == 'notice') ...[
                              _lineCard(line!, partsOnly: _kind == 'notice'),
                              const SizedBox(height: 12),
                              Text(widget.unit.tips),
                            ],
                            if (_kind == 'dialogue') ...[
                              Text(
                                'အလှည့်ကျ နားထောင်၊ ပြောကြည့်ပါ',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              for (final id in List<String>.from(
                                _step['lines'] as List,
                              ))
                                _lineCard(widget.course.lines[id]!),
                              const Text(
                                'ကိုယ်တိုင် ပြောကြည့်ခြင်းဖြစ်ပြီး အသံထွက်ကို အလိုအလျောက် စစ်မထားပါ။',
                              ),
                            ],
                            if (_kind == 'reflect') ...[
                              const Icon(
                                Icons.record_voice_over_rounded,
                                size: 56,
                              ),
                              const SizedBox(height: 18),
                              Text(
                                widget.unit.goal,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'နမူနာမကြည့်ဘဲ ကိုယ်တိုင် ပြောကြည့်ပါ။ ပြောကြည့်ပြီးတာကို မှတ်သားနိုင်ပေမယ့် အသံထွက်မှန်ကြောင်း အမှတ်မပေးပါ။',
                              ),
                              if (widget.unit.id == 'u01') ...[
                                const SizedBox(height: 18),
                                TextField(
                                  controller: _name,
                                  maxLength: 60,
                                  key: const ValueKey('course-own-name'),
                                  onChanged: (_) => setState(() {}),
                                  decoration: const InputDecoration(
                                    labelText: 'ကိုယ့်နာမည်နဲ့ ပြောကြည့်မယ်',
                                    helperText:
                                        'နာမည်ကို စက်ထဲမှာသာ သုံးပါတယ်။',
                                  ),
                                ),
                                if (_name.text.trim().isNotEmpty)
                                  Text(
                                    '${_style == 'male' ? 'ผม' : 'ฉัน'}ชื่อ ${_name.text.trim()} ${_style == 'male' ? 'ครับ' : 'ค่ะ'}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                const Text(
                                  'ကိုယ့်နာမည်ကို ကိုယ်တိုင်ပြောပါ။ နမူနာနာမည်အသံနဲ့ အစားမထိုးပါ။',
                                ),
                              ],
                            ],
                            if (_kind == 'choice') ...[
                              Text(
                                _text
                                    ? line!.scene
                                    : 'နားထောင်ပြီး မြန်မာအဓိပ္ပာယ် ရွေးပါ',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 18),
                              _audio(line!),
                              if (!_text)
                                TextButton(
                                  key: const ValueKey('course-text-mode'),
                                  onPressed: () => setState(() {
                                    _text = true;
                                    _hint = true;
                                  }),
                                  child: const Text('စာသားနဲ့ ဆက်လေ့ကျင့်မယ်'),
                                ),
                              if (_text)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    'စာသားလေ့ကျင့်မှု · နားထောင်စစ်ဆေးမှုအဖြစ် မတွက်ပါ။',
                                  ),
                                ),
                              if (_showThai || _answered)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  child: Text(
                                    line.thai(_style),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineSmall,
                                  ),
                                ),
                              for (final option in _options)
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: OutlinedButton(
                                    key: ValueKey('course-option-${option.id}'),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: _selected == option.id
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primaryContainer
                                          : null,
                                      padding: const EdgeInsets.all(18),
                                    ),
                                    onPressed: _answered || (!_heard && !_text)
                                        ? null
                                        : () => setState(
                                            () => _selected = option.id,
                                          ),
                                    child: Text(option.myFor(_style)),
                                  ),
                                ),
                            ],
                            if (_kind == 'build') ...[
                              Text(
                                'အပိုင်းတွေကို တွဲသုံးကြည့်ပါ',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 10),
                              Text(line!.myFor(_style)),
                              const SizedBox(height: 18),
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      if (_selectedParts.isEmpty)
                                        const Text('ဒီနေရာမှာ ဝါကျဖွဲ့မယ်'),
                                      for (final i in _selectedParts)
                                        InputChip(
                                          label: Text(
                                            _showThai
                                                ? widget
                                                      .course
                                                      .lines[line.parts(
                                                        _style,
                                                      )[i]]!
                                                      .thai(_style)
                                                : widget
                                                      .course
                                                      .lines[line.parts(
                                                        _style,
                                                      )[i]]!
                                                      .my,
                                          ),
                                          onDeleted: _answered
                                              ? null
                                              : () => setState(
                                                  () =>
                                                      _selectedParts.remove(i),
                                                ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final i in _order)
                                    ActionChip(
                                      key: ValueKey('course-part-$i'),
                                      label: Text(
                                        _showThai
                                            ? widget
                                                  .course
                                                  .lines[line.parts(_style)[i]]!
                                                  .thai(_style)
                                            : widget
                                                  .course
                                                  .lines[line.parts(_style)[i]]!
                                                  .my,
                                      ),
                                      onPressed:
                                          _answered ||
                                              _selectedParts.contains(i)
                                          ? null
                                          : () => setState(
                                              () => _selectedParts.add(i),
                                            ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'အကူအညီနဲ့ ဝါကျဖွဲ့ခြင်းပါ။ ကိုယ်တိုင်လွတ်လပ်စွာ ပြောနိုင်မှုကို မစစ်ရသေးပါ။',
                              ),
                              if (_answered) ...[
                                const SizedBox(height: 16),
                                _lineCard(line),
                              ],
                            ],
                            if (_feedback != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 18),
                                child: Text(
                                  _feedback!,
                                  style: TextStyle(
                                    color: _correct
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            key: const ValueKey('course-primary'),
                            onPressed: _busy
                                ? null
                                : interactive && !_answered
                                ? ((_kind == 'choice' &&
                                              (_selected == null ||
                                                  (!_heard && !_text))) ||
                                          (_kind == 'build' &&
                                              _selectedParts.length !=
                                                  line!.parts(_style).length)
                                      ? null
                                      : _check)
                                : _answered && !_correct
                                ? () => setState(() {
                                    _answered = false;
                                    _selected = null;
                                    _selectedParts = [];
                                    _feedback = null;
                                    _hint = true;
                                  })
                                : _next,
                            child: Text(
                              interactive && !_answered
                                  ? 'အဖြေစစ်မယ်'
                                  : _answered && !_correct
                                  ? 'ပြန်စမ်းမယ်'
                                  : _index + 1 == _steps.length
                                  ? 'လေ့ကျင့်မှု သိမ်းမယ်'
                                  : 'ဆက်သွားမယ်',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _summary() => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      const Icon(Icons.task_alt_rounded, size: 72),
      const SizedBox(height: 20),
      Text(
        'ဒီ lesson လေ့ကျင့်ပြီးပါပြီ',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 16),
      Text(widget.unit.goal, textAlign: TextAlign.center),
      const SizedBox(height: 14),
      const Text(
        'လေ့ကျင့်မှုကို သိမ်းထားပါတယ်။ အသံမစုံသေးတဲ့အပိုင်းတွေရဲ့ နားထောင်စစ်ဆေးမှုကို နောက်မှ ပြန်လုပ်နိုင်ပါတယ်။ စကားပြောကျွမ်းကျင်မှု အတည်ပြုချက် မဟုတ်ပါ။',
      ),
      const SizedBox(height: 24),
      FilledButton(
        key: const ValueKey('course-done'),
        onPressed: () => Navigator.pop(context),
        child: const Text('လမ်းကြောင်းကို ပြန်သွားမယ်'),
      ),
    ],
  );
}
