import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Keeps route content readable on wide screens without constraining scrolling.
class ContentFrame extends StatelessWidget {
  const ContentFrame({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppTheme.contentWidth),
      child: SafeArea(top: false, child: child),
    ),
  );
}
