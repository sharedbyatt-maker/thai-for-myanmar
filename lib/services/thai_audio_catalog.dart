import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/phrase.dart';

enum ThaiAudioForm { shared, male, female }

class ThaiAudioEntry {
  const ThaiAudioEntry({
    required this.phraseId,
    required this.form,
    required this.thai,
    required this.assetPath,
  });

  final String phraseId;
  final ThaiAudioForm form;
  final String thai;

  /// Relative to Flutter's default `assets/` directory.
  final String assetPath;
}

class ThaiAudioCatalog {
  ThaiAudioCatalog._(Map<(String, ThaiAudioForm), ThaiAudioEntry> entries)
    : _entries = Map.unmodifiable(entries);

  static const manifestAsset = 'assets/data/thai_audio_manifest.json';

  final Map<(String, ThaiAudioForm), ThaiAudioEntry> _entries;

  factory ThaiAudioCatalog.empty() => ThaiAudioCatalog._(const {});

  factory ThaiAudioCatalog.fromJson(Map<String, dynamic> json) {
    if (json['schemaVersion'] != 1) {
      throw const FormatException('Unsupported Thai audio manifest version.');
    }
    final rawEntries = json['entries'];
    if (rawEntries is! List) {
      throw const FormatException('Thai audio manifest entries must be a list.');
    }

    final entries = <(String, ThaiAudioForm), ThaiAudioEntry>{};
    for (final raw in rawEntries) {
      if (raw is! Map) {
        throw const FormatException('Thai audio manifest entry must be an object.');
      }
      final value = Map<String, dynamic>.from(raw);
      final phraseId = value['phraseId'];
      final rawForm = value['form'];
      final thai = value['thai'];
      final assetPath = value['asset'];
      if (phraseId is! String || phraseId.trim().isEmpty) {
        throw const FormatException('Thai audio phraseId must be non-empty.');
      }
      if (thai is! String || thai.trim().isEmpty) {
        throw const FormatException('Thai audio text must be non-empty.');
      }
      if (assetPath is! String || !_isSafeMp3Path(assetPath)) {
        throw const FormatException('Thai audio asset must be a bundled MP3 path.');
      }
      final form = ThaiAudioForm.values.where((item) => item.name == rawForm);
      if (form.isEmpty) {
        throw const FormatException('Thai audio form must be shared, male, or female.');
      }
      final entry = ThaiAudioEntry(
        phraseId: phraseId,
        form: form.single,
        thai: thai,
        assetPath: assetPath,
      );
      final key = (phraseId, entry.form);
      if (entries.containsKey(key)) {
        throw FormatException(
          'Duplicate Thai audio mapping for $phraseId/${entry.form.name}.',
        );
      }
      entries[key] = entry;
    }
    return ThaiAudioCatalog._(entries);
  }

  static Future<ThaiAudioCatalog> load(AssetBundle bundle) async {
    final contents = await bundle.loadString(manifestAsset);
    final decoded = jsonDecode(contents);
    if (decoded is! Map) {
      throw const FormatException('Thai audio manifest must be a JSON object.');
    }
    return ThaiAudioCatalog.fromJson(Map<String, dynamic>.from(decoded));
  }

  ThaiAudioEntry? match(Phrase phrase, String politeStyle) {
    final text = phrase.thaiFor(politeStyle);
    if (text.trim().isEmpty) return null;

    final selectedForm = switch (politeStyle) {
      'male' => ThaiAudioForm.male,
      'female' => ThaiAudioForm.female,
      _ => ThaiAudioForm.shared,
    };
    final selected = _entries[(phrase.id, selectedForm)];
    if (selected != null && selected.thai == text) return selected;

    final shared = _entries[(phrase.id, ThaiAudioForm.shared)];
    if (shared != null && shared.thai == text) return shared;
    return null;
  }

  static bool _isSafeMp3Path(String path) {
    if (!path.startsWith('audio/thai/') ||
        path.contains('\\') ||
        path.contains('//') ||
        path.split('/').any((part) => part == '.' || part == '..') ||
        !path.toLowerCase().endsWith('.mp3')) {
      return false;
    }
    return true;
  }
}
