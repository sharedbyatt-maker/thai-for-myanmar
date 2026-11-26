import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'ad_slot_config.dart';
import 'remote_audio_cache.dart';

Map<String, dynamic> controlMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : {};

String? controlText(Object? value) =>
    value is String && value.trim().isNotEmpty ? value : null;

class RemoteControls {
  RemoteControls._();
  static final instance = RemoteControls._();
  static const _cacheKey = 'chang_thai_published_controls_v1';
  Map<String, dynamic> _settings = {};
  int buildNumber = 0;
  bool _hasLiveSettings = false;
  final audio = <(String, String), String>{};

  AndroidAdsConfig get androidAds =>
      _hasLiveSettings && !_settings.containsKey('androidAds')
      ? AndroidAdsConfig.testDefaults
      : AndroidAdsConfig(controlMap(_settings['androidAds']));
  Map<String, dynamic> get announcement =>
      controlMap(_settings['announcement']);
  Map<String, dynamic> get update => controlMap(_settings['androidUpdate']);
  Map<String, dynamic> unit(String id) =>
      controlMap(controlMap(_settings['units'])[id]);
  Map<String, dynamic> lesson(String id) =>
      controlMap(controlMap(_settings['lessons'])[id]);
  Map<String, dynamic> line(String id, String voice) {
    final entry = controlMap(
      controlMap(controlMap(_settings['lines'])[id])[voice],
    );
    if (entry['audio'] is String && !audio.containsKey((id, voice))) return {};
    return entry;
  }

  Future<void> load(AssetBundle bundle) async {
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        try {
          buildNumber =
              await const MethodChannel(
                'chang.thai/controls',
              ).invokeMethod<int>('versionCode') ??
              0;
        } catch (_) {
          // Builds without the channel suppress Android update notices.
        }
      }
      final config = controlMap(
        jsonDecode(await bundle.loadString('assets/data/league_config.json')),
      );
      final base = Uri.parse(config['url'] as String);
      if (base.scheme != 'https') return;
      final prefs = await SharedPreferences.getInstance();
      final key = config['publishableKey'] as String;
      Map<String, dynamic> settings;
      var online = false;
      try {
        final response = await http
            .get(
              base.replace(
                path: '/rest/v1/chang_thai_controls',
                queryParameters: {'id': 'eq.1', 'select': 'settings'},
              ),
              headers: {'apikey': key},
            )
            .timeout(const Duration(seconds: 2));
        if (response.statusCode != 200) {
          throw StateError('Controls unavailable');
        }
        settings = controlMap(
          (jsonDecode(response.body) as List).single['settings'],
        );
        online = true;
        await prefs.setString(
          _cacheKey,
          jsonEncode({
            'units': settings['units'],
            'lessons': settings['lessons'],
            'lines': settings['lines'],
          }),
        );
      } catch (_) {
        settings = controlMap(jsonDecode(prefs.getString(_cacheKey) ?? '{}'));
      }
      final downloads = <Uri>{};
      for (final line in controlMap(settings['lines']).entries) {
        for (final voice in ['male', 'female']) {
          final item = controlMap(controlMap(line.value)[voice]);
          final name = item['audio'];
          if (name is! String ||
              !RegExp(r'^[a-zA-Z0-9_-]+[.]mp3$').hasMatch(name)) {
            continue;
          }
          final url = base.replace(
            path: '/storage/v1/object/public/chang-thai-lesson-audio/$name',
          );
          try {
            final path = await cacheRemoteAudio(url, online: online && kIsWeb);
            if (path != null) audio[(line.key, voice)] = path;
            if (online && path == null && !kIsWeb) downloads.add(url);
          } catch (_) {
            // Keep the bundled recording if the cache cannot be read.
          }
        }
      }
      unawaited(_download(downloads));
      _settings = settings;
      _hasLiveSettings = online;
    } catch (_) {
      // The offline learning bundle is always usable.
    }
  }

  Future<void> _download(Set<Uri> urls) async {
    for (final url in urls) {
      try {
        await cacheRemoteAudio(
          url,
          online: true,
        ).timeout(const Duration(seconds: 15));
      } catch (_) {
        // Retry at a later launch without blocking the bundled course.
      }
    }
  }
}
