import 'package:flutter/material.dart';

import '../data/phrase_repository.dart';
import '../services/app_state.dart';
import '../services/speech_service.dart';
import 'phrase_browser_screen.dart';

class SituationsScreen extends StatelessWidget {
  const SituationsScreen({
    required this.repository,
    required this.appState,
    required this.speechService,
    super.key,
  });

  final PhraseRepository repository;
  final AppState appState;
  final SpeechService speechService;

  @override
  Widget build(BuildContext context) {
    final categories = repository.categories
        .where((category) => category.kind != 'learn')
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      children: [
        Text(
          'ဘယ်နေရာမှာ သုံးမလဲ?',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 5),
        const Text('သက်ဆိုင်တဲ့ အခြေအနေကို ရွေးပြီး စကားစုကို အမြန်ရှာပါ။'),
        const SizedBox(height: 15),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 590 ? 3 : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categories.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                mainAxisExtent: 116,
              ),
              itemBuilder: (context, index) {
                final category = categories[index];
                final phraseCount = repository.inCategory(category.id).length;
                return Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => PhraseBrowserScreen(
                          repository: repository,
                          appState: appState,
                          speechService: speechService,
                          title: category.my,
                          categoryId: category.id,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(13),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.icon,
                            style: const TextStyle(fontSize: 25),
                          ),
                          const Spacer(),
                          Text(
                            category.my,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            '$phraseCount ခု',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
