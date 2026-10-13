import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/phrase.dart';
import '../models/phrase_issue.dart';
import '../services/app_state.dart';

class PhraseIssueScreen extends StatefulWidget {
  const PhraseIssueScreen({
    required this.phrase,
    required this.appState,
    super.key,
  });

  final Phrase phrase;
  final AppState appState;

  @override
  State<PhraseIssueScreen> createState() => _PhraseIssueScreenState();
}

class _PhraseIssueScreenState extends State<PhraseIssueScreen> {
  final _controller = TextEditingController();
  bool _saving = false;
  PhraseIssue? _saved;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final succeeded = await widget.appState.savePhraseIssue(
      phraseId: widget.phrase.id,
      thai: widget.phrase.thaiFor(widget.appState.politeStyle),
      myanmar: widget.phrase.myanmar,
      description: _controller.text,
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (succeeded) _saved = widget.appState.phraseIssues.first;
    });
    if (!succeeded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'စက်ထဲမှာ မသိမ်းနိုင်ပါ။ နေရာလွတ်/သိမ်းဆည်းမှုကို စစ်ပြီး ပြန်စမ်းပါ။',
          ),
        ),
      );
    }
  }

  Future<void> _copy() async {
    try {
      await Clipboard.setData(ClipboardData(text: _saved!.shareText));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Copy လုပ်ပြီးပါပြီ။ သင်ရွေးတဲ့ chat/email ထဲ paste လုပ်ပြီး ပို့ပါ။',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copy မလုပ်နိုင်ပါ။ ထပ်စမ်းကြည့်ပါ။')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('စကားစုအမှား ထောက်ပြရန်')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            widget.phrase.myanmar,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          SelectableText(widget.phrase.thaiFor(widget.appState.politeStyle)),
          const SizedBox(height: 8),
          Text('Phrase ID: ${widget.phrase.id}'),
          const SizedBox(height: 20),
          if (_saved case final saved?) ...[
            const Text('စက်ထဲမှာ သိမ်းပြီးပါပြီ။ Developer ဆီ မပို့ရသေးပါ။'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _copy,
              icon: const Icon(Icons.copy_rounded),
              label: const Text('အမှားထောက်ပြချက် Copy လုပ်ရန်'),
            ),
            const SizedBox(height: 8),
            Text('သိမ်းထားသည့်အချိန်: ${saved.createdAt.toLocal()}'),
          ] else ...[
            const Text(
              'ထိုင်းစာ၊ မြန်မာအဓိပ္ပာယ် သို့မဟုတ် အသံထွက် ဘာမှားနေလဲ ရေးပါ။',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLength: 1000,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'ဥပမာ — မြန်မာလို အဓိပ္ပာယ် ပြန်စစ်ပေးပါ',
              ),
            ),
            FilledButton(
              onPressed: _saving || _controller.text.trim().isEmpty
                  ? null
                  : _save,
              child: Text(_saving ? 'သိမ်းနေသည်…' : 'စက်ထဲ သိမ်းရန်'),
            ),
            const SizedBox(height: 12),
            const Text(
              'စက်ထဲမှာပဲ သိမ်းပါတယ်။ Copy လုပ်ပြီး သင်ရွေးတဲ့ chat/email မှ developer ဆီ ပို့နိုင်ပါတယ်။',
            ),
          ],
        ],
      ),
    );
  }
}

class SavedPhraseIssuesScreen extends StatelessWidget {
  const SavedPhraseIssuesScreen({required this.appState, super.key});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('သိမ်းထားသော အမှားထောက်ပြချက်များ')),
      body: AnimatedBuilder(
        animation: appState,
        builder: (context, _) {
          final issues = appState.phraseIssues;
          if (issues.isEmpty) {
            return const Center(
              child: Text('သိမ်းထားသော အမှားထောက်ပြချက် မရှိသေးပါ။'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: issues.length,
            itemBuilder: (context, index) {
              final issue = issues[index];
              return Card(
                child: ListTile(
                  title: Text(issue.myanmar),
                  subtitle: Text('${issue.phraseId}\n${issue.description}'),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    tooltip: 'လုပ်ဆောင်ချက်များ',
                    onSelected: (action) async {
                      if (action == 'copy') {
                        try {
                          await Clipboard.setData(
                            ClipboardData(text: issue.shareText),
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Copy လုပ်ပြီးပါပြီ။ chat/email ထဲ paste လုပ်ပြီး ပို့ပါ။',
                              ),
                            ),
                          );
                        } catch (_) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Copy မလုပ်နိုင်ပါ။')),
                          );
                        }
                      } else if (action == 'delete') {
                        final removed = await appState.removePhraseIssue(
                          issue.id,
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              removed
                                  ? 'ဖျက်ပြီးပါပြီ။'
                                  : 'ဖျက်မရပါ။ ထပ်စမ်းပါ။',
                            ),
                          ),
                        );
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'copy', child: Text('Copy လုပ်ရန်')),
                      PopupMenuItem(value: 'delete', child: Text('ဖျက်ရန်')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
