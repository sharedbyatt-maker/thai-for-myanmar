import 'dart:async';

import 'package:flutter/material.dart';

import '../models/phrase.dart';
import '../services/app_state.dart';
import '../services/thai_playback_service.dart';

class ThaiPlaybackButton extends StatefulWidget {
  const ThaiPlaybackButton({
    required this.phrase,
    required this.appState,
    required this.playbackService,
    required this.label,
    this.outlined = false,
    this.compact = false,
    this.hero = false,
    super.key,
  });

  final Phrase phrase;
  final AppState appState;
  final ThaiPlaybackService playbackService;
  final String label;
  final bool outlined;
  final bool compact;
  final bool hero;

  @override
  State<ThaiPlaybackButton> createState() => _ThaiPlaybackButtonState();
}

class _ThaiPlaybackButtonState extends State<ThaiPlaybackButton> {
  String? _failedStyle;
  @override
  void dispose() {
    if (widget.playbackService.isActiveFor(
      widget.phrase.id,
      widget.appState.politeStyle,
    )) {
      unawaited(widget.playbackService.stop());
    }
    super.dispose();
  }

  Future<void> _toggle(String politeStyle) async {
    final service = widget.playbackService;
    if (service.isActiveFor(widget.phrase.id, politeStyle)) {
      await service.stop();
      return;
    }

    setState(() => _failedStyle = null);
    await service.setVolume(widget.appState.audioVolume);
    if (!mounted) return;
    final result = await service.playThai(widget.phrase, politeStyle);
    if (result == ThaiPlaybackResult.unavailable && mounted) {
      setState(() => _failedStyle = politeStyle);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'ဒီစက် သို့မဟုတ် ဘရောက်ဇာမှာ ထိုင်းအသံ မရရှိပါ။ နောက်မှ ထပ်စမ်းနိုင်ပါတယ်။',
          ),
          action: SnackBarAction(label: 'ထပ်စမ်းရန်', onPressed: _retry),
        ),
      );
    }
  }

  void _retry() => unawaited(_toggle(widget.appState.politeStyle));

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final politeStyle = widget.appState.politeStyle;
        return AnimatedBuilder(
          animation: widget.playbackService,
          builder: (context, _) {
            final active = widget.playbackService.isActiveFor(
              widget.phrase.id,
              politeStyle,
            );
            final loading =
                active &&
                widget.playbackService.state == ThaiPlaybackState.loading;
            final playing =
                active &&
                widget.playbackService.state == ThaiPlaybackState.playing;
            final failed = _failedStyle == politeStyle && !active;
            final icon = loading
                ? SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: widget.compact || widget.outlined
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onPrimary,
                    ),
                  )
                : Icon(
                    playing
                        ? Icons.stop_rounded
                        : failed
                        ? Icons.refresh_rounded
                        : Icons.volume_up_rounded,
                  );
            final label = loading
                ? 'ဖွင့်နေသည်'
                : playing
                ? 'အသံရပ်ရန်'
                : widget.label;
            void onPressed() => unawaited(_toggle(politeStyle));

            if (widget.hero) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox.square(
                      dimension: 88,
                      child: IconButton.filled(
                        tooltip: failed ? 'အသံမရပါ • ထပ်စမ်းရန်' : label,
                        onPressed: onPressed,
                        iconSize: 42,
                        style: IconButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                        ),
                        icon: icon,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(label, style: Theme.of(context).textTheme.labelMedium),
                  ],
                ),
              );
            }
            if (widget.compact) {
              return IconButton.filledTonal(
                tooltip: failed ? 'အသံမရပါ • ထပ်စမ်းရန်' : label,
                onPressed: onPressed,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: icon,
              );
            }
            if (widget.outlined) {
              return OutlinedButton.icon(
                onPressed: onPressed,
                icon: icon,
                label: Text(label),
              );
            }
            return FilledButton.icon(
              onPressed: onPressed,
              icon: icon,
              label: Text(label),
            );
          },
        );
      },
    );
  }
}
