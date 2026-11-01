import 'package:flutter/material.dart';

/// Compact, persistent feedback above the existing check/continue button.
class LessonAnswerFeedback extends StatelessWidget {
  const LessonAnswerFeedback({
    required this.correct,
    required this.explanation,
    required this.onDetails,
    super.key,
  });
  final bool correct;
  final String explanation;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey('unit-one-answer-feedback'),
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: correct ? colors.secondaryContainer : colors.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                correct ? Icons.check_circle_rounded : Icons.refresh_rounded,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  correct ? 'မှန်ပါတယ်' : 'အတူတူ ပြန်ကြည့်မယ်',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(explanation, maxLines: 2, overflow: TextOverflow.ellipsis),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onDetails,
              child: const Text('ရှင်းပြချက် ကြည့်မယ်'),
            ),
          ),
        ],
      ),
    );
  }
}
