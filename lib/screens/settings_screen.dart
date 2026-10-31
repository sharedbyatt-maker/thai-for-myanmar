import 'package:flutter/material.dart';

import '../widgets/content_frame.dart';

import '../services/app_state.dart';
import '../data/phrase_repository.dart';
import '../services/thai_playback_service.dart';
import 'phrase_issue_screen.dart';
import 'speech_setup_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    required this.appState,
    required this.repository,
    required this.playbackService,
    super.key,
  });

  final AppState appState;
  final PhraseRepository repository;
  final ThaiPlaybackService playbackService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ဆက်တင်များ')),
      body: ContentFrame(
        child: AnimatedBuilder(
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
                      subtitle: const Text(
                        'ဖွင့်ထားလျှင် အမှောင်အရောင်သုံးမည်',
                      ),
                      value: appState.themePreference == 'dark',
                      onChanged: (enabled) => appState.setThemePreference(
                        enabled ? 'dark' : 'light',
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: TextButton.icon(
                          onPressed: () =>
                              appState.setThemePreference('system'),
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
                'တစ်နေ့ သင်ယူမှုရည်မှန်းချက်',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [5, 10, 20]
                    .map(
                      (goal) => ChoiceChip(
                        label: Text('$goal ခု'),
                        selected: appState.learning.dailyGoal == goal,
                        onSelected: (_) => appState.setDailyGoal(goal),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              Text(
                'ထိုင်းအသံ အတိုးအကျယ်',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Slider(
                value: appState.audioVolume,
                divisions: 10,
                label: '${(appState.audioVolume * 100).round()}%',
                onChanged: appState.setAudioVolume,
              ),
              const Text(
                'နောက်ဖွင့်မယ့်အသံအတွက် သုံးမယ်။ စက်ရဲ့ အသံအတိုးအကျယ်ကိုလည်း စစ်ပါ။',
              ),
              ListTile(
                leading: const Icon(Icons.hearing_rounded),
                title: const Text('ထိုင်းအသံ စမ်းရန် / ပြင်ဆင်နည်း'),
                subtitle: const Text(
                  'စက်မှာ အသံထွက်မထွက် စစ်ပြီး Thai voice ထည့်နည်းကြည့်ရန်',
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => SpeechSetupScreen(
                      repository: repository,
                      appState: appState,
                      playbackService: playbackService,
                    ),
                  ),
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
              ListTile(
                leading: const Icon(Icons.report_outlined),
                title: const Text('သိမ်းထားသော အမှားထောက်ပြချက်များ'),
                subtitle: Text(
                  '${appState.phraseIssues.length} ခု • Copy လုပ်ပြီး developer ဆီ ပို့နိုင်သည်',
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => SavedPhraseIssuesScreen(appState: appState),
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
                    'သင်ခန်းစာ၊ ရှာဖွေမှု၊ စကားစုသိမ်းခြင်း၊ လေ့လာမှုမှတ်တမ်းနဲ့ အမှားထောက်ပြချက်တွေကို ဒီစက်ထဲမှာသာ သိမ်းပါတယ်။ အမှားထောက်ပြချက်ကို Copy လုပ်ပြီး ပို့မှသာ အခြားသူဆီ ရောက်ပါတယ်။ သာမန်သင်ခန်းစာတွေအတွက် account မလိုပါ။ Web မှာ browser ရဲ့ local storage ကို သုံးပါတယ်။ Browser data ဖျက်လျှင် သို့မဟုတ် စက်ပြောင်းလျှင် ဒီမှတ်တမ်းတွေ ပါမလာပါ။\n\nအပတ်စဉ် League ကတော့ ရွေးချယ်ပါဝင်ရတာဖြစ်ပြီး Google account နဲ့ ဝင်ရပါတယ်။ Google က ပေးတဲ့ email နဲ့ profile အချက်အလက်ကို Supabase Auth မှာ၊ ကိုယ်ရွေးထားတဲ့ နာမည်ပြောင်၊ avatar နဲ့ League အမှတ်တွေကို server မှာ သိမ်းပါတယ်။ အဆင့်ဇယားမှာ နာမည်ပြောင်၊ avatar နဲ့ အမှတ်ပဲ ပြပါတယ်။ Google password ကို ဒီ app က မရရှိပါ။\n\nထိုင်းစာကြောင်းတွေကို နေ့စဉ်ဆက်သွယ်ရေးအတွက် ပြင်ဆင်ထားပါတယ်။ ကျန်းမာရေး၊ ဥပဒေ၊ အလုပ်စာချုပ်လို အရေးကြီးကိစ္စတွေမှာ စကားပြန် သို့မဟုတ် ကျွမ်းကျင်သူနဲ့ အတည်ပြုပါ။',
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
      ),
    );
  }
}
