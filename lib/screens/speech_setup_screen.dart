import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/phrase_repository.dart';
import '../services/app_state.dart';
import '../services/thai_playback_service.dart';

class SpeechSetupScreen extends StatefulWidget {
  const SpeechSetupScreen({
    required this.repository,
    required this.appState,
    required this.playbackService,
    super.key,
  });

  final PhraseRepository repository;
  final AppState appState;
  final ThaiPlaybackService playbackService;

  @override
  State<SpeechSetupScreen> createState() => _SpeechSetupScreenState();
}

class _SpeechSetupScreenState extends State<SpeechSetupScreen> {
  bool _busy = false;
  String _result = 'စမ်းသပ်မထားသေးပါ။';

  Future<void> _test() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _result = 'ထိုင်းအသံ စမ်းသပ်နေသည်…';
    });
    await widget.playbackService.setVolume(widget.appState.audioVolume);
    if (!mounted) return;
    final sample = widget.repository.phrases.firstWhere(
      (phrase) => phrase.id == 'greet_hello',
    );
    final result = await widget.playbackService.playThai(
      sample,
      widget.appState.politeStyle,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _result = switch (result) {
        ThaiPlaybackResult.spoken || ThaiPlaybackResult.audioAsset =>
          'ထိုင်းအသံ စမ်းသပ်ပြီးပါပြီ။ သင်ကြားရတဲ့အသံကိုလည်း စစ်ကြည့်ပါ။',
        ThaiPlaybackResult.cancelled => 'စမ်းသပ်မှု ရပ်သွားပါတယ်။',
        ThaiPlaybackResult.unavailable =>
          'ဒီစက်/ဘရောက်ဇာမှာ ထိုင်းအသံ မရရှိသေးပါ။ အောက်ကနည်းအတိုင်း စစ်ပြီး ပြန်စမ်းပါ။',
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final platform = defaultTargetPlatform;
    final instructions = kIsWeb
        ? 'ဘရောက်ဇာနှင့် စက်ရဲ့ Text-to-speech ထဲမှာ Thai (ไทย) အသံကို စစ်ပါ။ စက်မှာ voice ထည့်ပြီးရင် ဘရောက်ဇာကို ပြန်ဖွင့်ကာ ဒီခလုတ်ကို ထပ်နှိပ်ပါ။'
        : platform == TargetPlatform.android
        ? 'ဖုန်း Settings မှာ “Text-to-speech” ကို ရှာပါ။ သုံးနေတဲ့ speech engine ထဲမှာ Thai (ไทย) voice ရှိမရှိ စစ်ပြီး လိုအပ်ရင် download လုပ်ပါ။ ပြီးရင် ဒီနေရာမှာ ပြန်စမ်းပါ။ ဖုန်းအမျိုးအစားအလိုက် menu နာမည် ကွာနိုင်ပါတယ်။'
        : 'စက်ရဲ့ Settings ထဲက Speech / Spoken Content မှာ Thai (ไทย) voice ရှိမရှိ စစ်ပါ။ ပြီးရင် app ကို ပြန်ဖွင့်ပြီး ထပ်စမ်းပါ။';
    return Scaffold(
      appBar: AppBar(title: const Text('ထိုင်းအသံ စမ်းရန်')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('“မင်္ဂလာပါ” ကို ထိုင်းလို အသံထွက် စမ်းဖတ်ပါမယ်။ စက်ရဲ့ volume ကို ဖွင့်ထားပါ။'),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _test,
            icon: const Icon(Icons.volume_up_rounded),
            label: Text(_busy ? 'စမ်းသပ်နေသည်…' : 'ထိုင်းအသံ စမ်းရန်'),
          ),
          const SizedBox(height: 12),
          Text(_result, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 24),
          Text('အသံမထွက်ရင်', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(instructions),
          const SizedBox(height: 12),
          const Text('Thai voice ရှိတယ်ဆိုရင်တောင် အသံအရည်အသွေးက ဖုန်းနဲ့ voice engine အလိုက် ကွာနိုင်ပါတယ်။ အသံမရှိသေးရင် စကားစုစာသားကို ပြနိုင်ပါတယ်။'),
        ],
      ),
    );
  }
}
