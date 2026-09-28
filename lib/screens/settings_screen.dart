import 'package:flutter/material.dart';

import '../services/app_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({required this.appState, super.key});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ဆက်တင်များ')),
      body: AnimatedBuilder(
        animation: appState,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('အသွင်အပြင်', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.dark_mode_outlined),
                    title: const Text('အမှောင်ပုံစံ'),
                    subtitle: const Text('ဖွင့်ထားလျှင် အမှောင်အရောင်သုံးမည်'),
                    value: appState.themePreference == 'dark',
                    onChanged: (enabled) =>
                        appState.setThemePreference(enabled ? 'dark' : 'light'),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: TextButton.icon(
                        onPressed: () => appState.setThemePreference('system'),
                        icon: const Icon(Icons.settings_suggest_outlined),
                        label: const Text('စက်ရဲ့ ဆက်တင်အတိုင်း'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'ထိုင်းလို ယဉ်ကျေးစကားအဆုံးသတ်',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Wrap(
                  spacing: 9,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('အမျိုးသမီး (ค่ะ)'),
                      selected: appState.politeStyle == 'female',
                      onSelected: (_) => appState.setPoliteStyle('female'),
                    ),
                    ChoiceChip(
                      label: const Text('အမျိုးသား (ครับ)'),
                      selected: appState.politeStyle == 'male',
                      onSelected: (_) => appState.setPoliteStyle('male'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'အသုံးပြုမှုနဲ့ ကိုယ်ရေးအချက်အလက်',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'သင်ခန်းစာ၊ ရှာဖွေမှု၊ စကားစုသိမ်းခြင်းနဲ့ လေ့လာမှုမှတ်တမ်းတွေကို ဒီစက်ထဲမှာသာ သိမ်းပါတယ်။ V1 မှာ အကောင့်ဖွင့်စရာမလိုပါ။ Web Preview မှာလည်း browser ရဲ့ local storage ကို သုံးပါတယ်။\n\nထိုင်းစာကြောင်းတွေကို နေ့စဉ်ဆက်သွယ်ရေးအတွက် ပြင်ဆင်ထားပါတယ်။ ကျန်းမာရေး၊ ဥပဒေ၊ အလုပ်စာချုပ်လို အရေးကြီးကိစ္စတွေမှာ စကားပြန် သို့မဟုတ် ကျွမ်းကျင်သူနဲ့ အတည်ပြုပါ။',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'သင်ခန်းစာစကားစု ${appState.learned.length} ခု • Quiz ${appState.quizCount} ကြိမ်',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
