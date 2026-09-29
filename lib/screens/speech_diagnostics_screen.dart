import 'dart:async';

import 'package:flutter/material.dart';

import '../services/speech_service.dart';

/// Explicitly hidden diagnostics for reproducing device/browser TTS behavior.
/// Open only with `?tts-debug=1`; nothing is sent off the device.
class SpeechDiagnosticsScreen extends StatefulWidget {
  const SpeechDiagnosticsScreen({required this.speechService, super.key});

  final SpeechService speechService;

  @override
  State<SpeechDiagnosticsScreen> createState() =>
      _SpeechDiagnosticsScreenState();
}

class _SpeechDiagnosticsScreenState extends State<SpeechDiagnosticsScreen> {
  bool _busy = false;
  String _testResult = 'မစမ်းရသေးပါ';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_refresh()));
  }

  Future<void> _refresh() async {
    setState(() => _busy = true);
    await widget.speechService.refreshDiagnostics();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _testSpeech() async {
    setState(() {
      _busy = true;
      _testResult = 'စမ်းသပ်နေသည်';
    });
    final result = await widget.speechService.speakThai('สวัสดีค่ะ');
    if (mounted) {
      setState(() {
        _testResult = result == SpeechResult.spoken
            ? 'ထိုင်းအသံ စတင်ပြီး ပြီးဆုံးသည်'
            : 'ထိုင်းအသံ မဖွင့်နိုင်ပါ';
        _busy = false;
      });
    }
  }

  Future<void> _stopSpeech() async {
    await widget.speechService.stop();
    if (mounted) setState(() => _testResult = 'ရပ်ထားသည်');
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.speechService.diagnosticSnapshot;
    final thaiVoices =
        snapshot['thaiVoices'] as List<Map<String, String>>? ??
        const <Map<String, String>>[];
    return Scaffold(
      appBar: AppBar(title: const Text('Thai TTS diagnostics')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'ဒီစာမျက်နှာကို ?tts-debug=1 ဖြင့်သာ ဖွင့်နိုင်သည်။ အချက်အလက်များကို စက်ထဲတွင်သာ စစ်ဆေးပြီး မည်သည့်နေရာသို့မျှ မပို့ပါ။',
          ),
          const SizedBox(height: 16),
          _DiagnosticRow('Browser', snapshot['browser']),
          _DiagnosticRow('Platform', snapshot['platform']),
          _DiagnosticRow(
            'Speech API ရှိ/မရှိ',
            snapshot['speechSynthesisAvailable'],
          ),
          _DiagnosticRow(
            'Voice list ဖတ်ပြီး/မပြီး',
            snapshot['voiceListLoaded'],
          ),
          _DiagnosticRow('အစက voice အရေအတွက်', snapshot['initialVoiceCount']),
          _DiagnosticRow('နောက်ဆုံး voice အရေအတွက်', snapshot['voiceCount']),
          _DiagnosticRow(
            'voiceschanged events',
            snapshot['voicesChangedEvents'],
          ),
          _DiagnosticRow(
            'ရွေးထားသော Thai voice',
            snapshot['selectedThaiVoice'],
          ),
          _DiagnosticRow('နောက်ဆုံးရလဒ် / အကြောင်းရင်း', _testResult),
          _DiagnosticRow('နောက်ဆုံးစစ်ဆေးမှု', snapshot['lastFailureReason']),
          _DiagnosticRow(
            'Voice ရှာချိန် (ms)',
            snapshot['voiceLookupMilliseconds'],
          ),
          _DiagnosticRow('Browser API error', snapshot['engineError']),
          const SizedBox(height: 8),
          Text(
            'တွေ့ရှိသော Thai voice (${thaiVoices.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (thaiVoices.isEmpty)
            const ListTile(title: Text('Thai voice မတွေ့ပါ'))
          else
            ...thaiVoices.map(
              (voice) => ListTile(
                dense: true,
                title: Text(voice['name'] ?? ''),
                subtitle: Text(voice['locale'] ?? ''),
              ),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _busy ? null : _refresh,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Voice list ပြန်စစ်ရန်'),
              ),
              FilledButton.icon(
                onPressed: _busy ? null : _testSpeech,
                icon: const Icon(Icons.volume_up_rounded),
                label: const Text('ထိုင်းအသံ စမ်းရန်'),
              ),
              OutlinedButton.icon(
                onPressed: _stopSpeech,
                icon: const Icon(Icons.stop_rounded),
                label: const Text('ရပ်ရန်'),
              ),
            ],
          ),
          if (_busy) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
        ],
      ),
    );
  }
}

class _DiagnosticRow extends StatelessWidget {
  const _DiagnosticRow(this.label, this.value);

  final String label;
  final Object? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: SelectableText('$label: ${value ?? 'မသိရသေးပါ'}'),
    );
  }
}
