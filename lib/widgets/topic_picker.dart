import 'package:flutter/material.dart';
import '../data/phrase_repository.dart';
import '../learning/study_catalog.dart';
import '../services/app_state.dart';

class TopicPicker extends StatefulWidget {
  const TopicPicker({
    required this.repository,
    required this.appState,
    required this.selected,
    super.key,
  });
  final PhraseRepository repository;
  final AppState appState;
  final String selected;
  @override
  State<TopicPicker> createState() => _TopicPickerState();
}

class _TopicPickerState extends State<TopicPicker> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final topics = widget.repository.categories
        .where((c) => '${c.my} ${c.th} ${c.en}'.toLowerCase().contains(q))
        .toList();
    final lessons = StudyCatalog.lessons(widget.repository);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'သင်ချင်တဲ့ အကြောင်းအရာ',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'ပိတ်ရန်',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'အကြောင်းအရာ ရှာရန်',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 12),
            if (topics.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('အကြောင်းအရာ မတွေ့ပါ။'),
              ),
            ...topics.map((c) {
              final unit = lessons.where((l) => l.category.id == c.id).toList();
              final count = unit
                  .where(
                    (l) => widget.appState.learning.completedLessons.contains(
                      l.id,
                    ),
                  )
                  .length;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: ListTile(
                    leading: Text(c.icon, style: const TextStyle(fontSize: 26)),
                    title: Text(c.my),
                    subtitle: Text('$count / ${unit.length} သင်ခန်းစာ'),
                    trailing: c.id == widget.selected
                        ? const Icon(Icons.check_circle_rounded)
                        : const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.pop(context, c.id),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
