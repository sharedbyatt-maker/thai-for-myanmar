import 'dart:async';

import 'package:flutter/material.dart';

import '../services/league_service.dart';
import '../widgets/content_frame.dart';

class LeagueScreen extends StatefulWidget {
  const LeagueScreen({this.gateway, this.active = true, super.key});
  final LeagueGateway? gateway;
  final bool active;
  @override
  State<LeagueScreen> createState() => _LeagueScreenState();
}

class _LeagueScreenState extends State<LeagueScreen> {
  late final LeagueGateway _api = widget.gateway ?? LeagueService.instance;
  final _alias = TextEditingController();
  bool _loading = true;
  bool _ready = false;
  String? _message;
  Map<String, dynamic>? _board;
  int _avatar = 0;
  Timer? _poll;
  StreamSubscription<bool>? _authSubscription;
  bool _authReloadPending = false;
  final _boardAge = Stopwatch();
  static const _avatars = ['🐘', '🌱', '🐱', '🦊', '🐻', '🐼', '🐯', '🐨'];
  static const _tiers = [
    '🥉 Bronze',
    '🥈 Silver',
    '🥇 Gold',
    '💎 Diamond',
    '🐘 Elephant',
  ];
  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted && widget.active && !_loading && _ready && _api.signedIn) {
        _load();
      }
    });
  }

  @override
  void didUpdateWidget(covariant LeagueScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active && !_loading) _load();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _authSubscription?.cancel();
    _alias.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await _run(() async {
      _ready = await _api.initialize();
      if (!mounted) return;
      if (_ready) {
        _authSubscription ??= _api.authChanges.listen(
          (_) {
            if (!mounted) return;
            // Supabase auth callbacks must not await other Auth/RPC requests.
            _authReloadPending = true;
            if (!_loading) unawaited(_load());
          },
          onError: (Object _) {
            if (mounted) {
              setState(() {
                _board = null;
                _message = 'Account ဝင်မရသေးပါ။ ပြန်စမ်းပါ။';
              });
            }
          },
        );
      }
      _authReloadPending = false;
      _board = null;
      if (_ready && _api.signedIn) {
        _board = await _api.board();
        _boardAge.reset();
        _boardAge.start();
      }
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      await action();
    } catch (_) {
      _message =
          'ချိတ်ဆက်မှု သို့မဟုတ် ထည့်ထားသောအချက်အလက်ကို စစ်ပြီး ပြန်စမ်းပါ။';
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        if (_authReloadPending) unawaited(_load());
      }
    }
  }

  Future<void> _authenticate() => _run(() async {
    final launched = await _api.signInWithGoogle();
    if (!launched) {
      _message = 'Google ဖွင့်မရသေးပါ။ ပြန်စမ်းပါ။';
    }
  });
  Future<void> _practice() async {
    await _run(() async {
      final round = await _api.beginRound();
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => LeagueRoundScreen(gateway: _api, round: round),
        ),
      );
      if (mounted) _board = await _api.board();
    });
  }

  Widget _rules() => const ExpansionTile(
    title: Text('အမှတ်နဲ့ League စည်းမျဉ်း'),
    children: [
      Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'ဒီ League စမ်းသပ်မှုမှာ server က စစ်ပြီးမှ အမှတ်ပေးပါတယ်။ အဖြေမှန် စကားစုတစ်ခု 5 မှတ်၊ တစ်နေ့တစ်ကြိမ်သာ။ သင်ခန်းစာတစ်ခုလုံး မှန်ရင် ပထမဆုံးအကြိမ် 20 မှတ် ထပ်ရမယ်။ တစ်နေ့ စုစုပေါင်း 100 မှတ်အထိသာ ရနိုင်ပါတယ်။ ကိုယ်ပိုင် XP နဲ့ သီးခြားပါ။\n\nထိုင်းအချိန် တနင်္လာ 00:00 မှ အပတ်သစ်စပါတယ်။ အုပ်စုတစ်ခု လူ ၂၀ အထိ။ အမှတ်တူရင် အဲဒီအမှတ်ကို အရင်ရသူက အပေါ်မှာပါ။ အမှတ်ရသူ ၅ ယောက်နဲ့အထက်ရှိတဲ့ အုပ်စုမှာ ထိပ်ဆုံး 25% က နောက် League တက်မယ်။ အစပိုင်းမှာ အဆင့်မချပါ။ တကယ့်ပါဝင်သူတွေကိုပဲ ပြပါတယ်။',
        ),
      ),
    ],
  );
  @override
  Widget build(BuildContext context) {
    final rows = (_board?['rows'] as List? ?? []).cast<Map>();
    final daily = (_board?['daily_points'] as num? ?? 0).toInt();
    return Scaffold(
      appBar: AppBar(
        title: const Text('အပတ်စဉ် League'),
        actions: [
          IconButton(
            tooltip: 'ပြန်စစ်ရန်',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ContentFrame(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (_loading) const LinearProgressIndicator(),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(_message!, key: const ValueKey('league-message')),
              ),
            if (!_loading && !_ready) ...[
              const Icon(Icons.cloud_off_rounded, size: 56),
              const Text(
                'League ကို ဖွင့်ရန် ပြင်ဆင်နေပါတယ်။',
                textAlign: TextAlign.center,
              ),
              const Text(
                'ဒီအချိန်မှာ သင်ခန်းစာနဲ့ ကိုယ်ပိုင် Rank ကို ဆက်သုံးနိုင်ပါတယ်။',
                textAlign: TextAlign.center,
              ),
            ] else if (_ready && !_api.signedIn) ...[
              const Icon(Icons.emoji_events_rounded, size: 64),
              Text(
                'အတူ လေ့ကျင့်ကြမယ်',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Text(
                'ပါဝင်ချင်မှ account ဝင်ပါ။ ဇယားမှာ နာမည်ပြောင်နဲ့ avatar ပဲ ပြပါမယ်။',
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                key: const ValueKey('league-google-sign-in'),
                onPressed: _loading ? null : _authenticate,
                icon: const Icon(Icons.login_rounded),
                label: const Text('Google နဲ့ ဝင်မယ်'),
              ),
              _rules(),
            ] else if (_ready &&
                _api.signedIn &&
                _board?['joined'] != true) ...[
              Text(
                'ဇယားမှာ ပါဝင်မယ်',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _alias,
                maxLength: 24,
                decoration: const InputDecoration(labelText: 'နာမည်ပြောင်'),
              ),
              Wrap(
                spacing: 8,
                children: List.generate(
                  _avatars.length,
                  (i) => ChoiceChip(
                    label: Text(_avatars[i]),
                    selected: i == _avatar,
                    onSelected: _loading
                        ? null
                        : (_) => setState(() => _avatar = i),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loading
                    ? null
                    : () => _run(() async {
                        if (_alias.text.trim().length < 2) {
                          _message = 'နာမည်ပြောင် အနည်းဆုံး ၂ လုံး ထည့်ပါ။';
                          return;
                        }
                        await _api.join(_alias.text, _avatar);
                        _board = await _api.board();
                      }),
                child: const Text('ဒီနာမည်နဲ့ ပါဝင်မယ်'),
              ),
              _rules(),
              TextButton(
                onPressed: _loading
                    ? null
                    : () => _run(() async {
                        await _api.signOut();
                        _board = null;
                      }),
                child: const Text('Account ထွက်မယ်'),
              ),
            ] else if (_ready && _board?['joined'] == true) ...[
              _overview(context, rows, daily),
              const SizedBox(height: 18),
              if (rows.where((row) => (row['points'] as num) > 0).length < 5)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'အမှတ်ရသူ ၅ ယောက် ပြည့်ရင် အဆင့်တက်ဇုန် ဖွင့်ပါမယ်။',
                  ),
                ),
              ..._standings(context, rows),
              const SizedBox(height: 16),
              Text('ဒီနေ့ $daily / 100 မှတ်'),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _loading || daily >= 100 ? null : _practice,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(
                  daily >= 100
                      ? 'မနက်ဖြန် ပြန်လေ့ကျင့်မယ်'
                      : 'အမှတ်ရအောင် လေ့ကျင့်မယ်',
                ),
              ),
              _rules(),
              TextButton(
                onPressed: _loading
                    ? null
                    : () => _run(() async {
                        await _api.leave();
                        _board = await _api.board();
                      }),
                child: const Text('အဆင့်ဇယားမှ ထွက်မယ်'),
              ),
              TextButton(
                onPressed: _loading
                    ? null
                    : () => _run(() async {
                        await _api.signOut();
                        _board = null;
                      }),
                child: const Text('Account ထွက်မယ်'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _overview(BuildContext context, List<Map> rows, int daily) {
    final tier = (_board!['tier'] as num).toInt().clamp(0, 4);
    final mine = rows.where((r) => r['mine'] == true).firstOrNull;
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primaryContainer, colors.surfaceContainerLow],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Tooltip(
                  message: _tiers[i],
                  child: Semantics(
                    label: _tiers[i],
                    selected: i == tier,
                    child: _TierBadge(tier: i, selected: i == tier),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(_tiers[tier], style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('ဒီအပတ် · ${rows.length} / 20 ယောက်'),
          const SizedBox(height: 8),
          Text(
            '${_remaining()} · ထိုင်းအချိန်အရ',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _scoreMetric(context, '#${mine?['rank'] ?? '—'}', 'ကိုယ့်အဆင့်'),
              _scoreMetric(context, '${mine?['points'] ?? 0}', 'ဒီအပတ်'),
              _scoreMetric(context, '$daily/100', 'ဒီနေ့'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scoreMetric(BuildContext context, String value, String label) =>
      Expanded(
        child: Column(
          children: [
            Text(
              value,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      );

  List<Widget> _standings(BuildContext context, List<Map> rows) {
    final scorers = rows.where((r) => (r['points'] as num) > 0).length;
    final promoted = scorers >= 5 ? (scorers / 4).ceil() : 0;
    final colors = Theme.of(context).colorScheme;
    return [
      if (promoted > 0)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            '↑ အဆင့်တက်ဇုန် · ထိပ်ဆုံး $promoted ယောက်',
            style: TextStyle(
              color: colors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      for (var i = 0; i < rows.length; i++) ...[
        if (i == promoted && promoted > 0)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(),
          ),
        Card(
          color: rows[i]['mine'] == true ? colors.primaryContainer : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: i < promoted
                  ? const Color(0xFF27866E)
                  : colors.outlineVariant,
              width: i < promoted ? 2 : 1,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            leading: Text(
              '#${rows[i]['rank']}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            title: Text(
              '${_avatars[(rows[i]['avatar'] as num).toInt().clamp(0, 7)]} ${rows[i]['alias']}${rows[i]['mine'] == true ? ' · ကိုယ်' : ''}',
            ),
            subtitle: Text('${rows[i]['points']} မှတ်'),
            trailing: i < promoted
                ? const Icon(
                    Icons.arrow_upward_rounded,
                    color: Color(0xFF27866E),
                  )
                : null,
          ),
        ),
      ],
    ];
  }

  String _remaining() {
    final end = DateTime.parse(_board!['ends_at'] as String).toUtc();
    final now = _board!['server_now'] is String
        ? DateTime.parse(
            _board!['server_now'] as String,
          ).toUtc().add(_boardAge.elapsed)
        : DateTime.now().toUtc();
    final left = end.difference(now);
    if (left.isNegative) return 'အပတ်သစ်အတွက် ပြန်စစ်ပါ';
    return 'ကျန်ချိန် ${left.inDays} ရက် ${left.inHours % 24} နာရီ';
  }
}

class LeagueRoundScreen extends StatefulWidget {
  const LeagueRoundScreen({
    required this.gateway,
    required this.round,
    super.key,
  });
  final LeagueGateway gateway;
  final Map<String, dynamic> round;
  @override
  State<LeagueRoundScreen> createState() => _LeagueRoundScreenState();
}

class _LeagueRoundScreenState extends State<LeagueRoundScreen> {
  late final List<Map> _questions = (widget.round['questions'] as List)
      .cast<Map>();
  late final List<int> _choices = List.filled(_questions.length, -1);
  int _index = 0;
  bool _busy = false;
  String? _error;
  Map<String, dynamic>? _result;
  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await widget.gateway.submit(
        widget.round['id'] as String,
        _choices,
      );
      if (mounted) setState(() => _result = result);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'အမှတ်မသိမ်းရသေးပါ။ ခဏစောင့်ပြီး ပြန်စမ်းပါ။');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('League စမ်းသပ်မှု')),
    body: ContentFrame(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (_result != null) ...[
            const Icon(Icons.emoji_events_rounded, size: 72),
            Text(
              '+${_result!['earned']} မှတ်',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              '${_result!['correct']} / ${_result!['total']} မှန် · သင်ခန်းစာ bonus ${_result!['bonus']} မှတ်',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ...List.generate(_questions.length, (i) {
              final answer = (_result!['answers'] as List)[i] as Map;
              return ListTile(
                leading: Icon(
                  answer['correct'] == true
                      ? Icons.check_circle
                      : Icons.refresh,
                ),
                title: Text(_questions[i]['thai'] as String),
                subtitle: Text(
                  (_questions[i]['options'] as List)[answer['answer'] as int]
                      as String,
                ),
              );
            }),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('အဆင့်ဇယား ပြန်ကြည့်မယ်'),
            ),
          ] else ...[
            Text('${_index + 1} / ${_questions.length}'),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: (_index + 1) / _questions.length),
            const SizedBox(height: 32),
            Text(
              _questions[_index]['thai'] as String,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            ...List.generate(
              (_questions[_index]['options'] as List).length,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() => _choices[_index] = i),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: _choices[_index] == i
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                  ),
                  child: Text(
                    (_questions[_index]['options'] as List)[i] as String,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            if (_error != null) Text(_error!),
            FilledButton(
              onPressed: _busy || _choices[_index] < 0
                  ? null
                  : () {
                      if (_index + 1 < _questions.length) {
                        setState(() => _index++);
                      } else {
                        _submit();
                      }
                    },
              child: Text(
                _busy
                    ? 'သိမ်းနေပါတယ်…'
                    : _index + 1 < _questions.length
                    ? 'ဆက်မယ်'
                    : 'အမှတ်စစ်မယ်',
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _TierBadge extends StatelessWidget {
  const _TierBadge({required this.tier, required this.selected});
  final int tier;
  final bool selected;
  static const _colors = [
    Color(0xFFA65D33),
    Color(0xFF596C82),
    Color(0xFF9A6A00),
    Color(0xFF087C95),
    Color(0xFF6554CE),
  ];
  static const _icons = [
    Icons.shield_rounded,
    Icons.shield_outlined,
    Icons.workspace_premium_rounded,
    Icons.diamond_rounded,
    Icons.auto_awesome_rounded,
  ];
  @override
  Widget build(BuildContext context) => Container(
    width: 36,
    height: 42,
    decoration: BoxDecoration(
      color: selected ? _colors[tier] : Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _colors[tier], width: selected ? 3 : 1),
      boxShadow: selected
          ? [
              BoxShadow(
                color: _colors[tier].withValues(alpha: .25),
                offset: const Offset(0, 4),
              ),
            ]
          : [],
    ),
    child: Icon(
      _icons[tier],
      size: 22,
      color: selected ? Colors.white : _colors[tier],
    ),
  );
}
