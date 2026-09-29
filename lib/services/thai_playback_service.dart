import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../models/phrase.dart';
import 'speech_service.dart';
import 'thai_audio_catalog.dart';

enum ThaiPlaybackState { idle, loading, playing, unavailable }

enum ThaiPlaybackResult { audioAsset, spoken, unavailable, cancelled }

abstract interface class ThaiAudioAssetPlayer {
  Future<void> play(String assetPath, {required void Function() onStarted});
  Future<void> stop();
  Future<void> dispose();
}

class ThaiPlaybackService extends ChangeNotifier {
  ThaiPlaybackService({
    required SpeechService speechService,
    required ThaiAudioCatalog catalog,
    ThaiAudioAssetPlayer? assetPlayer,
  }) : _speechService = speechService,
       _catalog = catalog,
       _assetPlayer = assetPlayer ?? AudioPlayersThaiAssetPlayer();

  final SpeechService _speechService;
  final ThaiAudioCatalog _catalog;
  final ThaiAudioAssetPlayer _assetPlayer;

  SpeechService get speechService => _speechService;

  ThaiPlaybackState _state = ThaiPlaybackState.idle;
  String? _activePhraseId;
  String? _activeStyle;
  int _requestId = 0;
  bool _disposed = false;

  ThaiPlaybackState get state => _state;

  bool isActiveFor(String phraseId, String politeStyle) =>
      (_state == ThaiPlaybackState.loading ||
          _state == ThaiPlaybackState.playing) &&
      _activePhraseId == phraseId &&
      _activeStyle == politeStyle;

  Future<ThaiPlaybackResult> playThai(Phrase phrase, String politeStyle) async {
    final requestId = ++_requestId;
    _publish(ThaiPlaybackState.loading, phrase.id, politeStyle);
    await _stopPlayers();
    if (requestId != _requestId) return ThaiPlaybackResult.cancelled;

    final text = phrase.thaiFor(politeStyle);
    final entry = _catalog.match(phrase, politeStyle);
    if (entry != null) {
      try {
        await _assetPlayer.play(
          entry.assetPath,
          onStarted: () => _publishIfCurrent(
            requestId,
            ThaiPlaybackState.playing,
            phrase.id,
            politeStyle,
          ),
        );
        if (requestId != _requestId) return ThaiPlaybackResult.cancelled;
        _publish(ThaiPlaybackState.idle, null, null);
        return ThaiPlaybackResult.audioAsset;
      } catch (_) {
        if (requestId != _requestId) return ThaiPlaybackResult.cancelled;
      }
    }

    if (requestId != _requestId) return ThaiPlaybackResult.cancelled;
    final speechResult = await _speechService.speakThai(
      text,
      onStarted: () => _publishIfCurrent(
        requestId,
        ThaiPlaybackState.playing,
        phrase.id,
        politeStyle,
      ),
    );
    if (requestId != _requestId) return ThaiPlaybackResult.cancelled;
    if (speechResult == SpeechResult.cancelled) {
      _publish(ThaiPlaybackState.idle, null, null);
      return ThaiPlaybackResult.cancelled;
    }
    if (speechResult == SpeechResult.spoken) {
      _publish(ThaiPlaybackState.idle, null, null);
      return ThaiPlaybackResult.spoken;
    }
    _publish(ThaiPlaybackState.unavailable, phrase.id, politeStyle);
    return ThaiPlaybackResult.unavailable;
  }

  Future<void> stop() async {
    if (_state != ThaiPlaybackState.loading &&
        _state != ThaiPlaybackState.playing) {
      return;
    }
    ++_requestId;
    _publish(ThaiPlaybackState.idle, null, null);
    await _stopPlayers();
  }

  Future<void> _stopPlayers() async {
    await Future.wait<void>([_stopAssetPlayer(), _stopSpeech()]);
  }

  Future<void> _stopAssetPlayer() async {
    try {
      await _assetPlayer.stop().timeout(const Duration(seconds: 2));
    } catch (_) {
      // Stopping an unavailable platform player is best-effort.
    }
  }

  Future<void> _stopSpeech() async {
    try {
      await _speechService.stop().timeout(const Duration(seconds: 2));
    } catch (_) {
      // Stopping an unavailable platform voice is best-effort.
    }
  }

  void _publishIfCurrent(
    int requestId,
    ThaiPlaybackState state,
    String phraseId,
    String politeStyle,
  ) {
    if (requestId == _requestId) _publish(state, phraseId, politeStyle);
  }

  void _publish(ThaiPlaybackState state, String? phraseId, String? style) {
    if (_disposed) return;
    _state = state;
    _activePhraseId = phraseId;
    _activeStyle = style;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_requestId;
    unawaited(_speechService.stop());
    unawaited(_assetPlayer.dispose());
    super.dispose();
  }
}

class AudioPlayersThaiAssetPlayer implements ThaiAudioAssetPlayer {
  AudioPlayersThaiAssetPlayer({AudioPlayer? player})
    : _player = player ?? AudioPlayer();

  final AudioPlayer _player;
  _PendingAssetPlayback? _pending;

  @override
  Future<void> play(
    String assetPath, {
    required void Function() onStarted,
  }) async {
    await stop();
    final pending = _PendingAssetPlayback();
    _pending = pending;
    final stateSubscription = _player.onPlayerStateChanged.listen(
      (state) {
        if (state == PlayerState.playing) {
          if (!pending.started.isCompleted) pending.started.complete();
          onStarted();
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        pending.fail(error, stackTrace);
      },
    );
    final completeSubscription = _player.onPlayerComplete.listen(
      (_) {
        if (!pending.completed.isCompleted) pending.completed.complete();
      },
      onError: (Object error, StackTrace stackTrace) {
        pending.fail(error, stackTrace);
      },
    );

    try {
      await _player.play(AssetSource(assetPath));
      await pending.started.future.timeout(const Duration(seconds: 5));
      pending.throwIfFailed();
      if (pending.cancelled) throw const _AssetPlaybackCancelled();
      await pending.completed.future.timeout(const Duration(seconds: 20));
      pending.throwIfFailed();
      if (pending.cancelled) throw const _AssetPlaybackCancelled();
    } catch (_) {
      if (!pending.cancelled) await _stopPlatformPlayer();
      rethrow;
    } finally {
      await stateSubscription.cancel();
      await completeSubscription.cancel();
      if (identical(_pending, pending)) _pending = null;
    }
  }

  @override
  Future<void> stop() async {
    final pending = _pending;
    if (pending != null && !pending.cancelled) {
      pending.cancelled = true;
      if (!pending.started.isCompleted) pending.started.complete();
      if (!pending.completed.isCompleted) pending.completed.complete();
    }
    await _stopPlatformPlayer();
  }

  Future<void> _stopPlatformPlayer() async {
    try {
      await _player.stop();
    } catch (_) {
      // Best-effort when a browser or device has no usable audio output.
    }
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _player.dispose();
  }
}

class _PendingAssetPlayback {
  final started = Completer<void>();
  final completed = Completer<void>();
  Object? error;
  StackTrace? stackTrace;
  bool cancelled = false;

  void fail(Object error, StackTrace stackTrace) {
    this.error = error;
    this.stackTrace = stackTrace;
    if (!started.isCompleted) started.complete();
    if (!completed.isCompleted) completed.complete();
  }

  void throwIfFailed() {
    final playbackError = error;
    if (playbackError != null) {
      Error.throwWithStackTrace(
        playbackError,
        stackTrace ?? StackTrace.current,
      );
    }
  }
}

class _AssetPlaybackCancelled implements Exception {
  const _AssetPlaybackCancelled();
}
