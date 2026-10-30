import 'package:flutter/material.dart';
import '../data/phrase_repository.dart';
import '../models/phrase.dart';
import '../services/app_state.dart';
import '../services/thai_playback_service.dart';
import '../widgets/playful_components.dart';
import '../widgets/polite_style_picker.dart';
import '../widgets/phrase_tile.dart';
import '../widgets/content_frame.dart';
import 'phrase_browser_screen.dart';
import 'quick_speak_screen.dart';
import 'situations_screen.dart';

class EverydayScreen extends StatefulWidget {
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
  State<EverydayScreen> createState() => _EverydayScreenState();
}

class _EverydayScreenState extends State<EverydayScreen> {
  final _controller = TextEditingController();
  String _query = '';
  bool _saved = false;
  int _limit = 20;
  PhraseRepository get repository => widget.repository;
  AppState get appState => widget.appState;
  ThaiPlaybackService get playbackService => widget.playbackService;
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: appState,
    builder: (context, _) {
      void open(Widget page) {
        FocusManager.instance.primaryFocus?.unfocus();
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('အမြန်သုံး')),
              body: ContentFrame(child: page),
            ),
          ),
        );
      }

      const groups = [
        ('စားသောက်', 'food', Icons.ramen_dining_rounded, Color(0xFFFFE2D3)),
        ('အလုပ်', 'workplace', Icons.work_rounded, Color(0xFFDFE5FF)),
        (
          'သွားလာ',
          'transport',
          Icons.directions_bus_rounded,
          Color(0xFFD7F0EA),
        ),
        ('ဈေးဝယ်', 'shopping', Icons.shopping_bag_rounded, Color(0xFFF9E1EF)),
        (
          'ကျန်းမာရေး',
          'health',
          Icons.medical_services_rounded,
          Color(0xFFE2E8FF),
        ),
        ('အရေးပေါ်', 'emergency', Icons.sos_rounded, Color(0xFFFFDEDE)),
      ];
      final searching = _query.trim().isNotEmpty || _saved;
      final results = repository
          .search(_query)
          .where((p) => !_saved || appState.isFavorite(p.id))
          .toList();
      final recent = appState.recent
          .expand((id) => repository.phrases.where((p) => p.id == id))
          .take(3)
          .toList();
      Widget tile(Phrase phrase) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: PhraseTile(
          phrase: phrase,
          repository: repository,
          appState: appState,
          playbackService: playbackService,
        ),
      );
      return ListView(
        key: const ValueKey('everyday-scroll'),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          TextField(
            key: const ValueKey('everyday-search'),
            controller: _controller,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            onChanged: (v) => setState(() {
              _query = v;
              _limit = 20;
            }),
            decoration: InputDecoration(
              hintText: 'ဘာပြောချင်လဲ?',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'ဖျက်ရန်',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _controller.clear();
                        setState(() {
                          _query = '';
                          _limit = 20;
                        });
                      },
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              ChoiceChip(
                label: const Text('အားလုံး'),
                selected: !_saved,
                onSelected: (_) => setState(() {
                  _saved = false;
                  _limit = 20;
                }),
              ),
              ChoiceChip(
                avatar: const Icon(Icons.favorite_rounded, size: 16),
                label: const Text('သိမ်းထားတာ'),
                selected: _saved,
                onSelected: (_) => setState(() {
                  _saved = true;
                  _limit = 20;
                }),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (searching) ...[
            Text(
              '${results.length} ခုတွေ့သည်',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 12),
            if (results.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        _saved
                            ? Icons.favorite_border_rounded
                            : Icons.search_off_rounded,
                        size: 36,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _saved && _query.trim().isEmpty
                            ? 'သိမ်းထားတာ မရှိသေးပါဘူး။'
                            : 'ဒီစကားစုကို မတွေ့ပါဘူး။',
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _saved
                            ? 'စကားစုဘေးက နှလုံးပုံနဲ့ သိမ်းနိုင်ပါတယ်။'
                            : 'အခြားစကားလုံးနဲ့ ရှာကြည့်ပါ။',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ...results.take(_limit).map(tile),
            if (results.length > _limit)
              TextButton.icon(
                onPressed: () => setState(() => _limit += 20),
                icon: const Icon(Icons.expand_more),
                label: const Text('ပိုကြည့်မယ်'),
              ),
          ] else ...[
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
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
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
            const SizedBox(height: 12),
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
            if (recent.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'နောက်ဆုံး သုံးထားတာ',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ...recent.map(tile),
            ],
          ],
          const SizedBox(height: 16),
          PoliteStylePicker(
            appState: appState,
            playbackService: playbackService,
          ),
        ],
      );
    },
  );
}
