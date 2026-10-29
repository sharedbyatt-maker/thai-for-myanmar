import 'package:flutter/material.dart';

import '../data/phrase_repository.dart';
import '../services/app_state.dart';
import '../services/thai_playback_service.dart';
import '../widgets/playful_components.dart';
import '../widgets/polite_style_picker.dart';
import 'favorites_screen.dart';
import 'phrase_browser_screen.dart';
import 'quick_speak_screen.dart';
import 'situations_screen.dart';

class EverydayScreen extends StatelessWidget {
  const EverydayScreen({
    required this.repository,
    required this.appState,
    required this.playbackService,
    required this.onSearch,
    super.key,
  });
  final PhraseRepository repository;
  final AppState appState;
  final ThaiPlaybackService playbackService;
  final VoidCallback onSearch;
  @override
  Widget build(BuildContext context) {
    void open(Widget page) => Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('အမြန်သုံး')),
          body: page,
        ),
      ),
    );
    const groups = [
      ('စားသောက်', 'food', Icons.ramen_dining_rounded, Color(0xFFFFE2D3)),
      ('အလုပ်', 'workplace', Icons.work_rounded, Color(0xFFDFE5FF)),
      ('သွားလာ', 'transport', Icons.directions_bus_rounded, Color(0xFFD7F0EA)),
      ('ဈေးဝယ်', 'shopping', Icons.shopping_bag_rounded, Color(0xFFF9E1EF)),
      (
        'ကျန်းမာရေး',
        'health',
        Icons.medical_services_rounded,
        Color(0xFFE2E8FF),
      ),
      ('အရေးပေါ်', 'emergency', Icons.sos_rounded, Color(0xFFFFDEDE)),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Text(
          'အခုပဲ ပြောလိုက်ပါ',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        const Text('လိုတဲ့စကားရှာ၊ နှိပ်ပြီး နားထောင်'),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: onSearch,
          icon: const Icon(Icons.search),
          label: const Align(
            alignment: Alignment.centerLeft,
            child: Text('ဘာပြောချင်လဲ?'),
          ),
        ),
        const SizedBox(height: 16),
        const SizedBox(height: 4),
        LayoutBuilder(
          builder: (context, constraints) {
            return GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: constraints.maxWidth >= 600 ? 3 : 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent:
                    150 +
                    (MediaQuery.textScalerOf(context).scale(14) - 14).clamp(
                          0,
                          28,
                        ) *
                        6,
              ),
              children: groups
                  .map(
                    (g) => Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => PhraseBrowserScreen(
                              repository: repository,
                              appState: appState,
                              playbackService: playbackService,
                              title: g.$1,
                              categoryId: g.$2,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: g.$4,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Icon(
                                  g.$3,
                                  size: 30,
                                  color: const Color(0xFF34315B),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                g.$1,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 18),
        LiftButton(
          label: 'ထိုင်းလူမျိုးကို ပြမယ်',
          icon: Icons.open_in_full_rounded,
          onPressed: () => open(
            QuickSpeakScreen(
              repository: repository,
              appState: appState,
              playbackService: playbackService,
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: () => open(
            SituationsScreen(
              repository: repository,
              appState: appState,
              playbackService: playbackService,
            ),
          ),
          icon: const Icon(Icons.grid_view_rounded),
          label: const Text('အခြေအနေအားလုံး'),
        ),
        TextButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => FavoritesScreen(
                repository: repository,
                appState: appState,
                playbackService: playbackService,
              ),
            ),
          ),
          icon: const Icon(Icons.favorite_rounded),
          label: const Text('သိမ်းထားတဲ့ စကားစု'),
        ),
        const SizedBox(height: 14),
        PoliteStylePicker(appState: appState, playbackService: playbackService),
      ],
    );
  }
}
