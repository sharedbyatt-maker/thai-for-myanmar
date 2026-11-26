import 'package:flutter/widgets.dart';

void initializeAds() {}
void preloadLessonAds() {}
void maybeShowAppOpenAd() {}

Future<void> showLessonTransitionAd(
  BuildContext context, {
  required int completedLessons,
  required Future<void> Function()? onReward,
}) async {}

class InlineAdSlot extends StatelessWidget {
  const InlineAdSlot({super.key, this.native = false});
  final bool native;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class AdBonusButton extends StatelessWidget {
  const AdBonusButton({super.key, required this.onReward});
  final Future<void> Function() onReward;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class AdPrivacyOptions extends StatelessWidget {
  const AdPrivacyOptions({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class AdTestSettings extends StatelessWidget {
  const AdTestSettings({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
