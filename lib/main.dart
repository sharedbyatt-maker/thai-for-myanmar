import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'data/phrase_repository.dart';
import 'services/ad_slot.dart';
import 'services/app_state.dart';
import 'services/speech_service.dart';
import 'services/remote_controls.dart';
import 'services/thai_audio_catalog.dart';
import 'services/thai_playback_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RemoteControls.instance.load(rootBundle);
  final repository = await PhraseRepository.load(rootBundle);
  final audioCatalog = await ThaiAudioCatalog.load(rootBundle).catchError(
    (Object error, StackTrace stack) {
      // Optional audio must never prevent the offline phrase library opening.
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'Chang Thai startup',
          context: ErrorDescription(
            'while loading the optional Thai audio catalog',
          ),
        ),
      );
      return ThaiAudioCatalog.empty();
    },
  );
  final appState = AppState();
  await appState.load();
  runApp(
    ThaiForMyanmarApp(
      repository: repository,
      appState: appState,
      playbackService: ThaiPlaybackService(
        speechService: SpeechService(),
        catalog: audioCatalog,
      ),
    ),
  );
  WidgetsBinding.instance.addPostFrameCallback((_) => initializeAds());
}
