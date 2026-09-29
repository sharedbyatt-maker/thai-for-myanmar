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
    super.key,
  });

  final Phrase phrase;
  final AppState appState;
  final ThaiPlaybackService playbackService;
  final String label;
  final bool outlined;

  @override
  State<ThaiPlaybackButton> createState() => _ThaiPlaybackButtonState();
}

class _ThaiPlaybackButtonState extends State<ThaiPlaybackButton> {
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

    final result = await service.playThai(widget.phrase, politeStyle);
    if (result == ThaiPlaybackResult.unavailable && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'အသံဖွင့်၍မရပါ။ ထိုင်းစာကြောင်းကို ပြသပြီး အကူအညီတောင်းနိုင်ပါတယ်။',
          ),
        ),
      );
    }
  }

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
            final icon = loading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(playing ? Icons.stop_rounded : Icons.volume_up_rounded);
            final label = loading
                ? 'ဖွင့်နေသည်'
                : playing
                ? 'အသံရပ်ရန်'
                : widget.label;
            final onPressed = () => unawaited(_toggle(politeStyle));
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
