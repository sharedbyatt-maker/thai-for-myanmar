import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'data/phrase_repository.dart';
import 'services/ad_slot.dart';
import 'services/app_state.dart';
import 'services/remote_controls.dart';
import 'services/speech_service.dart';
import 'services/thai_audio_catalog.dart';
import 'services/thai_playback_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Draw the exact branded artwork immediately. Do not wait for JSON assets,
  // local preferences, or remote controls before the first Flutter frame.
  runApp(const _ChangThaiStartupScreen());
  unawaited(_startApp());
  WidgetsBinding.instance.addPostFrameCallback((_) => initializeAds());
}

Future<void> _startApp() async {
  try {
    final appState = AppState();

    // Start independent asset and preference loads together while the branded
    // splash is already visible.
    final repositoryFuture = PhraseRepository.load(rootBundle);
    final audioCatalogFuture = ThaiAudioCatalog.load(rootBundle);
    unawaited(RemoteControls.instance.load(rootBundle));
    await appState.load();

    final repository = await repositoryFuture;
    final audioCatalog = await audioCatalogFuture;

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
  } catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'Chang Thai startup',
      ),
    );
  }
}

class _ChangThaiStartupScreen extends StatelessWidget {
  const _ChangThaiStartupScreen();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Chang Thai',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFF111431),
        body: SizedBox.expand(
          child: Image(
            image: AssetImage(
              'tool/android_brand/drawable-nodpi/chang_thai_splash.png',
            ),
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}
