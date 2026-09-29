import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'data/phrase_repository.dart';
import 'services/ad_slot.dart';
import 'services/app_state.dart';
import 'services/speech_service.dart';
import 'services/thai_audio_catalog.dart';
import 'services/thai_playback_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await PhraseRepository.load(rootBundle);
  final audioCatalog = await ThaiAudioCatalog.load(rootBundle);
  final appState = AppState();
  await appState.load();
  await initializeAds();
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
}
